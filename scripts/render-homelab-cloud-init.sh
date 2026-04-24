#!/usr/bin/env bash
# render-homelab-cloud-init.sh — Render the cloud-init template for the
# `homelab` OrbStack VM into a local, gitignored file ready for `orb create`.
#
# Reads:
#   targets/hosts/homelab/cloud-init.yaml    (versioned template)
#   secrets/keys/age/key.txt                 (local age private key, gitignored)
#   modules/users/authorized-keys.nix        (canonical mfo SSH pubkey)
#
# Writes:
#   secrets/keys/homelab-cloud-init.yaml     (gitignored)
#
# Usage:
#   render-homelab-cloud-init [--repo-url URL] [--branch BRANCH] [--age-key PATH]

set -euo pipefail

_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./lib/workstation-install.sh
source "$_SCRIPT_DIR/lib/workstation-install.sh"
# shellcheck source=./lib/install-target.sh
source "$_SCRIPT_DIR/lib/install-target.sh"
REPO_ROOT="$(resolve_repo_root "$_SCRIPT_DIR")"

REPO_URL="https://github.com/mikl-974/infra"
BRANCH="main"
AGE_KEY_OVERRIDE=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo-url) REPO_URL="$2"; shift 2 ;;
    --branch)   BRANCH="$2";   shift 2 ;;
    --age-key)  AGE_KEY_OVERRIDE="$2"; shift 2 ;;
    -h|--help)
      sed -n '2,16p' "$0"; exit 0 ;;
    *) die "Argument inconnu : $1" ;;
  esac
done

TEMPLATE="$REPO_ROOT/targets/hosts/homelab/cloud-init.yaml"
KEYS_NIX="$REPO_ROOT/modules/users/authorized-keys.nix"
SOPS_YAML="$REPO_ROOT/.sops.yaml"
OUT="$REPO_ROOT/secrets/keys/homelab-cloud-init.yaml"

AGE_KEY="${AGE_KEY_OVERRIDE:-}"
[[ -z "$AGE_KEY" && -n "${SOPS_AGE_KEY_FILE:-}" ]] && AGE_KEY="$SOPS_AGE_KEY_FILE"
[[ -z "$AGE_KEY" && -f "$HOME/.config/sops/age/keys.txt" ]] && AGE_KEY="$HOME/.config/sops/age/keys.txt"
[[ -z "$AGE_KEY" && -f "$REPO_ROOT/secrets/keys/age/key.txt" ]] && AGE_KEY="$REPO_ROOT/secrets/keys/age/key.txt"

[[ -f "$TEMPLATE" ]] || die "template introuvable : $TEMPLATE"
[[ -n "$AGE_KEY" && -f "$AGE_KEY" ]] || die "aucune clé age privée trouvée"
[[ -f "$KEYS_NIX" ]] || die "modules/users/authorized-keys.nix introuvable"

PUB_FROM_KEY="$(grep -oE 'age1[0-9a-z]{58}' "$AGE_KEY" | head -1 || true)"
MFO_RECIPIENT="$(grep -oE 'age1[0-9a-z]{58}' "$SOPS_YAML" | head -1 || true)"
[[ "$PUB_FROM_KEY" == "$MFO_RECIPIENT" ]] \
  || die "la clé Age fournie ($PUB_FROM_KEY) ne matche pas le recipient mfo ($MFO_RECIPIENT)"
ok "Clé publique mfo confirmée : $PUB_FROM_KEY"

SSH_KEY="$(grep -oE 'ssh-ed25519 [A-Za-z0-9+/=]+ [^"]+' "$KEYS_NIX" | head -1 || true)"
[[ -n "$SSH_KEY" ]] || die "aucune clé ssh-ed25519 trouvée dans $KEYS_NIX"

AGE_INDENTED_FILE="$(mktemp)"
sed 's/^/      /' "$AGE_KEY" > "$AGE_INDENTED_FILE"

mkdir -p "$(dirname "$OUT")"
awk -v ssh_key="$SSH_KEY" \
    -v repo_url="$REPO_URL" \
    -v branch="$BRANCH" \
    -v age_file="$AGE_INDENTED_FILE" \
    '
      { line = $0 }
      { gsub(/\{\{SSH_AUTHORIZED_KEY\}\}/, ssh_key, line) }
      { gsub(/\{\{INFRA_REPO_URL\}\}/, repo_url, line) }
      { gsub(/\{\{INFRA_REPO_BRANCH\}\}/, branch, line) }
      line ~ /\{\{AGE_PRIVATE_KEY_BLOCK\}\}/ {
        while ((getline ageline < age_file) > 0) print ageline
        close(age_file)
        next
      }
      { print line }
    ' "$TEMPLATE" > "$OUT"

rm -f "$AGE_INDENTED_FILE"

chmod 0600 "$OUT"

ok "Rendu : $OUT (mode 0600, gitignored)"
log ""
log "Création de la VM (sur le Mac hôte d'OrbStack) :"
log "  orb create -a arm64 -u root \\"
log "    --user-data $OUT \\"
log "    nixos homelab"
log ""
log "Après ~2 min :"
log "  ssh mickael@homelab@orb"
log "  ssh admin@homelab@orb"
