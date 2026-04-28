# Architecture du repo `infra`

## Perimetre

Le repo est volontairement centre sur trois hosts reels :

- `mac-mini`
- `ms-s1-max`
- `contabo`

Les faux hosts, VMs de test et experiments OrbStack ont ete retires.

Les VMs ne sont pas niees par le modele.
Elles sont simplement sorties de `targets/hosts/` parce qu'une VM est portable
entre plusieurs machines physiques et ne doit pas etre confondue avec un host.

## Couches

| Couche | Role | Source de verite |
|---|---|---|
| `systems/` | briques Nix reutilisables | modules systeme, reseau, securite, desktop |
| `targets/hosts/` | machines concretes | un dossier par host reel |
| `targets/vms/` | definitions de VM portables | une definition reutilisable, independante du host physique |
| `home/` | composition utilisateur | users, roles, binding final par host |
| `dotfiles/` | fichiers applicatifs | Hyprland, terminal, launchers, notifications |
| `stacks/` | services deployables | contrat `stack.nix` par stack |
| `deployments/` | placement des stacks | `topology.nix`, `inventory.nix`, `validation.nix` |
| `secrets/` | donnees chiffrees | SOPS |
| `tofu/` | targets cloud | workspaces OpenTofu |

## Regle de modelisation

Le repo distingue maintenant clairement deux choses :

- les capacites locales d'une machine
- les services deployables du modele `target -> stack instances`
- les definitions de VM portables

### VMs portables

Une VM portable ne vit pas dans `targets/hosts/`.

Elle vit dans :

- `targets/vms/<name>/`

et decrit par exemple :

- son role
- sa base logicielle
- son format d'image ou son bootstrap
- les variables attendues pour l'hebergeur

Ce qu'une definition de VM ne choisit pas :

- le host physique final
- le placement courant sur une machine donnee
- l'identite d'un serveur reel

Autrement dit :

- `targets/hosts/` = "ou ca tourne concretement"
- `targets/vms/` = "ce qu'est la VM en tant qu'objet portable"

### Capacites locales

Une capacite locale vit dans la cible elle-meme.

Exemple :

- `targets/hosts/ms-s1-max/config/capabilities.nix`

Ce fichier repond directement a la question :

- "qu'est-ce que cette machine a d'installe et d'active ?"

On y trouve explicitement :

- `ollama`
- `llama-cpp`
- `opencode-desktop`
- `Podman Desktop`
- `btop`
- `VS Code`
- `Rider`
- `WebStorm`
- `GitKraken`
- `Flatpak`
- `ROCm`

### Services deployables

Une stack de service reste decrite dans `stacks/<nom>/stack.nix` puis placee
dans `deployments/inventory.nix`.

Exemple :

- `homepage`, `beszel`, `tsdproxy`, `kopia`, `nextcloud` sur `contabo`
- `uptime-kuma` sur `azure-ext`

`ms-s1-max` ne porte plus de stack IA locale.
Son IA reste un choix de machine locale, pas un service infra partage.

## Hosts

### `ms-s1-max`

- NixOS
- workstation principale
- base desktop : `systems/profiles/workstation-common.nix`
- user systeme : `systems/users/mfo.nix`
- Home Manager : `home/targets/ms-s1-max.nix`
- mapping logiciel local : `targets/hosts/ms-s1-max/config/capabilities.nix`
- IA GPU AMD : `pkgs.ollama-rocm`, `pkgs.llama-cpp-rocm`, `pkgs.python3Packages.huggingface-hub`, `nixpkgs.config.rocmSupport = true`
- runtime systeme ROCm : `rocm-runtime`, `rocminfo`, `rocm-smi`, `amdsmi`

### `contabo`

- NixOS
- serveur headless
- base serveur : `systems/profiles/server.nix`
- runtime d'apps : Dokploy
- placement des stacks dans `deployments/inventory.nix`

### `mac-mini`

- Darwin
- composition `nix-darwin`
- mapping logiciel local : `targets/hosts/mac-mini/config/capabilities.nix`
- apps reparties entre Nix, Homebrew et MAS

## Home Manager

Le modele retenu est simple :

- `home/users/` : identite
- `home/roles/` : composition reutilisable
- `home/targets/` : binding final par host

Cas reels :

- `home/targets/ms-s1-max.nix` : user `mfo`, Hyprland, Noctalia
- `home/targets/contabo.nix` : vide, intentionnel

## Deployments

`deployments/validation.nix` impose :

- target existant
- stack existante
- compatibilite `supportedTargets`
- respect des modes `singleton` / `perTarget`

Le runtime d'un target ne devient jamais la source de verite.
Le repo reste la source de verite.
