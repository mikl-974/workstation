# infra

Ce repo est traité comme un monorepo `infra` :
une seule base pour les briques Nix réutilisables, les machines concrètes,
la composition utilisateur, les dotfiles, les services et les secrets.

## Structure retenue

- `modules/` : briques composables réutilisables
- `targets/hosts/` : machines réelles, NixOS ou Darwin
- `home/` : composition Home Manager (`users/`, `roles/`, `targets/`)
- `dotfiles/` : bibliothèque de configs applicatives réutilisables
- `stacks/` : services/applications portés par ce repo
- `deployments/` : modèle de placement strict `target → stack instances` (`topology`, `inventory`, `validation`, hive Colmena)
- `tofu/` : workspaces OpenTofu pour les targets cloud (`azure-ext`, `cloudflare-ext`, `gcp-ext`)
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
- `openclaw-vm`
- `ms-s1-max`
- `contabo` (server VPS, headless, déployé via Colmena — voir `docs/colmena.md`)

### Darwin
- `mac-mini`

`mac-mini` reste le nom retenu à ce stade :
- c'est déjà l'entrée fonctionnelle connue pour `darwin-rebuild --flake .#mac-mini`
- aucun signal plus durable n'existe encore dans le repo pour justifier un renommage propre
- le refactor avance donc sans régression inutile

## Darwin : structure désormais retenue

Le target Darwin est maintenant explicite dans le repo :
- `targets/hosts/mac-mini/vars.nix`
- `targets/hosts/mac-mini/default.nix`
- `targets/hosts/mac-mini/config/default.nix`
- `targets/hosts/mac-mini/config/user.nix`
- `targets/hosts/mac-mini/config/apps.nix`
- `targets/hosts/mac-mini/config/networking.nix`

Briques Darwin réutilisables :
- `modules/darwin/base.nix`
- `modules/darwin/homebrew.nix`

Le `flake.nix` expose maintenant :
- `nixosConfigurations.*`
- `darwinConfigurations.mac-mini`

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

`openclaw-vm` introduit maintenant un vrai host concret VM dans le repo :
- `targets/hosts/openclaw-vm/default.nix`
- `targets/hosts/openclaw-vm/config/default.nix`
- `targets/hosts/openclaw-vm/config/user.nix`
- `targets/hosts/openclaw-vm/disko.nix`
- `home/targets/openclaw-vm.nix`
- `stacks/openclaw/default.nix`
- `stacks/openclaw/env/public.env`
- `stacks/openclaw/README.md`

Composition retenue pour cette passe :
- target concret NixOS : `targets/hosts/openclaw-vm/`
- contexte machine : VM explicite via `modules/profiles/virtual-machine.nix`
- base système : VM de service minimale, pas de desktop
- Home Manager : binding vide assumé dans `home/targets/openclaw-vm.nix`
- stack portée : `stacks/openclaw/` comme couche locale mince
- upstream officiel : `nix-openclaw`
- installation distante : `targets/hosts/openclaw-vm/disko.nix` branché, disque réel à renseigner dans `vars.nix`

Tous les targets NixOS du repo utilisent maintenant un `home/targets/<host>.nix` explicite.
Le fallback `home/users/default.nix` a été retiré.

Parcours NixOS Anywhere réellement prêts en V1 :
- structure et scripts : `main`, `laptop`, `gaming`, `openclaw-vm`
- prérequis opératoire restant : renseigner le vrai `disk` sur la machine cible avant installation
- hors périmètre Anywhere actuel : `ms-s1-max` (pas de `disko.nix`)

## VM : règle de modélisation

- un target VM reste un host concret dans `targets/hosts/`
- le fait "tourne dans une VM" se déclare via `modules/profiles/virtual-machine.nix`
- le profil VM ne choisit ni `disk`, ni `disko.nix`, ni l'hyperviseur
- les scripts montrent maintenant explicitement `bare-metal` vs `virtual-machine`
- `openclaw-vm` est maintenant le premier host versionné qui importe explicitement ce profil

