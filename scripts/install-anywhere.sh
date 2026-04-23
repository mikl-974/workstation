#!/usr/bin/env bash
# install-anywhere.sh — Orchestration transparente de l'installation via NixOS Anywhere

set -euo pipefail

_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./lib/workstation-install.sh
source "$_SCRIPT_DIR/lib/workstation-install.sh"
REPO_ROOT="$(resolve_repo_root "$_SCRIPT_DIR")"

RED='\033[0;31m'
GRN='\033[0;32m'
YLW='\033[1;33m'
BLD='\033[1m'
RST='\033[0m'

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <host> <ip-cible>"
  echo "Hosts disponibles : $(list_hosts "$REPO_ROOT")"
  exit 1
fi

HOST="$1"
TARGET_IP="$2"
VARS_FILE="$(host_vars_file "$REPO_ROOT" "$HOST")"
DOCTOR_SCRIPT="$REPO_ROOT/scripts/doctor.sh"
VALIDATE_SCRIPT="$REPO_ROOT/scripts/validate-install.sh"
MACHINE_CONTEXT="$(host_machine_context "$REPO_ROOT" "$HOST")"

SYSTEM="$(read_nix_string_var "$VARS_FILE" "system")"
USERNAME="$(read_nix_string_var "$VARS_FILE" "username")"
DISK="$(read_nix_string_var "$VARS_FILE" "disk")"

check_cmd() {
  local cmd="$1"
  local hint="$2"
  if command -v "$cmd" &>/dev/null; then
    echo -e "  ${GRN}✔${RST}  $cmd disponible"
  else
    echo -e "  ${RED}✘${RST}  $cmd introuvable — $hint"
    exit 1
  fi
}

echo ""
echo -e "${BLD}=== Installation NixOS Anywhere : host '$HOST' → $TARGET_IP ===${RST}"
echo ""

echo -e "${BLD}── Étape 1/6 : Diagnostic local${RST}"
if [[ -f "$DOCTOR_SCRIPT" ]]; then
  bash "$DOCTOR_SCRIPT" --host "$HOST"
else
  echo -e "  ${RED}✘${RST}  scripts/doctor.sh manquant"
  exit 1
fi

echo ""
echo -e "${BLD}── Étape 2/6 : Validation du host${RST}"
if [[ -f "$VALIDATE_SCRIPT" ]]; then
  bash "$VALIDATE_SCRIPT" "$HOST"
else
  echo -e "  ${RED}✘${RST}  scripts/validate-install.sh manquant"
  exit 1
fi

if ! host_uses_disko "$REPO_ROOT" "$HOST"; then
  echo ""
  echo -e "${RED}✘ Ce host n'a pas de disko.nix : NixOS Anywhere n'est pas disponible.${RST}"
  echo "  Utiliser le fallback : nix run .#install-manual -- --host $HOST"
  exit 1
fi

if [[ -z "$DISK" ]] || is_placeholder_value "$DISK"; then
  echo ""
  echo -e "${RED}✘ Le host '$HOST' a bien un disko.nix, mais le vrai disque cible n'est pas encore renseigné dans targets/hosts/$HOST/vars.nix.${RST}"
  echo "  Vérifie le disque réel sur la machine cible avec 'lsblk', renseigne le champ 'disk', puis relance :"
  echo "    nix run .#validate-install -- $HOST"
  exit 1
fi

echo ""
echo -e "${BLD}── Étape 3/6 : Prérequis locaux${RST}"
check_cmd "nix" "Nix avec flakes est requis"
check_cmd "ssh" "SSH est requis pour joindre la cible"
check_cmd "ssh-keyscan" "nécessaire pour lire la clé hôte avant connexion"
check_cmd "ssh-keygen" "nécessaire pour afficher l'empreinte de la clé hôte"

if ! (cd "$REPO_ROOT" && nix flake show . --all-systems --no-write-lock-file >/dev/null); then
  echo -e "  ${RED}✘${RST}  Le flake n'est pas lisible par nix"
  exit 1
fi
echo -e "  ${GRN}✔${RST}  Flake lisible"

echo ""
echo -e "${BLD}── Étape 4/6 : Vérification de la clé SSH et de la connectivité${RST}"
TMP_KNOWN_HOSTS="$(mktemp)"
trap 'rm -f "$TMP_KNOWN_HOSTS"' EXIT

