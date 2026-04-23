# Colmena

## Rôle

Colmena est l'outil de déploiement des targets `nixosHost` **déjà installés**. Il applique les définitions Nix des hosts décrites dans ce repo sur les machines existantes.

## Différence avec NixOS Anywhere

- **NixOS Anywhere** (cf. `docs/nixos-anywhere.md`) : installation ou réinstallation initiale du socle NixOS d'une machine vierge.
- **Colmena** : convergence quotidienne d'un host déjà installé vers l'état décrit dans ce repo.

## Périmètre dans `infra`

Colmena ne pilote pas tous les hosts NixOS du repo. Les **workstations** (`main`, `laptop`, `gaming`, `ms-s1-max`) sont mises à jour localement avec `nixos-rebuild switch --flake .#<host>` — le poste lui-même est l'opérateur, pas une machine de contrôle.

Colmena est utilisé pour les hosts **server-class** opérés à distance. Le hive actuel (cf. `deployments/colmena.nix`) ne contient que :

- `contabo` — VPS Contabo, runtime `dokploy`.

Tout futur host server headless suivra la même intégration.

## Intégration dans ce repo

- `deployments/colmena.nix` : description du hive (les hosts pilotés par Colmena).
- `targets/hosts/<host>/` : configurations NixOS référencées par le hive.
- `flake.nix` : input `colmena` + output `colmenaHive` + apps opératoires.

## Déployer un host

- `nix run .#deploy-contabo`

Ces commandes appellent `scripts/deploy-contabo.sh`, qui exécute Colmena avec le hive du repo, sans logique supplémentaire.

## Déployer plusieurs hosts

- `nix run .#deploy-all-hosts`

À utiliser après une modification commune des modules ou quand plusieurs hosts du hive doivent converger ensemble. Aujourd'hui le hive ne contient qu'un host, donc l'effet est identique à `deploy-contabo` ; la commande existe pour rester stable quand le hive grandira.

## Workflow recommandé

1. Modifier `modules/`, `targets/hosts/` ou `deployments/` selon la nature du changement.
2. Exécuter `nix run .#validate-inventory` pour vérifier l'inventory et les contrats.
3. Déployer le ou les hosts concernés via les apps du flake.
4. Vérifier ensuite le runtime local du target concerné (Dokploy pour `contabo`).

## Point d'attention

Colmena gère les hosts NixOS server-class. Il ne décrit ni les stacks (vivent dans `stacks/` + `deployments/inventory.nix`), ni les targets cloud (vivent dans `tofu/`).
