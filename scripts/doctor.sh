#!/usr/bin/env bash
# doctor.sh — Diagnostic opératoire du repo workstation
#
# Vérifie la readiness locale du repo et des outils avant installation ou rebuild.

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
HOST=""

ok()   { echo -e "  ${GRN}✔${RST}  $*"; }
fail() { echo -e "  ${RED}✘${RST}  $*"; ERRORS=$(( ERRORS + 1 )); }
warn() { echo -e "  ${YLW}⚠${RST}  $*"; WARNINGS=$(( WARNINGS + 1 )); }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --host|-h)
      HOST="$2"
      shift 2
      ;;
    *)
      echo "Usage: $0 [--host <host>]"
      exit 1
      ;;
  esac
done

echo ""
echo -e "${BLD}=== Doctor workstation ===${RST}"
echo ""

echo -e "${BLD}── Repo et fichiers critiques${RST}"
for path in \
  "$REPO_ROOT/flake.nix|flake.nix" \
  "$REPO_ROOT/scripts/init-host.sh|scripts/init-host.sh" \
  "$REPO_ROOT/scripts/validate-install.sh|scripts/validate-install.sh" \
  "$REPO_ROOT/scripts/doctor.sh|scripts/doctor.sh" \
  "$REPO_ROOT/scripts/install-anywhere.sh|scripts/install-anywhere.sh" \
  "$REPO_ROOT/scripts/install-manual.sh|scripts/install-manual.sh" \
  "$REPO_ROOT/scripts/post-install-check.sh|scripts/post-install-check.sh"; do
  file="${path%%|*}"
  label="${path##*|}"
  if [[ -f "$file" ]]; then
    ok "$label existe"
  else
    fail "$label manquant"
  fi
done

echo ""
echo -e "${BLD}── Outils locaux${RST}"
check_cmd() {
  local cmd="$1"
  local mandatory="$2"
  local reason="$3"
  if command -v "$cmd" &>/dev/null; then
    ok "$cmd disponible"
  elif [[ "$mandatory" == "yes" ]]; then
    fail "$cmd introuvable — $reason"
  else
    warn "$cmd introuvable — $reason"
  fi
}

check_cmd "bash" yes  "les scripts d'orchestration sont en shell"
check_cmd "git"  yes  "nécessaire pour cloner, relire et mettre à jour le repo"
check_cmd "nix"  yes  "nécessaire pour nix run, nix develop et les rebuilds"
check_cmd "ssh"  no   "requis pour le parcours NixOS Anywhere"
check_cmd "ssh-keyscan" no "recommandé pour vérifier la clé hôte avant installation distante"
check_cmd "ssh-keygen" no "utile pour lire les empreintes de clés SSH"

if command -v nix &>/dev/null; then
  if (cd "$REPO_ROOT" && nix flake show . --all-systems --no-write-lock-file >/dev/null); then
    ok "flake lisible par nix"
  else
    fail "nix n'arrive pas à lire le flake courant"
  fi
fi

echo ""
echo -e "${BLD}── Commandes flake exposées${RST}"
for app in init-host show-config validate-install doctor install-anywhere install-manual post-install-check; do
  if flake_exposes_app "$REPO_ROOT" "$app"; then
    ok "nix run .#${app} disponible"
  else
    fail "nix run .#${app} non exposé dans flake.nix"
  fi
done

