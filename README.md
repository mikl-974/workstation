# workstation

Repository dedie aux machines utilisateur personnelles (NixOS desktop, Hyprland, dotfiles, devShells), separe du scope `homelab`.

## Dependance partagee : `foundation`

Ce repo consomme [`mikl-974/foundation`](https://github.com/mikl-974/foundation) comme socle partage.

Briques consommees depuis `foundation` :

| Brique | Source | Raison |
|---|---|---|
| Tailscale | `foundation.nixosModules.networkingTailscale` | reseau generique, partage entre machines |

Briques conservees dans `workstation` :

| Brique | Raison |
|---|---|
| devShell `.NET` | environnement CLI de dev personnel (SDK, Docker, playwright) — pas une brique generique |
| Noctalia | theme et identite visuelle du poste — strictement personnel |
| Hyprland + base desktop | specifique machines utilisateur |
| Cloudflare WARP | client VPN desktop, pas une primitive infra generique |
| Editeurs / IDE | VS Code, Rider, WebStorm — applications desktop dev |
| theming / dotfiles | strictement desktop / utilisateur |

## Separation desktop / dev / shell

| Couche | Ce qu'elle contient | Localisation |
|---|---|---|
| Base desktop | Hyprland, terminal, audio, Noctalia, WARP | `profiles/desktop-hyprland.nix` |
| Dev utilisateur | VS Code, Rider, WebStorm, CLI outils systeme | `profiles/dev.nix` |
| Shell `.NET` | SDK .NET, Docker CLI, playwright | `devshells/dotnet.nix` |

Les IDEs sont des applications desktop. Ils sont installes en tant que paquets systeme
via `profiles/dev.nix` → `modules/apps/editors.nix`.
Le shell `.NET` fournit les runtimes et outils CLI avec lesquels ces editeurs travaillent.

## Structure

- `hosts/` : definition des machines concretes (`main`, `laptop`, `gaming`)
- `profiles/` : assemblages reutilisables (`desktop-hyprland`, `dev`, `gaming`, `networking`)
- `modules/` : modules Nix cibles par domaine (`desktop/`, `theming/`, `apps/`, `shell/`)
- `devshells/` : environnements de developpement CLI locaux (specifiques au poste)
- `home/` : configuration Home Manager utilisateur (dotfiles, programmes)
- `dotfiles/` : configurations applicatives brutes (`hypr/`, `foot/`, `wofi/`, `noctalia/`, `editors/`)
- `docs/` : documentation d'architecture et d'usage
- `scripts/` : orchestration, validation, vérification (ne redefinissent pas la configuration)
- `flake.nix` : point d'entree unique

## Separation des responsabilites

- **host** : identite machine + combinaison de profils
- **profile** : composition de briques fonctionnelles
- **module** : logique Nix isolee et reutilisable
- **home** : configuration utilisateur (Home Manager)
- **dotfiles** : configuration applicative brute (configs INI, CSS, conf)
- **devShell** : outillage CLI/runtime dev local, specifique au poste de travail

## Theming : Noctalia

Noctalia est le schema de couleurs et l'identite visuelle de cette workstation.

Le module systeme est dans `modules/theming/noctalia.nix`.
Les assets visuels (palette, CSS, wallpapers) vivent dans `dotfiles/noctalia/`.

Voir `docs/theming.md`.

## DevShell .NET

Entrer dans le shell :

```bash
nix develop .#dotnet
```

Contenu : `dotnet-sdk`, `git`, `curl`, `jq`, `openssl`, `pkg-config`, `docker-client`, `playwright`.

Les IDEs (VS Code, Rider, WebStorm) sont installes comme paquets systeme, pas dans le shell.

Voir `docs/devshells.md`.

## Installation via NixOS Anywhere

La machine `main` est prête à être installée via NixOS Anywhere :

```bash
# Avec le script d'orchestration (recommandé)
nix run .#install-anywhere -- main <IP-CIBLE>

# Ou directement
nix run nixpkgs#nixos-anywhere -- --flake .#main root@<IP-CIBLE>
```

Voir `docs/nixos-anywhere.md` et `docs/bootstrap.md`.

## Installation manuelle

Pour installer depuis un live ISO NixOS sans NixOS Anywhere :

```bash
# Guide interactif
nix run .#install-manual -- --host main

# Ou suivre la procédure complète
# docs/manual-install.md
```

## Validation et vérification

Avant l'installation :

```bash
nix run .#validate-install -- main
```

Après l'installation :

```bash
nix run .#post-install-check
```

Checklist opératoire : `docs/install-checklist.md`

## Hosts

- `main` : base desktop + profil dev + reseau (Tailscale + WARP)
- `laptop` : base desktop + profil dev + reseau
- `gaming` : base desktop + profil gaming + reseau
