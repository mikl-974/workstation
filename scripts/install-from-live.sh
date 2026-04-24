#!/usr/bin/env bash
# install-from-live.sh — Installation NixOS depuis un live ISO NixOS.
#
# Suppose : on tourne dans un live ISO NixOS, root, /mnt vide, nix dispo.
# Pas de garde-fou « disque racine » : le live ISO tourne en RAM, donc tout
# disque physique est légitimement formattable.
#
# Usage : install-from-live <host>

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

[[ $EUID -eq 0 ]] || die "Doit être lancé en root (sudo -i depuis le live ISO)."

VARS_FILE="$(host_vars_file "$REPO_ROOT" "$HOST")"
DISK="$(read_nix_string_var "$VARS_FILE" "disk")"

log ""
log "${C_BLD}=== Installation depuis live ISO : host '$HOST' ===${C_RST}"
log ""
log "  Repo   : $REPO_ROOT"
log "  Host   : $HOST"
log "  Disque : ${DISK:-NON DÉFINI}"
log ""

step "1/5 — Pre-flight"
preflight "$REPO_ROOT" "$HOST"
ok "Host prêt"

step "2/5 — Confirmation"
warn "Le disque $DISK va être effacé intégralement."
log "  Vérifie avec : lsblk"
confirm "Continuer l'installation pour '$HOST' ?" || { log "Annulé."; exit 0; }

step "3/5 — Partitionnement"
run_disko "$REPO_ROOT" "$HOST"

step "4/5 — Installation"
seed_repo_in_target "$REPO_ROOT"
run_nixos_install "$REPO_ROOT" "$HOST"

step "5/5 — Reboot"
finalize "$HOST"
