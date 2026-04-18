# Installation via NixOS Anywhere

Ce document decrit comment installer la machine `main` (ou toute autre machine NixOS de ce repo) via [NixOS Anywhere](https://github.com/nix-community/nixos-anywhere).

NixOS Anywhere permet de provisionner une machine NixOS a distance (ou en live ISO) en une seule commande, en utilisant la configuration declaree dans ce flake.

## Prerequis

Sur la machine hote (depuis laquelle tu lances l'installation) :

- Nix avec flakes active
- `nixos-anywhere` disponible (`nix run nixpkgs#nixos-anywhere -- ...`)
- Acces SSH a la machine cible (live ISO ou machine existante)

Sur la machine cible :

- Boot depuis un live ISO NixOS (ou systeme existant avec SSH actif)
- SSH accessible depuis la machine hote

## Preparer la configuration

### 1. Definir le disque cible

Ouvrir `hosts/main/disko.nix` et remplacer `/dev/sda` par le disque reel de la machine cible :

```nix
device = "/dev/nvme0n1";  # exemple pour un NVMe
```

Verifier le disque cible sur la machine : `lsblk`

### 2. Definir l'utilisateur

Dans `flake.nix`, remplacer `"user"` par le nom d'utilisateur reel :

```nix
home-manager.users.mikl = import ./home/default.nix;
```

Ajouter la definition de l'utilisateur dans la configuration host si elle n'existe pas encore :

```nix
users.users.mikl = {
  isNormalUser = true;
  extraGroups = [ "wheel" "docker" "networkmanager" ];
};
```

### 3. Ajouter une cle SSH autorisee (recommande)

Dans `hosts/main/default.nix` ou un profil :

```nix
users.users.mikl.openssh.authorizedKeys.keys = [
  "ssh-ed25519 AAAA... cle-publique"
];
```

## Lancer l'installation

```bash
nix run nixpkgs#nixos-anywhere -- \
  --flake .#main \
  root@<IP-MACHINE-CIBLE>
```

NixOS Anywhere va :
1. Partitionner et formater les disques selon `disko.nix`
2. Monter les partitions
3. Generer la configuration hardware
4. Installer NixOS
5. Redemarrer la machine

## Apres l'installation

Apres le premier boot :

```bash
# Reconnexion SSH avec le nouvel utilisateur
ssh mikl@<IP-MACHINE>

# Rebuilder si necessaire
sudo nixos-rebuild switch --flake github:mikl-974/workstation#main
```

Pour appliquer la configuration Home Manager (dotfiles) :

```bash
# Depuis la machine ou depuis la machine hote avec home-manager integre
# (si home-manager est integre dans le systeme NixOS, il s'applique automatiquement
# lors de nixos-rebuild switch)
```

Voir `docs/bootstrap.md` pour le workflow complet post-installation.

## Reconstruire la machine

```bash
sudo nixos-rebuild switch --flake .#main
# ou depuis n'importe ou avec le flake GitHub :
sudo nixos-rebuild switch --flake github:mikl-974/workstation#main
```

## Structure des fichiers pertinents

```
flake.nix               inputs disko + home-manager, nixosConfigurations.main
hosts/main/default.nix  configuration du host (boot, hostname, profils)
hosts/main/disko.nix    layout disque (GPT + EFI + btrfs avec subvolumes)
profiles/               profils assembles par le host
modules/                modules Nix
home/default.nix        configuration Home Manager (dotfiles, programmes)
dotfiles/               fichiers de configuration bruts
```
