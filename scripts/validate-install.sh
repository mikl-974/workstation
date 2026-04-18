#!/usr/bin/env bash
# validate-install.sh — Validateur pré-installation workstation
#
# Vérifie que la configuration est prête avant de lancer une installation
# via NixOS Anywhere ou manuellement.
#
# Usage :
#   ./scripts/validate-install.sh <host>
#   nix run .#validate-install -- <host>
#
# Exemple :
#   ./scripts/validate-install.sh main

set -euo pipefail

_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# When run via `nix run .#validate-install`, the script lives in /nix/store.
# In that case, use $PWD (the user must run from the repo root).
if [[ "$_SCRIPT_DIR" == /nix/store/* ]]; then
  REPO_ROOT="$PWD"
else
  REPO_ROOT="$(cd "$_SCRIPT_DIR/.." && pwd)"
fi

RED='\033[0;31m'
GRN='\033[0;32m'
YLW='\033[1;33m'
RST='\033[0m'

ERRORS=0
WARNINGS=0

ok()   { echo -e "  ${GRN}✔${RST}  $*"; }
fail() { echo -e "  ${RED}✘${RST}  $*"; ERRORS=$(( ERRORS + 1 )); }
warn() { echo -e "  ${YLW}⚠${RST}  $*"; WARNINGS=$(( WARNINGS + 1 )); }

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

echo ""
echo "=== Validation pré-installation : host '$HOST' ==="
echo ""

# ---------------------------------------------------------------------------
# 1. Le host existe
# ---------------------------------------------------------------------------

echo "── Existence du host"

if [[ -d "$HOST_DIR" ]]; then
  ok "hosts/$HOST/ existe"
else
  fail "hosts/$HOST/ introuvable — hôtes disponibles : $(ls "$REPO_ROOT/hosts" | tr '\n' ' ')"
  echo ""
  echo -e "${RED}Validation interrompue : host introuvable.${RST}"
  exit 1
fi

# ---------------------------------------------------------------------------
# 2. Fichiers critiques du host
# ---------------------------------------------------------------------------

echo ""
echo "── Fichiers critiques du host"

if [[ -f "$HOST_DIR/default.nix" ]]; then
  ok "hosts/$HOST/default.nix existe"
else
  fail "hosts/$HOST/default.nix manquant"
fi

if [[ -f "$HOST_DIR/disko.nix" ]]; then
  ok "hosts/$HOST/disko.nix existe"
  HAS_DISKO=true
else
  warn "hosts/$HOST/disko.nix absent — partitionnement disko non disponible pour ce host"
  warn "NixOS Anywhere nécessite un disko.nix. L'installation manuelle reste possible."
  HAS_DISKO=false
fi

# ---------------------------------------------------------------------------
# 3. flake.nix expose bien le host
# ---------------------------------------------------------------------------

echo ""
echo "── Exposition du host dans flake.nix"

if grep -q "\"$HOST\"" "$REPO_ROOT/flake.nix" || grep -q "$HOST = lib.nixosSystem" "$REPO_ROOT/flake.nix"; then
  ok "flake.nix expose nixosConfigurations.$HOST"
else
  fail "flake.nix n'expose pas nixosConfigurations.$HOST"
fi

# ---------------------------------------------------------------------------
# 4. Placeholders CHANGEME
# ---------------------------------------------------------------------------

echo ""
echo "── Placeholders CHANGEME"

CHANGEME_FILES=()
while IFS= read -r line; do
  CHANGEME_FILES+=("$line")
done < <(grep -rl "CHANGEME" "$REPO_ROOT" \
  --include="*.nix" --include="*.sh" --include="*.md" \
  --exclude-dir=".git" 2>/dev/null || true)

if [[ ${#CHANGEME_FILES[@]} -eq 0 ]]; then
  ok "Aucun placeholder CHANGEME détecté"
else
  for f in "${CHANGEME_FILES[@]}"; do
    rel="${f#"$REPO_ROOT/"}"
    # Afficher les lignes concernées
    while IFS= read -r match; do
      fail "Placeholder CHANGEME dans $rel : $match"
    done < <(grep -n "CHANGEME" "$f")
  done
fi

# ---------------------------------------------------------------------------
# 5. Disque cible dans disko.nix
# ---------------------------------------------------------------------------

echo ""
echo "── Disque cible (disko.nix)"

if [[ "$HAS_DISKO" == true ]]; then
  if grep -q "/dev/CHANGEME" "$HOST_DIR/disko.nix"; then
    fail "disko.nix contient encore '/dev/CHANGEME' — remplace par le disque réel (ex: /dev/nvme0n1)"
  else
    DISK=$(grep -oP 'device\s*=\s*"\K[^"]+' "$HOST_DIR/disko.nix" | head -1)
    if [[ -n "$DISK" ]]; then
      ok "Disque cible défini dans disko.nix : $DISK"
    else
      warn "Impossible de lire le disque cible dans disko.nix — vérifie manuellement"
    fi
  fi
else
  warn "Pas de disko.nix — vérification du disque ignorée"
fi

# ---------------------------------------------------------------------------
# 6. Username dans flake.nix
# ---------------------------------------------------------------------------

echo ""
echo "── Username Home Manager (flake.nix)"

if grep -q "CHANGEME_USERNAME" "$REPO_ROOT/flake.nix"; then
  fail "flake.nix contient encore 'CHANGEME_USERNAME' — remplace par le nom d'utilisateur réel"
else
  USERNAME=$(grep -oP 'home-manager\.users\.\K[a-zA-Z0-9_-]+' "$REPO_ROOT/flake.nix" | head -1)
  if [[ -n "$USERNAME" ]]; then
    ok "Username Home Manager défini : $USERNAME"
  else
    warn "Impossible de détecter le username dans flake.nix — vérifie manuellement"
  fi
fi

# ---------------------------------------------------------------------------
# 7. Dotfiles référencés dans home/default.nix
# ---------------------------------------------------------------------------

echo ""
echo "── Dotfiles référencés dans home/default.nix"

HOME_FILE="$REPO_ROOT/home/default.nix"
if [[ -f "$HOME_FILE" ]]; then
  DOTFILE_REFS=$(grep -oP '\.\./dotfiles/\K[^\s"]+' "$HOME_FILE" 2>/dev/null || true)
  if [[ -z "$DOTFILE_REFS" ]]; then
    ok "Aucun dotfile activé dans home/default.nix (section home.file vide)"
  else
    ALL_OK=true
    while IFS= read -r ref; do
      target="$REPO_ROOT/dotfiles/$ref"
      if [[ -e "$target" ]]; then
        ok "dotfiles/$ref → existe"
      else
        fail "dotfiles/$ref référencé dans home/default.nix mais introuvable"
        ALL_OK=false
      fi
    done <<< "$DOTFILE_REFS"
  fi
else
  warn "home/default.nix introuvable — vérification des dotfiles ignorée"
fi

# ---------------------------------------------------------------------------
# 8. home/default.nix existe
# ---------------------------------------------------------------------------

echo ""
echo "── Fichiers Home Manager"

if [[ -f "$REPO_ROOT/home/default.nix" ]]; then
  ok "home/default.nix existe"
else
  fail "home/default.nix manquant"
fi

# ---------------------------------------------------------------------------
# Résumé
# ---------------------------------------------------------------------------

echo ""
echo "=== Résumé ==="
echo ""

if [[ $ERRORS -eq 0 && $WARNINGS -eq 0 ]]; then
  echo -e "${GRN}✔ Validation complète : aucune erreur, aucun avertissement.${RST}"
  echo -e "  La configuration semble prête pour une installation du host '$HOST'."
elif [[ $ERRORS -eq 0 ]]; then
  echo -e "${YLW}⚠ Validation complète : $WARNINGS avertissement(s), aucune erreur bloquante.${RST}"
  echo -e "  Vérifie les avertissements avant de lancer l'installation."
else
  echo -e "${RED}✘ Validation échouée : $ERRORS erreur(s) bloquante(s), $WARNINGS avertissement(s).${RST}"
  echo -e "  Corrige les erreurs ci-dessus avant de lancer l'installation."
  exit 1
fi

echo ""
