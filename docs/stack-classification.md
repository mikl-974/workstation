# Classification des stacks

Cette table fige le `deploymentMode` et les `supportedTargets` déclarés par chaque contrat `stacks/<stack>/stack.nix`, et donne le target recommandé pour chaque instance dans le contexte actuel du repo `infra`.

Toute affectation décrite dans `deployments/inventory.nix` doit respecter cette table : `nix run .#validate-inventory` rejette tout placement incompatible.

| Stack | deploymentMode | supportedTargets | Target recommandé | Justification |
|---|---|---|---|---|
| `homepage` | singleton | nixosHost | `contabo` | portail central public |
| `beszel` | distributed | nixosHost | hub `contabo`, agents par host à venir | modèle hub/agent natif |
| `tsdproxy` | perTarget | nixosHost | `contabo` (et tout futur host headless) | exposition réseau locale par target |
| `kopia` | perTarget | nixosHost | `contabo` (et tout futur host avec données) | sauvegarde par target |
| `nextcloud` | singleton | nixosHost | `contabo` | usage limité à QTalk, sans hypothèse de full suite |
| `keycloak` | singleton | nixosHost, azureContainerApps | `contabo` (initial) | IAM, à durcir avant migration cloud |
| `rustdesk` | singleton | nixosHost | non assigné | accès distant stable, futur host server LAN |
| `uptime-kuma` | singleton | nixosHost, azureContainerApps, gcpCloudRun | `azure-ext` | supervision externe plus résiliente |
| `immich` | singleton | nixosHost | non assigné | stockage local et charges media — attendre un host LAN avec stockage |
| `n8n` | singleton | nixosHost | non assigné | automation locale — attendre un host LAN |
| `pihole` | singleton | nixosHost | non assigné | DNS local du LAN — attendre un host LAN dédié |
| `openwebui` | singleton | nixosHost | non assigné | front AI — proximité usage quotidien |
| `opencode` | singleton | nixosHost | non assigné | service interne |
| `ai-server` | singleton | nixosHost | `ms-s1-max` | service `ollama` natif `infra` consommé directement par le host via `modules/profiles/ai-server.nix` |
| `openclaw` | singleton | nixosHost | `openclaw-vm` | gateway opérée comme stack `infra` native |

## Points d'attention

- Les stacks marquées « non assigné » ont un contrat valide mais aucune ligne dans `inventory.nix` aujourd'hui. Elles sont prêtes à recevoir un placement quand un host compatible existera dans `topology.nix`.
- L'hôte historique `macmini` du repo `homelab` (kind `nixosHost`) **n'existe pas** dans `infra` aujourd'hui : le seul `macmini` du repo est un Darwin (cf. `docs/architecture.md` § "Conflit de nom `macmini`"). Tant que ce conflit n'est pas tranché, les stacks à vocation LAN restent non assignées plutôt que d'être collées à un host inexistant.
