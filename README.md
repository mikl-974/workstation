# infra (repo Git: `workstation`)

Ce repo est traité comme un monorepo `infra` :
une seule base pour les briques Nix réutilisables, les machines concrètes,
la composition utilisateur, les dotfiles, les services et les secrets.

## Structure retenue

- `modules/` : briques composables réutilisables
- `targets/hosts/` : machines réelles, NixOS ou Darwin
- `home/` : composition Home Manager (`users/`, `roles/`, `targets/`)
- `dotfiles/` : bibliothèque de configs applicatives réutilisables
- `stacks/` : services/applications portés par ce repo
- `secrets/` : secrets chiffrés avec `sops-nix`
- `docs/` : documentation
- `scripts/` : orchestration légère / validation

Le cas "machine virtuelle" est maintenant modélisé comme un profil réutilisable :
- `modules/profiles/virtual-machine.nix`
- un host concret peut l'importer s'il tourne dans une VM
- ce n'est pas un host abstrait supplémentaire dans `targets/hosts/`

## Targets concrets actuellement modélisés

### NixOS
- `main`
- `laptop`
- `gaming`
- `ms-s1-max`

### Darwin
- `macmini`

`macmini` reste le nom retenu à ce stade :
- c'est déjà l'entrée fonctionnelle connue pour `darwin-rebuild --flake .#macmini`
- aucun signal plus durable n'existe encore dans le repo pour justifier un renommage propre
- le refactor avance donc sans régression inutile

## Darwin : structure désormais retenue

Le target Darwin est maintenant explicite dans le repo :
- `targets/hosts/macmini/vars.nix`
- `targets/hosts/macmini/default.nix`
- `targets/hosts/macmini/config/default.nix`
- `targets/hosts/macmini/config/user.nix`
- `targets/hosts/macmini/config/apps.nix`
- `targets/hosts/macmini/config/networking.nix`

Briques Darwin réutilisables :
- `modules/darwin/base.nix`
- `modules/darwin/homebrew.nix`

Le `flake.nix` expose maintenant :
- `nixosConfigurations.*`
- `darwinConfigurations.macmini`

## Migration moderne des targets NixOS

`main` est maintenant branché explicitement sur le modèle moderne Home Manager :
- `targets/hosts/main/default.nix`
- `targets/hosts/main/config/default.nix`
- `targets/hosts/main/config/user.nix`
- `targets/hosts/main/disko.nix`
- `home/users/mikl.nix`
- `home/targets/main.nix`

Composition retenue pour cette passe :
- target concret NixOS : `targets/hosts/main/`
- identité user : `home/users/mikl.nix`
- rôle réutilisable : `home/roles/desktop-hyprland.nix`
- dotfiles bruts actifs : Hyprland / foot / wofi / mako via `dotfiles/`
- installation distante : `targets/hosts/main/disko.nix` branché, disque réel encore à renseigner dans `vars.nix`

`laptop` rejoint maintenant le même modèle :
- `targets/hosts/laptop/default.nix`
- `targets/hosts/laptop/config/default.nix`
- `targets/hosts/laptop/config/user.nix`
- `home/users/mikl.nix`
- `home/targets/laptop.nix`

Composition retenue pour cette passe :
- target concret NixOS : `targets/hosts/laptop/`
- identité user : `home/users/mikl.nix`
- rôle réutilisable : `home/roles/desktop-hyprland.nix`
- dotfiles bruts actifs : Hyprland / foot / wofi / mako via `dotfiles/`
- installation distante : `targets/hosts/laptop/disko.nix` branché, disque réel à renseigner dans `vars.nix`

`gaming` rejoint maintenant le même modèle :
- `targets/hosts/gaming/default.nix`
- `targets/hosts/gaming/config/default.nix`
- `targets/hosts/gaming/config/user.nix`
- `home/users/mikl.nix`
- `home/targets/gaming.nix`

Composition retenue pour cette passe :
- target concret NixOS : `targets/hosts/gaming/`
- identité user : `home/users/mikl.nix`
- rôles réutilisables : `home/roles/desktop-hyprland.nix`, `home/roles/gaming-steam.nix`
- dotfiles bruts actifs : Hyprland / foot / wofi / mako via `dotfiles/`
- installation distante : `targets/hosts/gaming/disko.nix` branché, disque réel à renseigner dans `vars.nix`

Tous les targets NixOS du repo utilisent maintenant un `home/targets/<host>.nix` explicite.
Le fallback `home/users/default.nix` a été retiré.

Parcours NixOS Anywhere réellement prêts en V1 :
- structure et scripts : `main`, `laptop`, `gaming`
- prérequis opératoire restant : renseigner le vrai `disk` sur la machine cible avant installation
- hors périmètre Anywhere actuel : `ms-s1-max` (pas de `disko.nix`)

## VM : règle de modélisation

- un target VM reste un host concret dans `targets/hosts/`
- le fait "tourne dans une VM" se déclare via `modules/profiles/virtual-machine.nix`
- le profil VM ne choisit ni `disk`, ni `disko.nix`, ni l'hyperviseur
- les scripts montrent maintenant explicitement `bare-metal` vs `virtual-machine`
- à ce stade, aucun host versionné n'importe encore ce profil : l'usage est documenté sans faire semblant qu'un target VM concret existe déjà

## Users normalisés disponibles

Le repo contient maintenant une base explicite d'identités utilisateur dans `home/users/` :
- `mfo` = Mickaël Folio
- `dfo` = Delphine Folio
- `zfo` = Zoé Folio
- `lfo` = Léna Folio

Ces identités sont disponibles pour la suite mais ne sont pas automatiquement
affectées à une machine. L'affectation réelle reste faite dans
`home/targets/<host>.nix`.

## Rôle de Nix / Homebrew / MAS sur Darwin

Pour `macmini` :
- Nix = paquets disponibles proprement via nixpkgs (`vim`, `neovim`, `alacritty`, `vscode`, JetBrains Mono)
- Homebrew casks = apps GUI macOS adaptées à Homebrew (`moonlight`, `omniwm`)
- MAS = apps mieux consommées via l'App Store (`NordVPN`, `Tailscale`)

`nix-darwin` reste la base de composition système Darwin.
`nix-homebrew` reste l'adapter d'intégration Homebrew.

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
