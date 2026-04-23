#!/usr/bin/env bash
# post-install-check.sh — Vérification post-installation workstation

set -euo pipefail

_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT=""
if [[ -f "$_SCRIPT_DIR/lib/workstation-install.sh" ]]; then
  # shellcheck source=./lib/workstation-install.sh
  source "$_SCRIPT_DIR/lib/workstation-install.sh"
  REPO_ROOT="$(resolve_repo_root "$_SCRIPT_DIR")"
fi

RED='\033[0;31m'
GRN='\033[0;32m'
YLW='\033[1;33m'
BLD='\033[1m'
RST='\033[0m'

ERRORS=0
WARNINGS=0
HOST_OVERRIDE=""

ok()   { echo -e "  ${GRN}✔${RST}  $*"; }
fail() { echo -e "  ${RED}✘${RST}  $*"; ERRORS=$(( ERRORS + 1 )); }
warn() { echo -e "  ${YLW}⚠${RST}  $*"; WARNINGS=$(( WARNINGS + 1 )); }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --host|-h)
      HOST_OVERRIDE="$2"
      shift 2
      ;;
    *)
      echo "Usage: $0 [--host <host>]"
      exit 1
      ;;
  esac
done

CURRENT_HOSTNAME="$(hostname 2>/dev/null || echo "inconnu")"
HOST_NAME="${HOST_OVERRIDE:-$CURRENT_HOSTNAME}"
HOST_VARS_FILE=""
HOST_DEFAULT_FILE=""
EXPECTED_USER=""
EXPECTED_USER_HOME=""
HOST_CONTEXT_AVAILABLE=false
EXPECT_DESKTOP=false
EXPECT_NETWORKING=false
if [[ -n "$REPO_ROOT" && -f "$REPO_ROOT/flake.nix" && -f "$REPO_ROOT/targets/hosts/$HOST_NAME/vars.nix" ]]; then
  HOST_CONTEXT_AVAILABLE=true
  HOST_VARS_FILE="$REPO_ROOT/targets/hosts/$HOST_NAME/vars.nix"
  HOST_DEFAULT_FILE="$REPO_ROOT/targets/hosts/$HOST_NAME/default.nix"
  EXPECTED_USER="$(read_nix_string_var "$HOST_VARS_FILE" "username")"
  host_has_profile "$REPO_ROOT" "$HOST_NAME" "desktop-hyprland" && EXPECT_DESKTOP=true
  host_has_profile "$REPO_ROOT" "$HOST_NAME" "networking" && EXPECT_NETWORKING=true
fi

if [[ -z "$EXPECTED_USER" ]]; then
  EXPECTED_USER="${USER:-$(whoami 2>/dev/null || echo '')}"
fi
if [[ -n "$EXPECTED_USER" ]]; then
  EXPECTED_USER_HOME="$(getent passwd "$EXPECTED_USER" 2>/dev/null | cut -d: -f6 || true)"
fi

check_binary() {
  local cmd="$1"
  local label="$2"
  if command -v "$cmd" &>/dev/null; then
    ok "$label disponible : $(command -v "$cmd")"
  else
    fail "$label introuvable dans PATH"
  fi
}

check_service() {
  local svc="$1"
  local label="$2"
  if systemctl is-active "$svc" &>/dev/null 2>&1; then
    ok "$label ($svc) — actif"
  elif systemctl is-enabled "$svc" &>/dev/null 2>&1; then
    warn "$label ($svc) — activé mais pas actif"
  else
    fail "$label ($svc) — inactif ou absent"
  fi
}

check_dotfile() {
  local home_dir="$1"
  local destination="$2"
  local source_rel="$3"
  local full_path="$home_dir/$destination"

  if [[ -L "$full_path" ]]; then
    ok "$destination → symlink Home Manager"
  elif [[ -e "$full_path" ]]; then
    warn "$destination présent mais non symlinké"
  else
    fail "$destination absent dans $home_dir"
  fi

  if [[ -n "$source_rel" && -n "$REPO_ROOT" && -f "$REPO_ROOT/dotfiles/$source_rel" ]]; then
    ok "dotfiles/$source_rel existe dans le repo"
  fi
}

