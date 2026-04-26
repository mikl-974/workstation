# First boot

## `ms-s1-max`

Verifier :

- session Hyprland disponible
- user `mfo` present
- `ollama` actif
- `rocminfo` et `rocm-smi` disponibles
- `ollama`, `llama-cli`, `opencode-desktop`, `rider`, `webstorm`, `code` dans le PATH

Commande utile :

```bash
nix run .#post-install-check -- --host ms-s1-max
```

## `contabo`

Verifier :

- SSH admin operationnel
- `tailscaled` actif
- `dokploy` operationnel

Commande utile :

```bash
nix run .#post-install-check -- --host contabo
```
