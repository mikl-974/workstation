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
| `targets/hosts/` | réalité machine | `main`, `openclaw-vm`, `macmini` |
| `home/users/` | identité d’un user | `mikl.nix`, `mfo.nix`, `dfo.nix`, `zfo.nix`, `lfo.nix` |
| `home/roles/` | binding réutilisable par usage | `desktop-hyprland.nix`, `terminal-kitty.nix` |
| `home/targets/` | composition finale par machine | `main.nix`, `openclaw-vm.nix`, `ms-s1-max.nix` |
| `dotfiles/` | contenu brut réutilisable | Hyprland, Kitty, GTK |
| `stacks/` | services/applications | `ai-server/`, `openclaw/` |
| `secrets/` | source chiffrée | `secrets/hosts/ms-s1-max.yaml` |

Le contexte "machine virtuelle" ne crée pas un nouveau type de target :
- le host reste concret dans `targets/hosts/`
- la VM est modélisée comme profil réutilisable dans `modules/profiles/virtual-machine.nix`

## NixOS vs Darwin

Le repo distingue maintenant explicitement :
- `nixosConfigurations.*` pour les targets NixOS
- `darwinConfigurations.*` pour les targets Darwin

Un target Darwin reste un target concret dans `targets/hosts/`.
Il ne devient pas un faux host NixOS.

## Bare metal vs VM

- `bare-metal` et `virtual-machine` décrivent un contexte machine
- ce ne sont ni des hosts abstraits, ni des modes d'installation
- un host VM importe `modules/profiles/virtual-machine.nix`
- `vars.nix` reste réservé aux valeurs opératoires machine-locales (`disk`, `timezone`, etc.)
- le profil VM ne prend pas en charge `disko.nix`, le disque réel, ni les guest tools hyperviseur-spécifiques

## NixOS moderne actuel

Cinq targets NixOS réels valident maintenant le modèle moderne :
- `main` en mono-user explicite
- `laptop` en mono-user explicite
- `gaming` en mono-user explicite
- `openclaw-vm` en host VM de service explicite
- `ms-s1-max` en multi-user explicite

### `main`
- host concret : `targets/hosts/main/`
- composition Home Manager : `home/targets/main.nix`
- identité user : `home/users/mikl.nix`
- rôle réutilisable : `home/roles/desktop-hyprland.nix`
- installation NixOS Anywhere : structure prête via `targets/hosts/main/disko.nix`, disque réel encore machine-dépendant

### `laptop`
- host concret : `targets/hosts/laptop/`
- composition Home Manager : `home/targets/laptop.nix`
- identité user : `home/users/mikl.nix`
- rôle réutilisable : `home/roles/desktop-hyprland.nix`
- installation NixOS Anywhere : structure prête via `targets/hosts/laptop/disko.nix`, disque réel encore machine-dépendant

### `gaming`
- host concret : `targets/hosts/gaming/`
- composition Home Manager : `home/targets/gaming.nix`
- identité user : `home/users/mikl.nix`
- rôles réutilisables : `home/roles/desktop-hyprland.nix`, `home/roles/gaming-steam.nix`
- installation NixOS Anywhere : structure prête via `targets/hosts/gaming/disko.nix`, disque réel encore machine-dépendant

### `openclaw-vm`
- host concret : `targets/hosts/openclaw-vm/`
- profil réutilisable : `modules/profiles/virtual-machine.nix`
- stack portée : `stacks/openclaw/`
- module upstream consommé : `nix-openclaw.nixosModules.openclaw-gateway`
- composition Home Manager : `home/targets/openclaw-vm.nix` volontairement vide
- base système : VM de service minimale avec SSH et boot explicite
- installation NixOS Anywhere : structure prête via `targets/hosts/openclaw-vm/disko.nix`, disque réel encore machine-dépendant

`main`, `laptop` et `gaming` ne dépendent plus d'aucun fallback Home Manager.

## Users normalisés

Le repo expose maintenant des identités explicites dans `home/users/` :
- `mfo` = Mickaël Folio
- `dfo` = Delphine Folio
- `zfo` = Zoé Folio
- `lfo` = Léna Folio

Définir un user dans `home/users/` ne l'active pas automatiquement.
L'affectation réelle reste déclarée dans `home/targets/<host>.nix`.

Un host de service comme `openclaw-vm` peut garder un binding Home Manager vide
si aucune composition utilisateur n'est réellement utile.

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

