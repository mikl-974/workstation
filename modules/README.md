# modules/

Briques Nix réutilisables composées dans les targets et profils.

## Règle

Ce dossier contient uniquement :
- modules NixOS réutilisables
- modules Darwin réutilisables
- profils réutilisables
- devshells
- templates
- helpers et lib

Il ne contient jamais :
- de machine concrète
- de stack applicative
- de logique d'installation spécifique à une machine

## Structure

| Dossier | Rôle |
|---|---|
| `modules/apps/` | Paquets et applications desktop |
| `modules/containers/` | Moteurs de containers locaux |
| `modules/darwin/` | Base et intégrations Darwin (`nix-darwin`, `nix-homebrew`) |
| `modules/desktop/` | Base système desktop (Hyprland, audio, connectivité) |
| `modules/devshells/` | Environnements de développement CLI |
| `modules/dokploy/` | Activation Docker + ports nécessaires à Dokploy (consommé par `targets/hosts/contabo/`) |
| `modules/networking/` | Briques réseau réutilisables (`tailscale`, `firewall-server`) |
| `modules/profiles/` | **Portes d'entrée publiques** importées par les targets (`virtual-machine`, `server`, `desktop-hyprland`, `gaming`, `ai`, …) |
| `modules/roles/` | **Compositions internes** d'un usage fonctionnel (`gaming`, `ai`) — réutilisées par les profils correspondants ; jamais importées directement par un target |
| `modules/security/` | Intégrations sécurité réutilisables (`sops-nix`, `ssh`, `server`) |
| `modules/shell/` | Configuration shell système |
| `modules/templates/` | Templates de configuration (ex. `host-vars.nix`) |
| `modules/theming/` | Theming et identité visuelle |
| `modules/users/` | Modules user système (ex. `admin` pour les server-class) |

## Convention `profiles/` vs `roles/`

- Un **profile** est la porte d'entrée que les `targets/hosts/<host>/` importent. Il assemble plusieurs modules cohérents et expose une API stable.
- Un **role** est une composition interne réutilisée par les profils. Il ne doit **pas** être importé directement par un target — l'importation passe toujours par un profile.

Exemple : `modules/profiles/gaming.nix` est un wrapper d'une ligne autour de `modules/roles/gaming.nix`. Le wrapper existe pour stabiliser l'API publique : si demain `gaming.nix` doit composer plusieurs roles ou ajouter une option, le contrat des hosts qui l'importent ne change pas.
