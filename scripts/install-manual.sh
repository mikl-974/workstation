#!/usr/bin/env bash
# install-manual.sh — Guide d'installation manuelle NixOS
#
# Ce script assiste le parcours d'installation manuelle depuis un live ISO NixOS.
# Il affiche les étapes, vérifie certains fichiers, et rappelle les commandes.
# Il ne remplace pas le jugement de l'opérateur.
#
# Usage :
#   ./scripts/install-manual.sh [--host <host>]
#   nix run .#install-manual -- [--host <host>]
#
# Exemple :
#   ./scripts/install-manual.sh --host main

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
RST='\033[0m'

HOST=""

# ---------------------------------------------------------------------------
# Arguments
# ---------------------------------------------------------------------------

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
  ls "$REPO_ROOT/hosts" | while read -r h; do echo "  - $h"; done
  echo ""
  read -rp "Host cible : " HOST
fi

HOST_DIR="$REPO_ROOT/hosts/$HOST"

if [[ ! -d "$HOST_DIR" ]]; then
  echo "Erreur : hosts/$HOST/ introuvable."
  exit 1
fi

# ---------------------------------------------------------------------------
# Présentation
# ---------------------------------------------------------------------------

echo ""
echo -e "${BLD}${CYN}=== Guide d'installation manuelle NixOS : host '$HOST' ===${RST}"
echo ""
echo "  Ce guide accompagne l'installation depuis un live ISO NixOS."
echo "  Chaque étape est expliquée. Les commandes sont à exécuter sur la machine cible."
echo "  Référence complète : docs/manual-install.md"
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

# ---------------------------------------------------------------------------
# Étape 1 : Boot ISO
# ---------------------------------------------------------------------------

step "1/9" "Boot sur l'ISO NixOS"

echo "  • Télécharger l'ISO NixOS minimal : https://nixos.org/download/"
echo "  • Écrire sur une clé USB : dd if=nixos-minimal.iso of=/dev/sdX bs=4M status=progress"
echo "  • Booter la machine cible sur la clé USB"
echo "  • Vérifier que le système a booté : uname -a"

pause

# ---------------------------------------------------------------------------
# Étape 2 : Réseau
# ---------------------------------------------------------------------------

step "2/9" "Préparation réseau"

echo "  • Vérifier la connectivité : ping -c 3 github.com"
echo ""
echo "  Si connexion filaire : automatique dans la plupart des cas."
echo "  Si Wi-Fi :"
echo "    wpa_supplicant -B -i wlan0 -c <(wpa_passphrase SSID 'PASS')"
echo "    dhclient wlan0"
echo ""
echo "  Activer SSH pour accès distant :"
echo "    passwd root          # définir un mot de passe temporaire"
echo "    systemctl start sshd"
echo "    ip a                 # noter l'IP"

pause

# ---------------------------------------------------------------------------
# Étape 3 : Partitionnement
# ---------------------------------------------------------------------------

step "3/9" "Partitionnement et formatage"

if [[ -f "$HOST_DIR/disko.nix" ]]; then
  DISK=$(grep -oP 'device\s*=\s*"\K[^"]+' "$HOST_DIR/disko.nix" 2>/dev/null | head -1 || echo "NON DÉFINI")
  echo "  disko.nix disponible pour ce host."
  echo "  Disque configuré dans hosts/$HOST/disko.nix : $DISK"
  echo ""
  if [[ "$DISK" == "/dev/CHANGEME" || "$DISK" == "NON DÉFINI" ]]; then
    echo -e "  ${YLW}⚠ Le disque n'est pas encore défini dans disko.nix.${RST}"
    echo "  Sur la machine cible : lsblk"
    echo "  Puis éditer hosts/$HOST/disko.nix et remplacer /dev/CHANGEME"
    echo ""
  fi
  echo "  Option A — utiliser disko pour partitionner automatiquement :"
  echo "    nix run github:nix-community/disko -- --mode disko hosts/$HOST/disko.nix"
  echo ""
  echo "  Option B — partitionnement manuel (voir docs/manual-install.md pour le détail) :"
  echo "    gdisk /dev/$DISK     # créer les partitions GPT + EFI"
  echo "    # Nommage partitions : /dev/${DISK}p1 et /dev/${DISK}p2 (NVMe) ou /dev/${DISK}1 et /dev/${DISK}2 (SATA/virtio)"
  echo "    mkfs.vfat <partition1>   # ex: /dev/${DISK}p1 ou /dev/${DISK}1"
  echo "    mkfs.btrfs <partition2>  # ex: /dev/${DISK}p2 ou /dev/${DISK}2"
  echo "    # créer les subvolumes btrfs et monter"
