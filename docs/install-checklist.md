# Checklist d'installation workstation

Checklist opératoire à parcourir avant et après l'installation.
Pour les détails, voir `docs/manual-install.md` ou `docs/nixos-anywhere.md`.

---

## Avant l'installation

### Machine cible

- [ ] Hostname confirmé (`main`, `laptop`, ou `gaming`)
- [ ] `targets/hosts/<hostname>/default.nix` existe
- [ ] `targets/hosts/<hostname>/disko.nix` existe (requis pour NixOS Anywhere et recommandé en manuel)

### Configuration machine (vars.nix)

- [ ] `targets/hosts/<hostname>/vars.nix` existe — initialiser avec `nix run .#init-host -- <hostname>` si absent
- [ ] `system` défini (`x86_64-linux` ou `aarch64-linux`)
- [ ] `username` défini (identifiant Unix valide)
- [ ] `hostname` défini (correspond à la clé nixosConfigurations dans flake.nix)
- [ ] `disk` défini si disko.nix est présent — vérifier avec `lsblk` sur la machine cible
- [ ] `timezone` défini
- [ ] `locale` défini
- [ ] Aucun champ avec valeur `DEFINE_*` restant dans vars.nix

### Validation

- [ ] `nix run .#doctor -- --host <hostname>` exécuté sans erreur bloquante
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

- [ ] **NixOS Anywhere** : `nix run .#install-anywhere -- <host> <ip-cible>` — voir `docs/nixos-anywhere.md`
- [ ] **Manuelle live ISO** : `sudo nix run .#install-from-live -- <host>` — voir `docs/manual-install.md`
- [ ] **Manuelle depuis NixOS existant** : `sudo nix run .#install-from-existing -- <host>` (autre disque que `/`) — voir `docs/manual-install.md`
- [ ] **Auto-détection live vs existing** : `sudo nix run .#install-manual -- <host>`

---

## Pendant l'installation

### NixOS Anywhere

- [ ] `nix run .#install-anywhere -- <hostname> <ip-cible>` lancé
- [ ] Disque reformaté confirmé
- [ ] Installation terminée sans erreur
- [ ] Machine redémarrée

### Installation manuelle (live ou existing)

- [ ] Repo cloné sur la cible (live) ou présent (existing)
- [ ] `sudo nix run .#install-from-live -- <host>` (ou `install-from-existing`) lancé
- [ ] disko a formaté le disque cible
- [ ] `nixos-install` a terminé sans erreur
- [ ] Reboot effectué (ou disque retiré pour cas existing)

---

## Après l'installation

### Premier boot

- [ ] Connexion SSH ou login console avec l'utilisateur défini dans vars.nix
- [ ] `sudo nixos-rebuild switch --flake .#<hostname>` si rebuild nécessaire
- [ ] `docs/first-boot.md` relu et appliqué

### Home Manager / Dotfiles

- [ ] Home Manager appliqué automatiquement (via `nixos-rebuild switch`)
- [ ] Symlinks dotfiles présents dans `~/.config/`

### Vérifications post-install

- [ ] `nix run .#post-install-check -- --host <hostname>` exécuté sans erreur critique
- [ ] Hyprland disponible : `which Hyprland`
- [ ] `mako`, `cliphist`, `wofi`, `foot`, `firefox`, `thunar` présents si profil desktop actif
- [ ] Tailscale actif : `systemctl status tailscaled`
- [ ] Audio fonctionnel : `systemctl status pipewire`
- [ ] DevShell .NET accessible : `nix develop .#dotnet`

---

## En cas de problème

| Symptôme | Piste |
|---|---|
| Champ DEFINE_ restant | Compléter `targets/hosts/<hostname>/vars.nix`, relancer `nix run .#validate-install -- <hostname>` |
| Rebuild échoue | Vérifier les erreurs Nix, corriger `targets/hosts/<hostname>/vars.nix` ou `targets/` |
| Home Manager non appliqué | Vérifier que le username dans `vars.nix` correspond à l'utilisateur système |
| Dotfiles absents | Vérifier la composition Home Manager active (`home/targets/<host>.nix`) — les entrées doivent pointer vers des fichiers existants |
| Service manquant | Vérifier que le profil correspondant est importé dans `targets/hosts/<hostname>/default.nix` |
