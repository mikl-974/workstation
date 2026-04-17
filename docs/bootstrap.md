# Bootstrap — installation et mise en place de la workstation

Ce document decrit le parcours complet : de la machine vierge a la workstation pleinement configuree.

## Vue d'ensemble

```
1. Machine cible bootee sur live ISO NixOS
2. NixOS Anywhere installe le systeme + partitionne les disques
3. Premier boot : NixOS est operationnel
4. Home Manager s'applique automatiquement (dotfiles, paquets utilisateur)
5. Machine prete
```

Voir `docs/nixos-anywhere.md` pour les details de l'etape 2.

## Etapes detaillees

### 1. Preparer le repo

Cloner le repo sur la machine hote :

```bash
git clone https://github.com/mikl-974/workstation
cd workstation
```

### 2. Adapter la configuration

Avant l'installation, verifier / ajuster :

| Fichier | Ce qu'il faut verifier |
|---|---|
| `hosts/main/disko.nix` | Remplacer `/dev/sda` par le disque reel |
| `flake.nix` | Remplacer `"user"` par le nom d'utilisateur |
| `hosts/main/default.nix` | Ajouter la definition utilisateur, les cles SSH |

### 3. Installer via NixOS Anywhere

```bash
nix run nixpkgs#nixos-anywhere -- \
  --flake .#main \
  root@<IP-CIBLE>
```

Le systeme est installe et la machine redemmarre.

### 4. Dotfiles — comment ils sont appliques

Les dotfiles sont geres par Home Manager, integre dans le systeme NixOS.

**Lors de `nixos-rebuild switch`**, Home Manager s'applique automatiquement pour l'utilisateur defini dans `flake.nix`. Les symlinks dans `~/.config/` sont crees ou mis a jour.

Ajouter un dotfile :
1. Placer le fichier dans `dotfiles/<app>/`
2. L'enregistrer dans `home/default.nix` :
   ```nix
   home.file.".config/foot/foot.ini".source = ../dotfiles/foot/foot.ini;
   ```
3. Rebuilder : `sudo nixos-rebuild switch --flake .#main`

### 5. Shell de developpement

Entrer dans le devShell .NET :

```bash
nix develop .#dotnet
```

### 6. Verifier l'installation

```bash
# Verifier que Hyprland est disponible
which Hyprland

# Verifier que Tailscale est actif
systemctl status tailscaled

# Verifier que WARP est actif
systemctl status warp-svc

# Verifier les dotfiles Home Manager
ls -la ~/.config/hypr/
ls -la ~/.config/foot/
```

## Reconstruire la machine

Apres une modification du repo :

```bash
sudo nixos-rebuild switch --flake .#main
```

Ou a distance :

```bash
nixos-rebuild switch --flake github:mikl-974/workstation#main \
  --target-host mikl@<IP-MACHINE> --use-remote-sudo
```

## Ajouter une nouvelle machine

1. Creer `hosts/<name>/default.nix` et `hosts/<name>/disko.nix`
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
3. Installer via NixOS Anywhere avec `--flake .#<name>`
