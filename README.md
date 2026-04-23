# infra (repo Git: `workstation`)

Ce repo est traité comme un monorepo `infra` :
une seule base pour les briques Nix réutilisables, les machines concrètes,
la composition utilisateur, les dotfiles, les services et les secrets.

## Structure retenue

- `modules/` : briques composables réutilisables
- `targets/hosts/` : machines réelles
- `home/` : composition Home Manager (`users/`, `roles/`, `targets/`)
- `dotfiles/` : bibliothèque de configs applicatives réutilisables
- `stacks/` : services/applications portés par ce repo
- `secrets/` : secrets chiffrés avec `sops-nix`
- `docs/` : documentation
- `scripts/` : orchestration légère / validation

## Flux `sops-nix` réellement branché

Le repo ne se limite plus à "avoir `sops-nix` dans le flake".

Premier flux réel branché :
- fichier chiffré : `secrets/hosts/ms-s1-max.yaml`
- mécanisme : `modules/security/sops.nix`
- host consommateur : `targets/hosts/ms-s1-max/default.nix`
- consommation réelle :
  - `users.users.mfo.hashedPasswordFile`
  - `users.users.dfo.hashedPasswordFile`
- secrets runtime root-only aussi exposés pour le bootstrap :
  - `/run/secrets/ms-s1-max/bootstrap/mfo-password`
  - `/run/secrets/ms-s1-max/bootstrap/dfo-password`

Voir `docs/secrets.md`.

## Dotfiles réellement branchés

### `mfo`
`mfo` consomme réellement :
- Hyprland
- profil Hyprland user (`chromium`)
- foot
- wofi
- mako

### `dfo`
`dfo` consomme réellement :
- Kitty
- profil Kitty user
- réglages GTK communs Noctalia pour GNOME
- préférences GNOME utilisateur
- Firefox avec réglages Home Manager minimaux

Voir `docs/user-composition.md`.

## Cas concret : `ms-s1-max`

### Système machine
`targets/hosts/ms-s1-max/` déclare :
- Hyprland + GNOME
- gaming (Steam/Lutris côté système)
- Tailscale
- Cloudflare WARP
- stack `ai-server`
- `sops-nix`

### Composition utilisateur
`home/targets/ms-s1-max.nix` compose :
- `mfo` → Hyprland, Steam, Chromium
- `dfo` → GNOME, Lutris, Steam, Firefox, Kitty

### Limite explicite
NordVPN reste documenté seulement tant que `nixpkgs` ne fournit pas de package/module officiel exploitable sur la base `nixos-unstable` retenue.

## Legacy réduit, pas cassé brutalement

`home/users/default.nix` existe encore comme **fallback de compatibilité transitoire** pour les targets pas encore migrés vers `home/targets/`.

Le chemin recommandé est désormais :
- `home/users/<user>.nix`
- `home/roles/*.nix`
- `home/targets/<host>.nix`

Les scripts de validation ne supposent plus uniquement `home/users/default.nix` lorsqu'un target Home Manager dédié existe.

## Nix unstable

Les packages suivent `nixos-unstable` via l’input `nixpkgs` du `flake.nix`.
