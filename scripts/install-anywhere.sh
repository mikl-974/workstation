#!/usr/bin/env bash
# install-anywhere.sh — Orchestration de l'installation via NixOS Anywhere
#
# Ce script orchestre et vérifie le parcours NixOS Anywhere.
# Il ne redéfinit pas la configuration — celle-ci reste dans flake.nix et hosts/.
#
# Usage :
#   ./scripts/install-anywhere.sh <host> <ip-cible>
#   nix run .#install-anywhere -- <host> <ip-cible>
#
# Exemple :
#   ./scripts/install-anywhere.sh main 192.168.1.50

set -euo pipefail

_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ "$_SCRIPT_DIR" == /nix/store/* ]]; then
  REPO_ROOT="$PWD"
else
  REPO_ROOT="$(cd "$_SCRIPT_DIR/.." && pwd)"
fi

RED='\033[0;31m'
GRN='\033[0;32m'
YLW='\033[1;33m'
BLD='\033[1m'
RST='\033[0m'

# ---------------------------------------------------------------------------
# Arguments
# ---------------------------------------------------------------------------

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <host> <ip-cible>"
  echo ""
  echo "Hosts disponibles : $(ls "$REPO_ROOT/hosts" | tr '\n' ' ')"
  echo ""
  echo "Exemple : $0 main 192.168.1.50"
  exit 1
fi

HOST="$1"
TARGET_IP="$2"

echo ""
echo -e "${BLD}=== Installation NixOS Anywhere : host '$HOST' → $TARGET_IP ===${RST}"
echo ""

# ---------------------------------------------------------------------------
# 1. Validation préalable
# ---------------------------------------------------------------------------

echo -e "${BLD}── Étape 1/5 : Validation de la configuration${RST}"
echo ""

VALIDATE_SCRIPT="$REPO_ROOT/scripts/validate-install.sh"
if [[ -x "$VALIDATE_SCRIPT" ]]; then
  if ! "$VALIDATE_SCRIPT" "$HOST"; then
    echo ""
    echo -e "${RED}✘ Validation échouée — installation annulée.${RST}"
    echo "  Corrige les erreurs signalées par validate-install.sh avant de relancer."
    exit 1
  fi
else
  echo -e "${YLW}⚠ validate-install.sh introuvable ou non exécutable — validation ignorée.${RST}"
fi

# ---------------------------------------------------------------------------
# 2. Vérification des prérequis locaux
# ---------------------------------------------------------------------------

echo ""
echo -e "${BLD}── Étape 2/5 : Vérification des prérequis${RST}"
echo ""

MISSING=0

check_cmd() {
  local cmd="$1"
  local hint="$2"
  if command -v "$cmd" &>/dev/null; then
    echo -e "  ${GRN}✔${RST}  $cmd disponible"
  else
    echo -e "  ${RED}✘${RST}  $cmd introuvable — $hint"
    MISSING=$(( MISSING + 1 ))
  fi
}

check_cmd "nix"         "Nix doit être installé avec les flakes activés"
check_cmd "ssh"         "SSH est requis pour accéder à la machine cible"

# Vérifier que les flakes sont activés
if nix flake --help &>/dev/null 2>&1; then
  echo -e "  ${GRN}✔${RST}  nix flakes activés"
else
  echo -e "  ${YLW}⚠${RST}  Impossible de vérifier l'activation des flakes — assure-toi qu'ils sont activés"
fi

if [[ $MISSING -gt 0 ]]; then
  echo ""
  echo -e "${RED}✘ Prérequis manquants — installation annulée.${RST}"
  exit 1
fi

# ---------------------------------------------------------------------------
# 3. Vérification de la connectivité SSH
# ---------------------------------------------------------------------------

echo ""
echo -e "${BLD}── Étape 3/5 : Vérification de la connectivité SSH${RST}"
echo ""

echo "  Test SSH vers root@$TARGET_IP ..."
if ssh -o ConnectTimeout=10 -o BatchMode=yes -o StrictHostKeyChecking=accept-new \
       "root@$TARGET_IP" "echo OK" &>/dev/null; then
  echo -e "  ${GRN}✔${RST}  SSH root@$TARGET_IP accessible"
else
  echo -e "  ${RED}✘${RST}  Impossible de se connecter à root@$TARGET_IP"
  echo ""
  echo "  Vérifications :"
  echo "   • La machine cible est-elle bootée sur un live ISO NixOS ?"
  echo "   • L'IP est-elle correcte ? (lancer 'ip a' sur la machine cible)"
  echo "   • SSH est-il actif sur la cible ? (systemctl status sshd)"
  echo "   • Le mot de passe root ou la clé SSH est-elle configurée ?"
  exit 1
fi

# ---------------------------------------------------------------------------
# 4. Rappel des points sensibles
# ---------------------------------------------------------------------------

echo ""
echo -e "${BLD}── Étape 4/5 : Points à vérifier avant de continuer${RST}"
echo ""

DISK=$(grep -oP 'device\s*=\s*"\K[^"]+' "$REPO_ROOT/hosts/$HOST/disko.nix" 2>/dev/null | head -1 || echo "inconnu")
USERNAME=$(grep -oP 'home-manager\.users\.\K[a-zA-Z0-9_-]+' "$REPO_ROOT/flake.nix" | head -1 || echo "inconnu")

echo -e "  Disque cible configuré dans disko.nix : ${BLD}$DISK${RST}"
echo -e "  Username Home Manager dans flake.nix  : ${BLD}$USERNAME${RST}"
echo ""
echo -e "  ${YLW}ATTENTION${RST} : NixOS Anywhere va ${RED}effacer et reformater${RST} le disque $DISK."
echo "  Assure-toi que c'est bien le bon disque sur la machine cible."
echo "  Lance 'lsblk' sur la machine cible pour confirmer."
echo ""

read -rp "  Confirmer l'installation sur $TARGET_IP avec le host '$HOST' ? [oui/NON] " CONFIRM
if [[ "${CONFIRM,,}" != "oui" ]]; then
  echo ""
  echo "  Installation annulée."
  exit 0
fi

# ---------------------------------------------------------------------------
# 5. Lancement de nixos-anywhere
# ---------------------------------------------------------------------------

echo ""
echo -e "${BLD}── Étape 5/5 : Lancement de NixOS Anywhere${RST}"
echo ""
echo "  Commande exécutée :"
echo -e "  ${BLD}nix run nixpkgs#nixos-anywhere -- --flake .#$HOST root@$TARGET_IP${RST}"
echo ""

cd "$REPO_ROOT"
nix run nixpkgs#nixos-anywhere -- --flake ".#$HOST" "root@$TARGET_IP"

# ---------------------------------------------------------------------------
# Résumé post-installation
# ---------------------------------------------------------------------------

echo ""
echo -e "${GRN}${BLD}=== Installation terminée ===${RST}"
echo ""
echo "  Prochaines étapes :"
echo "   1. Attendre le reboot de la machine cible"
echo "   2. Se reconnecter : ssh $USERNAME@$TARGET_IP"
echo "   3. Vérifier l'installation : nix run .#post-install-check"
echo "   4. Si nécessaire, rebuilder : sudo nixos-rebuild switch --flake .#$HOST"
echo ""
