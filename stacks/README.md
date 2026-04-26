# stacks/

Contrats des services deployables du repo.

## Regle

Une stack decrit :

- un service
- son contrat portable dans `stack.nix`
- ses roles logiques
- ses dependances et volumes

Une stack ne decrit pas :

- le host local d'une workstation
- la cartographie logicielle d'un poste utilisateur

## Decision de recentrage

L'IA locale de `ms-s1-max` ne vit plus ici.
Elle vit dans :

- `targets/hosts/ms-s1-max/config/capabilities.nix`

`stacks/` reste reserve aux services deployables, surtout pour `contabo`
et les targets cloud.
