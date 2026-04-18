# Installation via NixOS Anywhere

Ce document décrit comment installer la machine `main` (ou toute autre machine NixOS de ce repo) via [NixOS Anywhere](https://github.com/nix-community/nixos-anywhere).

NixOS Anywhere permet de provisionner une machine NixOS à distance (ou en live ISO) en une seule commande, en utilisant la configuration déclarée dans ce flake.

Parcours alternatif (sans NixOS Anywhere) : `docs/manual-install.md`
Checklist opératoire : `docs/install-checklist.md`

## Prérequis

Sur la machine hôte (depuis laquelle tu lances l'installation) :

- Nix avec flakes activé
- Accès SSH à la machine cible (live ISO ou machine existante)

Sur la machine cible :

- Boot depuis un live ISO NixOS (ou système existant avec SSH actif)
- SSH accessible depuis la machine hôte

## Préparer la configuration

Avant l'installation, les valeurs suivantes doivent être définies. Utiliser le validateur pour tout vérifier d'un coup :

```bash
nix run .#validate-install -- main
```

### 1. Définir le disque cible

Ouvrir `hosts/main/disko.nix` et remplacer `/dev/CHANGEME` par le disque réel de la machine cible :

```nix
device = "/dev/nvme0n1";  # exemple pour un NVMe
```

Vérifier le disque cible sur la machine : `lsblk`

### 2. Définir l'utilisateur

Dans `flake.nix`, remplacer `CHANGEME_USERNAME` par le nom d'utilisateur réel :

```nix
home-manager.users.mikl = import ./home/default.nix;
```

Ajouter la définition de l'utilisateur dans `hosts/main/default.nix` si elle n'existe pas encore :

```nix
users.users.mikl = {
  isNormalUser = true;
  extraGroups = [ "wheel" "docker" "networkmanager" "video" "audio" ];
};
```

### 3. Ajouter une clé SSH autorisée (recommandé)

Dans `hosts/main/default.nix` ou un profil :

```nix
users.users.mikl.openssh.authorizedKeys.keys = [
  "ssh-ed25519 AAAA... cle-publique"
];
```

## Lancer l'installation

### Avec le script d'orchestration (recommandé)

```bash
nix run .#install-anywhere -- main <IP-MACHINE-CIBLE>
```

Ce script valide la configuration, vérifie la connectivité SSH, demande confirmation, puis lance NixOS Anywhere.

### Directement

```bash
nix run nixpkgs#nixos-anywhere -- \
  --flake .#main \
  root@<IP-MACHINE-CIBLE>
```

NixOS Anywhere va :
1. Partitionner et formater les disques selon `disko.nix`
2. Monter les partitions
3. Générer la configuration hardware
4. Installer NixOS
5. Redémarrer la machine

## Après l'installation

Après le premier boot :

```bash
# Vérifier l'installation
nix run .#post-install-check

# Rebuilder si nécessaire
sudo nixos-rebuild switch --flake github:mikl-974/workstation#main
```

Home Manager est intégré dans le système NixOS via `home-manager.nixosModules.home-manager`.
Il s'applique automatiquement lors de `nixos-rebuild switch` — les dotfiles sont symlinqués dans `~/.config/`.

Voir `docs/bootstrap.md` pour le workflow complet post-installation.

## Reconstruire la machine

```bash
sudo nixos-rebuild switch --flake .#main
# ou depuis n'importe où avec le flake GitHub :
sudo nixos-rebuild switch --flake github:mikl-974/workstation#main
```

## Structure des fichiers pertinents

```
flake.nix               inputs disko + home-manager, nixosConfigurations.main, apps
hosts/main/default.nix  configuration du host (boot, hostname, profils)
hosts/main/disko.nix    layout disque (GPT + EFI + btrfs avec subvolumes)
profiles/               profils assemblés par le host
modules/                modules Nix
home/default.nix        configuration Home Manager (dotfiles, programmes)
dotfiles/               fichiers de configuration bruts
scripts/                validate-install, install-anywhere, post-install-check
```