## OpenClaw : frontière retenue

- `targets/hosts/openclaw-vm/` = machine concrète dédiée à OpenClaw
- `modules/profiles/virtual-machine.nix` = contexte VM réutilisable
- `stacks/openclaw/` = couche locale mince d’intégration
- `nix-openclaw` = packaging/module officiel upstream

Ce qui est réellement branché :
- input flake `nix-openclaw`
- module upstream `nixosModules.openclaw-gateway`
- package upstream `packages.<system>.openclaw-gateway`
- interface locale `infra.stacks.openclaw.*`
- config minimale `gateway.mode = "local"` + `gateway.bind = "tailnet"`
- répertoires hôte, port, fichier `public.env`
- token d’auth gateway généré localement au premier start
- point d’entrée `sops-nix` conservé pour des secrets externes futurs

Ce qui reste volontairement hors scope :
- secrets externes Telegram/provider versionnés
- config Telegram/providers complète
- choix runtime/plugins enrichis au-delà du minimum d’intégration

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

Pour `mac-mini` :
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
- accès SSH : clé publique de `mfo` autorisée partout (cf. `modules/users/authorized-keys.nix`)

Voir `docs/secrets.md`.

## Apps opératoires

Le point d'entrée quotidien est `nix run .#<app>`. Toutes les apps sont définies dans `flake.nix` et orchestrent — elles ne redéfinissent jamais la source de vérité (qui reste dans `targets/hosts/`, `home/`, `stacks/`, `deployments/`).

### Pré-installation et inspection
- `nix run .#init-host -- <host>` — génère `targets/hosts/<host>/vars.nix` interactivement
- `nix run .#show-config -- <host>` — affiche la configuration effective d'un host
- `nix run .#validate-install -- <host>` — vérifie qu'un host est prêt avant installation
- `nix run .#doctor` — diagnostic général de l'environnement

### Installation
- `nix run .#install-anywhere -- <host>` — installation distante via NixOS Anywhere
- `sudo nix run .#install-manual -- <host>` — installation manuelle (auto-détection live ISO vs NixOS existant)
- `sudo nix run .#install-from-live -- <host>` — depuis un live ISO NixOS
- `sudo nix run .#install-from-existing -- <host>` — depuis un NixOS existant, vers un autre disque (refuse de toucher au disque qui porte `/`)
- `nix run .#post-install-check -- <host>` — vérifications post-installation

### Déploiement (Colmena, hosts server-class)
- `nix run .#deploy-contabo` — déploie `contabo` via Colmena
- `nix run .#deploy-all-hosts` — déploie tous les hosts du hive

Les workstations (`main`, `laptop`, `gaming`, `ms-s1-max`) sont mises à jour localement avec `nixos-rebuild switch --flake .#<host>`, pas via Colmena. Voir `docs/colmena.md`.

### Cloud (OpenTofu)
- `nix run .#plan-azure-ext` / `nix run .#deploy-azure-ext`
- `nix run .#plan-cloudflare-ext` / `nix run .#deploy-cloudflare-ext`
- `nix run .#plan-gcp-ext` / `nix run .#deploy-gcp-ext`

Voir `docs/opentofu.md`.

### Validation du modèle deployments
- `nix run .#validate-inventory` — valide `topology.nix`, `inventory.nix` et tous les contrats `stacks/*/stack.nix` sous les règles strictes de `deployments/validation.nix`

### Outputs flake additionnels
- `nix eval .#inventory` — placement effectif (target → stack instances)
- `nix eval .#topology` — topologie déclarée (kind, runtime, region par target)
- `nix eval .#stacks` — contrats des stacks
- `nix eval .#colmenaHive` — hive Colmena
- `nix develop .#dotnet` — devShell .NET (voir `docs/dotnet-devshell.md`)