else
  echo "  Pas de disko.nix pour ce host — partitionnement entièrement manuel."
  echo ""
  echo "  Exemple de layout recommandé (GPT + EFI + btrfs) :"
  echo "    gdisk /dev/nvme0n1"
  echo "      n → partition 1 → +512M → EF00 (EFI)"
  echo "      n → partition 2 → 100%  → 8300 (Linux)"
  echo "    mkfs.vfat -F32 /dev/nvme0n1p1"
  echo "    mkfs.btrfs /dev/nvme0n1p2"
  echo "    # subvolumes : @, @home, @nix, @var-log"
  echo "  Voir docs/manual-install.md pour les détails complets."
fi

pause

# ---------------------------------------------------------------------------
# Étape 4 : Montage
# ---------------------------------------------------------------------------

step "4/9" "Montage des partitions"

echo "  Exemple pour btrfs avec subvolumes :"
echo ""
echo "    DISK=/dev/nvme0n1"
echo "    mount -o subvol=@,compress=zstd,noatime /dev/${DISK}p2 /mnt"
echo "    mkdir -p /mnt/{boot,home,nix,var/log}"
echo "    mount /dev/${DISK}p1 /mnt/boot"
echo "    mount -o subvol=@home,compress=zstd,noatime  /dev/${DISK}p2 /mnt/home"
echo "    mount -o subvol=@nix,compress=zstd,noatime   /dev/${DISK}p2 /mnt/nix"
echo "    mount -o subvol=@var-log,compress=zstd,noatime /dev/${DISK}p2 /mnt/var/log"
echo ""
echo "  Vérifier : lsblk"

pause

# ---------------------------------------------------------------------------
# Étape 5 : Clone du repo
# ---------------------------------------------------------------------------

step "5/9" "Clone du repo workstation"

echo "  Sur la machine cible :"
echo ""
echo "    nix-shell -p git"
echo "    git clone https://github.com/mikl-974/workstation /mnt/etc/nixos"
echo "    # ou cloner ailleurs et pointer le flake :"
echo "    git clone https://github.com/mikl-974/workstation /root/workstation"

pause

# ---------------------------------------------------------------------------
# Étape 6 : Génération de la config hardware
# ---------------------------------------------------------------------------

step "6/9" "Génération de la configuration hardware"

echo "  Générer la configuration hardware spécifique à cette machine :"
echo ""
echo "    nixos-generate-config --root /mnt"
echo ""
echo "  Cela produit /mnt/etc/nixos/hardware-configuration.nix"
echo "  Ce fichier peut être copié dans hosts/$HOST/ si nécessaire."
echo ""
echo "  Important : si tu utilises disko, le partitionnement est déjà déclaratif."
echo "  La hardware-config sert surtout à détecter le matériel (CPU, carte réseau, etc.)"

pause

# ---------------------------------------------------------------------------
# Étape 7 : Installation NixOS
# ---------------------------------------------------------------------------

step "7/9" "Installation NixOS via le flake"

USERNAME=$(grep -oP 'home-manager\.users\.\K[a-zA-Z0-9_-]+' "$REPO_ROOT/flake.nix" | head -1 || echo "CHANGEME_USERNAME")

echo "  Depuis le répertoire du repo cloné :"
echo ""
echo "    cd /root/workstation   # ou l'emplacement du clone"
echo "    nixos-install --flake .#$HOST --root /mnt"
echo ""
echo "  Username défini dans flake.nix : $USERNAME"
echo ""
echo -e "  ${YLW}⚠ Avant de lancer nixos-install :${RST}"
echo "   • disko.nix : disque correct ?"
echo "   • flake.nix : CHANGEME_USERNAME remplacé par le vrai username ?"
echo "   • hosts/$HOST/default.nix : users.users.$USERNAME défini ?"

pause

# ---------------------------------------------------------------------------
# Étape 8 : Reboot
# ---------------------------------------------------------------------------

step "8/9" "Reboot"

echo "  Démonter et redémarrer :"
echo ""
echo "    umount -R /mnt"
echo "    reboot"
echo ""
echo "  Retirer le support de boot (clé USB) avant le redémarrage."

pause

# ---------------------------------------------------------------------------
# Étape 9 : Post-install
# ---------------------------------------------------------------------------

step "9/9" "Vérifications post-installation"

echo "  Après le premier boot, lancer les vérifications :"
echo ""
echo "    nix run .#post-install-check"
echo ""
echo "  Ou manuellement :"
echo "    systemctl status tailscaled"
echo "    systemctl status home-manager-$USERNAME.service  # si applicable"
echo "    ls -la ~/.config/hypr/"
echo "    which Hyprland"
echo ""
echo "  Pour rebuilder après une modification du repo :"
echo "    sudo nixos-rebuild switch --flake .#$HOST"
echo ""
echo "  Voir docs/bootstrap.md pour le workflow complet."

echo ""
echo -e "${GRN}${BLD}=== Guide terminé ===${RST}"
echo ""
echo "  Référence complète : docs/manual-install.md"
echo "  Checklist opératoire : docs/install-checklist.md"
echo ""
