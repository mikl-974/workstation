#!/usr/bin/env bash
# show-config.sh — Affiche la configuration effective d'une machine

set -euo pipefail

_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./lib/workstation-install.sh
source "$_SCRIPT_DIR/lib/workstation-install.sh"
REPO_ROOT="$(resolve_repo_root "$_SCRIPT_DIR")"

BLD='\033[1m'
CYN='\033[0;36m'
GRN='\033[0;32m'
YLW='\033[1;33m'
RED='\033[0;31m'
DIM='\033[2m'
RST='\033[0m'

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <host>"
  echo "Hosts disponibles : $(list_hosts "$REPO_ROOT")"
  exit 1
fi

HOST="$1"
HOST_DIR="$REPO_ROOT/targets/hosts/$HOST"
VARS_FILE="$(host_vars_file "$REPO_ROOT" "$HOST")"
MACHINE_CONTEXT="$(host_machine_context "$REPO_ROOT" "$HOST")"

if [[ ! -d "$HOST_DIR" ]]; then
  echo -e "${RED}Erreur : targets/hosts/$HOST/ introuvable.${RST}"
  echo "Hosts disponibles : $(list_hosts "$REPO_ROOT")"
  exit 1
fi

echo ""
echo -e "${BLD}${CYN}=== Configuration effective : host '$HOST' ===${RST}"
echo ""

show_field() {
  local label="$1"
  local value="$2"
  local width=12
  if [[ -z "$value" ]]; then
    printf "  %-${width}s %s\n" "$label" "$(echo -e "${DIM}(non défini)${RST}")"
  elif is_placeholder_value "$value"; then
    printf "  %-${width}s %s\n" "$label" "$(echo -e "${YLW}${value}${RST}  ← à définir")"
  else
    printf "  %-${width}s %s\n" "$label" "$(echo -e "${GRN}${value}${RST}")"
  fi
}

echo -e "${BLD}── vars.nix${RST}  (targets/hosts/$HOST/vars.nix)"
echo ""
if [[ ! -f "$VARS_FILE" ]]; then
  echo -e "  ${RED}✘  targets/hosts/$HOST/vars.nix introuvable.${RST}"
  echo ""
  echo "  Initialiser avec :"
  echo "    nix run .#init-host -- $HOST"
  exit 1
fi

SYSTEM="$(read_nix_string_var "$VARS_FILE" "system")"
USERNAME="$(read_nix_string_var "$VARS_FILE" "username")"
HOSTNAME_VAL="$(read_nix_string_var "$VARS_FILE" "hostname")"
DISK="$(read_nix_string_var "$VARS_FILE" "disk")"
TIMEZONE="$(read_nix_string_var "$VARS_FILE" "timezone")"
LOCALE="$(read_nix_string_var "$VARS_FILE" "locale")"

show_field "system"   "$SYSTEM"
show_field "username" "$USERNAME"
show_field "hostname" "$HOSTNAME_VAL"
[[ -f "$(host_disko_file "$REPO_ROOT" "$HOST")" ]] && show_field "disk" "$DISK"
show_field "timezone" "$TIMEZONE"
show_field "locale"   "$LOCALE"

echo ""
echo -e "${BLD}── Contexte machine${RST}"
echo ""
if [[ "$MACHINE_CONTEXT" == "virtual-machine" ]]; then
  echo -e "  ${GRN}✔${RST}  virtual-machine — profil modules/profiles/virtual-machine.nix importé"
else
  echo -e "  ${GRN}✔${RST}  bare-metal — aucun profil VM détecté"
fi

echo ""
echo -e "${BLD}── Fichiers du host${RST}"
echo ""
for path in \
  "$VARS_FILE|vars.nix" \
  "$(host_default_file "$REPO_ROOT" "$HOST")|default.nix" \
  "$(host_disko_file "$REPO_ROOT" "$HOST")|disko.nix"; do
  file="${path%%|*}"
  label="${path##*|}"
  if [[ -f "$file" ]]; then
    echo -e "  ${GRN}✔${RST}  $label"
  else
    echo -e "  ${DIM}—${RST}  $label — absent"
  fi
done

echo ""
echo -e "${BLD}── Composition Home Manager${RST}"
echo ""
if [[ -f "$(home_target_file "$REPO_ROOT" "$HOST")" ]]; then
  echo -e "  ${GRN}✔${RST}  home/targets/$HOST.nix"
else
  echo -e "  ${RED}✘${RST}  aucune composition Home Manager trouvée"
fi

echo ""
DEFAULT_NIX="$(host_default_file "$REPO_ROOT" "$HOST")"
if [[ -d "$HOST_DIR" ]]; then
  echo -e "${BLD}── Profils importés${RST}"
  echo ""
  grep -RhoE 'modules/profiles/[^[:space:]]+\.nix' "$HOST_DIR" \
    | sed -E 's#.*modules/profiles/([^[:space:]]+)\.nix#  ·  \1#' \
    | sort -u
  echo ""
fi

if [[ -d "$HOST_DIR" ]]; then
  echo -e "${BLD}── Stacks importées${RST}"
  echo ""
  STACKS="$(grep -RhoE 'stacks/[^[:space:]]+/default\.nix' "$HOST_DIR" \
    | sed -E 's#.*stacks/([^/]+)/default\.nix#  ·  \1#' \
    | sort -u || true)"
  if [[ -n "$STACKS" ]]; then
    echo "$STACKS"
  else
    echo -e "  ${DIM}—${RST}  aucune stack importée explicitement"
  fi
  echo ""
fi

echo -e "${BLD}── Statut${RST}"
echo ""
UNDEFINED=0
for value in "$SYSTEM" "$USERNAME" "$HOSTNAME_VAL" "$TIMEZONE" "$LOCALE"; do
  if [[ -z "$value" ]] || is_placeholder_value "$value"; then
    UNDEFINED=$(( UNDEFINED + 1 ))
  fi
done
if [[ -f "$(host_disko_file "$REPO_ROOT" "$HOST")" ]] && { [[ -z "$DISK" ]] || is_placeholder_value "$DISK"; }; then
  UNDEFINED=$(( UNDEFINED + 1 ))
fi

if [[ $UNDEFINED -eq 0 ]]; then
  echo -e "  ${GRN}✔  Configuration complète — prête pour validation.${RST}"
  echo ""
  echo "  Prochaine étape :"
  echo "    nix run .#doctor -- --host $HOST"
  echo "    nix run .#validate-install -- $HOST"
else
  echo -e "  ${YLW}⚠  $UNDEFINED champ(s) à définir dans targets/hosts/$HOST/vars.nix.${RST}"
  echo ""
  echo "  Compléter avec :"
  echo "    nix run .#init-host -- $HOST"
fi

echo ""
