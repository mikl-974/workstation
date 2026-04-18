# Checklist d'installation workstation

Checklist opératoire à parcourir avant et après l'installation.
Pour les détails, voir `docs/manual-install.md` ou `docs/nixos-anywhere.md`.

---

## Avant l'installation

### Machine cible

- [ ] Hostname confirmé (`main`, `laptop`, ou `gaming`)
- [ ] `hosts/<hostname>/default.nix` existe
- [ ] `hosts/<hostname>/disko.nix` existe (requis pour NixOS Anywhere et recommandé en manuel)

### Configuration machine (vars.nix)

- [ ] `hosts/<hostname>/vars.nix` existe — initialiser avec `nix run .#init-host -- <hostname>` si absent
- [ ] `username` défini (identifiant Unix valide)
- [ ] `hostname` défini (correspond à la clé nixosConfigurations dans flake.nix)
- [ ] `disk` défini si disko.nix est présent — vérifier avec `lsblk` sur la machine cible
- [ ] `timezone` défini
- [ ] `locale` défini
- [ ] Aucun champ avec valeur `DEFINE_*` restant dans vars.nix

### Validation

- [ ] `nix run .#validate-install -- <hostname>` exécuté sans erreur bloquante
- [ ] Aucun placeholder dans les fichiers structurants (flake.nix, default.nix, disko.nix)

### Secrets / accès

- [ ] Clé SSH autorisée configurée dans le host si nécessaire (accès post-install)
- [ ] Clé SSH disponible sur la machine hôte (parcours NixOS Anywhere)

### Réseau

- [ ] Accès réseau disponible sur la machine cible
- [ ] IP de la machine cible connue (parcours NixOS Anywhere)

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

- [ ] Connexion SSH ou login console avec l'utilisateur défini dans vars.nix
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
| Champ DEFINE_ restant | Compléter `hosts/<hostname>/vars.nix`, relancer `nix run .#validate-install -- <hostname>` |
| Rebuild échoue | Vérifier les erreurs Nix, corriger `hosts/<hostname>/vars.nix` ou `hosts/` |
| Home Manager non appliqué | Vérifier que le username dans `vars.nix` correspond à l'utilisateur système |
| Dotfiles absents | Vérifier `home/default.nix` — les entrées doivent pointer vers des fichiers existants |
| Service manquant | Vérifier que le profil correspondant est importé dans `hosts/<hostname>/default.nix` |