if ! ssh-keyscan -T 10 "$TARGET_IP" > "$TMP_KNOWN_HOSTS" 2>/dev/null; then
  echo -e "  ${RED}✘${RST}  Impossible de récupérer la clé SSH de $TARGET_IP"
  echo "  Vérifie que la cible est bootée, joignable et que SSH est actif."
  exit 1
fi

if [[ ! -s "$TMP_KNOWN_HOSTS" ]]; then
  echo -e "  ${RED}✘${RST}  Aucune clé SSH récupérée depuis $TARGET_IP"
  exit 1
fi

echo "  Empreintes récupérées pour $TARGET_IP :"
ssh-keygen -lf "$TMP_KNOWN_HOSTS" | sed 's/^/    /'
echo ""
echo "  Vérifie ces empreintes sur la machine cible avant de continuer :"
echo "    ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub"
echo "    ssh-keygen -lf /etc/ssh/ssh_host_rsa_key.pub"
echo ""
read -rp "  Faire confiance à cette clé hôte pour $TARGET_IP ? [oui/NON] " TRUST_HOST
if [[ "${TRUST_HOST,,}" != "oui" ]]; then
  echo "  Installation annulée."
  exit 0
fi

if ssh -o ConnectTimeout=10 -o BatchMode=yes -o StrictHostKeyChecking=yes \
       -o UserKnownHostsFile="$TMP_KNOWN_HOSTS" \
       "root@$TARGET_IP" "echo OK" &>/dev/null; then
  echo -e "  ${GRN}✔${RST}  SSH root@$TARGET_IP accessible"
else
  echo -e "  ${RED}✘${RST}  Impossible de se connecter à root@$TARGET_IP"
  echo "  Vérifications utiles :"
  echo "   • la machine cible est bootée sur un live ISO NixOS"
  echo "   • systemctl status sshd sur la cible"
  echo "   • mot de passe root ou clé SSH configurés"
  exit 1
fi

echo ""
echo -e "${BLD}── Étape 5/6 : Récapitulatif opératoire${RST}"
echo "  Host attr     : $HOST"
echo "  Contexte      : $MACHINE_CONTEXT"
echo "  Système       : ${SYSTEM:-inconnu}"
echo "  Username      : ${USERNAME:-inconnu}"
echo "  Disque cible  : ${DISK:-inconnu}"
echo "  Cible SSH     : root@$TARGET_IP"
echo "  Flake         : .#$HOST"
echo ""
if [[ "$MACHINE_CONTEXT" == "virtual-machine" ]]; then
  echo "  Note VM       : le profil VM signale le contexte guest, mais ne choisit ni le disque, ni le firmware, ni l'hyperviseur."
  echo ""
fi
echo -e "  ${YLW}ATTENTION${RST} : le disque ${DISK:-inconnu} sera effacé et reformaté."
echo "  Confirme le disque avec 'lsblk' sur la machine cible avant de continuer."
echo ""
read -rp "  Lancer l'installation NixOS Anywhere pour '$HOST' sur $TARGET_IP ? [oui/NON] " CONFIRM
if [[ "${CONFIRM,,}" != "oui" ]]; then
  echo "  Installation annulée."
  exit 0
fi

echo ""
echo -e "${BLD}── Étape 6/6 : Lancement de NixOS Anywhere${RST}"
echo "  Commande :"
echo -e "  ${BLD}nix run nixpkgs#nixos-anywhere -- --flake .#$HOST root@$TARGET_IP${RST}"
echo ""
cd "$REPO_ROOT"
nix run nixpkgs#nixos-anywhere -- --flake ".#$HOST" "root@$TARGET_IP"

echo ""
echo -e "${GRN}${BLD}=== Installation terminée ===${RST}"
echo ""
echo "  Prochaines étapes :"
echo "   1. Attendre le reboot de la machine cible"
echo "   2. Se connecter avec l'utilisateur '${USERNAME:-attendu}'"
echo "   3. Relire : docs/first-boot.md"
echo "   4. Vérifier : nix run .#post-install-check -- --host $HOST"
echo "   5. Si besoin : sudo nixos-rebuild switch --flake .#$HOST"
echo ""
