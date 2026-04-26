# OpenTofu

OpenTofu reste utilise pour les targets cloud du modele de deploiement :

- `azure-ext`
- `cloudflare-ext`
- `gcp-ext`

Chaque workspace vit dans `tofu/stacks/<target>/`.

## Workflow

```bash
nix run .#validate-inventory
nix run .#plan-azure-ext
nix run .#deploy-azure-ext
```

Le placement applicatif reste dans `deployments/inventory.nix`.
OpenTofu ne devient jamais la source de verite des stacks.
