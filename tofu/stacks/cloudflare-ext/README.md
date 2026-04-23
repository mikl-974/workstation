# tofu/stacks/cloudflare-ext/

OpenTofu workspace for the `cloudflare-ext` cloud target.

- **Kind** : `cloudflareContainers`

## Responsibility

This workspace owns Cloudflare-side resources required to host stack
instances assigned to `cloudflare-ext` in `deployments/inventory.nix`.

No stack from this repo is currently assigned to `cloudflare-ext`. The
workspace exists so the convention is uniform across the three cloud
targets (`azure-ext`, `cloudflare-ext`, `gcp-ext`).

## Credentials

Set one of the following in the operator's environment:

- `CLOUDFLARE_API_TOKEN` (recommended)
- `CLOUDFLARE_API_KEY` + `CLOUDFLARE_EMAIL`

`CLOUDFLARE_ACCOUNT_ID` is read from `var.account_id` (`TF_VAR_account_id`).

## State

Local state by default. Switch to a remote backend (e.g. R2) once real
resources are declared. Do NOT commit `*.tfstate`.

## Operating

- `nix run .#plan-cloudflare-ext`
- `nix run .#deploy-cloudflare-ext`
