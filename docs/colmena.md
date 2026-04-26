# Colmena

Colmena ne sert ici qu'a `contabo`.

## Pourquoi

- `contabo` est un serveur pousse a distance
- `ms-s1-max` est gere localement avec `nixos-rebuild`
- `mac-mini` est un host Darwin

## Commandes

```bash
nix run .#deploy-contabo
nix run .#deploy-all-hosts
```

Actuellement, `deploy-all-hosts` revient a deployer `contabo`.
