#!/usr/bin/env bash
# bootstrap-host-on-orbstack.sh — Prepare an existing OrbStack NixOS VM for
# its first `nixos-rebuild switch --flake .#<host>`.
#
# Pushes onto the VM (over SSH):
#   - the mfo Age private key into /var/lib/sops-nix/key.txt (mode 0600)
#   - generated SSH host keys (ssh-keygen -A) if missing
#   - the mfo SSH pubkey into the live user's authorized_keys (so the
#     compatibility user keeps working after promotion)
#
# Usage:
#   bootstrap-host-on-orbstack [--ssh-target USER@HOST] [--age-key PATH] [--host NAME]
#
# Defaults:
#   --ssh-target mickael@orb
#   --age-key    $SOPS_AGE_KEY_FILE > ~/.config/sops/age/keys.txt > secrets/keys/age/key.txt
#   --host       homelab

set -euo pipefail

_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./lib/workstation-install.sh
source "$_SCRIPT_DIR/lib/workstation-install.sh"
# shellcheck source=./lib/install-target.sh
source "$_SCRIPT_DIR/lib/install-target.sh"
REPO_ROOT="$(resolve_repo_root "$_SCRIPT_DIR")"

SSH_TARGET="mickael@orb"
AGE_KEY_OVERRIDE=""
HOST="homelab"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --ssh-target) SSH_TARGET="$2"; shift 2 ;;
    --age-key)    AGE_KEY_OVERRIDE="$2"; shift 2 ;;
    --host)       HOST="$2"; shift 2 ;;
    -h|--help)
      sed -n '2,18p' "$0"; exit 0 ;;
    *) die "Argument inconnu : $1" ;;
  esac
done

KEYS_NIX="$REPO_ROOT/modules/users/authorized-keys.nix"
SOPS_YAML="$REPO_ROOT/.sops.yaml"

AGE_KEY="${AGE_KEY_OVERRIDE:-}"
[[ -z "$AGE_KEY" && -n "${SOPS_AGE_KEY_FILE:-}" ]] && AGE_KEY="$SOPS_AGE_KEY_FILE"
[[ -z "$AGE_KEY" && -f "$HOME/.config/sops/age/keys.txt" ]] && AGE_KEY="$HOME/.config/sops/age/keys.txt"
[[ -z "$AGE_KEY" && -f "$REPO_ROOT/secrets/keys/age/key.txt" ]] && AGE_KEY="$REPO_ROOT/secrets/keys/age/key.txt"

[[ -n "$AGE_KEY" && -f "$AGE_KEY" ]] \
  || die "aucune clé age privée trouvée (essayé: --age-key, \$SOPS_AGE_KEY_FILE, ~/.config/sops/age/keys.txt, secrets/keys/age/key.txt)"
[[ -f "$KEYS_NIX" ]] || die "modules/users/authorized-keys.nix introuvable"
[[ -f "$SOPS_YAML" ]] || die ".sops.yaml introuvable"

PUB_FROM_KEY="$(grep -oE 'age1[0-9a-z]{58}' "$AGE_KEY" | head -1 || true)"
MFO_RECIPIENT="$(grep -oE 'age1[0-9a-z]{58}' "$SOPS_YAML" | head -1 || true)"
[[ -n "$PUB_FROM_KEY" ]] || die "aucune clé publique age trouvée dans $AGE_KEY"
[[ -n "$MFO_RECIPIENT" ]] || die "recipient mfo introuvable dans .sops.yaml"
[[ "$PUB_FROM_KEY" == "$MFO_RECIPIENT" ]] \
  || die "la clé Age fournie correspond à $PUB_FROM_KEY, mais le projet attend $MFO_RECIPIENT"
ok "Clé publique mfo confirmée : $PUB_FROM_KEY"

SSH_KEY="$(grep -oE 'ssh-ed25519 [A-Za-z0-9+/=]+ [^"]+' "$KEYS_NIX" | head -1 || true)"
[[ -n "$SSH_KEY" ]] || die "aucune clé ssh-ed25519 trouvée dans $KEYS_NIX"

step "Cible SSH : $SSH_TARGET"
ssh -o BatchMode=yes -o ConnectTimeout=5 "$SSH_TARGET" true \
  || die "connexion SSH impossible vers $SSH_TARGET"
ok "SSH ok"

step "Dépôt de la clé Age dans /var/lib/sops-nix/key.txt"
ssh "$SSH_TARGET" "sudo install -d -m 0700 -o root -g root /var/lib/sops-nix"
ssh "$SSH_TARGET" "sudo tee /var/lib/sops-nix/key.txt >/dev/null && sudo chmod 0600 /var/lib/sops-nix/key.txt && sudo chown root:root /var/lib/sops-nix/key.txt" \
  < "$AGE_KEY"
ok "Clé Age déposée"

step "Génération des clés d'hôte SSH manquantes"
ssh "$SSH_TARGET" "sudo ssh-keygen -A"
ok "Clés d'hôte SSH prêtes"

step "Ajout de la clé mfo aux authorized_keys courants"
ssh "$SSH_TARGET" "
  set -e
  mkdir -p \$HOME/.ssh
  chmod 700 \$HOME/.ssh
  touch \$HOME/.ssh/authorized_keys
  chmod 600 \$HOME/.ssh/authorized_keys
  grep -qF '$SSH_KEY' \$HOME/.ssh/authorized_keys || echo '$SSH_KEY' >> \$HOME/.ssh/authorized_keys
"
ok "Clé mfo présente côté utilisateur"

step "Terminé"
log ""
log "Promotion en host '$HOST' (depuis la VM, repo cloné en /root/workstation) :"
log "  ssh $SSH_TARGET 'sudo nix --extra-experimental-features \"nix-command flakes\" run /root/workstation#install-manual -- $HOST'"
log ""
log "Ou via reconfigure direct :"
log "  ssh $SSH_TARGET 'sudo nix --extra-experimental-features \"nix-command flakes\" run /root/workstation#reconfigure -- $HOST --mode test'"
