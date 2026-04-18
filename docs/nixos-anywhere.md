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

Les variables spécifiques à la machine sont centralisées dans `hosts/<name>/vars.nix`.
**C'est le seul fichier à éditer avant d'installer.**

### 1. Initialiser la config machine

```bash
nix run .#init-host -- main
```

Ce script interactif crée `hosts/main/vars.nix` avec :
- username (identifiant Unix de l'utilisateur)
- hostname (doit correspondre à la clé dans flake.nix)
- disk (device cible — lancer `lsblk` sur la machine pour l'identifier)
- timezone
- locale

Ou éditer directement `hosts/main/vars.nix` :

```nix
{
  username = "mikl";
  hostname = "main";
  disk     = "/dev/nvme0n1";  # identifier avec lsblk sur la machine cible
  timezone = "Europe/Paris";
  locale   = "fr_FR.UTF-8";
}
```

### 2. Vérifier la configuration

```bash
nix run .#validate-install -- main
```

Ce script vérifie que `vars.nix` est complet, que les fichiers critiques existent, et qu'aucun placeholder n'est resté dans les fichiers structurants.

### 3. Afficher un résumé de la config effective

```bash
nix run .#show-config -- main
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
1. Partitionner et formater les disques selon `disko.nix` (en lisant le disque depuis `vars.nix`)
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
hosts/main/vars.nix     variables machine (username, disk, timezone…) — seul fichier à éditer
flake.nix               inputs disko + home-manager, nixosConfigurations.main, apps
hosts/main/default.nix  configuration du host (boot, hostname, profils, utilisateur)
hosts/main/disko.nix    layout disque (GPT + EFI + btrfs) — lit le disque depuis vars.nix
profiles/               profils assemblés par le host
modules/                modules Nix
home/default.nix        configuration Home Manager (dotfiles, programmes)
dotfiles/               fichiers de configuration bruts
scripts/                init-host, show-config, validate-install, install-anywhere, post-install-check
templates/host-vars.nix template de vars.nix pour un nouveau host
```
