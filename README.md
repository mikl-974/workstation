# infra

Monorepo d'infrastructure Nix recentre sur trois hosts reels :

- `mac-mini` : workstation Darwin geree via `nix-darwin`
- `ms-s1-max` : workstation NixOS principale
- `contabo` : VPS NixOS headless, operee via Dokploy et Colmena

Les anciens hosts de test ou de transition (`main`, `laptop`, `gaming`, `homelab`, `sandbox`, `orbstack`, `openclaw-vm`) ont ete retires du graphe.

Les VMs ne sont plus modelisees comme des `hosts` physiques.
Quand il faudra en versionner de nouveau, elles vivront dans `targets/vms/`
comme definitions portables, decouplees du materiel qui les heberge.

## Intention

Le repo porte une seule source de verite pour :

- les machines concretes
- la composition utilisateur Home Manager
- les modules Nix reutilisables
- les stacks de services deployables
- les secrets SOPS
- les targets cloud OpenTofu

Le point cle du recentrage :

- les services deployables restent modelises dans `stacks/` + `deployments/`
- les capacites locales d'une machine restent mappees directement dans son host

Exemple :

- `targets/hosts/ms-s1-max/config/capabilities.nix` dit explicitement que la machine porte `ollama`, `llama-cpp`, `opencode-desktop`, `Rider`, `WebStorm`, `VS Code`, `GitKraken` et `Flatpak`
- `deployments/inventory.nix` ne modele pas cette IA locale comme une stack

## Structure

- `modules/` : briques Nix reutilisables
- `targets/hosts/` : machines concretes
- `targets/vms/` : definitions de VM portables
- `home/` : composition Home Manager
- `dotfiles/` : fichiers applicatifs versionnes
- `stacks/` : contrats des services deployables
- `deployments/` : topologie + inventory + validation stricte
- `secrets/` : secrets chiffres avec SOPS
- `tofu/` : targets cloud OpenTofu
- `scripts/` : orchestration et validation
- `docs/` : documentation de reference

## Hosts actifs

### `ms-s1-max`

- host NixOS principal
- desktop Hyprland
- user unique `mfo`
- IA locale GPU AMD via ROCm et outils dev declares dans `targets/hosts/ms-s1-max/config/capabilities.nix`
- runtime ROCm installe sur le systeme pour les usages IA GPU
- Home Manager dans `home/targets/ms-s1-max.nix`
- secret host dans `secrets/hosts/ms-s1-max.yaml`

### `contabo`

- VPS NixOS headless
- base serveur dans `modules/profiles/server.nix`
- Dokploy active via `modules/dokploy`
- stacks deployees via `deployments/inventory.nix`
- deployable par Colmena

### `mac-mini`

- host Darwin
- configuration par `nix-darwin`
- carte logicielle locale dans `targets/hosts/mac-mini/config/capabilities.nix`
- apps macOS partagees entre Nix, Homebrew et MAS

## Flux operatoires

- inspecter un host : `nix run .#show-config -- <host>`
- diagnostiquer le repo : `nix run .#doctor -- --host <host>`
- valider un host : `nix run .#validate-install -- <host>`
- reconfigurer un host NixOS existant : `nix run .#reconfigure -- <host>`
- deployer `contabo` : `nix run .#deploy-contabo`
- valider l'inventory : `nix run .#validate-inventory`
- planifier un target cloud : `nix run .#plan-azure-ext`

## Documentation

Commencer par :

- `docs/architecture.md`
- `docs/repo-structure.md`
- `docs/ai.md`
- `docs/secrets.md`
- `docs/update-workflow.md`
