# Installation via NixOS Anywhere

Ce document décrit comment installer la machine `main` (ou toute autre machine NixOS de ce repo) via [NixOS Anywhere](https://github.com/nix-community/nixos-anywhere).

NixOS Anywhere permet de provisionner une machine NixOS à distance (ou en live ISO) en une seule commande, en utilisant la configuration déclarée dans ce flake.

Parcours alternatif (sans NixOS Anywhere) : `docs/manual-install.md`
Checklist opératoire : `docs/install-checklist.md`

## Prérequis

Sur la machine hôte (depuis laquelle tu lances l'installation) :

- Nix avec flakes activé
- Accès SSH à la machine cible (live ISO ou machine existante)
- `ssh-keyscan` et `ssh-keygen` disponibles pour vérifier explicitement la clé hôte

Sur la machine cible :

- Boot depuis un live ISO NixOS (ou système existant avec SSH actif)
- SSH accessible depuis la machine hôte

## Préparer la configuration

Les variables spécifiques à la machine sont centralisées dans `targets/hosts/<name>/vars.nix`.
**C'est le seul fichier à éditer avant d'installer.**

### 1. Initialiser la config machine

```bash
nix run .#init-host -- main
```

Ce script interactif crée `targets/hosts/main/vars.nix` avec :
- system (plateforme NixOS du host)
- username (identifiant Unix de l'utilisateur)
- hostname (doit correspondre à la clé dans flake.nix)
- disk (device cible — lancer `lsblk` sur la machine pour l'identifier)
- timezone
- locale

Ou éditer directement `targets/hosts/main/vars.nix` :

```nix
{
  system   = "x86_64-linux";
  username = "mikl";
  hostname = "main";
  disk     = "/dev/nvme0n1";  # identifier avec lsblk sur la machine cible
  timezone = "Europe/Paris";
  locale   = "fr_FR.UTF-8";
}
```

### 2. Vérifier la configuration

```bash
nix run .#doctor -- --host main
```

Ce diagnostic vérifie la disponibilité des outils locaux, la structure du repo et l'exposition des commandes flake.

### 3. Valider la configuration

```bash
nix run .#validate-install -- main
```

Ce script vérifie que `vars.nix` est complet (`system`, `username`, `hostname`, `disk` si disko est présent, `timezone`, `locale`), que les fichiers critiques existent, qu'aucun placeholder ne reste, que le host est bien exposé dans `flake.nix`, et que les dotfiles activés existent réellement.

### 4. Afficher un résumé de la config effective

```bash
nix run .#show-config -- main
```

## Lancer l'installation

### Avec le script d'orchestration (recommandé)

```bash
nix run .#install-anywhere -- main <IP-MACHINE-CIBLE>
```

Ce script :

1. lance `doctor`
2. lance `validate-install`
3. vérifie les prérequis locaux
4. récupère et affiche les empreintes SSH de la cible
5. demande une confirmation explicite
6. lance NixOS Anywhere

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
nix run .#post-install-check -- --host main

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
targets/hosts/main/vars.nix     variables machine (username, disk, timezone…) — seul fichier à éditer
flake.nix               inputs disko + home-manager, nixosConfigurations.main, apps
targets/hosts/main/default.nix  configuration du host (boot, hostname, profils, utilisateur)
targets/hosts/main/disko.nix    layout disque (GPT + EFI + btrfs) — lit le disque depuis vars.nix
modules/profiles/       profils assembles par les targets (desktop-hyprland, dev, networking, gaming, ai)
modules/                modules Nix
home/targets/<host>.nix       composition Home Manager recommandée par host
home/users/default.nix        fallback legacy temporaire pour les hosts non migrés
dotfiles/               fichiers de configuration bruts
scripts/                init-host, show-config, doctor, validate-install, install-anywhere, install-manual, post-install-check
templates/host-vars.nix template de vars.nix pour un nouveau host
```
