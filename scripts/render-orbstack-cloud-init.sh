#!/usr/bin/env bash
# render-orbstack-cloud-init.sh — Render the cloud-init template for the
# `orbstack` host into a local, gitignored file ready for `orb create`.
#
# Reads:
#   targets/hosts/orbstack/cloud-init.yaml      (versioned template)
#   secrets/keys/age/key.txt                    (local age private key, gitignored)
#   modules/users/authorized-keys.nix           (canonical mfo SSH pubkey)
#
# Writes:
#   secrets/keys/orbstack-cloud-init.yaml       (gitignored)
#
# Usage:
#   render-orbstack-cloud-init [--repo-url URL] [--branch BRANCH]

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
      cat <<EOF
Usage: render-orbstack-cloud-init [--repo-url URL] [--branch BRANCH] [--age-key PATH]

Defaults:
  --repo-url $REPO_URL
  --branch   $BRANCH
  --age-key  \$SOPS_AGE_KEY_FILE > ~/.config/sops/age/keys.txt > secrets/keys/age/key.txt
EOF
      exit 0 ;;
    *) die "Argument inconnu : $1" ;;
  esac
done

TEMPLATE="$REPO_ROOT/targets/hosts/orbstack/cloud-init.yaml"
KEYS_NIX="$REPO_ROOT/modules/users/authorized-keys.nix"
SOPS_YAML="$REPO_ROOT/.sops.yaml"
OUT="$REPO_ROOT/secrets/keys/orbstack-cloud-init.yaml"

# Resolve the age private key to embed.
# Priority:
#   1. --age-key <path> arg
#   2. $SOPS_AGE_KEY_FILE
#   3. ~/.config/sops/age/keys.txt
#   4. secrets/keys/age/key.txt
AGE_KEY="${AGE_KEY_OVERRIDE:-}"
if [[ -z "$AGE_KEY" && -n "${SOPS_AGE_KEY_FILE:-}" ]]; then
  AGE_KEY="$SOPS_AGE_KEY_FILE"
fi
if [[ -z "$AGE_KEY" && -f "$HOME/.config/sops/age/keys.txt" ]]; then
  AGE_KEY="$HOME/.config/sops/age/keys.txt"
fi
if [[ -z "$AGE_KEY" && -f "$REPO_ROOT/secrets/keys/age/key.txt" ]]; then
  AGE_KEY="$REPO_ROOT/secrets/keys/age/key.txt"
fi

[[ -f "$TEMPLATE" ]] || die "template introuvable : $TEMPLATE"
[[ -n "$AGE_KEY" && -f "$AGE_KEY" ]] || die "aucune clé age privée trouvée (essayé: --age-key, \$SOPS_AGE_KEY_FILE, ~/.config/sops/age/keys.txt, secrets/keys/age/key.txt)"
[[ -f "$KEYS_NIX" ]] || die "modules/users/authorized-keys.nix introuvable"

log "Clé age embarquée : $AGE_KEY"

# Sanity checks:
#   1. the embedded key must match the canonical `mfo` recipient declared in
#      .sops.yaml
#   2. the same recipient must already be present in existing encrypted files
#      consumed by the host
PUB_FROM_KEY="$(grep -oE 'age1[0-9a-z]{58}' "$AGE_KEY" | head -1 || true)"
MFO_RECIPIENT="$(grep -oE 'age1[0-9a-z]{58}' "$SOPS_YAML" | head -1 || true)"
if [[ -n "$PUB_FROM_KEY" ]]; then
  if [[ -z "$MFO_RECIPIENT" ]]; then
    die "recipient mfo introuvable dans .sops.yaml"
  fi
  if [[ "$PUB_FROM_KEY" != "$MFO_RECIPIENT" ]]; then
    die "la clé Age fournie correspond à $PUB_FROM_KEY, mais le projet attend la clé mfo $MFO_RECIPIENT"
  fi
  ok "Clé publique mfo confirmée : $PUB_FROM_KEY"

  missing_recipients=()
  while IFS= read -r secret_file; do
    if ! grep -q "$PUB_FROM_KEY" "$secret_file"; then
      missing_recipients+=( "${secret_file#$REPO_ROOT/}" )
    fi
  done < <(
    find "$REPO_ROOT/secrets" -type f \
      \( -name '*.yaml' -o -name '*.yml' -o -name '*.json' -o -name '*.env' -o -name '*.ini' \) \
      ! -path "$REPO_ROOT/secrets/keys/*" -print | while IFS= read -r file; do
        if grep -q 'recipient:' "$file"; then
          printf '%s\n' "$file"
        fi
      done
  )

  if (( ${#missing_recipients[@]} > 0 )); then
    die "recipient mfo absent de ${#missing_recipients[@]} fichier(s) chiffré(s) existant(s)"
  else
    ok "Recipient mfo déjà présent dans tous les fichiers chiffrés existants."
  fi
fi

# Extract mfo's first SSH key (one-line). The Nix file is plain text; grep is enough.
SSH_KEY="$(grep -oE 'ssh-ed25519 [A-Za-z0-9+/=]+ [^"]+' "$KEYS_NIX" | head -1 || true)"
[[ -n "$SSH_KEY" ]] || die "aucune clé ssh-ed25519 trouvée dans $KEYS_NIX"

# Indent the age private key by 6 spaces (cloud-init `content: |` block).
AGE_INDENTED="$(sed 's/^/      /' "$AGE_KEY")"

# Render. Awk handles the multi-line age block injection; single-line tokens
# are also handled here for consistency.
#
# Placeholders (substituted in this exact form):
#   {{SSH_AUTHORIZED_KEY}}     one line, mfo's ssh-ed25519 pubkey
#   {{AGE_PRIVATE_KEY_BLOCK}}  whole line replaced by the indented age key
#   {{INFRA_REPO_URL}}         https URL to the infra repo
#   {{INFRA_REPO_BRANCH}}      branch to clone
mkdir -p "$(dirname "$OUT")"
awk -v ssh_key="$SSH_KEY" \
    -v repo_url="$REPO_URL" \
    -v branch="$BRANCH" \
    -v age_block="$AGE_INDENTED" \
    '
      { line = $0 }
      { gsub(/\{\{SSH_AUTHORIZED_KEY\}\}/, ssh_key, line) }
      { gsub(/\{\{INFRA_REPO_URL\}\}/, repo_url, line) }
      { gsub(/\{\{INFRA_REPO_BRANCH\}\}/, branch, line) }
      line ~ /\{\{AGE_PRIVATE_KEY_BLOCK\}\}/ { print age_block; next }
      { print line }
    ' "$TEMPLATE" > "$OUT"

chmod 0600 "$OUT"

ok "Rendu : $OUT (mode 0600, gitignored)"
log ""
log "Vérifications utiles :"
log "  head -20 $OUT"
log ""
log "Création de la VM (sur le Mac hôte d'OrbStack) :"
log "  orb create -a arm64 -u root \\"
log "    --user-data $OUT \\"
log "    nixos orbstack"
log ""
log "Après ~2 min :"
log "  ssh mfo@orbstack@orb"
