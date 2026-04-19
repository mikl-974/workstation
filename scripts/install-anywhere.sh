#!/usr/bin/env bash
# install-anywhere.sh — Orchestration de l'installation via NixOS Anywhere
#
# Ce script orchestre et vérifie le parcours NixOS Anywhere.
# Il ne redéfinit pas la configuration — celle-ci reste dans flake.nix et hosts/.
#
# Usage :
#   ./scripts/install-anywhere.sh <host> <target>
#   nix run .#install-anywhere -- <host> <target>
#
# <target> peut être :
#   192.168.1.50          → se connecte en root@192.168.1.50
#   root@192.168.1.50     → explicitement root
#   nixos@orb             → utilisateur non-root : configure root via sudo
#
# Exemples :
#   ./scripts/install-anywhere.sh main 192.168.1.50
#   ./scripts/install-anywhere.sh main nixos@orb

set -euo pipefail

# ---------------------------------------------------------------------------
# Couleurs et helpers
# ---------------------------------------------------------------------------

RED='\033[0;31m'
GRN='\033[0;32m'
YLW='\033[1;33m'
BLD='\033[1m'
RST='\033[0m'

info()  { echo -e "  ${GRN}✔${RST}  $*"; }
warn()  { echo -e "  ${YLW}⚠${RST}  $*"; }
fail()  { echo -e "  ${RED}✘${RST}  $*"; }
die()   { fail "$@"; exit 1; }

# ---------------------------------------------------------------------------
# Résolution du répertoire du projet
# ---------------------------------------------------------------------------

_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -n "${REPO_ROOT:-}" ]]; then
  REPO_ROOT="${REPO_ROOT}"
