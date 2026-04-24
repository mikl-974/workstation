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

step "1/3 — Validation du host '$HOST'"
bash "$REPO_ROOT/scripts/validate-install.sh" "$HOST" \
  || die "validate-install a échoué — corrige avant de reconfigurer."

step "2/3 — nixos-rebuild $MODE --flake .#$HOST"
log "  Repo : $REPO_ROOT"
log ""
( cd "$REPO_ROOT" && sudo nixos-rebuild "$MODE" --flake ".#$HOST" )

step "3/3 — Terminé"
ok "Configuration '$HOST' appliquée (mode: $MODE)"
log ""
log "Vérifications utiles :"
log "  nixos-rebuild list-generations | head -5"
log "  nix run .#post-install-check -- --host $HOST"
