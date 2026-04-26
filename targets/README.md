# targets/

Cibles concretes du repo.

## Sous-dossiers

- `targets/hosts/` : machines physiques ou identites de machines concretes
- `targets/vms/` : definitions de VM portables

## Hosts actifs

### NixOS

- `ms-s1-max`
- `contabo`

### Darwin

- `mac-mini`

## Regle

Un host concret vit dans `targets/hosts/<name>/`.
La machine decide ce qu'elle embarque.

Une VM portable ne vit pas dans `targets/hosts/`.
Elle doit vivre dans `targets/vms/<name>/` pour rester decouplee du materiel
qui l'heberge.

En particulier :

- `ms-s1-max` mappe explicitement ses outils locaux dans `config/capabilities.nix`
- `contabo` mappe explicitement sa base serveur dans `default.nix`
- `mac-mini` mappe explicitement ses apps Nix, casks et apps MAS dans `config/capabilities.nix`
