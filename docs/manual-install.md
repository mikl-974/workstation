# Installation manuelle

Le dispatcher :

```bash
nix run .#install-manual -- <host>
```

Decide entre :

- `install-from-live`
- `reconfigure`

## Cas utile aujourd'hui

### `ms-s1-max`

Host principal sans `disko.nix`.
La voie normale est :

```bash
nix run .#install-manual -- ms-s1-max
```

ou, sur un systeme deja installe :

```bash
nix run .#reconfigure -- ms-s1-max
```
