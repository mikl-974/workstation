# deployments

## Rôle

`deployments/` contient la vérité de placement de ce repo `infra` :
- quels targets existent ;
- de quel type ils sont (`kind`) et avec quel runtime ils sont opérés ;
- quelles instances de stacks y sont affectées.

## Structure

- `topology.nix` : définition des targets (`kind`, `runtime`, `address`, `region`).
- `inventory.nix` : affectations `target -> stack instances`.
- `validation.nix` : validation Nix stricte entre inventory, topology et contrats de stacks (`stacks/<name>/stack.nix`).

Les hosts NixOS Colmena-pilotables et le `colmena.nix` correspondant sont introduits par les lots ultérieurs de la migration (lot C3 pour `contabo` notamment).

## Convention `target`

| Champ | Type | Description |
|---|---|---|
| `kind` | string | `nixosHost`, `azureContainerApps`, `gcpCloudRun`, `cloudflareContainers` (les 3 derniers arrivent au lot C4) |
| `runtime` | string | `nixos-systemd`, `dokploy`, `compose`, `tofu` |
| `address` | string | nom DNS / hostname utilisé par les outils de déploiement |
| `region` | string | étiquette logique de localisation (`home-lan`, `eu-central`, `westeurope`, ...) |

## Convention `assignment`

Chaque entrée dans `assignments.<target>` est un attribut :

| Champ | Type | Obligatoire | Description |
|---|---|---|---|
| `stack` | string | oui | doit exister dans `stacks/<name>/stack.nix` |
| `instance` | string | oui | identifiant logique unique de cette instance |
| `role` | string | non | doit appartenir à `stacks.<stack>.roles` quand présent |

## Ajouter un élément

### Ajouter un target

1. Déclarer le target dans `topology.nix`.
2. Choisir explicitement son `kind` et son `runtime`.
3. Préparer ses affectations dans `inventory.nix` (liste vide acceptée).
4. Si le target est un host NixOS, l'ajouter aussi dans `colmena.nix` quand celui-ci sera introduit (lot C3).

### Ajouter une affectation

1. Choisir le target.
2. Ajouter une entrée avec `stack`, `instance` et éventuellement `role`.
3. Exécuter `nix run .#validate-inventory`.

## Modifier un élément

- Modifier `topology.nix` quand la nature d'un target change.
- Modifier `inventory.nix` quand le placement ou les instances changent.
- Modifier `validation.nix` seulement si le modèle du repo évolue réellement.

## Utilisation / déploiement

- Validation : `nix run .#validate-inventory`
- Déploiement des hosts NixOS : exposé par le lot C3 (`deploy-contabo`, `deploy-all-hosts`, ...).
- Déploiement cloud : exposé par le lot C4 (`plan-azure-ext`, `deploy-azure-ext`, ...).

## Points d’attention

- L'inventory ne doit référencer qu'une stack existante et compatible avec le `kind` du target.
- Le `runtime` décrit comment on opère le target ; il ne remplace jamais la source de vérité du repo.
