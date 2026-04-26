# Composition utilisateur

## Modele

- `home/users/` : identite utilisateur
- `home/roles/` : composition reutilisable
- `home/targets/` : binding final par host

## Etat actuel

### `ms-s1-max`

- user compose : `mfo`
- identite : `home/users/mfo.nix`
- roles : `home/roles/desktop-hyprland.nix`, `home/roles/noctalia.nix`
- binding final : `home/targets/ms-s1-max.nix`

Overrides locaux :

- `~/.config/hypr/profile.conf`
- variable `BROWSER=chromium`

### `contabo`

- `home/targets/contabo.nix` est vide
- c'est intentionnel
- l'operateur `admin` est gere au niveau systeme, pas via Home Manager