elif [[ "$_SCRIPT_DIR" == /nix/store/* ]]; then
  REPO_ROOT="$PWD"
else
  REPO_ROOT="$(cd "$_SCRIPT_DIR/.." && pwd)"
fi

# ---------------------------------------------------------------------------
# Arguments
# ---------------------------------------------------------------------------

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <host> <target>"
  echo ""
  echo "  <host>   : nom du host NixOS (sous-dossier de hosts/)"
  echo "  <target> : [user@]ip-ou-hostname de la machine cible"
  echo ""
  echo "Hosts disponibles : $(ls "$REPO_ROOT/hosts" | tr '\n' ' ')"
  echo ""
  echo "Exemples :"
  echo "  $0 main 192.168.1.50          # root direct (live ISO)"
  echo "  $0 main nixos@orb             # via utilisateur non-root (OrbStack, VM…)"
  exit 1
fi

HOST="$1"
TARGET_RAW="$2"

# Parser user@host
if [[ "$TARGET_RAW" == *@* ]]; then
  TARGET_USER="${TARGET_RAW%%@*}"
  TARGET_HOST="${TARGET_RAW#*@}"
else
  TARGET_USER="root"
  TARGET_HOST="$TARGET_RAW"
fi

echo ""
echo -e "${BLD}=== Installation NixOS Anywhere : host '$HOST' → ${TARGET_USER}@${TARGET_HOST} ===${RST}"

# ---------------------------------------------------------------------------
# 1. Validation préalable
# ---------------------------------------------------------------------------

echo ""
echo -e "${BLD}── Étape 1/5 : Validation de la configuration${RST}"
echo ""

VALIDATE_SCRIPT="$REPO_ROOT/scripts/validate-install.sh"
if [[ -x "$VALIDATE_SCRIPT" ]]; then
  if ! "$VALIDATE_SCRIPT" "$HOST"; then
    echo ""
    die "Validation échouée — corrige les erreurs avant de relancer."
  fi
else
  warn "validate-install.sh introuvable — validation ignorée."
fi

# ---------------------------------------------------------------------------
# 2. Prérequis locaux
# ---------------------------------------------------------------------------

echo ""
echo -e "${BLD}── Étape 2/5 : Vérification des prérequis${RST}"
echo ""

MISSING=0
check_cmd() {
  if command -v "$1" &>/dev/null; then
    info "$1 disponible"
  else
    fail "$1 introuvable — $2"
    MISSING=$(( MISSING + 1 ))
  fi
}
check_cmd "nix" "Nix doit être installé avec les flakes activés"
check_cmd "ssh" "SSH est requis pour accéder à la machine cible"

nix flake --help &>/dev/null 2>&1 && info "nix flakes activés" \
  || warn "Impossible de vérifier l'activation des flakes"

[[ $MISSING -gt 0 ]] && die "Prérequis manquants — installation annulée."

# Trouver la clé SSH locale
SSH_PRIVKEY=""
SSH_PUBKEY_FILE=""
for kf in "$HOME/.ssh/id_ed25519" "$HOME/.ssh/id_rsa" "$HOME/.ssh/id_ecdsa"; do
  if [[ -f "$kf" && -f "${kf}.pub" ]]; then
    SSH_PRIVKEY="$kf"
    SSH_PUBKEY_FILE="${kf}.pub"
    break
  fi
done
[[ -z "$SSH_PRIVKEY" ]] && die "Aucune clé SSH dans ~/.ssh/. Génère-en une : ssh-keygen -t ed25519"

# S'assurer que la clé est dans l'agent SSH (évite les demandes de passphrase en boucle)
KEY_FP=$(ssh-keygen -lf "$SSH_PUBKEY_FILE" 2>/dev/null | awk '{print $2}')
if ! ssh-add -l 2>/dev/null | grep -q "$KEY_FP"; then
  warn "Clé $SSH_PRIVKEY absente de l'agent SSH — ajout en cours…"
  ssh-add "$SSH_PRIVKEY" || die "Impossible d'ajouter la clé à l'agent. Lance 'ssh-add $SSH_PRIVKEY'."
fi
info "Clé SSH disponible dans l'agent"

# ---------------------------------------------------------------------------
# 3. Connectivité SSH
# ---------------------------------------------------------------------------

echo ""
echo -e "${BLD}── Étape 3/5 : Vérification de la connectivité SSH${RST}"
echo ""

SSH_BASE="ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=accept-new"

echo "  Test de connexion vers ${TARGET_USER}@${TARGET_HOST}…"
if ! $SSH_BASE "${TARGET_USER}@${TARGET_HOST}" "echo OK" 2>/dev/null | grep -q OK; then
  die "Impossible de se connecter à ${TARGET_USER}@${TARGET_HOST}.
  Vérifie : IP correcte ? SSH actif sur la cible ? Utilisateur valide ?"
fi
info "SSH ${TARGET_USER}@${TARGET_HOST} accessible"

# ---------------------------------------------------------------------------
# Établir un accès root fiable pour nixos-anywhere
#
# nixos-anywhere a besoin d'un accès SSH root direct avec vrais privilèges.
#
# Cas A : TARGET_USER=root                       → on utilise directement
# Cas B : TARGET_USER≠root, root@host fonctionne → on vérifie les vrais droits
# Cas C : TARGET_USER≠root, root@host KO         → on configure via sudo + tunnel
# ---------------------------------------------------------------------------

NA_SSH_TARGET=""
NA_SSH_EXTRA_OPTS=()

setup_root_key() {
  # Copie la clé publique locale dans /root/.ssh/authorized_keys via sudo
  echo "  → Installation de la clé SSH pour root…"
  $SSH_BASE "${TARGET_USER}@${TARGET_HOST}" "
    sudo mkdir -p /root/.ssh &&
    sudo chmod 700 /root/.ssh &&
    sudo tee /root/.ssh/authorized_keys > /dev/null &&
    sudo chmod 600 /root/.ssh/authorized_keys
  " < "$SSH_PUBKEY_FILE" 2>/dev/null \
    || die "Impossible d'installer la clé SSH pour root (sudo fonctionne ?)"
}

test_real_root() {
  # Vérifie que root a les vrais privilèges (accès /dev/)
  local target="$1"
  shift
  ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no -o BatchMode=yes \
      -i "$SSH_PRIVKEY" "$@" "$target" \
      'test "$(whoami)" = root && test -w /dev/ && echo ROOT_OK' 2>/dev/null | grep -q ROOT_OK
}

if [[ "$TARGET_USER" == "root" ]]; then
  # ── Cas A : root direct ──
  NA_SSH_TARGET="root@${TARGET_HOST}"
  # Installer la clé locale dans authorized_keys de root pour nixos-anywhere
  echo "  → Installation de la clé SSH pour root…"
  $SSH_BASE "root@${TARGET_HOST}" "
    mkdir -p /root/.ssh && chmod 700 /root/.ssh &&
    tee /root/.ssh/authorized_keys > /dev/null &&
    chmod 600 /root/.ssh/authorized_keys
  " < "$SSH_PUBKEY_FILE" 2>/dev/null \
    || warn "Impossible d'installer la clé SSH pour root (non critique si déjà présente)"
  NA_SSH_EXTRA_OPTS+=(-i "$SSH_PRIVKEY")

else
  # ── Cas B ou C ──
  setup_root_key
  sleep 1

  if test_real_root "root@${TARGET_HOST}"; then
    info "root@${TARGET_HOST} accessible avec vrais privilèges"
    NA_SSH_TARGET="root@${TARGET_HOST}"
  else
    # ── Cas C : proxy SSH (OrbStack, etc.) — tunnel nécessaire ──
    echo "  → root@${TARGET_HOST} n'a pas les vrais privilèges (proxy SSH détecté)"
    echo "  → Lancement d'un sshd temporaire + tunnel…"

    # Trouver sshd sur la cible
    SSHD_PATH=$($SSH_BASE "${TARGET_USER}@${TARGET_HOST}" '
      find /nix/store -maxdepth 3 -name sshd -type f 2>/dev/null | head -1
      command -v sshd 2>/dev/null || true
    ' 2>/dev/null | head -1)
    [[ -z "$SSHD_PATH" ]] && die "sshd introuvable sur la cible"

    # Préparer et démarrer sshd temporaire sur port 22222
    # Chaque commande sudo séparée pour éviter les problèmes de parsing en heredoc
    # "|| true" sur chaque appel SSH : OrbStack retourne parfois 255 à la fermeture
    $SSH_BASE "${TARGET_USER}@${TARGET_HOST}" "sudo mkdir -p /var/empty /tmp/sshd-tmp" 2>/dev/null || true
    $SSH_BASE "${TARGET_USER}@${TARGET_HOST}" "sudo useradd --system --no-create-home --shell /sbin/nologin sshd 2>/dev/null; true" 2>/dev/null || true
    $SSH_BASE "${TARGET_USER}@${TARGET_HOST}" "sudo rm -f /tmp/sshd-tmp/host_key /tmp/sshd-tmp/host_key.pub && sudo ssh-keygen -t ed25519 -f /tmp/sshd-tmp/host_key -N ''" 2>/dev/null || true
    $SSH_BASE "${TARGET_USER}@${TARGET_HOST}" "sudo pkill -f 'sshd.*-p 22222' 2>/dev/null; true" 2>/dev/null || true
    # Créer le fichier log avec les bonnes permissions AVANT de lancer sshd en sudo
    $SSH_BASE "${TARGET_USER}@${TARGET_HOST}" "sudo touch /tmp/sshd-tmp/sshd.log && sudo chmod 666 /tmp/sshd-tmp/sshd.log" 2>/dev/null || true
    sleep 0.3
    # Lancer sshd en background (nohup pour survivre à la fermeture SSH)
    # Le "|| true" est indispensable : OrbStack retourne 255 sur les connexions avec &
    $SSH_BASE "${TARGET_USER}@${TARGET_HOST}" \
      "nohup sudo '$SSHD_PATH' -p 22222 -D -o PermitRootLogin=yes -o AuthorizedKeysFile=/root/.ssh/authorized_keys -o StrictModes=no -o HostKey=/tmp/sshd-tmp/host_key >> /tmp/sshd-tmp/sshd.log 2>&1 & disown; exit 0" 2>/dev/null || true
    sleep 1
    # Vérifier que sshd écoute (connexion séparée pour ne pas être affecté par le 255)
    SSHD_STATUS=$($SSH_BASE "${TARGET_USER}@${TARGET_HOST}" \
      "ss -tlnp 2>/dev/null | grep -q ':22222' && echo SSHD_OK || echo SSHD_FAIL" 2>/dev/null || echo SSHD_FAIL)
    echo "$SSHD_STATUS" | grep -q SSHD_OK \
      || die "Impossible de démarrer sshd temporaire sur la cible"
    info "sshd temporaire démarré sur port 22222"

    # Tunnel local:22222 → VM:22222
    echo "  → Ouverture du tunnel SSH local:22222 → cible:22222…"
    pkill -f "ssh.*-L 22222:localhost:22222" 2>/dev/null || true
    sleep 0.3
    ssh -f -N -o StrictHostKeyChecking=accept-new \
      -L 22222:localhost:22222 "${TARGET_USER}@${TARGET_HOST}" 2>/dev/null
    sleep 1

    # Tester root via le tunnel
    if test_real_root "root@127.0.0.1" -p 22222; then
      info "root SSH fonctionnel via tunnel local:22222"
      NA_SSH_TARGET="root@127.0.0.1"
      NA_SSH_EXTRA_OPTS+=(--ssh-port 22222)
      NA_SSH_EXTRA_OPTS+=(--ssh-option "StrictHostKeyChecking=no")
      NA_SSH_EXTRA_OPTS+=(-i "$SSH_PRIVKEY")
    else
      die "Impossible de se connecter en root via le tunnel.
  → Le port 22222 est-il libre ? (lsof -i :22222)
  → La clé est-elle dans l'agent ? (ssh-add -l)"
    fi
  fi
fi

# ---------------------------------------------------------------------------
# 4. Points de contrôle
# ---------------------------------------------------------------------------

echo ""
echo -e "${BLD}── Étape 4/5 : Points à vérifier avant de continuer${RST}"
echo ""

DISK=$(grep -E 'disk[[:space:]]*=' "$REPO_ROOT/hosts/$HOST/vars.nix" 2>/dev/null \
  | sed -E 's/.*=[[:space:]]*"([^"]+)".*/\1/' | head -1 || true)
USERNAME=$(grep -E 'username[[:space:]]*=' "$REPO_ROOT/hosts/$HOST/vars.nix" 2>/dev/null \
  | sed -E 's/.*=[[:space:]]*"([^"]+)".*/\1/' | head -1 || true)
DISK="${DISK:-inconnu}"
USERNAME="${USERNAME:-inconnu}"

echo -e "  Cible nixos-anywhere   : ${BLD}${NA_SSH_TARGET}${RST}"
echo -e "  Disque cible (disko)   : ${BLD}$DISK${RST}"
echo -e "  Utilisateur (home-mgr) : ${BLD}$USERNAME${RST}"
echo ""
echo -e "  ${YLW}ATTENTION${RST} : NixOS Anywhere va ${RED}effacer et reformater${RST} le disque $DISK."
echo "  Assure-toi que c'est bien le bon disque. Lance 'lsblk' sur la cible pour confirmer."
echo ""

read -rp "  Confirmer l'installation ? [oui/NON] " CONFIRM
CONFIRM_LOWER=$(echo "$CONFIRM" | tr '[:upper:]' '[:lower:]')
[[ "$CONFIRM_LOWER" != "oui" ]] && { echo "  Installation annulée."; exit 0; }

# ---------------------------------------------------------------------------
# 5. Pré-configuration Nix + lancement nixos-anywhere
# ---------------------------------------------------------------------------

echo ""
echo -e "${BLD}── Étape 5/5 : Lancement de NixOS Anywhere${RST}"
echo ""

# Fonction pour exécuter des commandes sur la cible via le canal root validé
na_ssh() {
  if [[ "$NA_SSH_TARGET" == "root@127.0.0.1" ]]; then
    ssh -o StrictHostKeyChecking=no -o BatchMode=yes \
        -i "$SSH_PRIVKEY" -p 22222 "$NA_SSH_TARGET" "$@"
  else
    $SSH_BASE "$NA_SSH_TARGET" "$@"
  fi
}

# Pré-configuration Nix (seulement si Nix est présent sur la cible)
echo "  Vérification de Nix sur la cible…"
REMOTE_HAS_NIX=false
if na_ssh 'command -v nix-daemon >/dev/null 2>&1 || test -e /run/current-system/sw/bin/nix-daemon || test -e /nix/var/nix/profiles/default/bin/nix-daemon' 2>/dev/null; then
  REMOTE_HAS_NIX=true
  info "Nix détecté sur la cible — pré-configuration du daemon…"
  na_ssh '
    set -e
    CONF=/etc/nix/nix.conf
    RESOLVED=$(readlink -f "$CONF" 2>/dev/null || echo "$CONF")
    SNIPPET="trusted-users = root
download-buffer-size = 524288000"
    if [ -w "$RESOLVED" ]; then
      printf "\n%s\n" "$SNIPPET" >> "$RESOLVED"
    else
      cp "$RESOLVED" /tmp/nix.conf.patched 2>/dev/null || touch /tmp/nix.conf.patched
      printf "\n%s\n" "$SNIPPET" >> /tmp/nix.conf.patched
      mount --bind /tmp/nix.conf.patched "$RESOLVED"
    fi
    systemctl restart nix-daemon 2>/dev/null || true
    # Rendre nix-daemon accessible dans le PATH SSH non-interactif
    NIX_DAEMON=$(command -v nix-daemon 2>/dev/null \
      || ls /run/current-system/sw/bin/nix-daemon \
         /nix/var/nix/profiles/default/bin/nix-daemon 2>/dev/null | head -1 || true)
    if [ -n "$NIX_DAEMON" ] && [ ! -e /usr/local/bin/nix-daemon ]; then
      ln -sf "$NIX_DAEMON" /usr/local/bin/nix-daemon 2>/dev/null || true
    fi
    echo DONE
  ' 2>/dev/null | grep -q DONE && info "daemon Nix reconfiguré" \
    || warn "Reconfiguration Nix non confirmée (non critique)"
else
  info "Nix absent sur la cible — construction en local (Mac → remote copy)"
  # Préparer l'environnement kexec NixOS pour avoir assez d'espace :
  # - /tmp → vrai disque (évite "No space left" dans le tmpfs RAM)
  # - zram swap (augmente la RAM disponible pour les gros builds)
  echo "  → Préparation de l'environnement kexec (espace disque + swap)…"
  na_ssh '
    # /tmp sur le vrai disque si pas déjà fait
    if df /tmp 2>/dev/null | grep -q tmpfs; then
      mkdir -p /mnt/tmp
      mount --bind /mnt/tmp /tmp 2>/dev/null || true
    fi
    # zram swap si pas déjà actif
    if ! swapon --show 2>/dev/null | grep -q zram; then
      modprobe zram 2>/dev/null || true
      ZDEV=$(zramctl --find --size 3G 2>/dev/null || echo "")
      if [ -n "$ZDEV" ]; then
        mkswap "$ZDEV" >/dev/null 2>&1 && swapon "$ZDEV" 2>/dev/null || true
      fi
    fi
    echo KEXEC_PREP_DONE
  ' 2>/dev/null | grep -q KEXEC_PREP_DONE \
    && info "Environnement kexec prêt (espace + swap)" \
    || warn "Préparation kexec non confirmée (non critique si déjà prête)"
fi

# Construire les options nixos-anywhere
# Si Nix est absent : kexec (phases par défaut) — nixos-anywhere boot un live NixOS sur la cible
# Si Nix est présent : skip kexec, build-on-remote — la cible a déjà un store Nix utilisable
NIXOS_ANYWHERE_OPTS=(
  --flake "path:${REPO_ROOT}#${HOST}"
  "${NA_SSH_EXTRA_OPTS[@]+"${NA_SSH_EXTRA_OPTS[@]}"}"
)
if [[ "$REMOTE_HAS_NIX" == true ]]; then
  NIXOS_ANYWHERE_OPTS+=(--build-on remote --phases disko,install)
  info "Mode : build-on-remote + skip kexec (Nix présent sur la cible)"
else
  # Kexec : nixos-anywhere boot un live NixOS sur la cible, puis installe.
  # On ne passe PAS --build-on remote car le kexec env a peu de RAM et
  # son daemon Nix n'accepte pas nos settings → build local sur le Mac.
  info "Mode : kexec (Nix absent — construction locale Mac → copie remote)"
fi

echo ""
echo "  Commande :"
echo -e "  ${BLD}nix run nixpkgs#nixos-anywhere -- ${NIXOS_ANYWHERE_OPTS[*]} $NA_SSH_TARGET${RST}"
echo ""

cd "$REPO_ROOT"
nix run nixpkgs#nixos-anywhere -- "${NIXOS_ANYWHERE_OPTS[@]}" "$NA_SSH_TARGET"

# ---------------------------------------------------------------------------
# Résumé
# ---------------------------------------------------------------------------

# Nettoyage tunnel
pkill -f "ssh.*-L 22222:localhost:22222" 2>/dev/null || true

echo ""
echo -e "${GRN}${BLD}=== Installation terminée ===${RST}"
echo ""
echo "  Prochaines étapes :"
echo "   1. Attendre le reboot de la machine cible"
echo "   2. Se reconnecter : ssh $USERNAME@$TARGET_HOST"
echo "   3. Vérifier : nix run .#post-install-check"
echo "   4. Si nécessaire : sudo nixos-rebuild switch --flake .#$HOST"
echo ""
