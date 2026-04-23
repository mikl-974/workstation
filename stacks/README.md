# stacks/

Services et applications portés par ce repo `infra`.

## Règle

Une stack décrit :
- un service ou une application
- sa configuration applicative
- ses dépendances de service si nécessaire
- son **contrat** déclaratif dans `stack.nix`

Une stack ne décide jamais :
- quelle machine l’embarque
- quel user la consomme
- quelle logique système générique réutilisable doit vivre dans `modules/`

## Frontière

- `modules/` = briques système réutilisables
- `targets/hosts/` = machines concrètes
- `stacks/` = services/applications
- `home/` = composition utilisateur
- `deployments/` = placement target → stack instances (cf. `deployments/README.md` dès le lot C2)

## Convention de fichiers

Chaque stack vit dans `stacks/<nom>/` avec, au minimum :

- `stack.nix` : **contrat canonique** de la stack (voir plus bas).
- `README.md` : rappel opérationnel propre à la stack.

Selon le besoin, le dossier peut aussi contenir :

- `default.nix` : module NixOS local activable via `infra.stacks.<nom>.enable` (utilisé par les stacks `ai-server` et `openclaw` qui sont consommées directement par un host).
- `compose.yaml` : squelette d'exécution local/runtime (Docker/Podman compose) — utilisé par les stacks portées par un runtime `compose` ou `dokploy`.
- `env/public.env` : variables non secrètes versionnées.
- `targets/<kind>.nix` : adaptation à un type de target donné (ex. `targets/nixosHost.nix`).

## Contrat `stack.nix`

Le fichier `stack.nix` est un **attribut Nix pur** (pas un module) qui décrit le contrat portable de la stack. Champs obligatoires :

| Champ | Type | Description |
|---|---|---|
| `name` | string | Nom de la stack, doit correspondre au nom du dossier |
| `deploymentMode` | enum | `singleton`, `perTarget`, `distributed` |
| `supportedTargets` | list[string] | Types de targets compatibles : `nixosHost`, `azureContainerApps`, `gcpCloudRun`, `cloudflareContainers` |
| `roles` | list[string] | Rôles que la stack expose (ex. `hub`, `agent`, `app`, `ml`, `gateway`) |
| `secrets` | list[string] | Identifiants logiques de secrets attendus (ex. `immich/token`) |
| `needs` | list[string] | Besoins service requis (ex. `postgres`, `redis`, `persistentVolume`) |
| `volumes` | list[string] | Volumes persistants nommés |

Le contrat est consommé par la validation Nix stricte de `deployments/validation.nix` (voir lot C2).

## Stacks actuelles

### Stacks `infra` natives (consommées directement par un host)

- `ai-server` : service `ollama` porté par ce repo
- `openclaw` : intégration locale mince vers `nix-openclaw`, sans duplication du packaging upstream

### Stacks importées depuis `homelab` (contrats prêts, instances déclarées dans `deployments/inventory.nix` au lot C2)

| Stack | deploymentMode | Rôles | Notes |
|---|---|---|---|
| `beszel` | distributed | hub / agent | Supervision hub-agent |
| `homepage` | singleton | portal | Portail central public |
| `immich` | singleton | app / ml | Photos, dépend postgres/redis |
| `keycloak` | singleton | iam | IAM, à durcir avant cloud |
| `kopia` | perTarget | backup-client | Sauvegarde par target |
| `n8n` | singleton | automation | Automation locale |
| `nextcloud` | singleton | main | Périmètre QTalk uniquement |
| `opencode` | singleton | service | Service interne homelab |
| `openwebui` | singleton | front | Front AI |
| `pihole` | singleton | dns | DNS LAN |
| `rustdesk` | singleton | relay | Accès distant stable |
| `tsdproxy` | perTarget | edge-proxy | Exposition réseau locale par target |
| `uptime-kuma` | singleton | monitor | Supportée aussi sur targets cloud |

Voir `docs/stack-classification.md` pour la justification de placement (ajoutée au lot C6).
