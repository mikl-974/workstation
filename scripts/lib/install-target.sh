#!/usr/bin/env bash
# Shared helpers for install-from-live / install-from-existing.
#
# Both flows reduce to the same three steps:
#   1. validate-install on the host
#   2. disko --mode disko targets/hosts/<host>/disko.nix
#   3. nixos-install --flake <repo>#<host> --root /mnt --no-root-passwd
#
# The two scripts only differ in the safety checks performed before disko.

set -euo pipefail

# Colors (only when stdout is a TTY).
if [[ -t 1 ]]; then
  C_BLD=$'\033[1m'; C_RED=$'\033[0;31m'; C_GRN=$'\033[0;32m'
  C_YLW=$'\033[1;33m'; C_CYN=$'\033[0;36m'; C_RST=$'\033[0m'
else
  C_BLD=""; C_RED=""; C_GRN=""; C_YLW=""; C_CYN=""; C_RST=""
fi

log()  { printf '%s\n' "$*"; }
ok()   { printf '%b\n' "  ${C_GRN}✔${C_RST}  $*"; }
warn() { printf '%b\n' "  ${C_YLW}!${C_RST}  $*"; }
err()  { printf '%b\n' "  ${C_RED}✘${C_RST}  $*" >&2; }
step() { printf '\n%b\n' "${C_BLD}${C_CYN}── $*${C_RST}"; }

die() { err "$*"; exit 1; }

confirm() {
  local prompt="$1"
  local answer
  read -rp "  ${prompt} [oui/NON] " answer
  [[ "${answer,,}" == "oui" ]]
}

# Disk currently holding `/` on the running system. Empty if not detectable.
current_root_disk() {
  local src
  src="$(findmnt -no SOURCE / 2>/dev/null || true)"
  [[ -z "$src" ]] && return 0
  lsblk -no PKNAME "$src" 2>/dev/null | head -1 | awk '{ if ($1) print "/dev/"$1 }'
}

# Refuse to format a disk that is part of the running root filesystem.
ensure_disk_safe_to_format() {
  local target_disk="$1"
  local root_disk
  root_disk="$(current_root_disk)"

  if [[ -z "$target_disk" ]]; then
    die "Aucun disque cible défini (vars.nix:disk vide)."
  fi
  if [[ ! -b "$target_disk" ]]; then
    die "Le disque cible '$target_disk' n'existe pas (block device introuvable)."
  fi
  if [[ -n "$root_disk" && "$target_disk" == "$root_disk" ]]; then
    die "Refus : le disque cible $target_disk porte / sur ce système. Reboot sur un live ISO ou choisis un autre disque."
  fi
}

# Pre-flight checks shared by both flows.
preflight() {
  local repo_root="$1" host="$2"
  command -v nix >/dev/null || die "nix introuvable. Sur un live ISO : nix-shell -p nix git"
  command -v git >/dev/null || die "git introuvable. Sur un live ISO : nix-shell -p nix git"
  [[ -d "$repo_root/targets/hosts/$host" ]] \
    || die "targets/hosts/$host/ introuvable dans $repo_root"
  [[ -f "$repo_root/targets/hosts/$host/disko.nix" ]] \
    || die "targets/hosts/$host/disko.nix manquant — l'installation auto requiert disko."
  bash "$repo_root/scripts/validate-install.sh" "$host" \
    || die "validate-install a échoué — corrige avant de continuer."
}

# Run disko (formats + mounts under /mnt).
run_disko() {
  local repo_root="$1" host="$2"
  step "Disko : partitionnement, formatage et montage sous /mnt"
  ( cd "$repo_root" && \
    nix --extra-experimental-features 'nix-command flakes' \
      run github:nix-community/disko -- \
      --mode disko "targets/hosts/$host/disko.nix" )
  ok "Disko terminé"
  log ""
  lsblk
}

# Copy the repo into the target so the installed system has it locally.
seed_repo_in_target() {
  local repo_root="$1"
  step "Copie du repo dans /mnt/etc/infra (utile au premier boot)"
  mkdir -p /mnt/etc/infra
  # rsync would be cleaner but isn't always present; use cp -a with --reflink if possible.
  cp -a --reflink=auto "$repo_root/." /mnt/etc/infra/
  ok "/mnt/etc/infra peuplé"
}

# Run nixos-install with the flake.
run_nixos_install() {
  local repo_root="$1" host="$2"
  step "Installation NixOS : nixos-install --flake .#$host --root /mnt"
  ( cd "$repo_root" && \
    nixos-install --no-root-passwd --flake ".#$host" --root /mnt )
  ok "Installation NixOS terminée"
}

# Final reboot prompt.
finalize() {
  local host="$1"
  step "Finalisation"
  if confirm "Démonter /mnt et redémarrer maintenant ?"; then
    umount -R /mnt || true
    log "Reboot dans 3 secondes..."
    sleep 3
    reboot
  else
    warn "Reboot manuel requis : umount -R /mnt && reboot"
  fi
  log ""
  log "Après reboot :"
  log "  - se connecter avec mfo (clé SSH ou mot de passe sops)"
  log "  - sudo nixos-rebuild switch --flake /etc/infra#$host  (si modifications locales)"
  log "  - nix run .#post-install-check -- --host $host"
}
