# Theming — Noctalia

## Architecture

Le theming de la workstation est structure en deux couches :

| Couche | Localisation | Role |
|---|---|---|
| Module systeme | `modules/theming/noctalia.nix` | packages GTK, env vars, activation |
| Assets visuels | `dotfiles/themes/noctalia/` | couleurs, wallpapers, CSS applicatifs |

Ces deux couches sont intentionnellement separees : le module Nix gere ce qui releve du systeme, les dotfiles gerent ce qui releve de la personnalisation visuelle brute.

## Activation

Noctalia est active dans `modules/profiles/desktop-hyprland.nix` :

```nix
workstation.theming.noctalia.enable = true;
```

Tous les hosts qui importent `desktop-hyprland.nix` heritent de Noctalia.
Si un host ne doit pas avoir le theme, il ne doit pas importer ce profil.

## Module systeme (`modules/theming/noctalia.nix`)

Ce module installe :
- `adwaita-icon-theme`
- `gnome-themes-extra`
- `bibata-cursors`

Et configure :
- `GTK_THEME=Adwaita:dark` (variable de session — peut etre surchargee par home-manager)

## Dotfiles visuels (`dotfiles/themes/noctalia/`)

La palette de couleurs et les assets visuels vivent dans `dotfiles/themes/noctalia/`.

Structure prevue :

```
dotfiles/themes/noctalia/
  colors.conf          palette de base (variables nommees)
  wallpaper/           fonds d'ecran
  gtk/                 surcharges CSS GTK
  waybar/              style.css waybar
  foot/                snippet couleurs foot (inclus dans foot.ini)
```

Les fichiers de ce dossier sont lies par Home Manager (la composition Home Manager active (`home/targets/<host>.nix`)).

## Etendre Noctalia

### Ajouter un package systeme

Dans `modules/theming/noctalia.nix`, section `environment.systemPackages`.

### Ajouter un fichier de theme applicatif

1. Placer le fichier dans `dotfiles/themes/noctalia/`
2. L'enregistrer dans la composition Home Manager active (`home/targets/<host>.nix`) via `home.file`

### Changer le theme GTK

Modifier `environment.sessionVariables.GTK_THEME` dans `noctalia.nix`,
ou surcharger via `home-manager.users.<user>.gtk.theme`.

## Ajouter un second theme

Creer `modules/theming/<nom>.nix` en suivant le meme pattern que `noctalia.nix`.
Exposer une option `workstation.theming.<nom>.enable`.
Ne pas activer deux themes en meme temps sans gerer les conflits de variables.
