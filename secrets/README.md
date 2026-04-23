# secrets/

Source chiffrée du repo `infra`.

## Ce qui est réellement branché

Premier flux réel actif : `ms-s1-max`.

- fichier chiffré : `secrets/hosts/ms-s1-max.yaml`
- règles SOPS : `.sops.yaml`
- module : `modules/security/sops.nix`
- consommation : `targets/hosts/ms-s1-max/default.nix`

## Secret actuellement consommé

Pour `ms-s1-max`, le repo gère réellement :
- `hosts.ms-s1-max.users.mfo.passwordHash`
- `hosts.ms-s1-max.users.dfo.passwordHash`

Ces secrets sont injectés dans :
- `users.users.mfo.hashedPasswordFile`
- `users.users.dfo.hashedPasswordFile`

Le même fichier chiffré contient aussi les bootstrap passwords root-only :
- `hosts.ms-s1-max.users.mfo.bootstrapPassword`
- `hosts.ms-s1-max.users.dfo.bootstrapPassword`

## Reproduction

1. dériver une identité Age depuis la clé SSH privée Ed25519 correspondant à la clé publique de `mikl-974`
2. placer cette identité sur le host dans `/var/lib/sops-nix/key.txt`
3. éditer `secrets/hosts/ms-s1-max.yaml` avec `sops`
4. rebuild le host

Voir `docs/secrets.md`.