if [[ -n "$HOST" ]]; then
  MACHINE_CONTEXT="$(host_machine_context "$REPO_ROOT" "$HOST")"
  echo ""
  echo -e "${BLD}── Readiness du host '${HOST}'${RST}"
  if host_exists "$REPO_ROOT" "$HOST"; then
    ok "targets/hosts/$HOST existe"
  else
    fail "targets/hosts/$HOST introuvable — hôtes disponibles : $(list_hosts "$REPO_ROOT")"
  fi

  for path in \
    "$(host_vars_file "$REPO_ROOT" "$HOST")|targets/hosts/$HOST/vars.nix" \
    "$(host_default_file "$REPO_ROOT" "$HOST")|targets/hosts/$HOST/default.nix"; do
    file="${path%%|*}"
    label="${path##*|}"
    if [[ -f "$file" ]]; then
      ok "$label existe"
    else
      fail "$label manquant"
    fi
  done

  if [[ "$MACHINE_CONTEXT" == "virtual-machine" ]]; then
    ok "Contexte machine : virtual-machine (profil modules/profiles/virtual-machine.nix)"
  else
    ok "Contexte machine : bare-metal"
  fi

  if host_uses_disko "$REPO_ROOT" "$HOST"; then
    if flake_host_uses_disko_module "$REPO_ROOT" "$HOST"; then
      ok "disko branché dans flake.nix pour ce host"
    else
      fail "disko.nix présent, mais disko.nixosModules.disko n'est pas branché dans flake.nix pour ce host"
    fi

    HOST_DISK="$(read_nix_string_var "$(host_vars_file "$REPO_ROOT" "$HOST")" "disk")"
    if [[ -n "$HOST_DISK" ]] && ! is_placeholder_value "$HOST_DISK"; then
      ok "NixOS Anywhere possible pour ce host (disko.nix présent, module disko branché, disk renseigné)"
    else
      warn "NixOS Anywhere structurellement prêt pour ce host, mais le vrai disk reste à renseigner dans vars.nix"
    fi
  else
    warn "NixOS Anywhere indisponible pour ce host (pas de disko.nix)"
  fi

  if [[ -f "$(home_target_file "$REPO_ROOT" "$HOST")" ]]; then
    ok "home/targets/$HOST.nix existe — composition Home Manager moderne détectée"
  else
    fail "Aucune composition Home Manager trouvée pour '$HOST'"
  fi

  HOST_STACKS="$(grep -RhoE 'stacks/[^[:space:]]+/default\.nix' "$REPO_ROOT/targets/hosts/$HOST" \
    | sed -E 's#.*stacks/([^/]+)/default\.nix#\1#' \
    | sort -u || true)"
  if [[ -n "$HOST_STACKS" ]]; then
    while IFS= read -r stack_name; do
      [[ -z "$stack_name" ]] && continue
      ok "Stack locale détectée : $stack_name"
    done <<< "$HOST_STACKS"
  else
    ok "Aucune stack locale importée explicitement par ce host"
  fi

  if grep -Rhoq 'stacks/openclaw/default\.nix' "$REPO_ROOT/targets/hosts/$HOST"; then
    if [[ -f "$REPO_ROOT/stacks/openclaw/env/public.env" ]]; then
      ok "OpenClaw : public env versionné"
    else
      fail "OpenClaw : stacks/openclaw/env/public.env manquant"
    fi

    ok "OpenClaw : posture réseau minimale retenue = tailnet-only"
    ok "OpenClaw : token d'auth gateway généré localement au premier start"

    if [[ -f "$REPO_ROOT/secrets/stacks/openclaw.yaml" ]]; then
      ok "OpenClaw : secret env sops présent (secrets/stacks/openclaw.yaml)"
    else
      warn "OpenClaw : aucun secret env externe versionné — le premier boot minimal reste possible, mais Telegram/providers restent volontairement hors scope"
    fi
  fi
fi

echo ""
echo "=== Résumé ==="
echo ""
if [[ $ERRORS -eq 0 && $WARNINGS -eq 0 ]]; then
  echo -e "${GRN}${BLD}✔ Doctor OK : aucun problème détecté.${RST}"
elif [[ $ERRORS -eq 0 ]]; then
  echo -e "${YLW}${BLD}⚠ Doctor terminé : $WARNINGS avertissement(s), aucune erreur bloquante.${RST}"
else
  echo -e "${RED}${BLD}✘ Doctor terminé : $ERRORS erreur(s), $WARNINGS avertissement(s).${RST}"
  exit 1
fi

echo ""
