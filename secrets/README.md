# secrets/

Le dossier `secrets/` contient désormais **deux catégories strictement séparées** :

1. **sources chiffrées versionnées** pour `sops-nix` ;
2. **clés locales de travail non versionnées** pour ce checkout.

Cette séparation est volontaire :
- les fichiers `secrets/*.yaml` restent la source versionnée et chiffrée ;
- `secrets/keys/` ne sert qu'au stockage local de clés privées ;
- `secrets/keys/` n'est **pas** un coffre-fort ni une sauvegarde suffisante.

## Structure

### 1. Secrets chiffrés versionnés

- `common.yaml` : secrets transverses (email admin, ...).
- `hosts/<host>.yaml` : secrets spécifiques à un host (clé hôte SSH, mots de passe utilisateurs, auth key Tailscale).
- `stacks/<stack>.yaml` : secrets spécifiques à une stack. Les clés DOIVENT correspondre au champ `secrets` du contrat `stacks/<stack>/stack.nix`.
- `cloud/<provider>.yaml` : secrets fournisseurs cloud (`azure`, `cloudflare`, `gcp`).

Les règles SOPS associent chaque sous-chemin à un groupe de clés Age dans `.sops.yaml`. La clé canonique du projet est `mfo`, utilisée partout de manière cohérente.

### 2. Clés locales de travail non versionnées

- `keys/ssh/id_ed25519_infra` : clé SSH privée locale du checkout.
- `keys/ssh/id_ed25519_infra.pub` : clé SSH publique correspondante.
- `keys/age/key.txt` : identité Age privée locale du checkout.
- `keys/age/key.pub` : recipient Age public correspondant.

Ces fichiers :
- ne sont **jamais** versionnés ;
- ne sont **jamais** chiffrés par `sops` ;
- servent uniquement au poste de travail local ;
- doivent être sauvegardés dans un support externe chiffré si on veut pouvoir les récupérer.

Le `.gitignore` local à `secrets/` bloque toute tentative de commit de contenu réel sous `secrets/keys/`.

## Génération des clés locales

Le repo fournit :

```bash
./scripts/init-keys.sh
```

Ce script :
- crée `secrets/keys/ssh/` et `secrets/keys/age/` si besoin ;
- génère uniquement les clés manquantes ;
- n'écrit jamais dans les fichiers `secrets/*.yaml` versionnés ;
- affiche les prochaines étapes utiles (diffusion de la clé SSH publique, ajout du recipient Age dans `.sops.yaml`, installation de `key.txt` sur un host).

## Convention de nommage

| Chemin | Rôle |
|---|---|
| `secrets/keys/ssh/id_ed25519_infra` | clé SSH privée locale de travail |
| `secrets/keys/ssh/id_ed25519_infra.pub` | clé SSH publique à diffuser si besoin |
| `secrets/keys/age/key.txt` | identité Age privée locale pour `sops` / `sops-nix` |
| `secrets/keys/age/key.pub` | recipient public à ajouter dans `.sops.yaml` |

## Ce que ces clés servent à faire

- **SSH** : accès Git/forge, bootstrap SSH, accès admin ou autres usages de travail selon le projet.
- **Age** : chiffrement/déchiffrement des secrets `sops`, puis installation éventuelle sur un host dans `/var/lib/sops-nix/key.txt`.

Le fait que les deux vivent sous `secrets/keys/` ne change pas leur statut :
- **local et non versionné** pour les clés ;
- **versionné et chiffré** pour les fichiers `secrets/*.yaml`.

## Statut des secrets

| Chemin | Statut |
|---|---|
| `secrets/hosts/ms-s1-max.yaml` | **réellement chiffré et consommé** par le host |
| `secrets/hosts/{main,laptop,gaming,openclaw-vm,contabo,homelab,sandbox}.yaml` | **réellement chiffrés** pour les password hashes host-local |
| `secrets/stacks/{immich,kopia,n8n,nextcloud,openwebui,pihole}.yaml` | placeholders non chiffrés (lot C5) |
| `secrets/cloud/{azure,cloudflare,gcp}.yaml` | placeholders non chiffrés (lot C5) |
| `secrets/common.yaml` | **réellement chiffré** — secret transversal (`root.passwordHash`) |

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

Le même fichier chiffré contient uniquement les hash de mot de passe ; il n'y a plus de bootstrap password en clair (supprimé : on bootstrappe via clé SSH).

Les autres hosts NixOS branchés sur des mots de passe via `sops` suivent la même convention :
- `hosts.main.users.mfo.passwordHash`
- `hosts.laptop.users.mfo.passwordHash`
- `hosts.gaming.users.mfo.passwordHash`
- `hosts.openclaw-vm.users.openclaw.passwordHash`
- `hosts.contabo.users.admin.passwordHash`
- `hosts.homelab.users.admin.passwordHash`
- `hosts.sandbox.users.admin.passwordHash`
- `root.passwordHash` dans `secrets/common.yaml`

## Reproduction (chiffrer un nouveau secret)

1. générer une identité Age locale avec `./scripts/init-keys.sh` (ou réutiliser l'identité locale déjà présente dans `secrets/keys/age/key.txt`) ;
2. ajouter le recipient public de `secrets/keys/age/key.pub` dans `.sops.yaml` si cette identité doit devenir autorisée pour le repo ;
3. re-chiffrer les secrets concernés avec `sops updatekeys ...` ;
4. placer l'identité privée sur le host dans `/var/lib/sops-nix/key.txt` ;
5. éditer le fichier voulu avec `sops` ;
6. rebuild le host.

Voir `docs/secrets.md`.

## OpenClaw

Le repo branche un premier secret réel pour `stacks/openclaw/` :
- token d'auth gateway généré au premier start sur la VM sous
  `/var/lib/openclaw/secrets/gateway-token.env`

Le repo ne commit toujours pas de faux secret OpenClaw. Quand des secrets externes réels existeront (Telegram, provider, etc.), la stack pourra consommer un dotenv chiffré via `infra.stacks.openclaw.secrets.sopsFile`. Le chemin retenu reste `secrets/stacks/openclaw.yaml`.

## Règles

- Aucun secret en clair ne doit entrer dans Git.
- Aucune clé privée réelle ne doit être commitée dans `secrets/keys/`.
- Toujours modifier un secret via `sops`, jamais à la main.
- Les valeurs déchiffrées ne doivent pas être copiées dans le repo ou dans `env/public.env`.
- Les variables non sensibles peuvent rester dans `env/public.env`, mais jamais les mots de passe, tokens ou clés API.
- `secrets/keys/` est un stockage local de travail, pas une sauvegarde suffisante.
