# home/

Composition Home Manager des users, rôles et targets.

## Structure

| Dossier | Rôle |
|---|---|
| `home/users/` | identité utilisateur + overrides user utiles |
| `home/roles/` | binding réutilisable par rôle/app/domaine |
| `home/targets/` | composition finale d'un host |

## Modèle concret

### `mfo`
- identité : `home/users/mfo.nix`
- rôles : `desktop-hyprland`, `gaming-steam`, `browser-chromium`
- override réel : `~/.config/hypr/profile.conf`

### `dfo`
- identité : `home/users/dfo.nix`
- rôles : `desktop-gnome`, `gaming-lutris`, `gaming-steam`, `browser-firefox`, `terminal-kitty`
- overrides réels : `~/.config/kitty/profile.conf` + préférences GNOME utilisateur

## Legacy

`home/users/default.nix` reste un fallback transitoire pour les anciens hosts.
Ce n'est plus le chemin recommandé.

Le chemin recommandé est :
- `home/users/<user>.nix`
- `home/roles/*.nix`
- `home/targets/<host>.nix`
