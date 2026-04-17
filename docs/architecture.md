# Architecture du repo `workstation`

## Philosophie

`workstation` est dédié aux environnements utilisateur (desktop, dotfiles, devShells), avec une architecture modulaire et multi-machines.

Ce repo est volontairement séparé de `homelab` :

- `workstation` = machines utilisateur
- `homelab` = serveurs et infrastructure

Il consomme `foundation` comme socle partagé sans en dépendre structurellement.

## Relation avec `foundation`

`foundation` fournit des briques génériques réutilisables (modules NixOS, devShells, conventions).

Règle stricte :
- `foundation` ne connaît pas `workstation`
- `workstation` importe `foundation` via input flake

Briques actuellement consommées depuis `foundation` :

- `foundation.nixosModules.networkingTailscale` — module Tailscale

Briques restant dans `workstation` :

- devShell `.NET` : environnement de dev personnel (Docker, IDE) — pas une brique générique
- Hyprland et la base desktop : spécifique machines utilisateur
- Cloudflare WARP : client VPN desktop, pas une primitive infra
- theming, dotfiles, profils desktop, configuration utilisateur

## Modèle de composition

1. `hosts/` décrit une machine réelle
2. chaque host importe un ou plusieurs `profiles/`
3. les profils assemblent des `modules/` ciblés et des briques `foundation`
4. les dotfiles restent découplés dans `dotfiles/`
5. les environnements de dev sont définis localement dans `devshells/` (spécifiques au poste de travail)

## Évolution multi-machines

La structure est prête pour `main`, `laptop`, `gaming` sans changer le layout :

- ajouter un host = nouveau dossier dans `hosts/<name>/`
- factoriser ce qui est commun en `profiles/`
- isoler la logique technique réutilisable dans `modules/`

## Quand une brique doit rester dans `workstation`

Une brique reste dans `workstation` si elle est :

- liée au bureau/utilisateur (Hyprland, theming, WARP)
- trop spécifique au poste de travail pour être partagée utilement
- pas encore testée dans d'autres contextes

Une brique passe dans `foundation` si elle est :

- générique (networking, sécurité de base, users)
- utilisable sur des serveurs comme sur des postes
- stable et clairement délimitée

## Extension propre

- ajouter des modules petits et ciblés dans `modules/`
- factoriser les comportements communs en `profiles/`
- consommer `foundation` via l'input flake, pas via copie locale
- documenter chaque nouvelle brique fonctionnelle dans `docs/`
