# Repo structure

## Vue d'ensemble

- `systems/` : briques reutilisables
- `targets/hosts/` : machines concretes
- `targets/vms/` : definitions de VM portables
- `catalog/` : catalogue mutualise de paquets et bundles
- `home/` : composition Home Manager
- `dotfiles/` : fichiers applicatifs
- `stacks/` : contrats de services deployables
- `deployments/` : topologie + placement
- `secrets/` : secrets chiffres
- `tofu/` : cibles cloud OpenTofu
- `scripts/` : orchestration

## Ce qu'il faut modifier en premier selon le besoin

### Changer une machine

Modifier `targets/hosts/<host>/`.

Exemples :

- `targets/hosts/ms-s1-max/config/capabilities.nix`
- `targets/hosts/contabo/default.nix`
- `targets/hosts/mac-mini/config/capabilities.nix`

### Changer une VM portable

Modifier `targets/vms/<vm>/`.

Ce dossier doit decrire la VM elle-meme, pas le serveur physique qui
l'heberge.

### Changer une app ou un bundle reutilisable

Modifier :

- `catalog/apps/<app>.nix` ou `catalog/bundles/<bundle>.nix` si le changement porte sur une liste de paquets mutualisee
- `systems/apps/<app>.nix` pour une brique atomique
- `systems/bundles/<bundle>.nix` pour un lot coherent
- `systems/profiles/<profile>.nix` seulement si ce lot merite un vrai point d'entree reutilisable

### Changer la composition utilisateur

Modifier `home/targets/<host>.nix`, puis au besoin `home/users/` ou `home/roles/`.

### Changer des dotfiles

Modifier `dotfiles/`, puis verifier qui les consomme via `home/`.

### Changer un service deployable

Modifier :

- le contrat dans `stacks/<stack>/stack.nix`
- le placement dans `deployments/inventory.nix`

### Changer un secret

Modifier `secrets/...` via SOPS.

## Point important

`ms-s1-max` ne passe plus par un profil "IA vague".
Le mapping logiciel local est volontairement visible dans :

- `targets/hosts/ms-s1-max/config/capabilities.nix`

C'est le fichier de reference pour ajouter, retirer ou auditer les outils
de travail de cette machine.

Cette regle n'empeche pas les bundles utiles.
Exemple :

- `systems/apps/lutris.nix` peut etre importe seul
- `systems/profiles/gaming.nix` peut composer le pack gaming complet
- `systems/apps/rider.nix` peut etre importe seul
- `systems/bundles/dev-workstation.nix` peut composer le pack dev
