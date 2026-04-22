# Profils

## Rôle des profils

Un profil assemble des briques reutilisables pour un usage donne.

Le profil :

- n'est pas un host
- n'est pas un module technique bas niveau
- n'est pas un dotfile

Il sert de point d'entree lisible pour les hosts.

## Regle de composition

Ordre logique :

1. `modules/apps/` -> paquets
2. `modules/roles/` -> composition d'un usage (gaming, ai)
3. `profiles/` -> point d'entree simple pour les hosts
4. `hosts/` -> machine concrete

## Profils existants

| Profil | Rôle |
|---|---|
| `profiles/desktop-hyprland.nix` | base desktop commune |
| `profiles/dev.nix` | environnement dev utilisateur |
| `profiles/gaming.nix` | role gaming |
| `profiles/ai.nix` | role AI local |
| `profiles/networking.nix` | briques reseau partagees via `foundation` |

## Profil `desktop-hyprland`

Ce profil assemble la base workstation desktop :

- `modules/desktop/default.nix`
- `modules/apps/default.nix`
- `modules/shell/default.nix`
- `modules/theming/default.nix`

Effets notables :

- Hyprland
- audio desktop
- daily apps (`modules/apps/daily.nix`)
- connectivite locale (`modules/desktop/connectivity.nix`)
- utilitaires desktop (`modules/apps/utilities.nix`)
- WARP
- Noctalia

## Pourquoi pas un profil `utilities`

Les utilities demandees ici sont de la base desktop quotidienne.

Creer un profil `utilities` separe ajouterait une couche artificielle sans gain :

- tous les hosts desktop en ont besoin
- elles ne representent pas un usage specialise comme `gaming` ou `ai`
- elles sont deja composees proprement dans la base desktop

Le bon niveau est donc :

- apps quotidiennes -> `modules/apps/daily.nix`
- paquets -> `modules/apps/utilities.nix`
- systeme desktop -> `modules/desktop/connectivity.nix`
- activation -> `profiles/desktop-hyprland.nix`
