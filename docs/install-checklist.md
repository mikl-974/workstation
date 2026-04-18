# Checklist d'installation workstation

Checklist opératoire à parcourir avant et après l'installation.
Pour les détails, voir `docs/manual-install.md` ou `docs/nixos-anywhere.md`.

---

## Avant l'installation

### Machine cible

- [ ] Hostname confirmé (`main`, `laptop`, ou `gaming`)
- [ ] `hosts/<hostname>/default.nix` existe
- [ ] `hosts/<hostname>/disko.nix` existe (requis pour NixOS Anywhere et recommandé en manuel)

### Disque

- [ ] Disque cible identifié sur la machine (`lsblk`)
- [ ] Disque confirmé dans `hosts/<hostname>/disko.nix` — `/dev/CHANGEME` remplacé par le vrai device
- [ ] Taille du disque compatible avec le layout déclaré

### Utilisateur

- [ ] Username défini dans `flake.nix` — `CHANGEME_USERNAME` remplacé
- [ ] `users.users.<username>` défini dans `hosts/<hostname>/default.nix`
- [ ] Groupes corrects (`wheel`, `docker`, `networkmanager`, `video`, `audio`)

### Secrets / accès

- [ ] Clé SSH autorisée configurée dans le host si nécessaire (accès post-install)
- [ ] Clé SSH disponible sur la machine hôte (parcours NixOS Anywhere)

### Réseau

- [ ] Accès réseau disponible sur la machine cible
- [ ] IP de la machine cible connue (parcours NixOS Anywhere)

### Validation

- [ ] `./scripts/validate-install.sh <hostname>` exécuté sans erreur bloquante
- [ ] Aucun placeholder `CHANGEME` restant dans les fichiers Nix

---

## Méthode choisie

- [ ] **NixOS Anywhere** : machine cible accessible en SSH, disko.nix configuré → `docs/nixos-anywhere.md`
- [ ] **Installation manuelle** : boot ISO NixOS, partitionnement manuel ou disko → `docs/manual-install.md`

---

## Pendant l'installation

### NixOS Anywhere

- [ ] `nix run .#install-anywhere -- <hostname> <ip-cible>` lancé
- [ ] Disque reformaté confirmé
- [ ] Installation terminée sans erreur
- [ ] Machine redémarrée

### Installation manuelle

- [ ] Boot ISO OK
- [ ] Réseau opérationnel
- [ ] Partitionnement effectué (disko ou manuel)
- [ ] Partitions montées sous `/mnt`
- [ ] Repo cloné
- [ ] `nixos-install --flake .#<hostname> --root /mnt` exécuté
- [ ] Machine redémarrée

---

## Après l'installation

### Premier boot

- [ ] Connexion SSH ou login console avec l'utilisateur défini
- [ ] `sudo nixos-rebuild switch --flake .#<hostname>` si rebuild nécessaire

### Home Manager / Dotfiles

- [ ] Home Manager appliqué automatiquement (via `nixos-rebuild switch`)
- [ ] Symlinks dotfiles présents dans `~/.config/`

### Vérifications post-install

- [ ] `nix run .#post-install-check` exécuté sans erreur critique
- [ ] Hyprland disponible : `which Hyprland`
- [ ] Tailscale actif : `systemctl status tailscaled`
- [ ] Audio fonctionnel : `systemctl status pipewire`
- [ ] DevShell .NET accessible : `nix develop .#dotnet`

---

## En cas de problème

| Symptôme | Piste |
|---|---|
| Placeholder restant | Relancer `./scripts/validate-install.sh <hostname>` |
| Rebuild échoue | Vérifier les erreurs Nix, corriger `hosts/` ou `flake.nix` |
| Home Manager non appliqué | Vérifier que le username dans `flake.nix` correspond à l'utilisateur système |
| Dotfiles absents | Vérifier `home/default.nix` — les entrées doivent pointer vers des fichiers existants |
| Service manquant | Vérifier que le profil correspondant est importé dans `hosts/<hostname>/default.nix` |
