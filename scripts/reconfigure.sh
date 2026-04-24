#!/usr/bin/env bash
# reconfigure.sh — Apply the flake configuration to the running NixOS system.
#
# Use case : the system is already a working NixOS install (post-install,
# OrbStack VM, recovered system, etc.) and you want to bring its config in
# line with `targets/hosts/<host>/`. No formatting, no /mnt, no install.
#
# Equivalent to:
#   nix run .#validate-install -- <host>
#   sudo nixos-rebuild switch --flake .#<host>
#
# Usage : reconfigure <host> [--mode switch|test|boot|dry-activate]

set -euo pipefail

_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./lib/workstation-install.sh
source "$_SCRIPT_DIR/lib/workstation-install.sh"
# shellcheck source=./lib/install-target.sh
source "$_SCRIPT_DIR/lib/install-target.sh"
REPO_ROOT="$(resolve_repo_root "$_SCRIPT_DIR")"

HOST=""
MODE="switch"
REQUESTED_MODE="$MODE"
EFFECTIVE_MODE="$MODE"
REBUILD_EXTRA_ARGS=()
BOOTLOADER_FALLBACK=0
BOOTLOADER_MOUNTPOINT="/boot"

run_rebuild() {
  local extra_args=("$@")
  local log_file
  local status

  log_file="$(mktemp)"
  set +e
  (
    cd "$REPO_ROOT" && sudo nixos-rebuild "$MODE" --impure --flake ".#$HOST" "${extra_args[@]}"
  ) 2>&1 | tee "$log_file"
  status=${PIPESTATUS[0]}
  set -e

  REBUILD_LAST_LOG="$log_file"
  return "$status"
}

rebuild_hit_seccomp_filter_error() {
  [[ -n "$REBUILD_LAST_LOG" ]] && grep -q "unable to load seccomp BPF program" "$REBUILD_LAST_LOG"
}

rebuild_hit_unmounted_boot_error() {
  [[ -n "$REBUILD_LAST_LOG" ]] \
    && grep -Eq "efiSysMountPoint = '.*' is not a mounted partition" "$REBUILD_LAST_LOG"
}

capture_bootloader_mountpoint() {
  local mountpoint

  mountpoint="$(
    sed -n "s/.*efiSysMountPoint = '\\([^']*\\)' is not a mounted partition.*/\\1/p" "$REBUILD_LAST_LOG" \
      | tail -n 1
  )"
  if [[ -n "$mountpoint" ]]; then
    BOOTLOADER_MOUNTPOINT="$mountpoint"
  fi
}

print_bootloader_resolution_commands() {
  log "  Commandes utiles pour finaliser le bootloader :"
  log "    findmnt $BOOTLOADER_MOUNTPOINT || lsblk -f"
  log "    sudo mount <partition-efi> $BOOTLOADER_MOUNTPOINT"
  log "    sudo nix --extra-experimental-features 'nix-command flakes' run .#install-manual -- $HOST --mode switch"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --mode) MODE="$2"; shift 2 ;;
    -h|--help)
      cat <<EOF
Usage: reconfigure <host> [--mode switch|test|boot|dry-activate]

Modes (passed straight to nixos-rebuild):
  switch        apply now and set as default boot entry (default)
  test          apply now without changing the boot entry
  boot          stage for next boot, do not activate
  dry-activate  show what would change, change nothing
EOF
      exit 0
      ;;
    *) HOST="$1"; shift ;;
  esac
done

[[ -n "$HOST" ]] || die "Usage: reconfigure <host> [--mode switch|test|boot|dry-activate]"
[[ -d "$REPO_ROOT/targets/hosts/$HOST" ]] || die "targets/hosts/$HOST/ introuvable."
command -v nixos-rebuild >/dev/null \
  || die "nixos-rebuild introuvable — ce script ne s'utilise que sur un NixOS existant."
REQUESTED_MODE="$MODE"

step "1/3 — Validation du host '$HOST'"
bash "$REPO_ROOT/scripts/validate-install.sh" "$HOST" \
  || die "validate-install a échoué — corrige avant de reconfigurer."

step "2/3 — nixos-rebuild $MODE --flake .#$HOST"
log "  Repo : $REPO_ROOT"
log ""

REBUILD_LAST_LOG=""
REBUILD_OK=0
if run_rebuild; then
  REBUILD_OK=1
fi

if [[ $REBUILD_OK -eq 0 ]] && rebuild_hit_seccomp_filter_error; then
  warn "Le sandbox Nix du host courant ne supporte pas ce filtre seccomp — nouvelle tentative avec filter-syscalls=false"
  log ""
  REBUILD_EXTRA_ARGS=(--option filter-syscalls false)
  if run_rebuild "${REBUILD_EXTRA_ARGS[@]}"; then
    REBUILD_OK=1
  fi
fi

if [[ $REBUILD_OK -eq 0 ]]; then
  if [[ "$MODE" == "switch" ]] && rebuild_hit_unmounted_boot_error; then
    capture_bootloader_mountpoint
    warn "$BOOTLOADER_MOUNTPOINT n'est pas monté sur le host courant — nouvelle tentative en mode test pour appliquer la configuration sans toucher au bootloader"
    log ""
    MODE="test"
    if run_rebuild "${REBUILD_EXTRA_ARGS[@]}"; then
      REBUILD_OK=1
      BOOTLOADER_FALLBACK=1
    else
      log ""
      print_bootloader_resolution_commands
      die "nixos-rebuild test a échoué après l'échec d'installation du bootloader."
    fi
  elif [[ ${#REBUILD_EXTRA_ARGS[@]} -gt 0 ]]; then
    die "nixos-rebuild a échoué même après désactivation de filter-syscalls."
  else
    die "nixos-rebuild a échoué."
  fi
fi

EFFECTIVE_MODE="$MODE"

step "3/3 — Terminé"
if [[ $BOOTLOADER_FALLBACK -eq 1 || "$EFFECTIVE_MODE" != "$REQUESTED_MODE" ]]; then
  ok "Configuration '$HOST' appliquée (mode effectif : $EFFECTIVE_MODE ; demandé : $REQUESTED_MODE)"
  warn "Le bootloader n'a pas été mis à jour."
  log ""
  print_bootloader_resolution_commands
else
  ok "Configuration '$HOST' appliquée (mode: $EFFECTIVE_MODE)"
fi
log ""
log "Vérifications utiles :"
log "  nixos-rebuild list-generations | head -5"
log "  nix run .#post-install-check -- --host $HOST"
