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
2. Initialiser la config : nix run .#init-host -- <host>
3. Diagnostiquer : nix run .#doctor -- --host <host>
4. Valider : nix run .#validate-install -- <host>
5. Lancer : nix run .#install-anywhere -- <host> <IP-CIBLE>
6. Premier boot : NixOS opérationnel, Home Manager actif
7. Vérifier : nix run .#post-install-check -- --host <host>

Parcours Manuel
─────────────────────────────────────────────────────────────
1. Boot sur ISO NixOS
2. Préparer le réseau, partitionner, monter
3. Cloner le repo, initialiser vars.nix, lancer doctor puis validate-install
4. nixos-install --flake .#<host> --root /mnt
5. Reboot
6. Vérifier : nix run .#post-install-check -- --host <host>
```

## Étapes détaillées

### 1. Préparer le repo

Cloner le repo sur la machine hôte :

```bash
git clone https://github.com/mikl-974/workstation
cd workstation
```

### 2. Configurer la machine

Toutes les valeurs spécifiques à la machine sont dans `targets/hosts/<name>/vars.nix`.
**C'est le seul fichier à renseigner.**

```bash
# Initialiser vars.nix interactivement
nix run .#init-host -- <host>
```

Ou éditer directement `targets/hosts/<host>/vars.nix` :

```nix
{
  system   = "x86_64-linux";   # plateforme NixOS du host
  username = "mikl";           # nom d'utilisateur système
  hostname = "<host>";         # doit correspondre à la clé nixosConfigurations
  disk     = "/dev/nvme0n1";   # vérifier avec lsblk sur la machine cible
  timezone = "Europe/Paris";
  locale   = "fr_FR.UTF-8";
}
```

Ces valeurs sont lues automatiquement par :
- `flake.nix` → système du host (`system`) + username pour Home Manager
- `targets/hosts/<host>/default.nix` → entrée machine
- `targets/hosts/<host>/config/*` → responsabilités machine si le host est découpé
- `targets/hosts/<host>/disko.nix` → disque cible quand le host est Anywhere-ready

Aucun autre fichier n'est à modifier.

### 3. Valider la configuration

```bash
nix run .#doctor -- --host <host>
```

Puis :

```bash
nix run .#validate-install -- <host>
```

Vérifications effectuées :
- outils locaux et structure du repo (`doctor`)
- `vars.nix` existe et tous les champs obligatoires sont définis
- Aucun placeholder `DEFINE_` dans les fichiers structurants
- Fichiers critiques présents (`default.nix`, `disko.nix`)
- `flake.nix` expose bien le host
- la composition Home Manager active (`home/targets/<host>.nix`) présent

### 3a. Installer via NixOS Anywhere

```bash
nix run .#install-anywhere -- <host> <IP-CIBLE>
```

Le système est installé et la machine redémarre.

### 3b. Installer manuellement

```bash
nix run .#install-manual -- --host <host>
```

Ce guide interactif accompagne le parcours manuel étape par étape.
Voir `docs/manual-install.md` pour la procédure complète.

### 4. Dotfiles — comment ils sont appliqués

Les dotfiles sont gérés par Home Manager, intégré dans le système NixOS.

**Lors de `nixos-rebuild switch`**, Home Manager s'applique automatiquement pour l'utilisateur défini dans `vars.nix`. Les symlinks dans `~/.config/` sont créés ou mis à jour.

Ajouter un dotfile :
1. Placer le fichier dans `dotfiles/<app>/`
2. L'enregistrer dans la composition Home Manager active (`home/targets/<host>.nix`) :
   ```nix
   home.file.".config/foot/foot.ini".source = ../dotfiles/terminal/foot.ini;
   ```
3. Rebuilder : `sudo nixos-rebuild switch --flake .#<host>`

### État V1 du parcours NixOS

- `main`, `laptop` et `gaming` ont maintenant un `disko.nix`
- leur parcours NixOS Anywhere est donc branché dans le repo
- le dernier paramètre volontairement local reste le vrai `disk` dans `targets/hosts/<host>/vars.nix`
- `ms-s1-max` reste sur un parcours manuel tant qu'aucun `disko.nix` n'est défini

### 5. Shell de développement

Entrer dans le devShell .NET :

```bash
nix develop .#dotnet
```

### 6. Vérifier l'installation

```bash
nix run .#post-install-check -- --host <host>
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
sudo nixos-rebuild switch --flake .#<host>
```

Workflow local complet avec Git :

```bash
cd ~/workstation
git pull --ff-only
git diff
sudo nixos-rebuild switch --flake .#$(hostname)
```

Voir `docs/update-workflow.md` pour le workflow complet (etat Git, commit, push, verification).

Pour le premier boot / premier login, voir `docs/first-boot.md`.

Ou à distance :

```bash
nixos-rebuild switch --flake github:mikl-974/workstation#<host> \
  --target-host <user>@<IP-MACHINE> --use-remote-sudo
```

## Ajouter une nouvelle machine

1. Créer `targets/hosts/<name>/default.nix` (copier depuis un host existant et adapter)
2. Créer `targets/hosts/<name>/disko.nix` si le host utilise disko
3. Initialiser la config :
   ```bash
   nix run .#init-host -- <name>
   ```
4. Ajouter la configuration dans `flake.nix` :
   ```nix
   <name> = mkHost {
     vars    = import ./targets/hosts/<name>/vars.nix;
     modules = [ disko.nixosModules.disko ./targets/hosts/<name>/default.nix ];
   };
   ```
5. Valider : `nix run .#validate-install -- <name>`
6. Installer via NixOS Anywhere : `nix run .#install-anywhere -- <name> <IP-CIBLE>`
