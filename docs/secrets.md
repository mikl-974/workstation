# Flux secrets `sops-nix`

## Séparation stricte entre secrets versionnés et clés locales

Le repo distingue maintenant explicitement :

- **les secrets chiffrés versionnés** (`secrets/common.yaml`, `secrets/hosts/*.yaml`, `secrets/stacks/*.yaml`, `secrets/cloud/*.yaml`) ;
- **les clés privées locales non versionnées** (`secrets/keys/ssh/`, `secrets/keys/age/`).

Cette séparation est intentionnelle :
- les fichiers `secrets/*.yaml` sont la source Git du projet ;
- `secrets/keys/` est un simple stockage local de travail pour ce checkout ;
- `secrets/keys/` n'est pas une sauvegarde suffisante et ne remplace pas un coffre chiffré externe.

## Clés locales de travail

### Convention de nommage

| Chemin | Rôle |
|---|---|
| `secrets/keys/ssh/id_ed25519_infra` | clé SSH privée locale |
| `secrets/keys/ssh/id_ed25519_infra.pub` | clé SSH publique locale |
| `secrets/keys/age/key.txt` | identité Age privée locale |
| `secrets/keys/age/key.pub` | recipient Age public local |

### Génération locale

```bash
./scripts/init-keys.sh
```

Le script :
- crée les dossiers nécessaires ;
- génère seulement les clés manquantes ;
- ne touche jamais aux fichiers `secrets/*.yaml` ;
- affiche les prochaines étapes pour brancher la nouvelle identité Age dans `.sops.yaml`.

### Backup

Les clés privées stockées sous `secrets/keys/` sont **locales uniquement**. Elles ne doivent jamais être commitées. Si elles doivent survivre à la perte de la machine, une sauvegarde externe chiffrée reste nécessaire.

## Identité Age active du repo

La clé publique Age actuellement déclarée dans `.sops.yaml` est :
```
age1j9nearzgw8k859r0re0r4uzejxr67sg5glfhnhrzuu5e5f63pyesyvdche
```

Cette identité est l'identité historique du repo. Une nouvelle identité générée localement avec `./scripts/init-keys.sh` ne devient utilisable pour `sops` qu'après :

1. ajout de `secrets/keys/age/key.pub` dans `.sops.yaml` ;
2. re-chiffrement des fichiers concernés avec `sops updatekeys ...`.

## Où stocker la clé Age sur les hosts

Sur chaque machine qui doit déchiffrer des secrets, la clé privée doit être présente à :
```
/var/lib/sops-nix/key.txt   (chmod 600, propriétaire root)
```
Ce chemin est déclaré dans `modules/security/sops.nix` via `ageKeyFile`.

## Premier provisionnement avec la nouvelle structure locale

```bash
# 1. Générer les clés locales de travail
./scripts/init-keys.sh

# 2. Ajouter le recipient public au repo si cette identité doit servir à sops
#    (copier le contenu de secrets/keys/age/key.pub dans .sops.yaml)

# 3. Installer l'identité Age sur la machine cible
sudo mkdir -p /var/lib/sops-nix
sudo install -m 600 -o root -g root \
  secrets/keys/age/key.txt /var/lib/sops-nix/key.txt
```

## Rotation de la clé Age

1. Générer une nouvelle identité avec `./scripts/init-keys.sh` sur un poste de travail sûr, ou remplacer explicitement `secrets/keys/age/key.txt` par une nouvelle identité locale.
2. Extraire / relire le nouveau recipient via `cat secrets/keys/age/key.pub`.
3. Ajouter le nouveau recipient dans `.sops.yaml`.
4. Re-chiffrer tous les fichiers secrets : `sops updatekeys secrets/hosts/ms-s1-max.yaml` (etc.).
5. Installer la nouvelle identité sur les machines concernées dans `/var/lib/sops-nix/key.txt`.
6. Retirer l'ancien recipient de `.sops.yaml` si rotation complète.
7. Supprimer l'ancienne identité privée des machines et des stockages locaux concernés.

## Flux réellement branché

Hosts réellement branchés sur `sops` pour les mots de passe :
- `ms-s1-max`
- `main`
- `laptop`
- `gaming`
- `openclaw-vm`
- `contabo`
- `homelab`
- `sandbox`

### Source chiffrée
- fichiers : `secrets/hosts/*.yaml` concernés + `secrets/common.yaml` pour `root.passwordHash`
- règle de chiffrement : `.sops.yaml`

