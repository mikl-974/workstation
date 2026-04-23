# Composition utilisateur

## Règle

- `home/users/` = identité + overrides user utiles
- `home/roles/` = binding réutilisable commun
- `home/targets/` = assemblage final par machine
- `dotfiles/` = contenu brut, jamais la décision finale

## Cas `ms-s1-max`

### `mfo`
- rôles : Hyprland, Steam, Chromium
- identité : `home/users/mfo.nix`
- affectation : `home/targets/ms-s1-max.nix`
- dotfiles réellement actifs :
  - `dotfiles/hyprland/hyprland.conf`
  - `dotfiles/hyprland/profiles/mfo.conf`
  - `dotfiles/terminal/foot.ini`
  - `dotfiles/launchers/config`
  - `dotfiles/launchers/style.css`
  - `dotfiles/notifications/config`

### `dfo`
- rôles : GNOME, Lutris, Steam, Firefox, Kitty
- identité : `home/users/dfo.nix`
- affectation : `home/targets/ms-s1-max.nix`
- dotfiles réellement actifs :
  - `dotfiles/terminal/kitty.conf`
  - `dotfiles/terminal/profiles/dfo-kitty.conf`
  - `dotfiles/themes/noctalia/gtk/settings.ini`

## Users disponibles mais non assignés

- `home/users/zfo.nix`
- `home/users/lfo.nix`

Ils existent comme identités normalisées mais ne sont encore composés dans
aucun `home/targets/<host>.nix`.

## Hosts sans composition utilisateur

Deux hosts NixOS du repo n'ont aucune composition Home Manager :

- `home/targets/openclaw-vm.nix` = `{}` — VM de service portant `stacks/openclaw/`. Aucun desktop, aucun user composé.
- `home/targets/contabo.nix` = `{ }` — serveur VPS headless. L'opérateur (`admin`) est provisionné au niveau système par `modules/users/admin.nix`, sans Home Manager.

Ces bindings vides sont **intentionnels** : `mkHomeUsers` dans le `flake.nix` exige qu'un fichier existe pour tout host NixOS (plus de fallback implicite). Voir `home/targets/README.md`.

## Cas `main`

### `mikl`
- rôles : Hyprland
- identité : `home/users/mikl.nix`
- affectation : `home/targets/main.nix`
- dotfiles réellement actifs :
  - `dotfiles/hyprland/hyprland.conf`
  - `dotfiles/hyprland/profiles/default.conf`
  - `dotfiles/terminal/foot.ini`
  - `dotfiles/launchers/config`
  - `dotfiles/launchers/style.css`
  - `dotfiles/notifications/config`

## Cas `laptop`

### `mikl`
- rôles : Hyprland
- identité : `home/users/mikl.nix`
- affectation : `home/targets/laptop.nix`
- dotfiles réellement actifs :
  - `dotfiles/hyprland/hyprland.conf`
  - `dotfiles/hyprland/profiles/default.conf`
  - `dotfiles/terminal/foot.ini`
  - `dotfiles/launchers/config`
  - `dotfiles/launchers/style.css`
  - `dotfiles/notifications/config`

## Cas `gaming`

### `mikl`
- rôles : Hyprland, gaming-steam
- identité : `home/users/mikl.nix`
- affectation : `home/targets/gaming.nix`
- dotfiles réellement actifs :
  - `dotfiles/hyprland/hyprland.conf`
  - `dotfiles/hyprland/profiles/default.conf`
  - `dotfiles/terminal/foot.ini`
  - `dotfiles/launchers/config`
  - `dotfiles/launchers/style.css`
  - `dotfiles/notifications/config`

## Legacy

Le fallback `home/users/default.nix` a été retiré.
Tous les nouveaux bindings passent désormais par `home/targets/`.
