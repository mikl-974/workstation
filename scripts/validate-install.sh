#!/usr/bin/env bash
# validate-install.sh — Validateur pré-installation workstation
#
# Vérifie qu'un host est réellement prêt avant installation.

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

ERRORS=0
WARNINGS=0

ok()   { echo -e "  ${GRN}✔${RST}  $*"; }
fail() { echo -e "  ${RED}✘${RST}  $*"; ERRORS=$(( ERRORS + 1 )); }
warn() { echo -e "  ${YLW}⚠${RST}  $*"; WARNINGS=$(( WARNINGS + 1 )); }

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <host>"
  echo "Hosts disponibles : $(list_hosts "$REPO_ROOT")"
  exit 1
fi

HOST="$1"
HOST_DIR="$REPO_ROOT/targets/hosts/$HOST"
VARS_FILE="$(host_vars_file "$REPO_ROOT" "$HOST")"
DEFAULT_FILE="$(host_default_file "$REPO_ROOT" "$HOST")"
DISKO_FILE="$(host_disko_file "$REPO_ROOT" "$HOST")"
SYSTEM=""
USERNAME=""
HOSTNAME_VAL=""
DISK=""
TIMEZONE=""
LOCALE=""

print_field_status() {
  local field="$1"
  local value="$2"
  local required_hint="$3"

  if [[ -z "$value" ]]; then
    fail "vars.nix : champ '${field}' absent${required_hint}"
  elif is_placeholder_value "$value"; then
    fail "vars.nix : ${field} non défini ('$value')"
  else
    ok "${field} : ${value}"
  fi
}

echo ""
echo -e "${BLD}=== Validation pré-installation : host '$HOST' ===${RST}"
echo ""

echo -e "${BLD}── Existence du host${RST}"
if host_exists "$REPO_ROOT" "$HOST"; then
  ok "targets/hosts/$HOST/ existe"
else
  fail "targets/hosts/$HOST/ introuvable — hôtes disponibles : $(list_hosts "$REPO_ROOT")"
  echo ""
  echo -e "${RED}Validation interrompue : host introuvable.${RST}"
  exit 1
fi

echo ""
echo -e "${BLD}── Fichiers critiques du host${RST}"
for path in "$VARS_FILE|targets/hosts/$HOST/vars.nix" "$DEFAULT_FILE|targets/hosts/$HOST/default.nix"; do
  file="${path%%|*}"
  label="${path##*|}"
  if [[ -f "$file" ]]; then
    ok "$label existe"
  else
    fail "$label manquant"
  fi
done

if host_uses_disko "$REPO_ROOT" "$HOST"; then
  ok "targets/hosts/$HOST/disko.nix existe"
  HAS_DISKO=true
else
  warn "targets/hosts/$HOST/disko.nix absent — NixOS Anywhere n'est pas disponible pour ce host"
  HAS_DISKO=false
fi

echo ""
echo -e "${BLD}── Exposition dans flake.nix${RST}"
if [[ -f "$REPO_ROOT/flake.nix" ]]; then
  ok "flake.nix existe"
else
  fail "flake.nix manquant"
fi

if host_exposed_in_flake "$REPO_ROOT" "$HOST"; then
  ok "flake.nix expose nixosConfigurations.$HOST"
else
  fail "flake.nix n'expose pas nixosConfigurations.$HOST"
fi

