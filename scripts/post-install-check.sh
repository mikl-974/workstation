#!/usr/bin/env bash
# post-install-check.sh — Vérification post-installation workstation
#
# Vérifie que la machine est correctement installée et configurée.
# À lancer après le premier boot ou après un nixos-rebuild switch.
#
# Usage :
#   ./scripts/post-install-check.sh
#   nix run .#post-install-check

set -euo pipefail

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

echo ""
echo -e "${BLD}=== Vérifications post-installation workstation ===${RST}"
echo ""

# ---------------------------------------------------------------------------
# 1. Système NixOS
# ---------------------------------------------------------------------------

echo -e "${BLD}── Système NixOS${RST}"
echo ""

if command -v nixos-rebuild &>/dev/null; then
  ok "nixos-rebuild disponible (système NixOS actif)"
else
  fail "nixos-rebuild introuvable — ce script doit être lancé sur un système NixOS"
fi

if [[ -f /etc/nixos/flake.nix ]] || [[ -L /run/current-system ]]; then
  ok "Génération courante du système NixOS présente : $(readlink /run/current-system | cut -d- -f2- | cut -c1-40)..."
else
  warn "Impossible de lire la génération courante NixOS"
fi

HOSTNAME=$(hostname 2>/dev/null || echo "inconnu")
echo -e "  Hostname détecté : ${BLD}$HOSTNAME${RST}"

# ---------------------------------------------------------------------------
# 2. Utilisateur
# ---------------------------------------------------------------------------

echo ""
echo -e "${BLD}── Utilisateur${RST}"
echo ""

CURRENT_USER="${USER:-$(whoami 2>/dev/null || echo '')}"

if [[ -n "$CURRENT_USER" && "$CURRENT_USER" != "root" ]]; then
  ok "Utilisateur courant : $CURRENT_USER"
  if id "$CURRENT_USER" &>/dev/null; then
    GROUPS_OUTPUT=$(id -nG "$CURRENT_USER")
    ok "Utilisateur $CURRENT_USER existe dans /etc/passwd"
    echo "    Groupes : $GROUPS_OUTPUT"
    if echo "$GROUPS_OUTPUT" | grep -qw "wheel"; then
      ok "Membre du groupe wheel (sudo)"
    else
      warn "$CURRENT_USER n'est pas dans le groupe wheel — sudo non disponible"
    fi
  fi
else
  warn "Lancé en tant que root — les vérifications utilisateur sont limitées"
  warn "Relancer ce script avec l'utilisateur normal pour des vérifications complètes"
fi

# ---------------------------------------------------------------------------
# 3. Home Manager
# ---------------------------------------------------------------------------

echo ""
echo -e "${BLD}── Home Manager${RST}"
echo ""

if command -v home-manager &>/dev/null; then
  ok "home-manager disponible"
  HM_VERSION=$(home-manager --version 2>/dev/null || echo "inconnu")
  echo "    Version : $HM_VERSION"
else
  # Home Manager intégré dans NixOS — vérifier via le service
  if [[ -n "$CURRENT_USER" && "$CURRENT_USER" != "root" ]]; then
    if systemctl --user status "home-manager-$CURRENT_USER.service" &>/dev/null 2>&1; then
      ok "Service Home Manager actif pour $CURRENT_USER"
    else
      # Peut être normal si intégré via nixosModules (pas de service dédié)
      warn "Commande home-manager absente — si Home Manager est intégré au système NixOS, c'est normal"
    fi
  else
    warn "home-manager non disponible comme commande (peut être intégré au système NixOS)"
  fi
fi

# Vérifier les dotfiles Home Manager
HM_GEN_DIR="$HOME/.local/state/home-manager/gcroots"
if [[ -d "$HM_GEN_DIR" ]]; then
  ok "Répertoire Home Manager gcroots présent (~/.local/state/home-manager/)"
else
  warn "Répertoire Home Manager gcroots absent — Home Manager n'a peut-être pas encore été activé"
fi

# ---------------------------------------------------------------------------
# 4. Dotfiles
# ---------------------------------------------------------------------------

echo ""
echo -e "${BLD}── Dotfiles${RST}"
echo ""

check_dotfile() {
  local path="$HOME/$1"
  local label="$2"
  if [[ -e "$path" ]]; then
    if [[ -L "$path" ]]; then
      ok "$label → $path (symlink Home Manager)"
    else
      ok "$label → $path (fichier direct)"
    fi
  else
    warn "$label absent : $path"
  fi
}

