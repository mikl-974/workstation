# targets/

Cibles concrètes portées par le repo `infra`.

## Structure

- `targets/hosts/` = machines réelles
- `targets/README.md` = frontière et conventions

## Règle

`targets/` contient uniquement :
- la réalité machine
- la config machine
- le layout disque si nécessaire côté NixOS
- la logique de bootstrap / installation liée à cette machine

Il ne contient jamais :
- des briques réutilisables
- des stacks applicatives génériques
- de la composition Home Manager utilisateur
- un faux host abstrait "vm"

## NixOS et Darwin

`targets/hosts/` peut maintenant contenir :
- un host NixOS exposé via `nixosConfigurations.<name>`
- un host Darwin exposé via `darwinConfigurations.<name>`

Le target Darwin reste une machine concrète, pas un faux target NixOS.

Le même principe vaut pour les VMs :
- un host VM reste un host concret dans `targets/hosts/`
- le fait "tourne dans une VM" se modélise via `modules/profiles/virtual-machine.nix`
- ce n'est pas un sous-dossier ou un type de host séparé

## Hosts actuels

### NixOS
- `main`
- `laptop`
- `gaming`
- `openclaw-vm`
- `ms-s1-max`

### Darwin
- `macmini`

## Ajouter une machine

### NixOS
1. créer `targets/hosts/<name>/vars.nix`
2. créer `targets/hosts/<name>/default.nix`
3. importer `modules/profiles/virtual-machine.nix` si ce host concret est une VM
4. ajouter `disko.nix` si le host doit être installable via NixOS Anywhere
5. exposer la machine dans `flake.nix`

Exemple concret dans le repo :
- `openclaw-vm` = host VM concret dédié à la future stack OpenClaw

### Darwin
1. créer `targets/hosts/<name>/vars.nix`
2. créer `targets/hosts/<name>/default.nix`
3. créer `targets/hosts/<name>/config/` pour les responsabilités machine
4. exposer la machine dans `flake.nix` via `darwinConfigurations.<name>`