echo ""
echo -e "${BLD}── Valeurs dans vars.nix${RST}"
if [[ -f "$VARS_FILE" ]]; then
  SYSTEM="$(read_nix_string_var "$VARS_FILE" "system")"
  USERNAME="$(read_nix_string_var "$VARS_FILE" "username")"
  HOSTNAME_VAL="$(read_nix_string_var "$VARS_FILE" "hostname")"
  DISK="$(read_nix_string_var "$VARS_FILE" "disk")"
  TIMEZONE="$(read_nix_string_var "$VARS_FILE" "timezone")"
  LOCALE="$(read_nix_string_var "$VARS_FILE" "locale")"

  print_field_status "system" "$SYSTEM" " — requis (x86_64-linux ou aarch64-linux)"
  if [[ -n "$SYSTEM" ]] && ! is_placeholder_value "$SYSTEM"; then
    if is_supported_nixos_system "$SYSTEM"; then
      ok "system supporté"
    else
      fail "vars.nix : system='$SYSTEM' non supporté (attendu : x86_64-linux ou aarch64-linux)"
    fi
  fi

  print_field_status "username" "$USERNAME" ""
  if [[ -n "$USERNAME" ]] && ! is_placeholder_value "$USERNAME"; then
    if [[ "$USERNAME" =~ ^[a-z][a-z0-9_-]*$ ]]; then
      ok "username valide pour Unix"
    else
      fail "vars.nix : username='$USERNAME' invalide (attendu : [a-z][a-z0-9_-]*)"
    fi
  fi

  print_field_status "hostname" "$HOSTNAME_VAL" ""
  if [[ -n "$HOSTNAME_VAL" ]] && ! is_placeholder_value "$HOSTNAME_VAL"; then
    if [[ "$HOSTNAME_VAL" =~ ^[a-z0-9][a-z0-9-]*$ ]]; then
      ok "hostname valide"
    else
      fail "vars.nix : hostname='$HOSTNAME_VAL' invalide"
    fi
  fi

  if [[ "$HAS_DISKO" == true ]]; then
    print_field_status "disk" "$DISK" " — requis quand disko.nix est présent"
    if [[ -n "$DISK" ]] && ! is_placeholder_value "$DISK"; then
      if [[ "$DISK" == /dev/* ]]; then
        ok "disk au bon format (/dev/...)"
      else
        fail "vars.nix : disk='$DISK' invalide (attendu : /dev/...)"
      fi
    fi
  elif [[ -n "$DISK" ]] && ! is_placeholder_value "$DISK"; then
    ok "disk renseigné (utile pour une future migration vers disko)"
  fi

  print_field_status "timezone" "$TIMEZONE" ""
  print_field_status "locale" "$LOCALE" ""
else
  fail "vars.nix manquant — impossible de vérifier les valeurs"
fi

echo ""
echo -e "${BLD}── Cohérence du host${RST}"
if [[ -n "$HOSTNAME_VAL" ]] && ! is_placeholder_value "$HOSTNAME_VAL"; then
  if [[ "$HOSTNAME_VAL" == "$HOST" ]]; then
    ok "hostname cohérent avec la clé host"
  else
    fail "hostname='$HOSTNAME_VAL' différent de la clé host '$HOST'"
  fi
fi

echo ""
echo -e "${BLD}── Absence de placeholders dans les fichiers structurants${RST}"
FOUND_PLACEHOLDERS=0
for file in \
  "$REPO_ROOT/flake.nix" \
  "$VARS_FILE" \
  "$DEFAULT_FILE" \
  "$DISKO_FILE" \
  "$(home_target_file "$REPO_ROOT" "$HOST")"; do
  [[ -f "$file" ]] || continue
  rel="${file#"$REPO_ROOT/"}"
  while IFS= read -r match; do
    [[ -z "$match" ]] && continue
    fail "Placeholder dans $rel : $match"
    FOUND_PLACEHOLDERS=$(( FOUND_PLACEHOLDERS + 1 ))
  done < <(grep -nE 'DEFINE_|CHANGEME' "$file" || true)
done
if [[ $FOUND_PLACEHOLDERS -eq 0 ]]; then
  ok "Aucun placeholder dans les fichiers structurants"
fi

echo ""
echo -e "${BLD}── Dotfiles activés par Home Manager${RST}"
if [[ -f "$(home_target_file "$REPO_ROOT" "$HOST")" ]]; then
  ok "home/targets/$HOST.nix existe — composition Home Manager target-specific détectée"
  DOTFILES_FOUND=0
  while IFS= read -r relpath; do
    [[ -z "$relpath" ]] && continue
    DOTFILES_FOUND=$(( DOTFILES_FOUND + 1 ))
    if [[ -e "$REPO_ROOT/dotfiles/$relpath" ]]; then
      ok "dotfiles/$relpath → existe"
    else
      fail "dotfiles/$relpath référencé dans home/targets/$HOST.nix ou ses imports mais introuvable"
    fi
  done < <(collect_active_dotfiles_for_host "$REPO_ROOT" "$HOST")
else
  fail "Aucune composition Home Manager trouvée (home/targets/$HOST.nix manquant)"
fi

echo ""
echo -e "${BLD}── Parcours d'installation réellement possible${RST}"
if [[ -f "$REPO_ROOT/scripts/install-manual.sh" ]]; then
  ok "fallback manuel disponible : scripts/install-manual.sh"
else
  fail "scripts/install-manual.sh manquant"
fi

if [[ -f "$REPO_ROOT/scripts/post-install-check.sh" ]]; then
  ok "vérification post-install disponible : scripts/post-install-check.sh"
else
  fail "scripts/post-install-check.sh manquant"
fi

if [[ "$HAS_DISKO" == true ]]; then
  if grep -q 'hostVars.disk' "$DISKO_FILE"; then
    ok "disko.nix lit bien le disque depuis hostVars.disk"
  else
    fail "targets/hosts/$HOST/disko.nix n'utilise pas hostVars.disk"
  fi

  if [[ -f "$REPO_ROOT/scripts/install-anywhere.sh" ]]; then
    ok "parcours NixOS Anywhere disponible : scripts/install-anywhere.sh"
  else
    fail "scripts/install-anywhere.sh manquant"
  fi
else
  warn "NixOS Anywhere non disponible pour ce host sans disko.nix"
fi

echo ""
echo "=== Résumé ==="
echo ""
if [[ $ERRORS -eq 0 && $WARNINGS -eq 0 ]]; then
  echo -e "${GRN}${BLD}✔ Validation complète : aucune erreur, aucun avertissement.${RST}"
  echo "  La configuration est prête pour une installation de '$HOST'."
elif [[ $ERRORS -eq 0 ]]; then
  echo -e "${YLW}${BLD}⚠ Validation complète : $WARNINGS avertissement(s), aucune erreur bloquante.${RST}"
  echo "  Le parcours reste possible mais doit être relu avant installation."
else
  echo -e "${RED}${BLD}✘ Validation échouée : $ERRORS erreur(s) bloquante(s), $WARNINGS avertissement(s).${RST}"
  echo "  Corrige les erreurs ci-dessus avant toute installation."
  echo ""
  echo "  Raccourcis utiles :"
  echo "   • Ré-initialiser : nix run .#init-host -- $HOST"
  echo "   • Diagnostiquer : nix run .#doctor -- --host $HOST"
  exit 1
fi

echo ""
