# Base Hyprland

## Localisation

La base desktop Hyprland est organisee ainsi :

- profil : `profiles/desktop-hyprland.nix`
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

Tailscale est active via `profiles/networking.nix` (module `foundation`), pas depuis le profil desktop.

## Ce qui n'est volontairement pas inclus

- logique utilisateur cachee
- Tailscale (il vient de `foundation` via `profiles/networking.nix`)

## Noctalia

Noctalia est active dans `profiles/desktop-hyprland.nix` via :

```nix
workstation.theming.noctalia.enable = true;
```

Le module systeme (`modules/theming/noctalia.nix`) installe les packages GTK/curseur et definit les variables d'environnement.
La personnalisation visuelle (couleurs, CSS, wallpapers) vit dans `dotfiles/noctalia/`.

Voir `docs/theming.md` pour les details.

## Cloudflare WARP

WARP est gere dans `modules/desktop/warp.nix` et active via `profiles/desktop-hyprland.nix`.

Il reste dans `workstation` parce que c'est un client VPN desktop (interface utilisateur), pas une primitive reseau serveur. Le module `foundation.networking.cloudflared` (tunnel daemon) est une brique differente et distincte.

## Connectivite locale et utilitaires

La base desktop integre aussi :

- `modules/apps/daily.nix` pour les applications de base du quotidien
- `modules/desktop/connectivity.nix` pour la pile Wi-Fi/Bluetooth locale et les applets
- `modules/apps/utilities.nix` pour les petits outils quotidiens

Solaar est gere dans `modules/desktop/connectivity.nix` via le module NixOS Logitech, car il a besoin des regles udev adequates.
Les applications quotidiennes restent dans `modules/apps/daily.nix`.
Les petits outils techniques desktop restent dans `modules/apps/utilities.nix`.

## Etendre proprement

- ajouter la logique desktop commune dans `modules/desktop/`
- garder les applications quotidiennes dans `modules/apps/daily.nix`
- garder les choix machine-specifiques dans `hosts/`
- deplacer la personnalisation utilisateur dans `dotfiles/` + `home/`
- garder Tailscale dans `profiles/networking.nix`
- garder la connectivite locale desktop (Wi-Fi/Bluetooth/Solaar) dans `modules/desktop/`
