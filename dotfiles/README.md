# dotfiles/

Bibliothèque réutilisable de configurations applicatives.

## Règle

`dotfiles/` contient uniquement du contenu brut applicatif.
Le binding se fait dans `home/`.

## Modèle concret actuel

### Binding moderne sur `main`, `laptop` et `gaming`
- `home/targets/main.nix` lie `home/users/mikl.nix` avec `home/roles/desktop-hyprland.nix`
- `home/targets/laptop.nix` lie `home/users/mikl.nix` avec `home/roles/desktop-hyprland.nix`
- `home/targets/gaming.nix` lie `home/users/mikl.nix` avec `home/roles/desktop-hyprland.nix` et `home/roles/gaming-steam.nix`
- les dotfiles actifs de `main`, `laptop` et `gaming` restent ceux de la base Hyprland commune
- aucun chemin legacy implicite n'est nécessaire pour ces targets

### Base commune par app/domaine
- `dotfiles/hyprland/hyprland.conf`
- `dotfiles/hyprland/profiles/default.conf`
- `dotfiles/terminal/kitty.conf`
- `dotfiles/terminal/profiles/default-kitty.conf`
- `dotfiles/themes/noctalia/gtk/settings.ini`

### Overrides user
- `dotfiles/hyprland/profiles/mfo.conf`
- `dotfiles/terminal/profiles/dfo-kitty.conf`

## Comment ajouter un nouveau dotfile

1. créer le contenu brut dans `dotfiles/`
2. le lier depuis un rôle si c'est commun
3. le surcharger depuis `home/users/<user>.nix` seulement si la différence est réellement spécifique à l'utilisateur
