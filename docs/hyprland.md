# Base Hyprland

## Localisation

La base desktop Hyprland est organisee ainsi :

- profil : `modules/profiles/desktop-hyprland.nix`
- modules :
  - `modules/desktop/default.nix`
  - `modules/desktop/hyprland.nix`
  - `modules/desktop/audio.nix`
  - `modules/desktop/connectivity.nix`
  - `modules/desktop/portals.nix`
  - `modules/desktop/fonts.nix`
  - `modules/desktop/warp.nix`
  - `modules/apps/daily.nix`
  - `modules/apps/utilities.nix`
  - la composition Home Manager active (`home/targets/<host>.nix`)
  - `dotfiles/hyprland/hyprland.conf`
  - `dotfiles/launchers/`
  - `dotfiles/terminal/`
  - `dotfiles/notifications/`
- theming : `modules/theming/noctalia.nix`

## Composition actuelle

La base inclut :

- Hyprland + XWayland
- login manager simple (`greetd` + `tuigreet`)
- PipeWire
- xdg portal Hyprland
- polkit
- NetworkManager
- nm-applet
- Bluetooth + Blueman
- Solaar (via `hardware.logitech.wireless.*`)
- Cloudflare WARP
- Noctalia (theme systeme)
- terminal (`foot`)
- launcher (`wofi`)
- applications quotidiennes (`firefox`, `zathura`, `imv`, `thunar`, `file-roller`, `cliphist`, `mako`)
- outils Wayland minimaux (`waybar`, `wl-clipboard`, `grim`, `slurp`)
- utilitaires desktop (`pavucontrol`, `brightnessctl`, `playerctl`, `nm-connection-editor`)
- dotfiles actifs pour Hyprland / foot / wofi / mako
- autostart explicite de `mako`
- historique clipboard actif via `cliphist` + `wl-paste --watch`
- bindings de base pour terminal, launcher, navigateur, fichiers et clipboard history

Tailscale est active via `modules/profiles/networking.nix` (module local `infra/modules/networking/tailscale.nix`), pas depuis le profil desktop.

## Ce qui n'est volontairement pas inclus

- logique utilisateur cachee
- Tailscale (il vient de `modules/networking/tailscale.nix` via `modules/profiles/networking.nix`)

## Noctalia

Noctalia est active dans `modules/profiles/desktop-hyprland.nix` via :

```nix
workstation.theming.noctalia.enable = true;
```

Le module systeme (`modules/theming/noctalia.nix`) installe les packages GTK/curseur et definit les variables d'environnement.
La personnalisation visuelle (couleurs, CSS, wallpapers) vit dans `dotfiles/themes/noctalia/`.

Voir `docs/theming.md` pour les details.

## Cloudflare WARP

WARP est gere dans `modules/desktop/warp.nix` et active via `modules/profiles/desktop-hyprland.nix`.

Il reste dans `workstation` parce que c'est un client VPN desktop (interface utilisateur), pas une primitive reseau serveur. Un eventuel module `cloudflared` (tunnel daemon) serait une brique differente et distincte, a placer dans `modules/networking/` cote serveur.

## Connectivite locale et utilitaires

La base desktop integre aussi :

- `modules/apps/daily.nix` pour les applications de base du quotidien
- `modules/desktop/connectivity.nix` pour la pile Wi-Fi/Bluetooth locale et les applets
- `modules/apps/utilities.nix` pour les petits outils quotidiens

Solaar est gere dans `modules/desktop/connectivity.nix` via le module NixOS Logitech, car il a besoin des regles udev adequates.
Les applications quotidiennes restent dans `modules/apps/daily.nix`.
Les petits outils techniques desktop restent dans `modules/apps/utilities.nix`.

## UX du premier login

La session Hyprland integre maintenant une base UX explicite et minimale :

- `mako` demarre via `exec-once`
- `cliphist` est alimente via deux watchers `wl-paste`
- `SUPER+Return` ouvre `foot`
- `SUPER+Space` ouvre `wofi`
- `SUPER+B` ouvre Firefox
- `SUPER+E` ouvre Thunar
- `SUPER+V` ouvre l'historique clipboard via `cliphist` + `wofi`

Cette couche reste volontairement simple :

- pas de logique cachee dans les modules Nix
- pas de script auxiliaire local
- pas de configuration eparpillee entre plusieurs couches sans regle claire

## Frontiere Hyprland / Home Manager / dotfiles

Repartition retenue :

| Couche | Rôle |
|---|---|
| `modules/desktop/hyprland.nix` | active Hyprland et les paquets Wayland de base |
| `modules/apps/daily.nix` | installe `mako` et `cliphist` comme apps desktop |
| la composition Home Manager active (`home/targets/<host>.nix`) | lie les fichiers utilisateur actifs |
| `dotfiles/hyprland/hyprland.conf` | autostart et bindings Hyprland |
| `dotfiles/launchers/` | comportement et style du launcher |
| `dotfiles/terminal/` | configuration du terminal |
| `dotfiles/notifications/` | configuration du daemon de notifications |

Ainsi :

- la logique systeme reste dans les modules
- la selection des fichiers actifs reste dans Home Manager
- le contenu applicatif brut reste dans `dotfiles/`

## Etendre proprement

- ajouter la logique desktop commune dans `modules/desktop/`
- garder les applications quotidiennes dans `modules/apps/daily.nix`
- garder l'autostart et les bindings utilisateur dans `dotfiles/hyprland/hyprland.conf`
- garder les fichiers applicatifs bruts dans `dotfiles/`
- garder les choix machine-specifiques dans `targets/`
- deplacer la personnalisation utilisateur dans `dotfiles/` + `home/`
- garder Tailscale dans `modules/profiles/networking.nix`
- garder la connectivite locale desktop (Wi-Fi/Bluetooth/Solaar) dans `modules/desktop/`
