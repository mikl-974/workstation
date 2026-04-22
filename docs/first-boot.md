# First boot / UX Hyprland

## Objectif

Cette passe rend la session utilisateur directement exploitable au premier login.

Le but n'est pas de ricer le desktop, mais de fournir une base simple, explicite et utile :

- notifications actives
- historique clipboard actif
- launcher branche
- terminal branche
- dotfiles reellement utilises

## Ce qui est integre

### `mako`

`mako` est :

- installe via `modules/apps/daily.nix`
- configure dans `dotfiles/mako/config`
- demarre explicitement dans `dotfiles/hypr/hyprland.conf`

Autostart :

```conf
exec-once = mako
```

### `cliphist`

`cliphist` est :

- installe via `modules/apps/daily.nix`
- alimente via Hyprland avec `wl-paste --watch`
- expose a l'utilisateur via `wofi`

Autostart :

```conf
exec-once = wl-paste --type text --watch cliphist store
exec-once = wl-paste --type image --watch cliphist store
```

Binding principal :

```conf
bind = $mod, V, exec, sh -c "cliphist list | wofi --dmenu --prompt 'Clipboard' | cliphist decode | wl-copy"
```

## Dotfiles actifs

Les dotfiles effectivement branches par Home Manager sont :

- `dotfiles/hypr/hyprland.conf`
- `dotfiles/foot/foot.ini`
- `dotfiles/wofi/config`
- `dotfiles/wofi/style.css`
- `dotfiles/mako/config`

Ils sont lies depuis :

- `home/default.nix`

## Parcours premier login

Des la premiere session Hyprland :

- `mako` demarre
- `cliphist` commence a stocker le presse-papiers
- `SUPER+Return` ouvre `foot`
- `SUPER+Space` ouvre `wofi`
- `SUPER+B` ouvre Firefox
- `SUPER+E` ouvre Thunar
- `SUPER+V` ouvre l'historique clipboard

## Frontieres

Regle stricte :

- `modules/` -> installation et activation systeme
- `home/default.nix` -> fichiers utilisateur actifs
- `dotfiles/` -> contenu applicatif brut

Concretement :

- ne pas mettre les bindings Hyprland dans un module Nix
- ne pas mettre le contenu d'un fichier `config` dans `home/default.nix`
- ne pas utiliser `dotfiles/` pour de la logique systeme

## Verification

Apres rebuild :

```bash
nix run .#post-install-check
```

Verifications manuelles utiles :

```bash
ls -la ~/.config/hypr/
ls -la ~/.config/wofi/
ls -la ~/.config/foot/
ls -la ~/.config/mako/

which Hyprland
which foot
which wofi
which mako
which cliphist
```

## Etendre proprement

Si la couche UX doit evoluer :

1. installer les nouvelles apps dans le bon module
2. ajouter leur config brute dans `dotfiles/<app>/`
3. lier explicitement le fichier dans `home/default.nix`
4. documenter l'integration

Ne pas :

- disperser l'autostart dans plusieurs endroits
- ajouter des scripts auxiliaires sans vrai besoin
- transformer `hyprland.conf` en fourre-tout de personnalisation non essentielle
