# Bootstrap — installation et mise en place de la workstation

Ce document décrit le parcours complet : de la machine vierge à la workstation pleinement configurée.

Deux parcours sont disponibles :
- **NixOS Anywhere** (recommandé) : installation à distance depuis la machine hôte → `docs/nixos-anywhere.md`
- **Manuel** (fallback) : installation depuis un live ISO NixOS → `docs/manual-install.md`

Checklist opératoire : `docs/install-checklist.md`

## Vue d'ensemble

```
Parcours NixOS Anywhere
─────────────────────────────────────────────────────────────
1. Machine cible bootée sur live ISO NixOS (SSH actif)
2. Valider la configuration : nix run .#validate-install -- main
3. Lancer : nix run .#install-anywhere -- main <IP-CIBLE>
4. Premier boot : NixOS opérationnel, Home Manager actif
5. Vérifier : nix run .#post-install-check

Parcours Manuel
─────────────────────────────────────────────────────────────
1. Boot sur ISO NixOS
2. Préparer le réseau, partitionner, monter
3. Cloner le repo, valider la configuration
4. nixos-install --flake .#main --root /mnt
5. Reboot
6. Vérifier : nix run .#post-install-check
```

## Étapes détaillées

### 1. Préparer le repo

Cloner le repo sur la machine hôte :

```bash
git clone https://github.com/mikl-974/workstation
cd workstation
```

### 2. Adapter la configuration

Avant l'installation, vérifier / ajuster :

| Fichier | Ce qu'il faut vérifier |
|---|---|
| `hosts/main/disko.nix` | Remplacer `/dev/CHANGEME` par le disque réel |
| `flake.nix` | Remplacer `CHANGEME_USERNAME` par le nom d'utilisateur |
| `hosts/main/default.nix` | Ajouter la définition utilisateur, les clés SSH |

Valider d'un coup :

```bash
nix run .#validate-install -- main
```

### 3a. Installer via NixOS Anywhere

```bash
nix run .#install-anywhere -- main <IP-CIBLE>
```

Le système est installé et la machine redémarre.

### 3b. Installer manuellement

```bash
nix run .#install-manual -- --host main
```

Ce guide interactif accompagne le parcours manuel étape par étape.
Voir `docs/manual-install.md` pour la procédure complète.

### 4. Dotfiles — comment ils sont appliqués

Les dotfiles sont gérés par Home Manager, intégré dans le système NixOS.

**Lors de `nixos-rebuild switch`**, Home Manager s'applique automatiquement pour l'utilisateur défini dans `flake.nix`. Les symlinks dans `~/.config/` sont créés ou mis à jour.

Ajouter un dotfile :
1. Placer le fichier dans `dotfiles/<app>/`
2. L'enregistrer dans `home/default.nix` :
   ```nix
   home.file.".config/foot/foot.ini".source = ../dotfiles/foot/foot.ini;
   ```
3. Rebuilder : `sudo nixos-rebuild switch --flake .#main`

### 5. Shell de développement

Entrer dans le devShell .NET :

```bash
nix develop .#dotnet
```

### 6. Vérifier l'installation

```bash
nix run .#post-install-check
```

Ou manuellement :

```bash
# Vérifier que Hyprland est disponible
which Hyprland

# Vérifier que Tailscale est actif
systemctl status tailscaled

# Vérifier que WARP est actif
systemctl status warp-svc

# Vérifier les dotfiles Home Manager
ls -la ~/.config/hypr/
ls -la ~/.config/foot/
```

## Reconstruire la machine

Après une modification du repo :

```bash
sudo nixos-rebuild switch --flake .#main
```

Ou à distance :

```bash
nixos-rebuild switch --flake github:mikl-974/workstation#main \
  --target-host mikl@<IP-MACHINE> --use-remote-sudo
```

## Ajouter une nouvelle machine

1. Créer `hosts/<name>/default.nix` et `hosts/<name>/disko.nix`
2. Ajouter la configuration dans `flake.nix` :
   ```nix
   <name> = lib.nixosSystem {
     system = "x86_64-linux";
     modules = sharedModules ++ [
       disko.nixosModules.disko
       ./hosts/<name>/default.nix
     ];
   };
   ```
3. Valider : `nix run .#validate-install -- <name>`
4. Installer via NixOS Anywhere : `nix run .#install-anywhere -- <name> <IP-CIBLE>`
