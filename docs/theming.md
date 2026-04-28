# Noctalia Shell

## Position retenue

Noctalia est un **desktop shell**, pas un simple theme.

Dans ce repo, l'integration correcte est :

| Couche | Localisation | Role |
|---|---|---|
| Activation workstation | `systems/profiles/desktop-hyprland.nix` | active l'integration Noctalia sur les postes Hyprland |
| Integration systeme | `systems/theming/noctalia.nix` | dependances visuelles globales et variables de session |
| Role Home Manager | `home/roles/noctalia.nix` | import du module Home Manager upstream + activation du shell |
| Config Noctalia par user | `home/users/<user>.nix` + `dotfiles/noctalia/<user>/settings.json` | fichier JSON versionne par user et reference par Home Manager |
| Overrides plugins par user | `dotfiles/noctalia/<user>/plugins*` | activation des plugins et correctifs locaux versionnes |
| Lancement de la session | `dotfiles/hyprland/hyprland.conf` | `exec-once = uwsm app -- noctalia-shell` |

Cette separation suit la documentation officielle :

- module Home Manager officiel pour la config utilisateur
- lancement depuis la session Wayland
- pas d'usage du service systemd Noctalia, upstream le marque comme deprecie

Documentation upstream :

- https://docs.noctalia.dev/
- https://docs.noctalia.dev/getting-started/nixos/

## Ce que fait le repo aujourd'hui

### `systems/theming/noctalia.nix`

Ce module ne porte **pas** la configuration du shell.

Il garde uniquement :

- `adwaita-icon-theme`
- `gnome-themes-extra`
- `bibata-cursors`
- `GTK_THEME=Adwaita:dark`

### `home/roles/noctalia.nix`

Ce fichier ne porte plus les reglages du shell. Il :

1. importe `inputs.noctalia.homeModules.default`
2. active `programs.noctalia-shell.enable = true`

### `home/users/mfo.nix` + `dotfiles/noctalia/mfo/settings.json`

La configuration Noctalia effective est maintenant :

1. stockee comme JSON versionne dans `dotfiles/noctalia/mfo/settings.json`
2. referencee par `home/users/mfo.nix`
3. rendue dans `~/.config/noctalia/settings.json` par Home Manager

### Plugins Noctalia par user

Les plugins actives pour `mfo` sont aussi rattaches a Home Manager :

1. `dotfiles/noctalia/mfo/plugins.json` garde l'etat des plugins Noctalia
2. `dotfiles/noctalia/mfo/plugins/...` contient les overrides locaux versionnes
3. `home/users/mfo.nix` les rend dans `~/.config/noctalia/plugins/...`

Cela permet de conserver dans le repo les petits correctifs locaux (par exemple
les icones de plugins) sans remettre en cause l'architecture officielle de
Noctalia.

### `dotfiles/hyprland/hyprland.conf`

Hyprland lance Noctalia explicitement :

```conf
exec-once = uwsm app -- noctalia-shell
```

Cela reste volontaire : upstream fournit un module NixOS `services.noctalia-shell`,
mais son execution comme service systemd utilisateur est deprecie.

Dans ce repo, on utilise le wrapper `noctalia-shell` fourni par le package Nix,
car il embarque deja le runtime Quickshell et le `QS_CONFIG_PATH`. Le binaire
`qs` n'est pas expose dans le PATH du systeme courant.

Le login Hyprland passe aussi par `uwsm start hyprland.desktop` via `greetd`,
ce qui correspond au demarrage recommande par Hyprland/NixOS pour une session
Wayland correctement geree par systemd.

## Modifier la configuration Noctalia

Editer :

```bash
dotfiles/noctalia/mfo/settings.json
```

Zone a modifier :

```json
{
  "settingsVersion": 0,
  "..."
}
```

Le raccord Home Manager reste dans :

```bash
home/users/mfo.nix
```

Les changements de barre, widgets, densite, couleurs, localisation et options de
shell doivent etre faits dans le JSON per-user, pas dans `systems/theming/noctalia.nix`.

## Mettre a jour Noctalia

### Mettre a jour la version du package/module upstream

Depuis le repo :

```bash
nix flake lock --update-input noctalia
```

Puis :

```bash
nix --extra-experimental-features 'nix-command flakes' flake check
PATH=/run/wrappers/bin:$PATH nix --extra-experimental-features 'nix-command flakes' --accept-flake-config run .#reconfigure -- ms-s1-max
```

### Mettre a jour la configuration apres un changement upstream

1. lire la doc upstream et le schema courant
2. verifier si `settingsVersion` doit changer
3. adapter `dotfiles/noctalia/mfo/settings.json`
4. rebuild le host
5. verifier en session que `noctalia-shell` demarre toujours correctement

## Ce qui ne doit pas etre fait

- ne pas deplacer la config Noctalia principale dans des dotfiles arbitraires
- ne pas activer `services.noctalia-shell` sauf besoin tres specifique et assume
- ne pas traiter Noctalia comme un simple theme GTK : c'est bien le shell desktop
