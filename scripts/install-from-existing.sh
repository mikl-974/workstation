#!/usr/bin/env bash
# install-from-existing.sh — Installation NixOS depuis un NixOS déjà installé,
# vers un *autre* disque que celui qui porte / sur le système courant.
#
# Cas d'usage : réinstaller `gaming` sur /dev/nvme1n1 depuis `main` qui boot
# sur /dev/nvme0n1, sans clé USB.
#
# Garde-fou : refuse explicitement si le disque cible est celui qui porte /.
#
# Usage : install-from-existing <host>

set -euo pipefail

_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./lib/workstation-install.sh
source "$_SCRIPT_DIR/lib/workstation-install.sh"
# shellcheck source=./lib/install-target.sh
source "$_SCRIPT_DIR/lib/install-target.sh"
REPO_ROOT="$(resolve_repo_root "$_SCRIPT_DIR")"

if [[ $# -lt 1 ]]; then
  log "Usage: $0 <host>"
  log "Hosts disponibles : $(list_hosts "$REPO_ROOT")"
  exit 1
fi
HOST="$1"

[[ $EUID -eq 0 ]] || die "Doit être lancé avec sudo."

VARS_FILE="$(host_vars_file "$REPO_ROOT" "$HOST")"
DISK="$(read_nix_string_var "$VARS_FILE" "disk")"
ROOT_DISK="$(current_root_disk)"

log ""
log "${C_BLD}=== Installation depuis NixOS existant : host '$HOST' ===${C_RST}"
log ""
log "  Repo          : $REPO_ROOT"
log "  Host          : $HOST"
log "  Disque cible  : ${DISK:-NON DÉFINI}"
log "  Disque actuel : ${ROOT_DISK:-?} (porte / — protégé)"
log ""

step "1/5 — Pre-flight"
preflight "$REPO_ROOT" "$HOST"
ensure_disk_safe_to_format "$DISK"
ok "Host prêt et disque cible distinct du disque racine"

step "2/5 — Confirmation"
warn "Le disque $DISK va être effacé intégralement."
log "  Vérifie avec : lsblk"
log "  Le système courant ($ROOT_DISK) ne sera pas touché."
confirm "Continuer l'installation de '$HOST' sur $DISK ?" || { log "Annulé."; exit 0; }

step "3/5 — Partitionnement"
run_disko "$REPO_ROOT" "$HOST"

step "4/5 — Installation"
seed_repo_in_target "$REPO_ROOT"
run_nixos_install "$REPO_ROOT" "$HOST"

step "5/5 — Finalisation"
log ""
log "Le système hôte n'est pas redémarré : retire le disque cible et boote-le"
log "sur la machine voulue, ou démonte simplement /mnt :"
log "    umount -R /mnt"
log ""
log "Après premier boot du nouveau système :"
log "  - sudo nixos-rebuild switch --flake /etc/infra#$HOST"
log "  - nix run .#post-install-check -- --host $HOST"
