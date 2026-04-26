# Profils

## Principe

Un profil reste une brique de composition reutilisable.
Il ne doit pas cacher la cartographie logicielle d'un host quand cette
cartographie doit rester evidente.

## Profils encore utiles

### `modules/profiles/workstation-common.nix`

Base commune pour une workstation NixOS :

- desktop Hyprland
- SSH
- reseau
- theming
- boot EFI

### `modules/profiles/server.nix`

Base commune pour un serveur NixOS :

- SSH
- firewall
- Tailscale
- user admin

### `modules/profiles/gaming.nix`

Profil optionnel de bundle.

Il a du sens uniquement parce qu'un setup gaming est souvent consomme comme
un tout coherent.

Mais le bundle ne remplace pas les briques atomiques :

- `modules/apps/lutris.nix`
- `modules/apps/steam.nix`
- `modules/apps/gaming.nix`

## Decision de recentrage

Les profils trop vagues ou sans usage reel ont ete retires :

- pas de profil GNOME
- pas de profil VM
- pas de profil IA generique

La logique veut maintenant que :

- une app seule reste installable seule quand c'est utile
- un bundle existe quand plusieurs apps forment un lot coherent
- le profil exprime une base reutilisable
- le host exprime ses capacites concretes

Exemple :

- `ms-s1-max` importe `workstation-common`
- `ms-s1-max` declare ses outils IA/dev dans `config/capabilities.nix`
- ces outils peuvent venir de bundles reutilisables comme `modules/apps/dev-workstation.nix` ou `modules/apps/ai-local.nix`
- un futur host gaming pourrait importer `modules/profiles/gaming.nix`
- un host non gaming pourrait n'importer que `modules/apps/lutris.nix`
