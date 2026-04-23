# secrets/

Source chiffrée du repo `infra`.

## Structure

- `common.yaml` : secrets transverses (email admin, ...).
- `hosts/<host>.yaml` : secrets spécifiques à un host (clé hôte SSH, mots de passe utilisateurs, auth key Tailscale).
- `stacks/<stack>.yaml` : secrets spécifiques à une stack. Les clés DOIVENT correspondre au champ `secrets` du contrat `stacks/<stack>/stack.nix`.
- `cloud/<provider>.yaml` : secrets fournisseurs cloud (`azure`, `cloudflare`, `gcp`).

Les règles SOPS associent chaque sous-chemin à un groupe de clés Age dans `.sops.yaml`. Aujourd'hui toutes les paths chiffrent vers la même clé `admin_mfo` ; la séparation des `creation_rules` par chemin est en place pour permettre ultérieurement une rotation par stack ou par provider sans réécrire les autres fichiers.

## Statut des secrets

| Chemin | Statut |
|---|---|
| `secrets/hosts/ms-s1-max.yaml` | **réellement chiffré et consommé** par le host |
| `secrets/hosts/contabo.yaml` | placeholder non chiffré (lot C3) — à matérialiser avec `sops` avant le premier install |
| `secrets/stacks/{immich,kopia,n8n,nextcloud,openwebui,pihole}.yaml` | placeholders non chiffrés (lot C5) |
| `secrets/cloud/{azure,cloudflare,gcp}.yaml` | placeholders non chiffrés (lot C5) |
| `secrets/common.yaml` | placeholder non chiffré (lot C5) |

Les fichiers placeholder contiennent une chaîne `ENC[AES256_GCM,data:REPLACE_ME,...]` reconnaissable. Ils ne sont **pas** déchiffrables : ils existent uniquement pour figer la structure et la convention de nommage.

## Premier flux réel actif : `ms-s1-max`

- fichier chiffré : `secrets/hosts/ms-s1-max.yaml`
- règles SOPS : `.sops.yaml`
- module : `modules/security/sops.nix`
- consommation : `targets/hosts/ms-s1-max/default.nix`

Pour `ms-s1-max`, le repo gère réellement :
- `hosts.ms-s1-max.users.mfo.passwordHash`
- `hosts.ms-s1-max.users.dfo.passwordHash`

Ces secrets sont injectés dans :
- `users.users.mfo.hashedPasswordFile`
- `users.users.dfo.hashedPasswordFile`

Le même fichier chiffré contient aussi les bootstrap passwords root-only :
- `hosts.ms-s1-max.users.mfo.bootstrapPassword`
- `hosts.ms-s1-max.users.dfo.bootstrapPassword`

## Reproduction (chiffrer un nouveau secret)

1. dériver une identité Age depuis la clé SSH privée Ed25519 correspondant à la clé publique de `mikl-974` ;
2. placer cette identité sur le host dans `/var/lib/sops-nix/key.txt` ;
3. éditer le fichier voulu avec `sops` (la creation_rule pertinente est appliquée automatiquement selon le chemin) ;
4. rebuild le host.

Voir `docs/secrets.md`.

## OpenClaw

Le repo branche un premier secret réel pour `stacks/openclaw/` :
- token d'auth gateway généré au premier start sur la VM sous
  `/var/lib/openclaw/secrets/gateway-token.env`

Le repo ne commit toujours pas de faux secret OpenClaw. Quand des secrets externes réels existeront (Telegram, provider, etc.), la stack pourra consommer un dotenv chiffré via `infra.stacks.openclaw.secrets.sopsFile`. Le chemin retenu reste `secrets/stacks/openclaw.yaml`.

## Règles

- Aucun secret en clair ne doit entrer dans Git.
- Toujours modifier un secret via `sops`, jamais à la main.
- Les valeurs déchiffrées ne doivent pas être copiées dans le repo ou dans `env/public.env`.
- Les variables non sensibles peuvent rester dans `env/public.env`, mais jamais les mots de passe, tokens ou clés API.
