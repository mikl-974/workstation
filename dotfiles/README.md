# dotfiles

`dotfiles/` centralise les configurations applicatives utilisateur de cette workstation.

Ces fichiers sont **bruts** — ce ne sont pas des modules Nix. Ils sont gérés et liés via Home Manager (`home/default.nix`).

## Structure

```
dotfiles/
  hypr/        Hyprland (hyprland.conf, keybinds, monitors, rules)
  foot/        Terminal foot (foot.ini)
  wofi/        Launcher wofi (config, style.css)
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

## Comment ranger un nouveau dotfile

1. Identifier l'application : creer `dotfiles/<app>/` si le dossier n'existe pas
2. Y placer le fichier de configuration brut
3. L'enregistrer dans `home/default.nix` via `home.file."<destination>".source`
4. Documenter l'ajout dans `dotfiles/<app>/README.md`

Exemple dans `home/default.nix` :

```nix
home.file.".config/foot/foot.ini".source = ../dotfiles/foot/foot.ini;
```

## Ce qui ne va PAS dans `dotfiles/`

- Les modules NixOS -> `modules/`
- La logique de profil -> `profiles/`
- Les secrets -> jamais dans le repo
- Les fichiers generes automatiquement par des outils

## Integration

Les dotfiles sont appliques lors de l'activation Home Manager :

```bash
home-manager switch --flake .#main
# ou via nixos-rebuild switch si home-manager est integre au systeme
```

Voir `docs/bootstrap.md` pour le workflow complet d'installation.
