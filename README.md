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
| devShell `.NET` | environnement de dev personnel (Docker, IDE, playwright) — pas une brique generique |
| Noctalia | theme et identite visuelle du poste — strictement personnel |
| Hyprland + base desktop | specifique machines utilisateur |
| Cloudflare WARP | client VPN desktop, pas une primitive infra generique |
| theming / dotfiles | strictement desktop / utilisateur |

## Structure

- `hosts/` : definition des machines concretes (`main`, `laptop`, `gaming`)
- `profiles/` : assemblages reutilisables (`desktop-hyprland`, `dev`, `gaming`, `networking`)
- `modules/` : modules Nix cibles par domaine (`desktop/`, `theming/`, `apps/`, `shell/`)
- `devshells/` : environnements de developpement locaux (specifiques au poste)
- `home/` : configuration Home Manager utilisateur (dotfiles, programmes)
- `dotfiles/` : configurations applicatives brutes (`hypr/`, `foot/`, `wofi/`, `noctalia/`, `editors/`)
- `docs/` : documentation d'architecture et d'usage
- `flake.nix` : point d'entree unique

## Separation des responsabilites

- **host** : identite machine + combinaison de profils
- **profile** : composition de briques fonctionnelles
- **module** : logique Nix isolee et reutilisable
- **home** : configuration utilisateur (Home Manager)
- **dotfiles** : configuration applicative brute (configs INI, CSS, conf)
- **devShell** : outillage dev local, specifique au poste de travail

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

Contenu : `dotnet-sdk`, `git`, `curl`, `jq`, `openssl`, `pkg-config`, `docker-client`, `playwright`, `vscode`.
Rider et WebStorm sont prepares (commentes) dans `devshells/dotnet.nix`.

Voir `docs/devshells.md`.

## Installation via NixOS Anywhere

La machine `main` est prete a etre installee via NixOS Anywhere :

```bash
nix run nixpkgs#nixos-anywhere -- --flake .#main root@<IP-CIBLE>
```

Voir `docs/nixos-anywhere.md` et `docs/bootstrap.md`.

## Hosts

- `main` : base desktop + profil dev + reseau (Tailscale + WARP)
- `laptop` : base desktop + profil dev + reseau
- `gaming` : base desktop + profil gaming + reseau
