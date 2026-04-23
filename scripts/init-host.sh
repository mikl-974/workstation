#!/usr/bin/env bash
# init-host.sh — Initialisation de la configuration d'une machine

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
RST='\033[0m'

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <host>"
  echo "Hosts disponibles : $(list_hosts "$REPO_ROOT")"
  exit 1
fi

HOST="$1"
HOST_DIR="$REPO_ROOT/targets/hosts/$HOST"
VARS_FILE="$HOST_DIR/vars.nix"

if [[ ! -d "$HOST_DIR" ]]; then
  echo -e "${RED}Erreur : targets/hosts/$HOST/ introuvable.${RST}"
  echo "Hosts disponibles : $(list_hosts "$REPO_ROOT")"
  exit 1
fi

echo ""
echo -e "${BLD}${CYN}=== Initialisation de la config machine : host '$HOST' ===${RST}"
echo ""
echo "  Ce script génère targets/hosts/$HOST/vars.nix."
echo "  Seul ce fichier contient les valeurs spécifiques à la machine."
echo "  Aucun autre fichier n'est modifié."
echo ""

if [[ -f "$VARS_FILE" ]]; then
  echo -e "${YLW}⚠  targets/hosts/$HOST/vars.nix existe déjà.${RST}"
  echo ""
  read -rp "  Écraser le fichier existant ? [oui/NON] " OVERWRITE
  if [[ "${OVERWRITE,,}" != "oui" ]]; then
    echo "  Initialisation annulée."
    exit 0
  fi
  echo ""
fi

echo -e "${BLD}── Valeurs à renseigner${RST}"
echo ""
echo -e "  ${BLD}System${RST} — architecture NixOS du host"
read -rp "  system [x86_64-linux] : " SYSTEM_INPUT
SYSTEM_VAL="${SYSTEM_INPUT:-x86_64-linux}"
while ! is_supported_nixos_system "$SYSTEM_VAL"; do
  echo -e "  ${RED}Valeur invalide.${RST} Utiliser x86_64-linux ou aarch64-linux."
  read -rp "  system [x86_64-linux] : " SYSTEM_INPUT
  SYSTEM_VAL="${SYSTEM_INPUT:-x86_64-linux}"
done

echo ""
echo -e "  ${BLD}Username${RST} — identifiant Unix de l'utilisateur principal"
read -rp "  username : " USERNAME
while [[ -z "$USERNAME" || ! "$USERNAME" =~ ^[a-z][a-z0-9_-]*$ ]]; do
  echo -e "  ${RED}Valeur invalide.${RST} Le username doit correspondre à [a-z][a-z0-9_-]*."
  read -rp "  username : " USERNAME
done

echo ""
echo -e "  ${BLD}Hostname${RST} — doit correspondre à la clé nixosConfigurations"
read -rp "  hostname [$HOST] : " HOSTNAME_INPUT
HOSTNAME_VAL="${HOSTNAME_INPUT:-$HOST}"

echo ""
DISK_VAL=""
if host_uses_disko "$REPO_ROOT" "$HOST"; then
  echo -e "  ${BLD}Disque cible${RST} — ex: /dev/nvme0n1, /dev/sda"
  echo "  Lancer 'lsblk' sur la machine cible pour identifier le bon disque."
  read -rp "  disk : " DISK_INPUT
  while [[ -z "$DISK_INPUT" || "$DISK_INPUT" != /dev/* ]]; do
    echo -e "  ${RED}Valeur requise.${RST} Utiliser un chemin /dev/..."
    read -rp "  disk : " DISK_INPUT
  done
  DISK_VAL="$DISK_INPUT"
  echo ""
fi

echo -e "  ${BLD}Fuseau horaire${RST} — ex: Europe/Paris"
read -rp "  timezone [Europe/Paris] : " TIMEZONE_INPUT
TIMEZONE_VAL="${TIMEZONE_INPUT:-Europe/Paris}"

echo ""
echo -e "  ${BLD}Locale${RST} — ex: fr_FR.UTF-8"
read -rp "  locale [fr_FR.UTF-8] : " LOCALE_INPUT
LOCALE_VAL="${LOCALE_INPUT:-fr_FR.UTF-8}"

echo ""
echo -e "${BLD}── Génération de targets/hosts/$HOST/vars.nix${RST}"
echo ""

cat > "$VARS_FILE" <<VARS_CONTENT
# Machine-specific variables for host '$HOST'.
#
# Edit this file to configure this machine.
# No other file needs to be modified for installation.
# Bare metal vs VM is not declared here: that context stays modeled by the
# concrete host imports (for example modules/profiles/virtual-machine.nix).
#
# After editing, validate before installing:
#   nix run .#doctor -- --host $HOST
#   nix run .#validate-install -- $HOST
{
  system   = "$SYSTEM_VAL"; # NixOS platform: x86_64-linux or aarch64-linux
  username = "$USERNAME"; # system username
  hostname = "$HOSTNAME_VAL"; # hostname — matches nixosConfigurations key in flake.nix
VARS_CONTENT

if [[ -n "$DISK_VAL" ]]; then
  echo "  disk     = \"$DISK_VAL\"; # target disk — run \\`lsblk\\` on target" >> "$VARS_FILE"
fi

cat >> "$VARS_FILE" <<VARS_CONTENT
  timezone = "$TIMEZONE_VAL"; # see: timedatectl list-timezones
  locale   = "$LOCALE_VAL"; # system locale
}
VARS_CONTENT

echo -e "  ${GRN}✔${RST}  targets/hosts/$HOST/vars.nix créé"
echo ""
echo -e "${BLD}── Récapitulatif${RST}"
echo ""
echo "  Host     : $HOST"
echo "  System   : $SYSTEM_VAL"
echo "  Username : $USERNAME"
echo "  Hostname : $HOSTNAME_VAL"
[[ -n "$DISK_VAL" ]] && echo "  Disk     : $DISK_VAL"
echo "  Timezone : $TIMEZONE_VAL"
echo "  Locale   : $LOCALE_VAL"
echo ""
echo -e "${BLD}── Prochaines étapes${RST}"
echo ""
echo "  1. Diagnostiquer le repo :"
echo "       nix run .#doctor -- --host $HOST"
echo ""
echo "  2. Valider la configuration :"
echo "       nix run .#validate-install -- $HOST"
echo ""
echo "  3. Installer via NixOS Anywhere :"
echo "       nix run .#install-anywhere -- $HOST <IP-CIBLE>"
echo ""
echo "  4. Ou suivre le fallback manuel :"
echo "       nix run .#install-manual -- --host $HOST"
echo ""
