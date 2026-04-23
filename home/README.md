# home/

Composition Home Manager des users, rôles et targets.

## Structure

| Dossier | Rôle |
|---|---|
| `home/users/` | identité utilisateur + overrides user utiles |
| `home/roles/` | binding réutilisable par rôle/app/domaine |
| `home/targets/` | composition finale d'un host |

## Users normalisés disponibles

### Famille Folio
- `home/users/mfo.nix` → Mickaël Folio
- `home/users/dfo.nix` → Delphine Folio
- `home/users/zfo.nix` → Zoé Folio
- `home/users/lfo.nix` → Léna Folio

Ces fichiers définissent seulement l'identité utilisateur.
Ils ne rendent pas un user actif sur une machine.

L'affectation réelle se fait uniquement dans `home/targets/<host>.nix`.

## Modèle concret

### `main`
- identité : `home/users/mikl.nix`
- rôle : `desktop-hyprland`
- composition finale : `home/targets/main.nix`
- dotfiles réellement actifs :
  - `dotfiles/hyprland/hyprland.conf`
  - `dotfiles/hyprland/profiles/default.conf`
  - `dotfiles/terminal/foot.ini`
  - `dotfiles/launchers/config`
  - `dotfiles/launchers/style.css`
  - `dotfiles/notifications/config`

### `laptop`
- identité : `home/users/mikl.nix`
- rôles sur ce target : `desktop-hyprland`
- composition finale : `home/targets/laptop.nix`
- dotfiles réellement actifs :
  - `dotfiles/hyprland/hyprland.conf`
  - `dotfiles/hyprland/profiles/default.conf`
  - `dotfiles/terminal/foot.ini`
  - `dotfiles/launchers/config`
  - `dotfiles/launchers/style.css`
  - `dotfiles/notifications/config`

### `gaming`
- identité : `home/users/mikl.nix`
- rôles sur ce target : `desktop-hyprland`, `gaming-steam`
- composition finale : `home/targets/gaming.nix`
- dotfiles réellement actifs :
  - `dotfiles/hyprland/hyprland.conf`
  - `dotfiles/hyprland/profiles/default.conf`
  - `dotfiles/terminal/foot.ini`
  - `dotfiles/launchers/config`
  - `dotfiles/launchers/style.css`
  - `dotfiles/notifications/config`

### `mfo`
- identité : `home/users/mfo.nix`
- actuellement assigné via : `home/targets/ms-s1-max.nix`
- rôles sur ce target : `desktop-hyprland`, `gaming-steam`, `browser-chromium`
- override target-specific réel : `~/.config/hypr/profile.conf`

### `dfo`
- identité : `home/users/dfo.nix`
- actuellement assigné via : `home/targets/ms-s1-max.nix`
- rôles sur ce target : `desktop-gnome`, `gaming-lutris`, `gaming-steam`, `browser-firefox`, `terminal-kitty`
- overrides target-specific réels : `~/.config/kitty/profile.conf` + préférences GNOME utilisateur

### `zfo`
- identité : `home/users/zfo.nix`
- aucun target assigné pour le moment

### `lfo`
- identité : `home/users/lfo.nix`
- aucun target assigné pour le moment

## Legacy

Il n'y a plus de fallback `home/users/default.nix`.
Le chemin retenu est maintenant uniquement :

- `home/users/<user>.nix`
- `home/roles/*.nix`
- `home/targets/<host>.nix`
