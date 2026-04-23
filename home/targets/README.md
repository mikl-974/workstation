# home/targets/

Composition finale Home Manager par machine.

## Rôle

Un fichier de ce dossier dit explicitement :
- quels users sont présents
- quels rôles ils reçoivent
- comment la machine assemble le tout

## Fichier requis pour tout host NixOS

Le `flake.nix` impose qu'un host NixOS expose explicitement sa composition Home Manager : `mkHomeUsers` *throw* si `home/targets/<host>.nix` n'existe pas. Il n'existe plus de fallback implicite.

## Pattern "binding vide"

Un host NixOS qui n'a pas de composition utilisateur (server headless, VM de service) fournit un binding vide :

- `contabo.nix` = `{ }` — serveur VPS headless. L'opérateur (`admin`) est provisionné au niveau système par `modules/users/admin.nix`, sans Home Manager.
- `openclaw-vm.nix` = `{}` — VM de service portant la stack `openclaw`. Aucune composition desktop forcée.

Le binding vide est **intentionnel** : il satisfait le contrat du flake sans imposer de composition utilisateur factice.

## Targets actuels

- `main.nix` — workstation mono-user (`mikl`)
- `laptop.nix` — workstation mono-user (`mikl`)
- `gaming.nix` — workstation mono-user (`mikl`) + role gaming
- `ms-s1-max.nix` — workstation multi-user (`mfo`, `dfo`)
- `openclaw-vm.nix` — binding vide (VM de service)
- `contabo.nix` — binding vide (serveur headless)
