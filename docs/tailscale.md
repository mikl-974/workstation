# Tailscale

## Pourquoi ce module existe

Tailscale fait partie du socle réseau commun des hosts NixOS de ce repo. Il est traité comme une responsabilité système (couche `modules/networking/`), pas comme une stack applicative.

## Où il vit

- `modules/networking/tailscale.nix` : module réutilisable sous l'option `infra.networking.tailscale.*` (vendoré dans le lot A1 depuis l'ancien flake `foundation`, dont le namespace était `foundation.networking.tailscale.*`).
- `modules/profiles/networking.nix` : activation par défaut côté workstation (cf. `docs/profiles.md`).
- `modules/profiles/server.nix` : activation côté server (importé par `targets/hosts/contabo/`).

## Où il est activé

- `contabo` (via le profil `server`)
- toutes les workstations qui consomment le profil `networking` (cf. `targets/hosts/<host>/default.nix`)

## Ce que le module inclut

- activation du service `tailscaled` ;
- mise à disposition de la CLI `tailscale` ;
- l'interface `tailscale0` est marquée comme interface de confiance dans le firewall via le module `infra.networking.firewallServer` (côté server uniquement).

## Ce qui reste volontairement minimal

- aucune auth key branchée automatiquement ;
- aucun tag ;
- aucun subnet router ;
- aucune option de routing avancée.

## Extension propre plus tard

Les placeholders de secrets côté host (`secrets/hosts/<host>.yaml` champ `tailscale_auth_key`, présent par exemple dans `secrets/hosts/contabo.yaml`) permettent de brancher plus tard une auth key ou une stratégie d'enrôlement plus riche sans mélanger cela avec les stacks.
