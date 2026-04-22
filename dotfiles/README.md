# dotfiles

`dotfiles/` centralise les configurations applicatives utilisateur de cette workstation.

Ces fichiers sont **bruts** — ce ne sont pas des modules Nix. Ils sont gérés et liés via Home Manager (`home/default.nix`).

## Structure

```
dotfiles/
  hypr/        Hyprland (hyprland.conf)
  foot/        Terminal foot (foot.ini)
  wofi/        Launcher wofi (config, style.css)
  mako/        Notifications mako (config)
  shell/       Shell bash (.bashrc, aliases, env)
  noctalia/    Theme Noctalia (colors.conf, wallpapers, CSS GTK/waybar/foot)
  editors/     Editeurs (VS Code settings, Rider overrides)
```

## Regle : ou va chaque config ?

| Type de config | Ou ca va |
|---|---|
| Parametre systeme NixOS | `modules/` |
| Activation d'un service ou programme | `modules/` ou `profiles/` |
| Config utilisateur declarative (shell, git, etc.) | `home/default.nix` via home-manager |
| Fichier de config brut applicatif (INI, CSS, conf) | `dotfiles/<app>/` |
| Couleurs / theming Noctalia | `dotfiles/noctalia/` |
| Config brute d'un utilitaire desktop (si necessaire) | `dotfiles/<app>/` |

## Comment ranger un nouveau dotfile

1. Identifier l'application : creer `dotfiles/<app>/` si le dossier n'existe pas
2. Y placer le fichier de configuration brut
3. L'enregistrer dans `home/default.nix` via `home.file."<destination>".source`
4. Documenter l'ajout dans `dotfiles/<app>/README.md`

Exemple dans `home/default.nix` :

```nix
home.file.".config/foot/foot.ini".source = ../dotfiles/foot/foot.ini;
```

## Dotfiles actuellement actifs

Les dotfiles effectivement relies par Home Manager sont :

- `dotfiles/hypr/hyprland.conf`
- `dotfiles/foot/foot.ini`
- `dotfiles/wofi/config`
- `dotfiles/wofi/style.css`
- `dotfiles/mako/config`

Ils sont actives via `home/default.nix`.

## Ce qui ne va PAS dans `dotfiles/`

- Les modules NixOS -> `modules/`
- La logique de profil -> `profiles/`
- Les integrations systeme Bluetooth / Wi-Fi / Solaar -> `modules/desktop/`
- Les secrets -> jamais dans le repo
- Les fichiers generes automatiquement par des outils

## Integration

Les dotfiles sont appliques lors de l'activation Home Manager :

```bash
sudo nixos-rebuild switch --flake .#$(hostname)
```

Dans cette architecture, Home Manager est integre au systeme.
Voir `docs/bootstrap.md` et `docs/update-workflow.md` pour le workflow complet.
