# AI dans le repo `infra`

Le repo porte désormais deux dimensions distinctes :
- `modules/profiles/ai.nix` = usage IA local utilisateur
- `stacks/ai-server/` + `modules/profiles/ai-server.nix` = service IA porté par une machine

## Frontière

### AI local
Cas d'usage utilisateur :
- `ollama` en CLI local
- `llama-cpp`
- expérimentation personnelle
- pas d'exposition réseau obligatoire

### AI server
Cas d'usage service :
- `ollama` en tant que service système
- porté par une machine donnée
- décrit dans `stacks/ai-server/`
- activé via `modules/profiles/ai-server.nix`

## Exemple

`targets/hosts/ms-s1-max/default.nix` active `modules/profiles/ai-server.nix`.
