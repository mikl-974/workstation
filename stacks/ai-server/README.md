# stacks/ai-server/

Stack de service IA portée par ce repo `infra`.

## Rôle

Cette stack décrit le service `ai-server` en tant que service/applicatif :
- runtime partagé `ollama`
- exposition locale au host
- pas de composition machine ici

## Frontière

- la stack décrit le service
- `modules/profiles/ai-server.nix` l'importe comme profil système réutilisable
- `targets/hosts/<name>/default.nix` décide si une machine porte ou non cette stack
