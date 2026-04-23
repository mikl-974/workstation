# targets/hosts/

Machines réelles gérées par ce repo.

Chaque dossier contient la vérité d’une machine donnée.

Une VM ne change pas cette règle :
- on ne crée pas de host abstrait `vm`
- on garde un host concret
- on lui ajoute le profil `modules/profiles/virtual-machine.nix` si nécessaire

## Structure typique

### NixOS
- `vars.nix` : variables machine opératoires
- `default.nix` : entrée du host
- `config/` : responsabilités machine lisibles quand le host le justifie
- `disko.nix` : layout disque seulement si le host est réellement prévu pour NixOS Anywhere
- `modules/profiles/virtual-machine.nix` : profil à importer si ce host concret est une VM

### Darwin
- `vars.nix` : variables machine opératoires
- `default.nix` : entrée du host
- `config/` : responsabilités machine Darwin

## Exemple concret

`openclaw-vm` est maintenant un exemple réel de ce modèle :
- host concret : `targets/hosts/openclaw-vm/`
- profil VM : `modules/profiles/virtual-machine.nix`
- stack portée : `stacks/openclaw/`

Un host VM reste un host concret ; seul son import change :

```nix
{ hostVars, ... }:
{
  imports = [
    ../../../../modules/profiles/networking.nix
    ../../../../modules/profiles/virtual-machine.nix
    ../../../../stacks/openclaw/default.nix
    ./user.nix
  ];

  networking.hostName = hostVars.hostname;
}
```

Le repo versionne maintenant un vrai target VM concret : `openclaw-vm`.
