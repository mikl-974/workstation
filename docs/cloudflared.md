# cloudflared

## Pourquoi ce document existe

`cloudflared` est traité comme une responsabilité **host/networking**, pas comme une stack applicative : un tunnel Cloudflare appartient à la couche réseau du host qui l'expose, et n'a pas de cycle de vie applicatif indépendant.

## Statut dans `infra`

Aucun host n'utilise `cloudflared` aujourd'hui dans ce repo.

Le module générique correspondant existait dans l'ancien flake `foundation` (`foundation.networking.cloudflared.*`). Il **n'a pas été vendoré** dans `infra` au lot A1 parce qu'aucun host ne le consomme actuellement : vendoriser un module mort introduit du code à entretenir sans contrepartie.

Le seul host qui utilisait `cloudflared` historiquement est `macmini` côté `homelab`. Or `macmini` dans ce repo est un Darwin (cf. `docs/architecture.md` § "Conflit de nom `macmini`"), pas un NixOS, et `services.cloudflared` est un service NixOS.

## Quand le brancher

Quand un host NixOS de ce repo a réellement besoin d'exposer un tunnel Cloudflare, ajouter dans cet ordre :

1. `modules/networking/cloudflared.nix` — vendoriser depuis `foundation` (~25 lignes) sous le namespace `infra.networking.cloudflared.*`.
2. Activation explicite dans `targets/hosts/<host>/default.nix` :
   ```nix
   infra.networking.cloudflared = {
     enable = true;
     tunnels = { ... };
   };
   ```
3. Slot de credentials dans `secrets/hosts/<host>.yaml` (le repo ne commit pas de tunnel fictif).

## Bonne propriété à conserver

Conditionner le service à la présence du fichier de configuration réel (`ConditionPathExists=/etc/cloudflared/config.yml`) permet de préparer proprement le host sans injecter de faux tunnel ni faire échouer la machine tant que les credentials ne sont pas fournis.
