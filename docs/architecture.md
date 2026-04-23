# Architecture du repo `infra`

## Principe

Le repo Git s'appelle encore `workstation`, mais son rôle cible est `infra`.
Il porte maintenant ensemble :
- machines
- users
- rôles Home Manager
- dotfiles
- stacks
- secrets

## Frontières

| Couche | Rôle | Exemple |
|---|---|---|
| `modules/` | briques réutilisables | desktop, shell, profiles, security |
| `targets/hosts/` | réalité machine | `ms-s1-max` |
| `home/users/` | identité d’un user | `mfo.nix`, `dfo.nix` |
| `home/roles/` | binding réutilisable par usage | `desktop-hyprland.nix`, `terminal-kitty.nix` |
| `home/targets/` | composition finale par machine | `ms-s1-max.nix` |
| `dotfiles/` | contenu brut réutilisable | Hyprland, Kitty, GTK |
| `stacks/` | services/applications | `ai-server/` |
| `secrets/` | source chiffrée | `secrets/hosts/ms-s1-max.yaml` |

## Secrets

Le premier flux réel branché utilise `sops-nix` pour `ms-s1-max` :
- le YAML chiffré vit dans `secrets/hosts/ms-s1-max.yaml`
- le host l'active via `infra.security.sops.defaultSopsFile`
- les hashes de mot de passe sont injectés vers `hashedPasswordFile`
- les bootstrap passwords sont matérialisés en root-only sous `/run/secrets/ms-s1-max/bootstrap/`

## Dotfiles et composition user

### Base commune
- `home/roles/desktop-hyprland.nix` lie Hyprland, foot, wofi, mako et le profil Hyprland par défaut
- `home/roles/desktop-gnome.nix` lie les réglages GTK communs Noctalia
- `home/roles/terminal-kitty.nix` lie Kitty et un profil Kitty par défaut

### Overrides user
- `home/users/mfo.nix` remplace `~/.config/hypr/profile.conf` pour passer le navigateur à Chromium
- `home/users/dfo.nix` remplace `~/.config/kitty/profile.conf` et ajoute des préférences GNOME utilisateur

## Legacy

`home/users/default.nix` reste un fallback de compatibilité pour les anciens hosts.
Ce n'est plus le chemin recommandé ni le chemin principal pour `ms-s1-max`.