echo ""
echo -e "${BLD}=== Vérifications post-installation workstation ===${RST}"
echo ""

echo -e "${BLD}── Système NixOS${RST}"
echo ""
if command -v nixos-rebuild &>/dev/null; then
  ok "nixos-rebuild disponible"
else
  fail "nixos-rebuild introuvable — ce script doit tourner sur un système NixOS"
fi

if [[ -L /run/current-system ]]; then
  ok "Génération courante présente : $(readlink /run/current-system | cut -d- -f2- | cut -c1-40)..."
else
  warn "/run/current-system absent"
fi

echo -e "  Hostname détecté : ${BLD}$CURRENT_HOSTNAME${RST}"
if [[ -n "$HOST_OVERRIDE" && "$HOST_OVERRIDE" != "$CURRENT_HOSTNAME" ]]; then
  warn "Host demandé '$HOST_OVERRIDE' différent du hostname courant '$CURRENT_HOSTNAME'"
fi

echo ""
echo -e "${BLD}── Host attendu et utilisateur${RST}"
echo ""
if [[ "$HOST_CONTEXT_AVAILABLE" == true ]]; then
  ok "Contexte repo détecté pour le host '$HOST_NAME'"
  ok "vars.nix lu depuis targets/hosts/$HOST_NAME/vars.nix"
else
  warn "Contexte repo indisponible pour '$HOST_NAME' — vérifications alignées sur le code limitées"
fi

if [[ -n "$EXPECTED_USER" ]] && getent passwd "$EXPECTED_USER" &>/dev/null; then
  ok "Utilisateur attendu présent : $EXPECTED_USER"
  if [[ -n "$EXPECTED_USER_HOME" ]]; then
    ok "Home détecté : $EXPECTED_USER_HOME"
  fi
else
  fail "Utilisateur attendu introuvable : ${EXPECTED_USER:-inconnu}"
fi

if [[ -n "${USER:-}" && "$USER" != "root" && -n "$EXPECTED_USER" && "$USER" != "$EXPECTED_USER" ]]; then
  warn "Session courante '$USER' différente de l'utilisateur attendu '$EXPECTED_USER'"
fi

echo ""
echo -e "${BLD}── Home Manager et dotfiles actifs${RST}"
echo ""
if command -v home-manager &>/dev/null; then
  ok "Commande home-manager disponible"
else
  warn "Commande home-manager absente (normal si Home Manager est intégré sans CLI)"
fi

if [[ -n "$EXPECTED_USER" ]]; then
  if systemctl status "home-manager-$EXPECTED_USER.service" &>/dev/null 2>&1; then
    ok "Service systemd home-manager-$EXPECTED_USER.service présent"
  elif [[ "$(id -u)" -eq 0 ]] && su - "$EXPECTED_USER" -c "systemctl --user status home-manager-$EXPECTED_USER.service" &>/dev/null 2>&1; then
    ok "Service user home-manager-$EXPECTED_USER.service présent"
  else
    warn "Service Home Manager dédié non détecté pour $EXPECTED_USER"
  fi
fi

if [[ -n "$EXPECTED_USER_HOME" ]]; then
  HM_GEN_DIR="$EXPECTED_USER_HOME/.local/state/home-manager/gcroots"
  if [[ -d "$HM_GEN_DIR" ]]; then
    ok "Répertoire Home Manager gcroots présent : $HM_GEN_DIR"
  else
    warn "Répertoire Home Manager gcroots absent pour $EXPECTED_USER"
  fi
fi

if [[ -n "$EXPECTED_USER_HOME" && -n "$REPO_ROOT" && -n "$EXPECTED_USER" ]]; then
  while IFS='|' read -r destination source_rel; do
    [[ -z "$destination" ]] && continue
    check_dotfile "$EXPECTED_USER_HOME" "$destination" "$source_rel"
  done < <(collect_home_file_mappings_for_host_user "$REPO_ROOT" "$HOST_NAME" "$EXPECTED_USER")
else
  warn "Impossible de vérifier les dotfiles actifs contre la composition Home Manager du host"
