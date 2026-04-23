# Installation via NixOS Anywhere

Ce document décrit comment installer un host NixOS de ce repo via [NixOS Anywhere](https://github.com/nix-community/nixos-anywhere).

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

## Bare metal vs VM

Dans ce repo :
- un target concret reste dans `targets/hosts/<name>/`
- une VM se modélise par import de `modules/profiles/virtual-machine.nix`
- NixOS Anywhere ne change pas de nature entre bare metal et VM

Ce que le profil VM change :
- il signale explicitement le contexte guest
- il peut porter de petits defaults système raisonnables pour une VM

Ce qu'il ne change pas :
- le vrai `disk` reste à renseigner dans `vars.nix`
- `disko.nix` reste attaché au host concret
- le firmware, le réseau et l'hyperviseur restent des choix du target concret

Cas concret désormais versionné :
- `openclaw-vm` = host NixOS concret, dédié à OpenClaw, qui importe `modules/profiles/virtual-machine.nix`
- `openclaw-vm` consomme `stacks/openclaw/default.nix`, qui lui-même importe le module upstream `nix-openclaw.nixosModules.openclaw-gateway`

## Préparer la configuration

Les variables spécifiques à la machine sont centralisées dans `targets/hosts/<name>/vars.nix`.
**C'est le seul fichier à éditer avant d'installer.**

### 1. Initialiser la config machine

```bash
nix run .#init-host -- <host>
```

Ce script interactif crée `targets/hosts/<host>/vars.nix` avec :
- system (plateforme NixOS du host)
- username (identifiant Unix de l'utilisateur)
- hostname (doit correspondre à la clé dans flake.nix)
- disk (device cible — lancer `lsblk` sur la machine pour l'identifier)
- timezone
- locale

Le contexte `bare-metal` vs `virtual-machine` ne se déclare pas dans `vars.nix`.
Il se déclare dans le host concret via l'import éventuel de `modules/profiles/virtual-machine.nix`.

Ou éditer directement `targets/hosts/<host>/vars.nix` :

```nix
{
  system   = "x86_64-linux";
  username = "mikl";
  hostname = "<host>";
  disk     = "/dev/nvme0n1";  # identifier avec lsblk sur la machine cible
  timezone = "Europe/Paris";
  locale   = "fr_FR.UTF-8";
}
```

### 2. Vérifier la configuration

```bash
nix run .#doctor -- --host <host>
```

Ce diagnostic vérifie la disponibilité des outils locaux, la structure du repo et l'exposition des commandes flake.

### 3. Valider la configuration

```bash
nix run .#validate-install -- <host>
```

Ce script vérifie que `vars.nix` est complet (`system`, `username`, `hostname`, `disk` si disko est présent, `timezone`, `locale`), que les fichiers critiques existent, qu'aucun placeholder ne reste, que le host est bien exposé dans `flake.nix`, et que les dotfiles activés existent réellement.
Il vérifie aussi qu'un host avec `disko.nix` branche bien `disko.nixosModules.disko` dans `flake.nix`.

### 4. Afficher un résumé de la config effective

```bash
nix run .#show-config -- <host>
```

## Lancer l'installation

### Avec le script d'orchestration (recommandé)

```bash
nix run .#install-anywhere -- <host> <IP-MACHINE-CIBLE>
```

Ce script :

1. lance `doctor`
2. lance `validate-install`
3. vérifie les prérequis locaux
4. récupère et affiche les empreintes SSH de la cible
5. demande une confirmation explicite
6. lance NixOS Anywhere

Les scripts `doctor`, `show-config`, `validate-install` et `install-anywhere`
affichent maintenant explicitement le contexte machine détecté :
- `bare-metal`
- ou `virtual-machine`

### Directement

```bash
nix run nixpkgs#nixos-anywhere -- \
  --flake .#<host> \
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
nix run .#post-install-check -- --host <host>

# Rebuilder si nécessaire
sudo nixos-rebuild switch --flake github:mikl-974/workstation#<host>
```

Home Manager est intégré dans le système NixOS via `home-manager.nixosModules.home-manager`.
Il s'applique automatiquement lors de `nixos-rebuild switch` — les dotfiles sont symlinqués dans `~/.config/`.

Pour un host mono-user explicite comme `main`, `laptop` ou `gaming`, la composition active passe désormais explicitement par :
- `home/targets/<host>.nix`
- `home/users/<user>.nix`
- `home/roles/*.nix`

Pour un host de service comme `openclaw-vm`, le repo garde un
`home/targets/openclaw-vm.nix` explicite mais volontairement vide :
- le modèle du flake reste homogène
- aucun faux périmètre Home Manager desktop n'est forcé sur la VM

Pour OpenClaw :
- le host reste responsable du fait "je porte OpenClaw"
- la stack locale reste responsable du câblage repo-local
- le runtime OpenClaw lui-même vient de `nix-openclaw`
- la première exposition retenue est `tailnet-only`
- le premier secret réellement consommé est le token d’auth gateway généré au premier start

Voir `docs/bootstrap.md` pour le workflow complet post-installation.

## Reconstruire la machine

```bash
sudo nixos-rebuild switch --flake .#<host>
# ou depuis n'importe où avec le flake GitHub :
sudo nixos-rebuild switch --flake github:mikl-974/workstation#<host>
```

## Structure des fichiers pertinents

```
targets/hosts/<host>/vars.nix     variables machine (username, disk, timezone…) — seul fichier à éditer
flake.nix               inputs disko + home-manager, nixosConfigurations.<host>, apps
targets/hosts/<host>/default.nix  entrée du host
targets/hosts/<host>/config/default.nix configuration du host (boot, hostname, profils) quand le host est structuré en config/
targets/hosts/<host>/config/user.nix    utilisateur système du host quand ce découpage existe
targets/hosts/<host>/disko.nix    layout disque (GPT + EFI + btrfs) — lit le disque depuis vars.nix quand le host est Anywhere-ready
modules/profiles/       profils assembles par les targets (desktop-hyprland, dev, networking, gaming, ai)
modules/                modules Nix
home/targets/<host>.nix composition Home Manager explicite par host
home/users/<user>.nix   identité utilisateur normalisée
dotfiles/               fichiers de configuration bruts
stacks/openclaw/        socle de la stack OpenClaw pour `openclaw-vm`
stacks/openclaw/env/public.env environnement public non secret pour la stack OpenClaw
scripts/                init-host, show-config, doctor, validate-install, install-anywhere, install-manual, post-install-check
templates/host-vars.nix template de vars.nix pour un nouveau host
```

## État réel du repo

Hosts NixOS structurellement prêts pour NixOS Anywhere :
- `main`
- `laptop`
- `gaming`
- `openclaw-vm`

Condition opératoire restante pour chacun :
- renseigner le vrai `disk` dans `targets/hosts/<host>/vars.nix` sur la machine cible concernée

Host NixOS non prêt pour NixOS Anywhere à ce stade :
- `ms-s1-max` (pas de `disko.nix`)

Exemple réel dans le repo :

```nix
{
  imports = [
    ../../../../modules/profiles/virtual-machine.nix
    ../../../../stacks/openclaw/default.nix
  ];
}
```
