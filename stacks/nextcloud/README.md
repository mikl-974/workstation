# nextcloud

Cette stack existe pour héberger **Nextcloud avec un périmètre volontairement limité à QTalk pour le moment**.

## Rôle dans le repo

- le contrat logique vit dans `stacks/nextcloud/stack.nix` ;
- l'affectation réelle du service reste dans `deployments/inventory.nix` ;
- le runtime concret dépend du target, ici `contabo` avec `runtime = "dokploy"`.

## Périmètre actuel

- instance singleton ;
- target supporté : `nixosHost` ;
- usage actuel : QTalk uniquement ;
- base réaliste avec Nextcloud, PostgreSQL et Redis ;
- variables publiques minimales dans `env/public.env`, sans figer la timezone du runtime ;
- secrets injectés par le runtime pour les mots de passe admin, PostgreSQL et Redis.

## Hors scope volontaire pour l'instant

- full suite Nextcloud ;
- Office/Collabora ;
- HA ou sharding ;
- object storage ;
- intégrations additionnelles non justifiées par QTalk.

## Contrat déclaré

- rôle logique : `main` ;
- secrets attendus : `nextcloud/admin_password`, `nextcloud/db_password`, `nextcloud/redis_password` ;
- besoins déclarés : PostgreSQL, Redis, ingress public, volume persistant ;
- volumes déclarés : données applicatives et données PostgreSQL.

Le `compose.yaml` reste exploitable immédiatement avec un runtime de type Dokploy/Compose : les secrets déclarés dans le contrat sont attendus sous forme de variables d'environnement injectées au déploiement.

Le fichier `secrets/stacks/nextcloud.yaml` reste volontairement sans secret réel dans le repo : ses valeurs chiffrées de remplacement doivent être regénérées avec `sops` avant tout déploiement effectif.
