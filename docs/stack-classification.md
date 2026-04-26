# Classification des stacks

Cette table reflete uniquement l'etat actuel du repo.

| Stack | deploymentMode | supportedTargets | Target actuel |
|---|---|---|---|
| `homepage` | singleton | `nixosHost` | `contabo` |
| `beszel` | distributed | `nixosHost` | `contabo` |
| `tsdproxy` | perTarget | `nixosHost` | `contabo` |
| `kopia` | perTarget | `nixosHost` | `contabo` |
| `nextcloud` | singleton | `nixosHost` | `contabo` |
| `uptime-kuma` | singleton | `nixosHost`, `azureContainerApps`, `gcpCloudRun` | `azure-ext` |
| `keycloak` | singleton | `nixosHost`, `azureContainerApps` | non assigne |
| `immich` | singleton | `nixosHost` | non assigne |
| `n8n` | singleton | `nixosHost` | non assigne |
| `openwebui` | singleton | `nixosHost` | non assigne |
| `opencode` | singleton | `nixosHost` | non assigne |
| `pihole` | singleton | `nixosHost` | non assigne |
| `rustdesk` | singleton | `nixosHost` | non assigne |

## Hors modele stack

L'IA locale de `ms-s1-max` est hors inventory.
Elle est decrite directement dans :

- `targets/hosts/ms-s1-max/config/capabilities.nix`
