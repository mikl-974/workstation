# targets/hosts/

Machines concretes versionnees par le repo.

Ce dossier ne contient pas de definitions de VM portables.
Une VM qui peut etre deployee sur plusieurs machines physiques doit vivre dans
`targets/vms/`.

## Actifs

- `mac-mini/`
- `ms-s1-max/`
- `contabo/`

## Convention

### `ms-s1-max`

- `default.nix` delegue a `config/default.nix`
- `config/capabilities.nix` est la carte logicielle du poste

### `contabo`

- `default.nix` declare la base serveur et Dokploy
- `disko.nix` declare le layout d'installation

### `mac-mini`

- `config/capabilities.nix` est la carte logicielle du host
- `config/nix-apps.nix` regroupe les apps Nix
- `config/casks.nix` regroupe les casks Homebrew
- `config/mas-apps.nix` regroupe les apps Mac App Store
