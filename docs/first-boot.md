# First boot / first login

## Objectif

Cette doc couvre le passage critique entre :

- installation terminée
- premier boot
- premier login
- machine réellement prête

Le but n'est pas de ricer le desktop, mais de confirmer que la machine est exploitable :

- pour un desktop : session et dotfiles cohérents
- pour un host de service : runtime et services critiques cohérents

## Workflow recommandé après installation

Ordre officiel :

1. se connecter avec l'utilisateur défini dans `targets/hosts/<host>/vars.nix`
2. si nécessaire : `sudo nixos-rebuild switch --flake .#<host>`
3. lancer : `nix run .#post-install-check -- --host <host>`
4. relire les warnings éventuels
5. vérifier la session ou le runtime réellement utile au host

## Ce qu'il faut vérifier au premier boot

- le hostname attendu est bien appliqué
- l'utilisateur attendu existe
- `nixos-rebuild` fonctionne
- le repo est bien présent localement si tu comptes rebuilder depuis la machine
- Home Manager a bien posé les dotfiles actifs
- les services réellement portés par le host démarrent

Commande de base :

```bash
nix run .#post-install-check -- --host <host>
```

## Cas service : `openclaw-vm`

Pour `openclaw-vm`, le premier boot crédible ne passe pas par un desktop.
Il faut vérifier :

- `openclaw-gateway.service` actif
- `/etc/openclaw/openclaw.json` présent
- `/etc/openclaw/public.env` présent
- `/var/lib/openclaw/secrets/gateway-token.env` présent
- `/var/log/openclaw/gateway.log` présent ou en cours de création
- le bind reste `tailnet`

Commandes utiles :

```bash
sudo systemctl status openclaw-gateway
sudo journalctl -u openclaw-gateway -n 50 --no-pager
sudo ls -la /etc/openclaw
sudo ls -la /var/lib/openclaw
sudo ls -la /var/lib/openclaw/secrets
sudo ls -la /var/log/openclaw
sudo grep '"bind"' /etc/openclaw/openclaw.json
```

Signal attendu pour cette première passe :
- le gateway démarre
- il n’est pas exposé publiquement par défaut
- l’auth gateway existe réellement
- les intégrations Telegram/provider restent absentes tant que leurs secrets ne sont pas fournis

## Cas desktop

### `mako`

`mako` est :

- installe via `modules/apps/daily.nix`
- configure dans `dotfiles/notifications/config`
- demarre explicitement dans `dotfiles/hyprland/hyprland.conf`

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

- `dotfiles/hyprland/hyprland.conf`
- `dotfiles/terminal/foot.ini`
- `dotfiles/launchers/config`
- `dotfiles/launchers/style.css`
- `dotfiles/notifications/config`

Ils sont lies depuis :

- la composition Home Manager active (`home/targets/<host>.nix`)

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
- la composition Home Manager active (`home/targets/<host>.nix`) -> fichiers utilisateur actifs
- `dotfiles/` -> contenu applicatif brut

Concretement :

- ne pas mettre les bindings Hyprland dans un module Nix
- ne pas mettre le contenu d'un fichier `config` dans la composition Home Manager active (`home/targets/<host>.nix`)
- ne pas utiliser `dotfiles/` pour de la logique systeme

## Verification et remediation

Apres rebuild :

```bash
nix run .#post-install-check -- --host <host>
```

Si un point critique manque :

- relancer `sudo nixos-rebuild switch --flake .#<host>`
- relancer `nix run .#post-install-check -- --host <host>`
- vérifier la composition Home Manager active (`home/targets/<host>.nix`) et les dotfiles réellement référencés
- vérifier que le host importe bien les profils attendus

## Etendre proprement

Si la couche UX doit evoluer :

1. installer les nouvelles apps dans le bon module
2. ajouter leur config brute dans `dotfiles/<app>/`
3. lier explicitement le fichier dans la composition Home Manager active (`home/targets/<host>.nix`)
4. documenter l'integration

Ne pas :

- disperser l'autostart dans plusieurs endroits
- ajouter des scripts auxiliaires sans vrai besoin
- transformer `hyprland.conf` en fourre-tout de personnalisation non essentielle
