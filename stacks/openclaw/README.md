# stacks/openclaw/

Stack applicative OpenClaw intégrée localement par ce repo `infra`.

## Rôle

Cette stack ne repackage pas OpenClaw.
Elle sert d’adaptateur local vers l’upstream officiel :
- input flake : `nix-openclaw`
- module NixOS consommé : `nix-openclaw.nixosModules.openclaw-gateway`
- package consommé : `nix-openclaw.packages.<system>.openclaw-gateway`

Point d’activation repo-local :
- `infra.stacks.openclaw.enable`

Ce que la couche locale prépare :
- `/etc/openclaw/openclaw.json` via le module upstream
- `/etc/openclaw/public.env` pour les variables publiques non secrètes
- `/var/lib/openclaw`
- `/var/log/openclaw`
- port du gateway
- bind réseau prudent (`tailnet`)
- génération locale du token d’auth gateway au premier start
- point d’entrée optionnel pour secrets externes via `sops-nix`

## Frontière

- `targets/hosts/openclaw-vm/` = machine concrète dédiée à OpenClaw
- `modules/profiles/virtual-machine.nix` = contexte VM réutilisable
- `stacks/openclaw/` = assemblage local du repo
- `nix-openclaw` = upstream officiel

La stack ne décide jamais :
- quelle machine la porte
- si cette machine est bare metal ou VM
- quel layout disque ou quel firmware utiliser

## Ce qui est réellement branché

- import du module upstream `openclaw-gateway`
- activation du service systemd NixOS via la stack locale
- fichier checked-in `env/public.env` pour les variables publiques
- interface locale `infra.stacks.openclaw.*`
- bind minimal `tailnet-only`
- génération du secret runtime `OPENCLAW_GATEWAY_TOKEN`
- option `infra.stacks.openclaw.secrets.sopsFile` pour raccorder un dotenv chiffré quand des secrets externes existent

## Ce qui reste volontairement pour la suite

- configuration bot/provider complète
- choix précis des plugins/outils OpenClaw
- secrets externes OpenClaw versionnés dans `secrets/stacks/openclaw.yaml`
- exposition réseau au-delà du bind `tailnet`
