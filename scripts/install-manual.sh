#!/usr/bin/env bash
# install-manual.sh — Dispatcher d'installation manuelle.
#
# Détecte le contexte d'exécution et délègue au script approprié :
#   - live ISO NixOS        → install-from-live
#   - NixOS déjà installé   → reconfigure
#
# Usage : install-manual <host> [--method live|existing] [args...]

set -euo pipefail

_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./lib/workstation-install.sh
source "$_SCRIPT_DIR/lib/workstation-install.sh"
# shellcheck source=./lib/install-target.sh
source "$_SCRIPT_DIR/lib/install-target.sh"
REPO_ROOT="$(resolve_repo_root "$_SCRIPT_DIR")"

HOST=""
METHOD=""
EXTRA_ARGS=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --method) METHOD="$2"; shift 2 ;;
    -h|--help)
      cat <<EOF
Usage: install-manual <host> [--method live|existing] [args...]

Détection automatique si --method n'est pas fourni :
  - kernel cmdline contient 'boot=' (live ISO) → live
  - sinon, fichier /etc/NIXOS présent → existing (reconfigure le système courant)

Notes :
  - 'existing' applique uniquement la config NixOS du host sur le système courant
  - pour installer sur un autre disque depuis un NixOS existant, utiliser
    directement : install-from-existing <host>
  - les arguments supplémentaires sont passés au script cible
    ex. : nix run .#install-manual -- homelab --mode test
EOF
      exit 0
      ;;
    --)
      shift
      EXTRA_ARGS+=("$@")
      break
      ;;
    *)
      if [[ -z "$HOST" ]]; then
        HOST="$1"
      else
        EXTRA_ARGS+=("$1")
      fi
      shift
      ;;
  esac
done

if [[ -z "$HOST" ]]; then
  log "Hosts disponibles : $(list_hosts "$REPO_ROOT")"
  read -rp "Host cible : " HOST
fi

if [[ -z "$METHOD" ]]; then
  if [[ -d /iso ]] || grep -qE '\bboot=' /proc/cmdline 2>/dev/null; then
    METHOD="live"
  elif [[ -e /etc/NIXOS ]]; then
    METHOD="existing"
  else
    die "Contexte indétectable. Précise --method live|existing."
  fi
  log "Méthode auto-détectée : $METHOD"
fi

dispatch_app() {
  local app_name="$1"
  local local_script="$2"

  if [[ "$_SCRIPT_DIR" == /nix/store/* ]]; then
    exec nix --extra-experimental-features 'nix-command flakes' run "${REPO_ROOT}#${app_name}" -- "$HOST" "${EXTRA_ARGS[@]}"
  fi

  exec bash "$_SCRIPT_DIR/$local_script" "$HOST" "${EXTRA_ARGS[@]}"
}

case "$METHOD" in
  live)     dispatch_app "install-from-live" "install-from-live.sh" ;;
  existing) dispatch_app "reconfigure" "reconfigure.sh" ;;
  *)        die "Méthode inconnue : $METHOD (attendu: live | existing)" ;;
esac
