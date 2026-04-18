#!/usr/bin/env bash
# init-host.sh — Initialisation de la configuration d'une machine
#
# Crée ou régénère hosts/<name>/vars.nix pour un host existant.
# Aucun autre fichier n'est modifié.
#
# Usage :
#   ./scripts/init-host.sh <host>
#   nix run .#init-host -- <host>
#
# Exemple :
#   ./scripts/init-host.sh main

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
echo -e "${BLD}${CYN}=== Initialisation de la config machine : host '$HOST' ===${RST}"
echo ""
echo "  Ce script génère hosts/$HOST/vars.nix."
echo "  Seul ce fichier contient les valeurs spécifiques à la machine."
echo "  Aucun autre fichier n'est modifié."
echo ""

# ---------------------------------------------------------------------------
# Avertissement si vars.nix existe déjà
# ---------------------------------------------------------------------------

if [[ -f "$VARS_FILE" ]]; then
  echo -e "${YLW}⚠  hosts/$HOST/vars.nix existe déjà.${RST}"
  echo ""
  read -rp "  Écraser le fichier existant ? [oui/NON] " OVERWRITE
  if [[ "${OVERWRITE,,}" != "oui" ]]; then
    echo ""
    echo "  Initialisation annulée. Fichier conservé."
    exit 0
  fi
  echo ""
fi

# ---------------------------------------------------------------------------
# Collecte des valeurs
# ---------------------------------------------------------------------------

echo -e "${BLD}── Valeurs à renseigner${RST}"
echo ""

# Username
echo -e "  ${BLD}Username${RST} — identifiant Unix de l'utilisateur principal (ex: alice, mikl)"
read -rp "  username : " USERNAME
while [[ -z "$USERNAME" || ! "$USERNAME" =~ ^[a-z][a-z0-9_-]*$ ]]; do
  echo -e "  ${RED}Valeur invalide.${RST} Le username doit commencer par une lettre minuscule et ne contenir que [a-z0-9_-]."
  read -rp "  username : " USERNAME
done

echo ""

# Hostname (pré-rempli avec le nom du host)
echo -e "  ${BLD}Hostname${RST} — nom de la machine (doit correspondre à la clé nixosConfigurations dans flake.nix)"
read -rp "  hostname [$HOST] : " HOSTNAME_INPUT
HOSTNAME_VAL="${HOSTNAME_INPUT:-$HOST}"

echo ""

# Disk (uniquement si disko.nix existe pour ce host)
DISK_VAL=""
if [[ -f "$HOST_DIR/disko.nix" ]]; then
  echo -e "  ${BLD}Disque cible${RST} — device à utiliser pour l'installation (ex: /dev/nvme0n1, /dev/sda)"
  echo "  Lancer 'lsblk' sur la machine cible pour identifier le bon disque."
  read -rp "  disk : " DISK_INPUT
  while [[ -z "$DISK_INPUT" ]]; do
    echo -e "  ${RED}Valeur requise${RST} — disko.nix est présent pour ce host."
    read -rp "  disk : " DISK_INPUT
  done
  DISK_VAL="$DISK_INPUT"
  echo ""
fi

# Timezone
echo -e "  ${BLD}Fuseau horaire${RST} — ex: Europe/Paris, America/New_York, UTC"
echo "  Liste complète : timedatectl list-timezones"
read -rp "  timezone [Europe/Paris] : " TIMEZONE_INPUT
TIMEZONE_VAL="${TIMEZONE_INPUT:-Europe/Paris}"

echo ""

# Locale
echo -e "  ${BLD}Locale${RST} — ex: fr_FR.UTF-8, en_US.UTF-8"
read -rp "  locale [fr_FR.UTF-8] : " LOCALE_INPUT
LOCALE_VAL="${LOCALE_INPUT:-fr_FR.UTF-8}"

echo ""

# ---------------------------------------------------------------------------
# Génération du fichier vars.nix
# ---------------------------------------------------------------------------

echo -e "${BLD}── Génération de hosts/$HOST/vars.nix${RST}"
echo ""

if [[ -n "$DISK_VAL" ]]; then
  DISK_LINE="  disk     = \"$DISK_VAL\"; # target disk — run \`lsblk\` on target (e.g. /dev/nvme0n1)"
else
  DISK_LINE=""
fi

cat > "$VARS_FILE" << EOF
# Machine-specific variables for host '$HOST'.
#
# Edit this file to configure this machine.
# No other file needs to be modified for installation.
#
# After editing, validate before installing:
#   nix run .#validate-install -- $HOST
{
  username = "$USERNAME"; # system username
  hostname = "$HOSTNAME_VAL"; # hostname — matches nixosConfigurations key in flake.nix
EOF

if [[ -n "$DISK_LINE" ]]; then
  echo "$DISK_LINE" >> "$VARS_FILE"
fi

cat >> "$VARS_FILE" << EOF
  timezone = "$TIMEZONE_VAL"; # see: timedatectl list-timezones
  locale   = "$LOCALE_VAL"; # system locale
}
EOF

echo -e "  ${GRN}✔${RST}  hosts/$HOST/vars.nix créé"
echo ""

# ---------------------------------------------------------------------------
# Récapitulatif
# ---------------------------------------------------------------------------

echo -e "${BLD}── Récapitulatif${RST}"
echo ""
echo "  Host     : $HOST"
echo "  Username : $USERNAME"
echo "  Hostname : $HOSTNAME_VAL"
[[ -n "$DISK_VAL" ]] && echo "  Disk     : $DISK_VAL"
echo "  Timezone : $TIMEZONE_VAL"
echo "  Locale   : $LOCALE_VAL"
echo ""
echo "  Fichier généré : hosts/$HOST/vars.nix"
echo ""
echo -e "${BLD}── Prochaines étapes${RST}"
echo ""
echo "  1. Valider la configuration :"
echo "       nix run .#validate-install -- $HOST"
echo ""
echo "  2. Installer via NixOS Anywhere :"
echo "       nix run .#install-anywhere -- $HOST <IP-CIBLE>"
echo ""
echo "  3. Ou afficher la configuration effective :"
echo "       nix run .#show-config -- $HOST"
echo ""
