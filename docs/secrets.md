# Flux secrets `sops-nix`

## Flux réellement branché

Host : `ms-s1-max`

### Source chiffrée
- fichier : `secrets/hosts/ms-s1-max.yaml`
- règle de chiffrement : `.sops.yaml`

### Déclaration
Dans `targets/hosts/ms-s1-max/default.nix` :
- `infra.security.sops.defaultSopsFile = ../../../secrets/hosts/ms-s1-max.yaml;`
- secrets déclarés via `sops.secrets.*`

### Injection runtime
- hashes utilisateurs : `/run/secrets-for-users/...`
- bootstrap passwords root-only : `/run/secrets/ms-s1-max/bootstrap/...`

### Consommation
- `users.users.mfo.hashedPasswordFile`
- `users.users.dfo.hashedPasswordFile`

## Comment reproduire

### 1. Préparer l'identité Age
Depuis la clé SSH privée Ed25519 correspondant à la clé publique GitHub de `mikl-974` :

```bash
ssh-to-age -private-key -i ~/.ssh/id_ed25519 > /var/lib/sops-nix/key.txt
chmod 600 /var/lib/sops-nix/key.txt
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
sudo ls /run/secrets/ms-s1-max/bootstrap/
sudo cat /run/secrets/ms-s1-max/bootstrap/mfo-password
sudo cat /run/secrets/ms-s1-max/bootstrap/dfo-password
```
