# Base Hyprland

## Localisation

La base desktop Hyprland est organisee ainsi :

- profil : `profiles/desktop-hyprland.nix`
- modules :
  - `modules/desktop/default.nix`
  - `modules/desktop/hyprland.nix`
  - `modules/desktop/audio.nix`
  - `modules/desktop/portals.nix`
  - `modules/desktop/fonts.nix`
  - `modules/desktop/warp.nix`
- theming : `modules/theming/noctalia.nix`

## Composition actuelle

La base inclut :

- Hyprland + XWayland
- login manager simple (`greetd` + `tuigreet`)
- PipeWire
- xdg portal Hyprland
- polkit
- NetworkManager
- Cloudflare WARP
- Noctalia (theme systeme)
- terminal (`foot`)
- launcher (`wofi`)
- outils Wayland minimaux (`waybar`, `wl-clipboard`, `grim`, `slurp`)

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

## Etendre proprement

- ajouter la logique desktop commune dans `modules/desktop/`
- garder les choix machine-specifiques dans `hosts/`
- deplacer la personnalisation utilisateur dans `dotfiles/` + `home/`
- ne pas ajouter de logique reseau ici — utiliser `profiles/networking.nix`
