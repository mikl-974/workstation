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

if [[ -f "$HOST_DIR/vars.nix" ]]; then
  ok "hosts/$HOST/vars.nix existe"
else
  fail "hosts/$HOST/vars.nix manquant — initialiser avec : nix run .#init-host -- $HOST"
fi

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

if grep -q "\"$HOST\"" "$REPO_ROOT/flake.nix" || grep -q "$HOST = mkHost" "$REPO_ROOT/flake.nix"; then
  ok "flake.nix expose nixosConfigurations.$HOST"
else
  fail "flake.nix n'expose pas nixosConfigurations.$HOST"
fi

# ---------------------------------------------------------------------------
# 4. Lecture de vars.nix
# ---------------------------------------------------------------------------

echo ""
echo "── Valeurs dans vars.nix"

VARS_FILE="$HOST_DIR/vars.nix"
read_var() {
  grep -oP "${1}\s*=\s*\"\K[^\"]+" "$VARS_FILE" 2>/dev/null | head -1 || echo ""
}

if [[ -f "$VARS_FILE" ]]; then
  USERNAME=$(read_var "username")
  HOSTNAME_VAL=$(read_var "hostname")
  DISK=$(read_var "disk")
  TIMEZONE=$(read_var "timezone")
  LOCALE=$(read_var "locale")

  # username
  if [[ -z "$USERNAME" ]]; then
    fail "vars.nix : champ 'username' absent"
  elif echo "$USERNAME" | grep -qE '^DEFINE_'; then
    fail "vars.nix : username non défini ('$USERNAME') — remplacer par le nom d'utilisateur réel"
  else
    ok "username : $USERNAME"
  fi

  # hostname
  if [[ -z "$HOSTNAME_VAL" ]]; then
    fail "vars.nix : champ 'hostname' absent"
  elif echo "$HOSTNAME_VAL" | grep -qE '^DEFINE_'; then
    fail "vars.nix : hostname non défini ('$HOSTNAME_VAL')"
  else
    ok "hostname : $HOSTNAME_VAL"
  fi

  # disk (uniquement si disko.nix est présent)
  if [[ "$HAS_DISKO" == true ]]; then
    if [[ -z "$DISK" ]]; then
      fail "vars.nix : champ 'disk' absent — requis pour disko.nix"
    elif echo "$DISK" | grep -qE 'DEFINE_DISK|/dev/DEFINE_DISK'; then
      fail "vars.nix : disk non défini ('$DISK') — lancer 'lsblk' sur la cible et définir le disque réel"
    else
      ok "disk : $DISK"
    fi
  fi

  # timezone
  if [[ -z "$TIMEZONE" ]]; then
    warn "vars.nix : champ 'timezone' absent — valeur par défaut NixOS sera utilisée"
  elif echo "$TIMEZONE" | grep -qE '^DEFINE_'; then
    fail "vars.nix : timezone non défini ('$TIMEZONE')"
  else
    ok "timezone : $TIMEZONE"
  fi

  # locale
  if [[ -z "$LOCALE" ]]; then
    warn "vars.nix : champ 'locale' absent — valeur par défaut NixOS sera utilisée"
  elif echo "$LOCALE" | grep -qE '^DEFINE_'; then
    fail "vars.nix : locale non défini ('$LOCALE')"
  else
    ok "locale : $LOCALE"
  fi
else
  fail "vars.nix manquant — impossible de vérifier les valeurs"
fi

# ---------------------------------------------------------------------------
# 5. Cohérence hostname
# ---------------------------------------------------------------------------

echo ""
echo "── Cohérence hostname"

if [[ -n "${HOSTNAME_VAL:-}" && "$HOSTNAME_VAL" != "$HOST" ]]; then
  warn "vars.nix : hostname='$HOSTNAME_VAL' diffère de la clé host '$HOST'"
  warn "Le hostname doit correspondre à la clé nixosConfigurations dans flake.nix"
elif [[ -n "${HOSTNAME_VAL:-}" ]]; then
  ok "hostname cohérent avec la clé host"
fi

# ---------------------------------------------------------------------------
# 6. Absence de placeholders DEFINE_ dans les fichiers structurants
# ---------------------------------------------------------------------------

echo ""
echo "── Absence de placeholders dans les fichiers structurants"

STRUCTURAL_FILES=(
  "$REPO_ROOT/flake.nix"
  "$HOST_DIR/default.nix"
  "$HOST_DIR/disko.nix"
)

FOUND_IN_STRUCTURAL=0
for f in "${STRUCTURAL_FILES[@]}"; do
  if [[ -f "$f" ]]; then
    rel="${f#"$REPO_ROOT/"}"
    if grep -q "DEFINE_\|CHANGEME" "$f" 2>/dev/null; then
      while IFS= read -r match; do
        fail "Placeholder dans fichier structurant $rel : $match"
        FOUND_IN_STRUCTURAL=$(( FOUND_IN_STRUCTURAL + 1 ))
      done < <(grep -n "DEFINE_\|CHANGEME" "$f")
    fi
  fi
done

if [[ $FOUND_IN_STRUCTURAL -eq 0 ]]; then
  ok "Aucun placeholder dans les fichiers structurants"
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
  echo ""
  echo -e "  Pour re-initialiser la config : nix run .#init-host -- $HOST"
  exit 1
fi

echo ""
