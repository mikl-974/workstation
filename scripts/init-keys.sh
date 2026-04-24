#!/usr/bin/env bash
#
# init-keys.sh — prepare local SSH and age identities for this infra checkout.
#
# This script only manages local, non-versioned working keys under:
#   secrets/keys/ssh/
#   secrets/keys/age/
# It never writes into versioned sops files under secrets/*.yaml.

set -euo pipefail

_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./lib/workstation-install.sh
source "$_SCRIPT_DIR/lib/workstation-install.sh"
REPO_ROOT="$(resolve_repo_root "$_SCRIPT_DIR")"

SSH_DIR="$REPO_ROOT/secrets/keys/ssh"
AGE_DIR="$REPO_ROOT/secrets/keys/age"
SSH_KEY="$SSH_DIR/id_ed25519_infra"
SSH_PUB="${SSH_KEY}.pub"
AGE_KEY="$AGE_DIR/key.txt"
AGE_PUB="$AGE_DIR/key.pub"

BLD='\033[1m'
GRN='\033[0;32m'
YLW='\033[1;33m'
RED='\033[0;31m'
RST='\033[0m'

created_any=0

die() {
  echo -e "${RED}Erreur:${RST} $*" >&2
  exit 1
}

note() {
  echo -e "${BLD}$*${RST}"
}

ok() {
  echo -e "  ${GRN}✔${RST} $*"
}

warn() {
  echo -e "  ${YLW}⚠${RST} $*"
}

require_cmd() {
  local cmd="$1"
  local hint="$2"
  command -v "$cmd" >/dev/null 2>&1 || die "commande manquante: $cmd ($hint)"
}

ensure_private_dir() {
  local dir="$1"
  mkdir -p "$dir"
  chmod 700 "$dir"
}

ensure_ssh_public_key() {
  if [[ -f "$SSH_KEY" && ! -f "$SSH_PUB" ]]; then
    ssh-keygen -y -f "$SSH_KEY" > "$SSH_PUB"
    chmod 600 "$SSH_PUB"
    ok "clé publique SSH régénérée: ${SSH_PUB#$REPO_ROOT/}"
  fi
}

ensure_age_public_key() {
  if [[ -f "$AGE_KEY" && ! -f "$AGE_PUB" ]]; then
    age-keygen -y "$AGE_KEY" > "$AGE_PUB"
    chmod 600 "$AGE_PUB"
    ok "recipient Age régénéré: ${AGE_PUB#$REPO_ROOT/}"
  fi
}

print_existing_summary() {
  local ssh_pub age_pub
  ssh_pub="$(cat "$SSH_PUB")"
  age_pub="$(cat "$AGE_PUB")"

  echo ""
  note "── Récapitulatif"
  echo ""
  echo "  SSH private : ${SSH_KEY#$REPO_ROOT/}"
  echo "  SSH public  : ${SSH_PUB#$REPO_ROOT/}"
  echo "  Age private : ${AGE_KEY#$REPO_ROOT/}"
  echo "  Age public  : ${AGE_PUB#$REPO_ROOT/}"
  echo ""
  echo "  SSH public key:"
  echo "    $ssh_pub"
  echo ""
  echo "  Age recipient:"
  echo "    $age_pub"
}

print_next_steps() {
  echo ""
  note "── Prochaines étapes"
  echo ""
  echo "  1. Conserver ces fichiers comme stockage local de travail uniquement."
  echo "     Ce dossier n'est pas une sauvegarde suffisante à lui seul."
  echo ""
  echo "  2. Sauvegarder les clés privées hors repo dans un coffre chiffré."
  echo ""
  echo "  3. Si la clé SSH doit être autorisée quelque part, diffuser uniquement:"
  echo "       ${SSH_PUB#$REPO_ROOT/}"
  echo ""
  echo "  4. Pour les secrets du projet, utiliser la clé Age canonique 'mfo'."
  echo "     La clé locale ${AGE_PUB#$REPO_ROOT/} n'est qu'un stockage de travail"
  echo "     tant qu'elle n'est pas explicitement la vraie clé mfo."
  echo ""
  echo "  5. Pour installer l'identité Age sur un host NixOS:"
  echo "       sudo mkdir -p /var/lib/sops-nix"
  echo "       sudo install -m 600 -o root -g root \\"
  echo "         ${AGE_KEY#$REPO_ROOT/} /var/lib/sops-nix/key.txt"
}

if [[ $# -gt 0 ]]; then
  die "usage: $0"
fi

require_cmd "ssh-keygen" "installer openssh"
require_cmd "age-keygen" "installer age"

echo ""
note "=== Initialisation des clés locales du repo ==="
echo ""
echo "  Répertoire repo : $REPO_ROOT"
echo "  Cibles locales  : secrets/keys/ssh/ et secrets/keys/age/"
echo ""

umask 077
ensure_private_dir "$SSH_DIR"
ensure_private_dir "$AGE_DIR"

if [[ -f "$SSH_PUB" && ! -f "$SSH_KEY" ]]; then
  die "état incohérent: ${SSH_PUB#$REPO_ROOT/} existe sans ${SSH_KEY#$REPO_ROOT/}"
fi

if [[ -f "$AGE_PUB" && ! -f "$AGE_KEY" ]]; then
  die "état incohérent: ${AGE_PUB#$REPO_ROOT/} existe sans ${AGE_KEY#$REPO_ROOT/}"
fi

note "── SSH"
if [[ -f "$SSH_KEY" ]]; then
  ensure_ssh_public_key
  ok "clé SSH déjà présente: ${SSH_KEY#$REPO_ROOT/}"
else
  ssh-keygen -q -t ed25519 -N "" -f "$SSH_KEY" -C "infra-local-working-key"
  chmod 600 "$SSH_KEY" "$SSH_PUB"
  ok "clé SSH générée: ${SSH_KEY#$REPO_ROOT/}"
  created_any=1
fi

echo ""
note "── age"
if [[ -f "$AGE_KEY" ]]; then
  ensure_age_public_key
  ok "identité Age déjà présente: ${AGE_KEY#$REPO_ROOT/}"
else
  age-keygen -o "$AGE_KEY" >/dev/null
  age-keygen -y "$AGE_KEY" > "$AGE_PUB"
  chmod 600 "$AGE_KEY" "$AGE_PUB"
  ok "identité Age générée: ${AGE_KEY#$REPO_ROOT/}"
  created_any=1
fi

if [[ $created_any -eq 0 ]]; then
  echo ""
  warn "aucune nouvelle clé générée — tout existait déjà"
fi

print_existing_summary
print_next_steps
echo ""
