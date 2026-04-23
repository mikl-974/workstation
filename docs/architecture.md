# Architecture du repo `infra`

## Principe

Le repo Git s'appelle encore `workstation`, mais son rôle cible est `infra`.
Il porte maintenant ensemble :
- machines NixOS
- machines Darwin
- users
- rôles Home Manager
- dotfiles
- stacks
- secrets

## Frontières

| Couche | Rôle | Exemple |
|---|---|---|
| `modules/` | briques réutilisables | profiles, security, darwin |
| `targets/hosts/` | réalité machine | `main`, `ms-s1-max`, `macmini` |
| `home/users/` | identité d’un user | `mikl.nix`, `mfo.nix`, `dfo.nix`, `zfo.nix`, `lfo.nix` |
| `home/roles/` | binding réutilisable par usage | `desktop-hyprland.nix`, `terminal-kitty.nix` |
| `home/targets/` | composition finale par machine | `main.nix`, `ms-s1-max.nix` |
| `dotfiles/` | contenu brut réutilisable | Hyprland, Kitty, GTK |
| `stacks/` | services/applications | `ai-server/` |
| `secrets/` | source chiffrée | `secrets/hosts/ms-s1-max.yaml` |

## NixOS vs Darwin

Le repo distingue maintenant explicitement :
- `nixosConfigurations.*` pour les targets NixOS
- `darwinConfigurations.*` pour les targets Darwin

Un target Darwin reste un target concret dans `targets/hosts/`.
Il ne devient pas un faux host NixOS.

## NixOS moderne actuel

Trois targets NixOS réels valident maintenant le modèle moderne :
- `main` en mono-user explicite
- `laptop` en mono-user explicite
- `ms-s1-max` en multi-user explicite

### `main`
- host concret : `targets/hosts/main/`
- composition Home Manager : `home/targets/main.nix`
- identité user : `home/users/mikl.nix`
- rôle réutilisable : `home/roles/desktop-hyprland.nix`

### `laptop`
- host concret : `targets/hosts/laptop/`
- composition Home Manager : `home/targets/laptop.nix`
- identité user : `home/users/mikl.nix`
- rôle réutilisable : `home/roles/desktop-hyprland.nix`

`main` et `laptop` ne dépendent plus du fallback `home/users/default.nix`.

## Users normalisés

Le repo expose maintenant des identités explicites dans `home/users/` :
- `mfo` = Mickaël Folio
- `dfo` = Delphine Folio
- `zfo` = Zoé Folio
- `lfo` = Léna Folio

Définir un user dans `home/users/` ne l'active pas automatiquement.
L'affectation réelle reste déclarée dans `home/targets/<host>.nix`.

## Darwin actuel

Le premier target Darwin modélisé est `macmini`.

### Base réutilisable
- `modules/darwin/base.nix` : base commune Darwin (`allowUnfree`, flakes, revision, stateVersion, hostPlatform)
- `modules/darwin/homebrew.nix` : activation Homebrew / nix-homebrew commune

### Spécifique machine
- `targets/hosts/macmini/config/user.nix` : user principal Darwin
- `targets/hosts/macmini/config/apps.nix` : paquets Nix + casks Homebrew
- `targets/hosts/macmini/config/networking.nix` : apps MAS réseau/VPN

### Principe d'installation
- Nix quand le package est proprement disponible sur Darwin
- Homebrew quand le bon adapter macOS est Homebrew
- MAS quand l'App Store est le canal pragmatique

## Secrets

Le premier flux réel branché utilise `sops-nix` pour `ms-s1-max` :
- le YAML chiffré vit dans `secrets/hosts/ms-s1-max.yaml`
- le host l'active via `infra.security.sops.defaultSopsFile`
- les hashes de mot de passe sont injectés vers `hashedPasswordFile`
- les bootstrap passwords sont matérialisés en root-only sous `/run/secrets/ms-s1-max/bootstrap/`

## Legacy

`home/users/default.nix` reste un fallback de compatibilité pour les anciens hosts NixOS.
Il ne couvre plus que `gaming`.
Ce n'est plus le chemin de `main`, ni de `laptop`, ni de `ms-s1-max`, et cela ne joue aucun rôle dans le target Darwin `macmini`.