### Déclaration
Dans chaque host NixOS concerné :
- `infra.security.sops.defaultSopsFile = ../../../secrets/hosts/<host>.yaml;` (ou chemin équivalent)
- secrets déclarés via `sops.secrets.*`
- `infra.users.root.sopsFile = ../../../secrets/common.yaml;`

### Injection runtime
- hashes utilisateurs : `/run/secrets-for-users/...`
- bootstrap passwords root-only : `/run/secrets/ms-s1-max/bootstrap/...`

### Consommation
- `users.users.mfo.hashedPasswordFile`
- `users.users.dfo.hashedPasswordFile`
- `users.users.openclaw.hashedPasswordFile`
- `infra.users.admin.hashedPasswordFile`
- `users.users.root.hashedPasswordFile`

## OpenClaw

La stack `stacks/openclaw/` consomme maintenant un premier secret réel :
- le token d’auth gateway, généré localement au premier start dans `/var/lib/openclaw/secrets/gateway-token.env`

Principe retenu :
- le repo ne commit aucun secret OpenClaw fictif
- le token d’auth nécessaire au gateway est créé sur la VM dédiée au premier start
- la stack locale peut toujours raccorder un fichier secret via `infra.stacks.openclaw.secrets.sopsFile`
- ce fichier alimente alors le service upstream `openclaw-gateway` comme `EnvironmentFile`

Secrets externes encore hors scope pour cette passe :
- token Telegram
- clés provider (`ANTHROPIC_API_KEY`, etc.)

Le bon emplacement retenu pour ces secrets externes, quand ils existeront, reste :
- `secrets/stacks/openclaw.yaml`

## Comment reproduire

### 1. Préparer l'identité Age locale

```bash
./scripts/init-keys.sh
sudo install -m 600 -o root -g root \
  secrets/keys/age/key.txt /var/lib/sops-nix/key.txt
```

### 2. Éditer le secret

```bash
sops secrets/hosts/ms-s1-max.yaml
```

### 3. Rebuild

```bash
sudo nixos-rebuild switch --flake .#ms-s1-max
```

### 4. Vérifier la consommation

```bash
sudo ls /run/secrets-for-users/ms-s1-max/users/
```

## Structure complète de `secrets/`

Au-delà du flux `ms-s1-max` réellement branché ci-dessus, le repo expose la structure suivante (cf. `secrets/README.md` pour le tableau de statut détaillé) :

| Sous-chemin | Contenu | Statut actuel |
|---|---|---|
| `secrets/common.yaml` | secrets transverses (`infra.admin_email`, `root.passwordHash`, ...) | chiffré |
| `secrets/hosts/<host>.yaml` | secrets spécifiques host (mots de passe utilisateurs, clé hôte SSH, auth key Tailscale) | chiffré pour `ms-s1-max`, `main`, `laptop`, `gaming`, `openclaw-vm`, `contabo`, `homelab`, `sandbox` |
| `secrets/stacks/<stack>.yaml` | secrets spécifiques stack (`token`, `*_password`, ...) | placeholders pour `immich`, `kopia`, `n8n`, `nextcloud`, `openwebui`, `pihole` |
| `secrets/cloud/<provider>.yaml` | identifiants cloud logiques (`subscription_id`, `account_id`, `project_id`) | placeholders pour `azure`, `cloudflare`, `gcp` |
| `secrets/keys/ssh/` | clés SSH privées/publiques locales de travail | non versionné, ignoré par Git |
| `secrets/keys/age/` | identités Age privées/publiques locales de travail | non versionné, ignoré par Git |

Les clés YAML d'un fichier `secrets/stacks/<stack>.yaml` doivent correspondre **exactement** au champ `secrets` du contrat `stacks/<stack>/stack.nix` correspondant.

## Règles de chiffrement (`.sops.yaml`)

Les `creation_rules` sont déclarées **par chemin** (`secrets/common`, `secrets/hosts/.*`, `secrets/stacks/.*`, `secrets/cloud/.*`). La clé canonique du projet est la recipient Age `mfo`, utilisée partout de manière cohérente.

## Placeholders vs vrais secrets

Un fichier placeholder contient une chaîne `ENC[AES256_GCM,data:REPLACE_ME,...]` reconnaissable. Il n'est **pas** déchiffrable par SOPS : il existe uniquement pour figer la structure et la convention de nommage. Tout placeholder doit être matérialisé avec `sops` avant qu'un host ou une stack n'en consomme la valeur.

## Rappel de sécurité

- `secrets/*.yaml` = **source versionnée et chiffrée** du projet ;
- `secrets/keys/` = **clés privées locales non versionnées** ;
- ne jamais mélanger les deux ;
- ne jamais considérer `secrets/keys/` comme une sauvegarde suffisante.
