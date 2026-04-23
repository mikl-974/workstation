# tofu/stacks/azure-ext/

OpenTofu workspace for the `azure-ext` cloud target.

- **Kind** : `azureContainerApps`
- **Region** : `westeurope` (overridable via `var.location`)

## Responsibility

This workspace owns the Azure-side resources required to host stack
instances assigned to `azure-ext` in `deployments/inventory.nix`. Currently
that is `uptime-kuma-public`.

What this workspace does NOT own:

- the stack contracts (live in `stacks/<stack>/stack.nix`);
- the placement (lives in `deployments/inventory.nix`);
- credentials (provisioned out-of-band, never in git).

## Credentials

Use the standard `azurerm` provider environment variables:

- `ARM_SUBSCRIPTION_ID`
- `ARM_TENANT_ID`
- `ARM_CLIENT_ID`
- `ARM_CLIENT_SECRET`

Or any other [`azurerm` authentication method](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs).

## State

Local state by default. Switch to a remote backend (e.g. Azure Storage) by
adding a `backend.tf` once a real resource exists. Do NOT commit `*.tfstate`.

## Operating

- `nix run .#plan-azure-ext`
- `nix run .#deploy-azure-ext`
