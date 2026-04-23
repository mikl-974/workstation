# Cloudflare WARP

## Pourquoi ce document existe

Cloudflare WARP est limité au **desktop/workstation** Linux. Il ne concerne pas les hosts serveurs headless (`contabo`, futurs servers) et ne doit pas être noyé dans un module desktop monolithique.

## Statut dans `infra`

Aucun host de ce repo n'active WARP en tant que module Nix structuré aujourd'hui. Le besoin a été identifié côté workstation Linux (`main`, `laptop`, `gaming`) mais le module dédié n'a pas encore été vendoré.

L'ancien flake `homelab` exposait un module `nix/modules/desktop/cloudflare-warp.nix` activé sur l'host `workstation`. Le concept reste valide pour `infra` mais le binding direct attend qu'un host de ce repo l'active réellement, pour éviter de vendoriser du code mort.

## Quand le brancher

Quand une workstation Linux de ce repo doit utiliser WARP comme client VPN, ajouter dans cet ordre :

1. `modules/desktop/cloudflare-warp.nix` — module dédié sous le namespace `infra.desktop.cloudflareWarp.*`. Périmètre minimal : activation du service `cloudflare-warp` et présence de la CLI.
2. Activation explicite dans `targets/hosts/<workstation>/default.nix` :
   ```nix
   infra.desktop.cloudflareWarp.enable = true;
   ```
3. Documentation de l'interaction éventuelle avec Tailscale (un seul WARP+Tailscale actif simultanément peut introduire du conflit de routing).

## Ce qu'il ne doit pas devenir

- un toggle implicite d'un profil desktop existant ;
- une dépendance des hosts servers ;
- un fourre-tout réseau concurrent du module Tailscale.

## Couplage avec Tailscale

WARP et Tailscale sont les deux clients VPN visés par ce repo. Aujourd'hui Tailscale est le seul activé (cf. `docs/tailscale.md`). Quand WARP arrivera, documenter ici la stratégie de coexistence (probablement : WARP off par défaut, Tailscale on par défaut).