fi

echo ""
echo -e "${BLD}── Session desktop et daily UX${RST}"
echo ""
if [[ "$EXPECT_DESKTOP" == true ]]; then
  check_binary "Hyprland" "Hyprland"
  check_binary "foot" "Terminal foot"
  check_binary "wofi" "Launcher wofi"
  check_binary "mako" "Notifications mako"
  check_binary "cliphist" "Clipboard history"
  if command -v chromium &>/dev/null || command -v firefox &>/dev/null; then
    ok "Navigateur web disponible (chromium ou firefox)"
  else
    fail "Navigateur web introuvable (ni chromium, ni firefox)"
  fi
  check_binary "thunar" "Gestionnaire de fichiers"

  if systemctl is-enabled greetd &>/dev/null 2>&1 || systemctl is-active greetd &>/dev/null 2>&1; then
    ok "Display manager greetd actif"
  else
    fail "greetd non détecté"
  fi

  if [[ "${XDG_CURRENT_DESKTOP:-}" == "Hyprland" || "${XDG_SESSION_DESKTOP:-}" == "Hyprland" ]]; then
    if pgrep -x mako >/dev/null 2>&1; then
      ok "mako lancé dans la session"
    else
      warn "mako non détecté dans la session Hyprland courante"
    fi

    if pgrep -af 'cliphist store' >/dev/null 2>&1; then
      ok "watchers cliphist détectés"
    else
      warn "watchers cliphist non détectés dans la session Hyprland courante"
    fi
  else
    warn "Vérifications runtime de session ignorées hors session Hyprland"
  fi
else
  warn "Le host ne semble pas exposer le profil desktop-hyprland"
fi

echo ""
echo -e "${BLD}── Réseau et services de base${RST}"
echo ""
check_service "NetworkManager" "NetworkManager"
if [[ "$EXPECT_NETWORKING" == true ]]; then
  check_service "tailscaled" "Tailscale"
else
  warn "Profil networking non détecté — check Tailscale ignoré"
fi
if [[ "$EXPECT_DESKTOP" == true ]]; then
  check_service "warp-svc" "Cloudflare WARP"
fi

check_service "pipewire" "PipeWire"
check_service "pipewire-pulse" "PipeWire Pulse"
check_service "wireplumber" "WirePlumber"

echo ""
echo -e "${BLD}── DevShell .NET${RST}"
echo ""
if command -v nix &>/dev/null; then
  ok "nix disponible"
  if [[ -n "$REPO_ROOT" && -f "$REPO_ROOT/flake.nix" ]]; then
    if (cd "$REPO_ROOT" && nix develop .#dotnet --command dotnet --version >/dev/null); then
      ok "devShell .NET accessible via nix develop .#dotnet"
    else
      warn "Impossible de confirmer le devShell .NET depuis le repo courant"
    fi
  else
    warn "Repo local indisponible — check du devShell .NET ignoré"
  fi
else
  fail "nix introuvable — devShell .NET non vérifiable"
fi

echo ""
echo "=== Résumé ==="
echo ""
if [[ $ERRORS -eq 0 && $WARNINGS -eq 0 ]]; then
  echo -e "${GRN}${BLD}✔ Vérification complète : aucune erreur, aucun avertissement.${RST}"
  echo "  La machine semble prête côté install, first boot et daily UX."
elif [[ $ERRORS -eq 0 ]]; then
  echo -e "${YLW}${BLD}⚠ Vérification complète : $WARNINGS avertissement(s), aucune erreur critique.${RST}"
  echo "  La machine est globalement exploitable mais certains points méritent une vérification manuelle."
else
  echo -e "${RED}${BLD}✘ Vérification : $ERRORS erreur(s), $WARNINGS avertissement(s).${RST}"
  echo "  Des éléments critiques restent incohérents après installation."
  echo ""
  echo "  Pistes :"
  echo "   • relancer : sudo nixos-rebuild switch --flake .#$(hostname)"
  echo "   • relire : docs/bootstrap.md"
  echo "   • relire : docs/first-boot.md"
  exit 1
fi

echo ""