Le fallback `home/users/default.nix` a été retiré.
Les hosts NixOS utilisent maintenant tous un binding explicite dans `home/targets/`.
Le target Darwin `macmini` reste séparé de cette logique Home Manager NixOS.

## Modèle target → stack instances

Le repo distingue trois objets :

- un **target** est un endroit où l'on exécute quelque chose. Un host NixOS est un target particulier (`kind = "nixosHost"`) ; un workspace cloud OpenTofu en est un autre (`kind = "azureContainerApps"`, `gcpCloudRun`, `cloudflareContainers`).
- une **stack** décrit son contrat portable dans `stacks/<stack>/stack.nix` (mode de déploiement, rôles, targets supportés, secrets, besoins, volumes).
- un **assignment** dit qu'une instance d'une stack est placée sur un target.

Les trois sources de vérité associées :

| Couche | Fichier |
|---|---|
| topologie déclarée | `deployments/topology.nix` |
| placement effectif | `deployments/inventory.nix` |
| contrats des stacks | `stacks/<stack>/stack.nix` |
| validation stricte | `deployments/validation.nix` (app `nix run .#validate-inventory`) |

Le `runtime` d'un target précise **comment** il est opéré (`nixos-systemd`, `dokploy`, `compose`, `tofu`). Il reste subordonné au repo : les contrats, les affectations et les secrets restent ici, jamais dans le control plane runtime.

Voir aussi `deployments/README.md`, `docs/stack-classification.md`, `docs/colmena.md`, `docs/opentofu.md`.

## Conflit de nom `macmini`

Le repo `infra` contient un target `macmini` qui est un **Darwin** (`darwinConfigurations.macmini`, cf. `targets/hosts/macmini/`). Le repo historique `homelab` contenait un target `macmini` qui était un **NixOS** server-class portant une partie des stacks LAN (`immich`, `n8n`, `pihole`, `openwebui`, `opencode`, `tsdproxy`, `kopia`, agent `beszel`).

Tant que ce conflit de nom n'est pas tranché :

- `topology.nix` ne déclare **pas** de target `macmini` côté `nixosHost` — le seul `macmini` du repo reste le Darwin, et il n'est volontairement pas dans le modèle de stacks ;
- les stacks à vocation LAN qui n'ont pas d'autre host candidat aujourd'hui (`immich`, `n8n`, `pihole`, `openwebui`, `opencode`, `rustdesk`) ont un contrat valide mais aucune affectation (cf. `docs/stack-classification.md`) ;
- `ai-server` fait exception : il est consommé directement par `ms-s1-max` via `modules/profiles/ai-server.nix` et l'inventory l'assigne en conséquence (`ai-server-ms-s1-max`) ;
- ces stacks sont prêtes à être assignées dès qu'un host NixOS LAN compatible existera dans `topology.nix` (par exemple un futur `macmini-nixos` ou un autre nom non ambigu).

Cette séparation évite deux erreurs :

1. instancier des stacks sur un host qui n'existe pas (cassait `validate-inventory`) ;
2. inventer un host NixOS fictif pour faire passer la validation.

## Parcours d'installation NixOS

- `main`, `laptop`, `gaming` et `openclaw-vm` ont maintenant un `disko.nix` branché
- leur parcours NixOS Anywhere est donc préparé structurellement
- le dernier paramètre volontairement local reste `disk` dans `vars.nix`, à renseigner sur la machine cible
- `ms-s1-max` reste sur un parcours manuel tant qu'aucun `disko.nix` n'est défini pour ce host

Le même principe vaut pour une VM :
- le workflow NixOS Anywhere ou manuel reste celui du host concret
- le profil VM ne remplace pas la nécessité de renseigner le bon disque
- le choix firmware/réseau/hyperviseur reste un choix du target concret

## OpenClaw : séparation des responsabilités

- `openclaw-vm` = la machine concrète
- `virtual-machine.nix` = le contexte VM réutilisable
- `stacks/openclaw/` = l’adaptateur local du repo
- `nix-openclaw` = le packaging et le module officiels upstream

La machine décide qu'elle porte la stack.
La stack ne devient pas un host.

Le rôle de `stacks/openclaw/default.nix` est volontairement mince :
- importer le bon module upstream
- mapper l’interface locale `infra.stacks.openclaw.*`
- préparer port, config, données, logs, `public.env`
- générer le secret minimal de bootstrap nécessaire au gateway auth
- garder un point d’entrée `sops-nix` pour des secrets externes réels quand ils existent
- éviter toute réimplémentation maison d’OpenClaw
