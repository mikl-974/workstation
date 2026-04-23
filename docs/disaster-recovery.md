# Disaster recovery

## Prérequis de reconstruction

1. Restaurer le repo Git (`mikl-974/infra`).
2. Restaurer la clé Age **privée** correspondant à la recipient `admin_mfo` déclarée dans `.sops.yaml` (hors repo, jamais commitée — typiquement dérivée de la clé SSH Ed25519 de `mikl-974`).
3. Pouvoir déchiffrer les secrets SOPS requis (`secrets/hosts/<host>.yaml` au minimum).

## Reconstruction d'une **workstation** (`main`, `laptop`, `gaming`, `ms-s1-max`)

1. Booter sur un live USB NixOS récent.
2. `nix run .#install-anywhere -- <host>` ou suivre `docs/manual-install.md` selon le contexte.
3. Au premier boot : `nixos-rebuild switch --flake .#<host>` localement.
4. Pour `ms-s1-max` : déposer la clé Age dans `/var/lib/sops-nix/key.txt` avant le premier rebuild qui consomme un secret.

## Reconstruction d'un **server** (`contabo`)

1. Provisionner un VPS vide chez Contabo, noter son IP.
2. Réinstaller NixOS via NixOS Anywhere : `nix run github:nix-community/nixos-anywhere -- --flake .#contabo --target-host root@<ip>`.
3. Déployer les changements suivants via Colmena : `nix run .#deploy-contabo`.
4. Matérialiser `secrets/hosts/contabo.yaml` (clé hôte SSH, auth key Tailscale) et redéployer.

## Reconstruction d'un **target cloud** (`azure-ext`, `cloudflare-ext`, `gcp-ext`)

1. Restaurer les credentials d'opérateur du provider correspondant (cf. `docs/opentofu.md`).
2. `cd tofu/stacks/<target>` et restaurer le `terraform.tfvars` local si nécessaire.
3. `nix run .#plan-<target>` et relire le plan.
4. `nix run .#deploy-<target>` une fois le plan validé.

## Restauration des données applicatives

Indépendant de la couche système. Pour chaque stack instanciée :

1. Restaurer les volumes persistants déclarés dans le contrat (`stacks/<stack>/stack.nix` champ `volumes`).
2. Restaurer les sauvegardes applicatives produites par `kopia`.
3. Réinjecter les variables et tokens en éditant `secrets/stacks/<stack>.yaml` avec `sops`.

## Relance des stacks

1. Vérifier que `nix run .#validate-inventory` passe.
2. Démarrer stack par stack selon criticité :
   - d'abord `tsdproxy` (exposition) et `homepage` (point d'entrée portail) ;
   - puis `nextcloud` / `keycloak` / `beszel` / `kopia` ;
   - en dernier les stacks d'usage (`uptime-kuma`, etc.).
3. Vérifier observabilité (`uptime-kuma-public`, `beszel-hub`) et endpoints publics.

## Point d'attention

La source de vérité reste **ce repo**. La reconstruction ne consiste jamais à régénérer une stack depuis un état runtime : elle consiste à réappliquer le repo sur du matériel/cloud restauré, puis à restaurer les données.
