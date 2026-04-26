# Secrets

## Emplacements

- `secrets/common.yaml` : secrets transverses
- `secrets/hosts/<host>.yaml` : secrets propres a un host
- `secrets/stacks/<stack>.yaml` : secrets propres a une stack
- `secrets/cloud/<provider>.yaml` : identifiants cloud

## Hosts encore couverts

- `secrets/hosts/ms-s1-max.yaml`
- `secrets/hosts/contabo.yaml`

`mac-mini` ne consomme pas SOPS dans ce repo.

## Cas `ms-s1-max`

Le repo utilise :

- `hosts/ms-s1-max/users/mfo/passwordHash`

Consommation :

- `targets/hosts/ms-s1-max/config/default.nix`
- `users.users.mfo.hashedPasswordFile`

## Cas `contabo`

Le repo utilise :

- `hosts/contabo/users/admin/passwordHash`

Consommation :

- `targets/hosts/contabo/default.nix`
- `infra.users.admin.hashedPasswordFile`

## Regle

- ne jamais editer un secret chiffre a la main
- passer par `sops`
- ne declarer dans la doc que les secrets effectivement consommes par le code
