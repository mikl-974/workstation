# Installation manuelle NixOS — Guide complet

Ce document décrit le parcours d'installation manuelle de la workstation à partir d'un live ISO NixOS.
Il couvre le cas où NixOS Anywhere n'est pas utilisé ou pas disponible.

Référence rapide : `docs/install-checklist.md`
Parcours NixOS Anywhere : `docs/nixos-anywhere.md`

---

## Prérequis

- ISO NixOS minimal téléchargée (https://nixos.org/download/)
- Clé USB bootable préparée
- Connexion réseau disponible sur la machine cible
- Accès au repo `workstation` (clone local ou accès GitHub)

---

## 1. Boot sur l'ISO NixOS

1. Écrire l'ISO sur la clé USB :

   ```bash
   dd if=nixos-minimal.iso of=/dev/sdX bs=4M status=progress conv=fsync
   ```

2. Booter la machine cible sur la clé USB (configurer le BIOS/UEFI en conséquence).

3. Vérifier que le système a démarré :

   ```bash
   uname -a
   ```

---

## 2. Préparation réseau

**Connexion filaire** : dans la plupart des cas, automatique via DHCP.

**Connexion Wi-Fi** :

```bash
wpa_supplicant -B -i wlan0 -c <(wpa_passphrase "NOM_RESEAU" "MOT_DE_PASSE")
dhclient wlan0
```

Vérifier la connectivité :

```bash
ping -c 3 github.com
```

**Activer SSH pour accès distant (optionnel mais recommandé)** :

```bash
passwd root            # définir un mot de passe temporaire
systemctl start sshd
ip a                   # noter l'IP de la machine cible
```

Depuis la machine hôte : `ssh root@<IP-CIBLE>`

---

## 3. Partitionnement et formatage

### Option A — Utiliser disko (recommandé si disko.nix est disponible)

La machine `main` dispose d'un `hosts/main/disko.nix` qui déclare le layout disque complet :

- Partition EFI 512 MiB
- Partition btrfs couvrant le reste, avec subvolumes :
  - `@` → `/`
  - `@home` → `/home`
  - `@nix` → `/nix`
  - `@var-log` → `/var/log`

**Avant de lancer disko, vérifier le disque cible** :

```bash
lsblk
```

Ouvrir `hosts/main/disko.nix` et remplacer `/dev/CHANGEME` par le disque réel :

```nix
device = "/dev/nvme0n1";  # exemple
```

Lancer disko :

```bash
nix run github:nix-community/disko -- --mode disko hosts/main/disko.nix
```

disko partitionne, formate et monte automatiquement.

### Option B — Partitionnement manuel

Identifier le disque cible :

```bash
lsblk
```

Créer la table de partitions GPT :

```bash
gdisk /dev/nvme0n1
# Dans gdisk :
#   o        → nouvelle table GPT
#   n        → partition 1 : début=défaut, fin=+512M, type=EF00 (EFI)
#   n        → partition 2 : début=défaut, fin=défaut, type=8300 (Linux)
#   w        → écrire et quitter
```

Formater les partitions :

```bash
mkfs.vfat -F32 /dev/nvme0n1p1
mkfs.btrfs -f /dev/nvme0n1p2
```

Créer les subvolumes btrfs :

```bash
mount /dev/nvme0n1p2 /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@nix
btrfs subvolume create /mnt/@var-log
umount /mnt
```

---

## 4. Montage des partitions

```bash
DISK=/dev/nvme0n1

# Subvolume racine
mount -o subvol=@,compress=zstd,noatime "${DISK}p2" /mnt

# Créer les points de montage
mkdir -p /mnt/{boot,home,nix,var/log}

# EFI
mount "${DISK}p1" /mnt/boot

# Subvolumes
mount -o subvol=@home,compress=zstd,noatime    "${DISK}p2" /mnt/home
mount -o subvol=@nix,compress=zstd,noatime     "${DISK}p2" /mnt/nix
mount -o subvol=@var-log,compress=zstd,noatime "${DISK}p2" /mnt/var/log
```

Vérifier :

```bash
lsblk
df -h /mnt
```

---

## 5. Clone du repo workstation

```bash
nix-shell -p git
git clone https://github.com/mikl-974/workstation /root/workstation
cd /root/workstation
```

---

## 6. Préparation de la configuration

Avant l'installation, vérifier et compléter les valeurs critiques.

### 6a. Disque cible (si pas déjà fait via disko)

Dans `hosts/main/disko.nix` :

```nix
device = "/dev/nvme0n1";  # remplacer /dev/CHANGEME par le disque réel
```

### 6b. Username

Dans `flake.nix`, remplacer `CHANGEME_USERNAME` par le nom d'utilisateur réel :

```nix
home-manager.users.mikl = import ./home/default.nix;
```

### 6c. Définition de l'utilisateur dans le host

Dans `hosts/main/default.nix`, ajouter la définition de l'utilisateur si elle n'est pas encore présente :

```nix
users.users.mikl = {
  isNormalUser = true;
  extraGroups = [ "wheel" "docker" "networkmanager" "video" "audio" ];
  # Optionnel — clé SSH pour accès post-install :
  openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAA... ma-cle-publique"
  ];
};
```

### 6d. Valider la configuration

```bash
./scripts/validate-install.sh main
```

Ce script détecte les placeholders restants, les fichiers manquants, et les incohérences.

---

## 7. Installation NixOS

Depuis le répertoire du repo cloné :

```bash
nixos-install --flake /root/workstation#main --root /mnt
```

Si la configuration hardware est nécessaire, la générer d'abord :

```bash
nixos-generate-config --root /mnt
# Vérifier /mnt/etc/nixos/hardware-configuration.nix
# L'intégrer dans hosts/main/default.nix si des détecteurs matériels sont nécessaires
```

---

## 8. Reboot

```bash
umount -R /mnt
reboot
```

Retirer la clé USB avant le redémarrage.

---

## 9. Premier boot et activation de Home Manager

Au premier boot, NixOS est opérationnel. Home Manager est intégré dans le système via `home-manager.nixosModules.home-manager` — il s'applique automatiquement lors de `nixos-rebuild switch`.

Se connecter avec l'utilisateur défini, puis vérifier :

```bash
# Vérifier que le système est bien le bon
nixos-rebuild list-generations

# Rebuilder si nécessaire
sudo nixos-rebuild switch --flake /root/workstation#main

# Vérifier les symlinks Home Manager
ls -la ~/.config/hypr/
ls -la ~/.config/foot/
```

---

## 10. Dotfiles

Les dotfiles sont gérés par Home Manager via `home/default.nix`.

Pour activer un dotfile :

1. Placer le fichier dans `dotfiles/<app>/`
2. L'enregistrer dans `home/default.nix` :

   ```nix
   home.file.".config/hypr/hyprland.conf".source = ../dotfiles/hypr/hyprland.conf;
   ```

3. Rebuilder :

   ```bash
   sudo nixos-rebuild switch --flake .#main
   ```

Les symlinks sont créés dans `~/.config/` automatiquement.

---

## 11. Vérifications post-installation

Lancer le script de vérification post-install :

```bash
nix run .#post-install-check
```

Ou manuellement :

```bash
# Hyprland disponible
which Hyprland

# Services réseau
systemctl status tailscaled
systemctl status warp-svc

# Audio
systemctl status pipewire
systemctl --user status pipewire

# Dotfiles Home Manager
ls -la ~/.config/hypr/
ls -la ~/.config/foot/

# DevShell .NET
nix develop .#dotnet --command dotnet --version
```

---

## 12. Rebuilder après modification du repo

```bash
# Local
sudo nixos-rebuild switch --flake .#main

# Depuis n'importe où (avec le flake GitHub)
sudo nixos-rebuild switch --flake github:mikl-974/workstation#main

# À distance
nixos-rebuild switch --flake github:mikl-974/workstation#main \
  --target-host mikl@<IP-MACHINE> --use-remote-sudo
```

---

## Récapitulatif des commandes clés

| Étape | Commande |
|---|---|
| Clé USB | `dd if=nixos-minimal.iso of=/dev/sdX bs=4M status=progress` |
| Connexion Wi-Fi | `wpa_supplicant -B -i wlan0 -c <(wpa_passphrase SSID PASS)` |
| SSH live | `systemctl start sshd && passwd root` |
| Disques | `lsblk` |
| Partitionnement disko | `nix run github:nix-community/disko -- --mode disko hosts/main/disko.nix` |
| Clone repo | `git clone https://github.com/mikl-974/workstation` |
| Validation pré-install | `./scripts/validate-install.sh main` |
| Installation | `nixos-install --flake /root/workstation#main --root /mnt` |
| Rebuild | `sudo nixos-rebuild switch --flake .#main` |
| Post-install check | `nix run .#post-install-check` |
