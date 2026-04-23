# OpenTofu

## Rôle

OpenTofu est utilisé pour les **targets cloud** parce qu'il fournit un workflow `plan` / `apply` explicite, versionné dans ce repo, cohérent avec l'idée qu'un target cloud doit être traité comme un target à part entière du modèle `target -> stack instances`.

## Structure `tofu/`

- `tofu/modules/` : blocs réutilisables. Vide aujourd'hui — un module y atterrit dès qu'au moins deux stacks le réutiliseraient.
- `tofu/stacks/<target>/` : pile OpenTofu autonome d'un target cloud donné. Une pile par target, jamais deux targets dans la même pile.

## Targets cloud actuels

| Target | Kind | Workspace | Région |
|---|---|---|---|
| `azure-ext` | `azureContainerApps` | `tofu/stacks/azure-ext/` | `westeurope` |
| `cloudflare-ext` | `cloudflareContainers` | `tofu/stacks/cloudflare-ext/` | global |
| `gcp-ext` | `gcpCloudRun` | `tofu/stacks/gcp-ext/` | `europe-west1` |

Chaque pile contient au minimum :

- `versions.tf` : OpenTofu et providers ;
- `variables.tf` : entrées paramétrables (région, tags, identifiants de compte) ;
- `main.tf` : ressources concrètes (vide aujourd'hui : les workspaces ne déclarent qu'un provider) ;
- `README.md` : notes opératoires (où sont les credentials, ce que le workspace possède, ce qu'il **ne** possède **pas**).

## Workflow `plan` / `apply`

1. Modifier `tofu/stacks/<target>/` ou un module référencé.
2. Vérifier que `deployments/topology.nix` et `deployments/inventory.nix` restent cohérents avec ce target ; lancer `nix run .#validate-inventory`.
3. Exécuter `nix run .#plan-azure-ext` (ou `plan-cloudflare-ext` / `plan-gcp-ext`).
4. Relire le plan.
5. Exécuter `nix run .#deploy-azure-ext` (ou `deploy-cloudflare-ext` / `deploy-gcp-ext`) **uniquement** après validation du plan.

Les apps font `tofu init -input=false -upgrade` puis `tofu plan|apply` dans le bon workspace, sans logique supplémentaire.

## Credentials

Aucun secret n'est lu par OpenTofu depuis le repo. Les credentials sont fournis hors-bande, via les variables d'environnement standard du provider :

- Azure : `ARM_SUBSCRIPTION_ID`, `ARM_TENANT_ID`, `ARM_CLIENT_ID`, `ARM_CLIENT_SECRET` (ou `az login`)
- Cloudflare : `CLOUDFLARE_API_TOKEN`
- GCP : `GOOGLE_APPLICATION_CREDENTIALS` ou `gcloud auth application-default login`

Les identifiants logiques (subscription, account id, project id) ont des slots chiffrés dans `secrets/cloud/{azure,cloudflare,gcp}.yaml` mais ces fichiers ne sont pas encore lus automatiquement par les workspaces — ils servent de mémoire opératoire.

## State

Backend local par défaut. Bascule vers un backend distant (Azure Storage, R2, GCS) en ajoutant un `backend.tf` dans le workspace dès qu'une ressource réelle existe. Aucun `*.tfstate` n'est commité.

## Ajouter un nouveau target cloud

1. Créer `tofu/stacks/<target>/` avec `versions.tf` / `variables.tf` / `main.tf` / `README.md`.
2. Déclarer le target dans `deployments/topology.nix` avec le bon `kind` et `runtime = "tofu"`.
3. Ajouter les affectations applicatives dans `deployments/inventory.nix`.
4. Exposer les apps `plan-<target>` / `deploy-<target>` dans `flake.nix` et leurs scripts dans `scripts/`.
5. Documenter ici si la cible introduit une particularité.

## Point d'attention

OpenTofu provisionne le target cloud ; il ne devient pas la source de vérité des stacks elles-mêmes. Le placement applicatif reste déclaré dans `deployments/inventory.nix`, et les contrats restent dans `stacks/<stack>/stack.nix`.