check_dotfile ".config/hypr/hyprland.conf"  "Config Hyprland"
check_dotfile ".config/foot/foot.ini"        "Config foot (terminal)"
check_dotfile ".config/wofi/config"          "Config wofi (launcher)"

# ---------------------------------------------------------------------------
# 5. Hyprland / session desktop
# ---------------------------------------------------------------------------

echo ""
echo -e "${BLD}── Hyprland / session desktop${RST}"
echo ""

if command -v Hyprland &>/dev/null; then
  ok "Hyprland disponible : $(command -v Hyprland)"
else
  fail "Hyprland introuvable dans PATH — le profil desktop-hyprland n'est peut-être pas activé"
fi

# Vérifier que le display manager est présent (greetd, gdm, etc.)
if systemctl is-enabled greetd &>/dev/null 2>&1 || systemctl is-active greetd &>/dev/null 2>&1; then
  ok "Display manager greetd actif"
elif systemctl is-enabled gdm &>/dev/null 2>&1; then
  ok "Display manager GDM actif"
elif systemctl is-enabled sddm &>/dev/null 2>&1; then
  ok "Display manager SDDM actif"
else
  warn "Display manager non détecté — vérifier manuellement si nécessaire"
fi

# ---------------------------------------------------------------------------
# 6. Services réseau
# ---------------------------------------------------------------------------

echo ""
echo -e "${BLD}── Services réseau${RST}"
echo ""

check_service() {
  local svc="$1"
  local label="$2"
  if systemctl is-active "$svc" &>/dev/null 2>&1; then
    ok "$label ($svc) — actif"
  elif systemctl is-enabled "$svc" &>/dev/null 2>&1; then
    warn "$label ($svc) — activé mais pas actif (démarrage en cours ?)"
  else
    warn "$label ($svc) — inactif ou non présent sur ce host"
  fi
}

check_service "tailscaled"    "Tailscale"
check_service "warp-svc"      "Cloudflare WARP"
check_service "NetworkManager" "NetworkManager"

# ---------------------------------------------------------------------------
# 7. DevShell .NET
# ---------------------------------------------------------------------------

echo ""
echo -e "${BLD}── DevShell .NET${RST}"
echo ""

if command -v nix &>/dev/null; then
  ok "nix disponible — devShell .NET accessible via : nix develop .#dotnet"
else
  warn "nix introuvable — le devShell .NET ne peut pas être vérifié"
fi

if command -v dotnet &>/dev/null; then
  ok "dotnet disponible dans PATH : $(dotnet --version 2>/dev/null || echo 'version inconnue')"
else
  warn "dotnet absent du PATH système (normal si non activé) — accessible via : nix develop .#dotnet"
fi

if command -v docker &>/dev/null; then
  ok "docker client disponible"
else
  warn "docker absent du PATH système — accessible via : nix develop .#dotnet"
fi

# ---------------------------------------------------------------------------
# 8. Audio
# ---------------------------------------------------------------------------

echo ""
echo -e "${BLD}── Audio${RST}"
echo ""

check_service "pipewire"        "PipeWire"
check_service "pipewire-pulse"  "PipeWire Pulse"
check_service "wireplumber"     "WirePlumber"

# ---------------------------------------------------------------------------
# Résumé
# ---------------------------------------------------------------------------

echo ""
echo "=== Résumé ==="
echo ""

if [[ $ERRORS -eq 0 && $WARNINGS -eq 0 ]]; then
  echo -e "${GRN}${BLD}✔ Vérification complète : aucune erreur, aucun avertissement.${RST}"
  echo "  La machine semble correctement installée et configurée."
elif [[ $ERRORS -eq 0 ]]; then
  echo -e "${YLW}${BLD}⚠ Vérification complète : $WARNINGS avertissement(s), aucune erreur critique.${RST}"
  echo "  Certains éléments méritent d'être vérifiés manuellement."
else
  echo -e "${RED}${BLD}✘ Vérification : $ERRORS erreur(s), $WARNINGS avertissement(s).${RST}"
  echo "  Des éléments critiques semblent manquants ou non configurés."
  echo ""
  echo "  Pistes :"
  echo "   • Relancer : sudo nixos-rebuild switch --flake .#$(hostname)"
  echo "   • Vérifier : docs/bootstrap.md"
  exit 1
fi

echo ""
