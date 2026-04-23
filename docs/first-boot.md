# First boot / first login

## Objectif

Cette doc couvre le passage critique entre :

- installation terminée
- premier boot
- premier login
- machine réellement prête

Le but n'est pas de ricer le desktop, mais de confirmer que la workstation est exploitable :

- notifications actives
- historique clipboard actif
- launcher branche
- terminal branche
- dotfiles reellement utilises
- install / rebuild / Home Manager cohérents

## Workflow recommandé après installation

Ordre officiel :

1. se connecter avec l'utilisateur défini dans `targets/hosts/<host>/vars.nix`
2. si nécessaire : `sudo nixos-rebuild switch --flake .#<host>`
3. lancer : `nix run .#post-install-check -- --host <host>`
4. relire les warnings éventuels
5. vérifier la session Hyprland au premier login

## Ce qu'il faut vérifier au premier boot

- le hostname attendu est bien appliqué
- l'utilisateur attendu existe
- `nixos-rebuild` fonctionne
- le repo est bien présent localement si tu comptes rebuilder depuis la machine
- Home Manager a bien posé les dotfiles actifs

Commande de base :

```bash
nix run .#post-install-check -- --host main
```

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

- la composition Home Manager active (`home/targets/<host>.nix` ou, en compatibilité, `home/users/default.nix`)

## Parcours premier login

Des la premiere session Hyprland :

- `mako` demarre
- `cliphist` commence a stocker le presse-papiers
- `SUPER+Return` ouvre `foot`
- `SUPER+Space` ouvre `wofi`
- `SUPER+B` ouvre Firefox
- `SUPER+E` ouvre Thunar
- `SUPER+V` ouvre l'historique clipboard

Checks manuels utiles :

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
which firefox
which thunar
```

## Frontieres

Regle stricte :

- `modules/` -> installation et activation systeme
- la composition Home Manager active (`home/targets/<host>.nix` ou, en compatibilité, `home/users/default.nix`) -> fichiers utilisateur actifs
- `dotfiles/` -> contenu applicatif brut

Concretement :

- ne pas mettre les bindings Hyprland dans un module Nix
- ne pas mettre le contenu d'un fichier `config` dans la composition Home Manager active (`home/targets/<host>.nix` ou, en compatibilité, `home/users/default.nix`)
- ne pas utiliser `dotfiles/` pour de la logique systeme

## Verification et remediation

Apres rebuild :

```bash
nix run .#post-install-check -- --host main
```

Si un point critique manque :

- relancer `sudo nixos-rebuild switch --flake .#main`
- relancer `nix run .#post-install-check -- --host main`
- vérifier la composition Home Manager active (`home/targets/<host>.nix` ou, en compatibilité, `home/users/default.nix`) et les dotfiles réellement référencés
- vérifier que le host importe bien les profils attendus

## Etendre proprement

Si la couche UX doit evoluer :

1. installer les nouvelles apps dans le bon module
2. ajouter leur config brute dans `dotfiles/<app>/`
3. lier explicitement le fichier dans la composition Home Manager active (`home/targets/<host>.nix` ou, en compatibilité, `home/users/default.nix`)
4. documenter l'integration

Ne pas :

- disperser l'autostart dans plusieurs endroits
- ajouter des scripts auxiliaires sans vrai besoin
- transformer `hyprland.conf` en fourre-tout de personnalisation non essentielle
