#!/usr/bin/env bash
# show-config.sh — Affiche la configuration effective d'une machine
#
# Lit hosts/<name>/vars.nix et affiche un résumé des valeurs configurées.
#
# Usage :
#   ./scripts/show-config.sh <host>
#   nix run .#show-config -- <host>
#
# Exemple :
#   ./scripts/show-config.sh main

set -euo pipefail

_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ "$_SCRIPT_DIR" == /nix/store/* ]]; then
  REPO_ROOT="$PWD"
else
  REPO_ROOT="$(cd "$_SCRIPT_DIR/.." && pwd)"
fi

BLD='\033[1m'
CYN='\033[0;36m'
GRN='\033[0;32m'
YLW='\033[1;33m'
RED='\033[0;31m'
DIM='\033[2m'
RST='\033[0m'

# ---------------------------------------------------------------------------
# Argument
# ---------------------------------------------------------------------------

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <host>"
  echo "Hosts disponibles : $(ls "$REPO_ROOT/hosts" | tr '\n' ' ')"
  exit 1
fi

HOST="$1"
HOST_DIR="$REPO_ROOT/hosts/$HOST"
VARS_FILE="$HOST_DIR/vars.nix"

if [[ ! -d "$HOST_DIR" ]]; then
  echo -e "${RED}Erreur : hosts/$HOST/ introuvable.${RST}"
  echo "Hosts disponibles : $(ls "$REPO_ROOT/hosts" | tr '\n' ' ')"
  exit 1
fi

echo ""
echo -e "${BLD}${CYN}=== Configuration effective : host '$HOST' ===${RST}"
echo ""

# ---------------------------------------------------------------------------
# Lecture de vars.nix
# ---------------------------------------------------------------------------

read_var() {
  local key="$1"
  grep -oP "${key}\s*=\s*\"\K[^\"]+" "$VARS_FILE" 2>/dev/null | head -1 || echo ""
}

show_field() {
  local label="$1"
  local value="$2"
  local width=12
  if [[ -z "$value" ]]; then
    printf "  %-${width}s %s\n" "$label" "$(echo -e "${DIM}(non défini)${RST}")"
  elif echo "$value" | grep -qE '^DEFINE_'; then
    printf "  %-${width}s %s\n" "$label" "$(echo -e "${YLW}${value}${RST}  ← à définir")"
  else
    printf "  %-${width}s %s\n" "$label" "$(echo -e "${GRN}${value}${RST}")"
  fi
}

# ---------------------------------------------------------------------------
# vars.nix
# ---------------------------------------------------------------------------

echo -e "${BLD}── vars.nix${RST}  (hosts/$HOST/vars.nix)"
echo ""

if [[ ! -f "$VARS_FILE" ]]; then
  echo -e "  ${RED}✘  hosts/$HOST/vars.nix introuvable.${RST}"
  echo ""
  echo "  Initialiser avec :"
  echo "    nix run .#init-host -- $HOST"
  echo ""
  exit 1
fi

USERNAME=$(read_var "username")
HOSTNAME_VAL=$(read_var "hostname")
DISK=$(read_var "disk")
TIMEZONE=$(read_var "timezone")
LOCALE=$(read_var "locale")

show_field "username"  "$USERNAME"
show_field "hostname"  "$HOSTNAME_VAL"
[[ -f "$HOST_DIR/disko.nix" ]] && show_field "disk" "$DISK"
show_field "timezone"  "$TIMEZONE"
show_field "locale"    "$LOCALE"

echo ""

# ---------------------------------------------------------------------------
# Fichiers du host
# ---------------------------------------------------------------------------

echo -e "${BLD}── Fichiers du host${RST}"
echo ""

show_file() {
  local path="$1"
  local label="$2"
  if [[ -f "$REPO_ROOT/$path" ]]; then
    echo -e "  ${GRN}✔${RST}  $label ($path)"
  else
    echo -e "  ${DIM}—${RST}  $label ($path) — absent"
  fi
}

show_file "hosts/$HOST/vars.nix"     "vars.nix"
show_file "hosts/$HOST/default.nix"  "default.nix"
show_file "hosts/$HOST/disko.nix"    "disko.nix"

echo ""

# ---------------------------------------------------------------------------
# Profils actifs
# ---------------------------------------------------------------------------

DEFAULT_NIX="$HOST_DIR/default.nix"
if [[ -f "$DEFAULT_NIX" ]]; then
  echo -e "${BLD}── Profils importés${RST}"
  echo ""
  grep -oP '../../profiles/\K[^"]+(?=\.nix)' "$DEFAULT_NIX" 2>/dev/null | while read -r p; do
    echo "  ·  $p"
  done
  echo ""
fi

# ---------------------------------------------------------------------------
# Statut de configuration
# ---------------------------------------------------------------------------

echo -e "${BLD}── Statut${RST}"
echo ""

UNDEFINED=0
for val in "$USERNAME" "$HOSTNAME_VAL" "$TIMEZONE" "$LOCALE"; do
  echo "$val" | grep -qE '^DEFINE_' && UNDEFINED=$(( UNDEFINED + 1 ))
done
if [[ -f "$HOST_DIR/disko.nix" ]]; then
  echo "$DISK" | grep -qE '^DEFINE_|^/dev/DEFINE_' && UNDEFINED=$(( UNDEFINED + 1 ))
fi

if [[ $UNDEFINED -eq 0 ]]; then
  echo -e "  ${GRN}✔  Configuration complète — prête pour validation.${RST}"
  echo ""
  echo "  Prochaine étape :"
  echo "    nix run .#validate-install -- $HOST"
else
  echo -e "  ${YLW}⚠  $UNDEFINED champ(s) à définir dans hosts/$HOST/vars.nix.${RST}"
  echo ""
  echo "  Compléter avec :"
  echo "    nix run .#init-host -- $HOST"
fi

echo ""
