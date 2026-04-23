#!/usr/bin/env bash
# install-manual.sh — Guide d'installation manuelle NixOS

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

HOST=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --host|-h)
      HOST="$2"
      shift 2
      ;;
    *)
      echo "Option inconnue : $1"
      echo "Usage: $0 [--host <host>]"
      exit 1
      ;;
  esac
done

if [[ -z "$HOST" ]]; then
  echo ""
  echo -e "${BLD}Hosts disponibles :${RST}"
  while IFS= read -r host; do
    [[ -z "$host" ]] && continue
    echo "  - $host"
  done < <(list_hosts "$REPO_ROOT")
  echo ""
  read -rp "Host cible : " HOST
fi

HOST_DIR="$REPO_ROOT/targets/hosts/$HOST"
if [[ ! -d "$HOST_DIR" ]]; then
  echo -e "${RED}Erreur : targets/hosts/$HOST/ introuvable.${RST}"
  exit 1
fi

VARS_FILE="$(host_vars_file "$REPO_ROOT" "$HOST")"
SYSTEM="$(read_nix_string_var "$VARS_FILE" "system")"
USERNAME="$(read_nix_string_var "$VARS_FILE" "username")"
DISK="$(read_nix_string_var "$VARS_FILE" "disk")"
TIMEZONE="$(read_nix_string_var "$VARS_FILE" "timezone")"
LOCALE="$(read_nix_string_var "$VARS_FILE" "locale")"

VALIDATE_SCRIPT="$REPO_ROOT/scripts/validate-install.sh"
if [[ -f "$VALIDATE_SCRIPT" ]]; then
  if ! bash "$VALIDATE_SCRIPT" "$HOST"; then
    echo ""
    echo -e "${RED}Le host '$HOST' n'est pas prêt : parcours manuel interrompu.${RST}"
    exit 1
  fi
fi

echo ""
echo -e "${BLD}${CYN}=== Guide d'installation manuelle NixOS : host '$HOST' ===${RST}"
echo ""
echo "  Ce fallback suit la même source de vérité que le parcours NixOS Anywhere."
echo "  Référence complète : docs/manual-install.md"
echo ""
echo -e "  ${BLD}Résumé host${RST}"
echo "    system   : ${SYSTEM:-inconnu}"
echo "    username : ${USERNAME:-inconnu}"
echo "    disk     : ${DISK:-non requis}"
echo "    timezone : ${TIMEZONE:-inconnue}"
echo "    locale   : ${LOCALE:-inconnue}"
echo ""

pause() {
  echo ""
  read -rp "  [Entrée pour continuer]" _
  echo ""
}

step() {
  echo -e "${BLD}${CYN}── Étape $1 : $2${RST}"
  echo ""
}

step "1/9" "Boot sur l'ISO NixOS"
echo "  • Télécharger l'ISO NixOS minimal : https://nixos.org/download/"
echo "  • Écrire sur une clé USB : dd if=nixos-minimal.iso of=/dev/sdX bs=4M status=progress conv=fsync"
echo "    (`conv=fsync` force la synchronisation finale pour éviter une clé incomplètement écrite)"
echo "  • Booter la machine cible sur la clé USB"
echo "  • Vérifier : uname -a"
pause

step "2/9" "Préparation réseau"
echo "  • Vérifier la connectivité : ping -c 3 github.com"
echo "  • Pour le Wi-Fi :"
echo "      wpa_supplicant -B -i wlan0 -c <(wpa_passphrase \"SSID\" \"PASS\")"
echo "      dhclient wlan0"
echo "  • Pour un accès distant :"
echo "      passwd root"
echo "      systemctl start sshd"
echo "      ip a"
pause

step "3/9" "Partitionnement et formatage"
if host_uses_disko "$REPO_ROOT" "$HOST"; then
  echo "  disko.nix est disponible pour ce host."
  echo "  Disque configuré : ${DISK:-NON DÉFINI}"
  echo ""
  echo "  Option A — déclarative (recommandée) :"
  echo "      nix run github:nix-community/disko -- --mode disko targets/hosts/$HOST/disko.nix"
  echo ""
fi
echo "  Option B — manuelle :"
echo "      lsblk"
echo "      gdisk ${DISK:-/dev/nvme0n1}"
echo "      mkfs.vfat -F32 <partition-efi>"
echo "      mkfs.btrfs -f <partition-root>"
echo "      mount <partition-root> /mnt"
echo "      btrfs subvolume create /mnt/@"
echo "      btrfs subvolume create /mnt/@home"
echo "      btrfs subvolume create /mnt/@nix"
echo "      btrfs subvolume create /mnt/@var-log"
echo "      umount /mnt"
pause

step "4/9" "Montage des partitions"
echo "  Exemple btrfs :"
echo "      DISK=${DISK:-/dev/nvme0n1}"
echo "      mount -o subvol=@,compress=zstd,noatime \"\${DISK}p2\" /mnt"
echo "      mkdir -p /mnt/{boot,home,nix,var/log}"
echo "      mount \"\${DISK}p1\" /mnt/boot"
echo "      mount -o subvol=@home,compress=zstd,noatime \"\${DISK}p2\" /mnt/home"
echo "      mount -o subvol=@nix,compress=zstd,noatime \"\${DISK}p2\" /mnt/nix"
echo "      mount -o subvol=@var-log,compress=zstd,noatime \"\${DISK}p2\" /mnt/var/log"
echo "      lsblk"
pause

step "5/9" "Clone du repo workstation"
echo "  Sur la machine cible :"
echo "      nix-shell -p git"
echo "      git clone https://github.com/mikl-974/workstation /root/workstation"
echo "      cd /root/workstation"
echo ""
echo "  Si tu n'as pas encore initialisé vars.nix sur la cible :"
echo "      nix run .#init-host -- $HOST"
echo "      nix run .#doctor -- --host $HOST"
echo "      nix run .#validate-install -- $HOST"
pause

step "6/9" "Configuration hardware et cohérence du host"
echo "  Générer la configuration hardware si nécessaire :"
echo "      nixos-generate-config --root /mnt"
echo ""
echo "  Vérifier ensuite :"
echo "      nix run .#show-config -- $HOST"
echo "      nix run .#validate-install -- $HOST"
pause

step "7/9" "Installation NixOS via le flake"
echo "  Depuis /root/workstation :"
echo "      nixos-install --flake /root/workstation#$HOST --root /mnt"
echo ""
echo "  Cette étape applique aussi la configuration Home Manager déclarée dans le flake."
pause

step "8/9" "Reboot"
echo "      umount -R /mnt"
echo "      reboot"
echo ""
echo "  Retirer la clé USB avant le redémarrage."
pause

step "9/9" "Premier boot et vérification"
echo "  Après le redémarrage :"
echo "      sudo nixos-rebuild switch --flake /root/workstation#$HOST   # si un rebuild est nécessaire"
echo "      nix run .#post-install-check -- --host $HOST"
echo ""
echo "  Puis relire :"
echo "      docs/first-boot.md"
echo "      docs/bootstrap.md"

echo ""
echo -e "${GRN}${BLD}=== Guide terminé ===${RST}"
echo ""
echo "  Référence complète : docs/manual-install.md"
echo "  Checklist opératoire : docs/install-checklist.md"
echo ""
