# stacks/

Services et applications portés par ce repo `infra`.

## Règle

Une stack décrit :
- un service ou une application
- sa configuration applicative
- ses dépendances de service si nécessaire

Une stack ne décide jamais :
- quelle machine l’embarque
- quel user la consomme
- quelle logique système générique réutilisable doit vivre dans `modules/`

## Frontière

- `modules/` = briques système réutilisables
- `targets/hosts/` = machines concrètes
- `stacks/` = services/applications
- `home/` = composition utilisateur

## Stacks actuelles

- `stacks/ai-server/` : service `ollama` porté par ce repo
- `stacks/openclaw/` : intégration locale mince vers `nix-openclaw`, sans duplication du packaging upstream
