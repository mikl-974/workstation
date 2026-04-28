# Base Hyprland

## Localisation

La base desktop Hyprland est organisee ainsi :

- profil : `systems/profiles/desktop-hyprland.nix`
- modules :
  - `systems/desktop/default.nix`
  - `systems/desktop/hyprland.nix`
  - `systems/desktop/audio.nix`
  - `systems/desktop/connectivity.nix`
  - `systems/desktop/portals.nix`
  - `systems/desktop/fonts.nix`
  - `systems/desktop/warp.nix`
  - `systems/bundles/daily.nix`
  - `systems/bundles/utilities.nix`
  - la composition Home Manager active (`home/targets/<host>.nix`)
  - `dotfiles/hyprland/hyprland.conf`
  - `dotfiles/launchers/`
  - `dotfiles/terminal/`
  - `dotfiles/notifications/`
- theming : `systems/theming/noctalia.nix`

## Composition actuelle

La base inclut :

- Hyprland + XWayland
- login manager simple (`greetd` + `tuigreet`)
- session manager Wayland (`uwsm`)
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
- autostart explicite de `noctalia-shell`
- autostart explicite de `mako`
- historique clipboard actif via `cliphist` + `wl-paste --watch`
- bindings de base pour terminal, launcher, navigateur, fichiers et clipboard history

Tailscale est active via `systems/profiles/networking.nix` (module local `infra/systems/networking/tailscale.nix`), pas depuis le profil desktop.

## Ce qui n'est volontairement pas inclus

- logique utilisateur cachee
- Tailscale (il vient de `systems/networking/tailscale.nix` via `systems/profiles/networking.nix`)

## Noctalia

Noctalia est active dans `systems/profiles/desktop-hyprland.nix` via :

```nix
workstation.theming.noctalia.enable = true;
```

Le module systeme (`systems/theming/noctalia.nix`) garde seulement les
dependances visuelles globales (GTK, curseur, variables de session).
La configuration officielle du shell lui-meme vit dans `home/roles/noctalia.nix`
via `inputs.noctalia.homeModules.default`.

Le shell est lance par Hyprland avec `exec-once = uwsm app -- noctalia-shell`.
Le paquet NixOS `noctalia-shell` embarque deja le wrapper Quickshell adequat et
reste donc la commande correcte sur ce poste, meme si la doc upstream montre
souvent `qs -c noctalia-shell` dans un contexte plus generique.

La session Hyprland elle-meme est demarree via `uwsm start hyprland.desktop`
depuis `greetd`, ce qui aligne le poste avec le chemin recommande par Hyprland
et evite les warnings Noctalia sur une session lancee avec une commande non
supportee. Le chemin systemd `services.noctalia-shell` existe upstream mais est
explicitement deprecie.

Voir `docs/theming.md` pour les details.

## Cloudflare WARP

WARP est gere dans `systems/desktop/warp.nix` et active via `systems/profiles/desktop-hyprland.nix`.

Il reste dans `workstation` parce que c'est un client VPN desktop (interface utilisateur), pas une primitive reseau serveur. Un eventuel module `cloudflared` (tunnel daemon) serait une brique differente et distincte, a placer dans `systems/networking/` cote serveur.

## Connectivite locale et utilitaires

La base desktop integre aussi :

- `systems/bundles/daily.nix` pour les applications de base du quotidien
- `systems/desktop/connectivity.nix` pour la pile Wi-Fi/Bluetooth locale et les applets
- `systems/bundles/utilities.nix` pour les petits outils quotidiens

Solaar est gere dans `systems/desktop/connectivity.nix` via le module NixOS Logitech, car il a besoin des regles udev adequates.
Les applications quotidiennes restent dans `systems/bundles/daily.nix`.
Les petits outils techniques desktop restent dans `systems/bundles/utilities.nix`.

## UX du premier login

La session Hyprland integre maintenant une base UX explicite et minimale :

- `mako` demarre via `exec-once`
- `noctalia-shell` demarre via `exec-once`
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
| `systems/desktop/hyprland.nix` | active Hyprland et les paquets Wayland de base |
| `systems/bundles/daily.nix` | installe `mako` et `cliphist` comme apps desktop |
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

- ajouter la logique desktop commune dans `systems/desktop/`
- garder les applications quotidiennes dans `systems/bundles/daily.nix`
- garder l'autostart et les bindings utilisateur dans `dotfiles/hyprland/hyprland.conf`
- garder les fichiers applicatifs bruts dans `dotfiles/`
- garder les choix machine-specifiques dans `targets/`
- deplacer la personnalisation utilisateur dans `dotfiles/` + `home/`
- garder Tailscale dans `systems/profiles/networking.nix`
- garder la connectivite locale desktop (Wi-Fi/Bluetooth/Solaar) dans `systems/desktop/`
