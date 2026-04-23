# Repo structure

Ce repo est désormais traité conceptuellement comme `infra` :
une seule base pour les briques système, les machines, la composition utilisateur,
les dotfiles, les services et les secrets.

## Structure retenue

- `modules/` : briques Nix réutilisables
- `targets/` : cibles concrètes
  - `targets/hosts/` : machines réelles NixOS et Darwin
- `home/` : composition Home Manager users / roles / targets
- `dotfiles/` : bibliothèque de fichiers applicatifs réutilisables
- `stacks/` : services/applications portés par le repo
- `deployments/` : modèle de placement strict `target → stack instances` (`topology.nix`, `inventory.nix`, `validation.nix`, `colmena.nix`)
- `tofu/` : workspaces OpenTofu pour les targets cloud (`azure-ext`, `cloudflare-ext`, `gcp-ext`)
- `secrets/` : secrets chiffrés avec `sops-nix`
- `docs/` : documentation
- `scripts/` : orchestration légère et validation

## Règles de placement

### `modules/`
Contient des briques réutilisables :
- modules système NixOS
- modules Darwin
- profils réutilisables
- devshells
- sécurité / intégrations transverses
- helpers et templates

Exemple explicite :
- `modules/profiles/virtual-machine.nix` = le contexte VM comme profil réutilisable, pas comme host abstrait

### `targets/`
Contient la réalité des machines :
- un host concret dans `targets/hosts/<name>/`
- ses variables machine
- sa config NixOS ou Darwin
- éventuellement son layout disque côté NixOS (`disko.nix`) quand le host doit être installable via NixOS Anywhere

Le fait qu'un target soit bare metal ou VM ne crée pas un nouveau sous-type de host :
- le host reste concret
- le contexte VM se déclare par import de `modules/profiles/virtual-machine.nix`

### `home/`
Contient la composition utilisateur :
- `home/users/` = identité d'un user
- `home/roles/` = rôles composables
- `home/targets/` = binding final par machine

Exemples réels :
- `home/users/mikl.nix` = identité du user de `main`
- `home/targets/main.nix` = composition finale de `main`
- `home/targets/laptop.nix` = composition finale de `laptop`
- `home/targets/gaming.nix` = composition finale de `gaming`
- `home/targets/openclaw-vm.nix` = binding volontairement vide pour une VM de service
- `home/targets/ms-s1-max.nix` = composition finale de `ms-s1-max`
- `home/targets/contabo.nix` = binding volontairement vide pour le serveur headless `contabo`

Le fichier `home/targets/<host>.nix` est **requis** pour tout NixOS host : `mkHomeUsers` dans `flake.nix` *throw* explicitement s'il manque. Les hosts headless ou de service sans desktop fournissent un binding vide (`{ }`).

### `dotfiles/`
Contient uniquement du contenu brut applicatif.
Le choix de qui consomme quoi se fait dans `home/`.

### `stacks/`
Contient les services et applications portés par le repo `infra`.
Une stack peut être importée par un profil système, mais elle ne décide jamais quelle machine l'utilise.

Chaque stack expose un **contrat portable** dans `stacks/<nom>/stack.nix` (cf. `stacks/README.md`). Les stacks `infra` natives (`ai-server`, `openclaw`) ajoutent en plus un `default.nix` qui est le module NixOS importable directement par un host.

Exemples :
- `stacks/ai-server/` = stack de service IA (`default.nix` + `stack.nix`)
- `stacks/openclaw/` = adaptateur local vers `nix-openclaw` pour la VM `openclaw-vm` (`default.nix` + `stack.nix`)
- `stacks/homepage/` = stack Dokploy (`stack.nix` + `compose.yaml` + `env/public.env`)

### `deployments/`
Contient le **modèle de placement** entre targets et instances de stacks :
- `topology.nix` : les targets connus du repo (`kind`, `runtime`, `region`)
- `inventory.nix` : les affectations effectives `<stack-instance> → <target>`
- `validation.nix` : la validation Nix stricte (lue par l'app `nix run .#validate-inventory`)
- `colmena.nix` : le hive Colmena pour les hosts NixOS server-class

Voir `deployments/README.md`, `docs/colmena.md`, `docs/stack-classification.md`.

### `tofu/`
Contient les workspaces OpenTofu pour les targets cloud. Une pile par target, jamais deux targets dans la même pile.

Workspaces actuels : `azure-ext`, `cloudflare-ext`, `gcp-ext`. Voir `docs/opentofu.md`.
