# Architecture du repo `workstation`

## Philosophie

`workstation` est dedie aux environnements utilisateur (desktop, dotfiles, devShells), avec une architecture modulaire et multi-machines.

Ce repo est volontairement separe de `homelab` :

- `workstation` = machines utilisateur
- `homelab` = serveurs et infrastructure

Il consomme `foundation` comme socle partage sans en dependre structurellement.

## Relation avec `foundation`

`foundation` fournit des briques generiques reutilisables (modules NixOS, conventions).

Regle stricte :
- `foundation` ne connait pas `workstation`
- `workstation` importe `foundation` via input flake

Briques actuellement consommees depuis `foundation` :

- `foundation.nixosModules.networkingTailscale` — module Tailscale

Briques conservees dans `workstation` :

- devShell `.NET` : environnement de dev personnel (Docker, IDE, playwright) — pas une brique generique
- Hyprland et la base desktop : specifique machines utilisateur
- Cloudflare WARP : client VPN desktop, pas une primitive infra
- Noctalia : theme et identite visuelle du poste
- theming, dotfiles, profils desktop, configuration utilisateur

## Modele de composition

1. `hosts/` decrit une machine reelle
2. chaque host importe un ou plusieurs `profiles/`
3. les profils assemblent des `modules/` cibles et des briques `foundation`
4. les dotfiles restent decouples dans `dotfiles/`
5. les environnements de dev sont definis localement dans `devshells/` (specifiques au poste de travail)
6. la configuration utilisateur est geree par Home Manager (`home/default.nix`)

## Inputs flake

| Input | Role |
|---|---|
| `nixpkgs` | Packages NixOS |
| `foundation` | Modules NixOS partages (Tailscale) |
| `disko` | Partitionnement declaratif — requis pour NixOS Anywhere |
| `home-manager` | Gestion de la configuration utilisateur et des dotfiles |

## Structure des fichiers

```
flake.nix             point d'entree, inputs, nixosConfigurations, devShells
hosts/                machines concretes
  main/
    default.nix       configuration host (profils, hostname, boot)
    disko.nix         layout disque (GPT + EFI + btrfs)
  laptop/
  gaming/
profiles/             assemblages de modules reutilisables
  desktop-hyprland.nix
  dev.nix
  networking.nix
  gaming.nix
modules/              logique Nix isolee par domaine
  desktop/            Hyprland, audio, portals, fonts, WARP
  theming/            Noctalia et theming systeme
  apps/               applications desktop generiques
  shell/              configuration shell systeme
devshells/            environnements de dev locaux
  dotnet.nix          shell .NET workstation
home/                 configuration Home Manager (utilisateur)
  default.nix         dotfiles, xdg, paquets utilisateur
dotfiles/             configurations applicatives brutes
  hypr/               Hyprland
  foot/               terminal
  wofi/               launcher
  shell/              shell
  noctalia/           theme Noctalia (palette, assets)
  editors/            editeurs (VS Code, Rider)
docs/                 documentation
```

## Evolution multi-machines

La structure est prete pour `main`, `laptop`, `gaming` sans changer le layout :

- ajouter un host = nouveau dossier dans `hosts/<name>/`
- factoriser ce qui est commun en `profiles/`
- isoler la logique technique reutilisable dans `modules/`

## Quand une brique doit rester dans `workstation`

Une brique reste dans `workstation` si elle est :

- liee au bureau/utilisateur (Hyprland, theming, WARP)
- trop specifique au poste de travail pour etre partagee utilement
- pas encore testee dans d'autres contextes

Une brique passe dans `foundation` si elle est :

- generique (networking, securite de base, users)
- utilisable sur des serveurs comme sur des postes
- stable et clairement delimitee

## Extension propre

- ajouter des modules petits et cibles dans `modules/`
- factoriser les comportements communs en `profiles/`
- consommer `foundation` via l'input flake, pas via copie locale
- documenter chaque nouvelle brique fonctionnelle dans `docs/`
