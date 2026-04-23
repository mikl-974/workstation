# tofu/

OpenTofu source-of-truth for cloud-side targets.

This directory only governs targets whose `runtime = "tofu"` in
`deployments/topology.nix`. NixOS hosts are NOT managed from here — they live
in `targets/hosts/<name>/` and are deployed via Colmena.

## Structure

- `tofu/stacks/<stack>/` : one OpenTofu workspace per cloud target. Each
  workspace declares its providers, variables and resources, and is the only
  place where `tofu plan` / `tofu apply` is invoked.
- `tofu/modules/` : reusable Terraform/OpenTofu modules shared across stacks.
  Empty today; modules land here when at least two stacks would reuse them.

## Convention

Each `tofu/stacks/<stack>/` must contain at minimum:

- `versions.tf` : OpenTofu and provider version constraints.
- `variables.tf` : inputs of the workspace (region, project id, tags, ...).
- `main.tf` : the resources of the workspace.
- `README.md` : operational notes (where credentials come from, what the
  workspace owns, what it does NOT own).

State management (local vs remote backend) is documented per-stack in its
`README.md`. No state file is committed.

## Cloud targets

The cloud targets currently declared in this repo are:

| Target | Kind | Workspace |
|---|---|---|
| `azure-ext` | `azureContainerApps` | `tofu/stacks/azure-ext/` |
| `cloudflare-ext` | `cloudflareContainers` | `tofu/stacks/cloudflare-ext/` |
| `gcp-ext` | `gcpCloudRun` | `tofu/stacks/gcp-ext/` |

A target listed here only becomes operational when:

1. its workspace contains real resource declarations and matching credentials
   are provisioned out-of-band; AND
2. `deployments/inventory.nix` assigns at least one stack instance to it; AND
3. `nix run .#validate-inventory` succeeds.

## Operating

- `nix run .#plan-azure-ext` (resp. `cloudflare-ext`, `gcp-ext`) — `tofu plan`.
- `nix run .#deploy-azure-ext` (resp. `cloudflare-ext`, `gcp-ext`) — `tofu apply`.

The thin shell scripts behind those apps live in `scripts/tofu-plan.sh` and
`scripts/tofu-apply.sh`. They `cd` into the workspace and call OpenTofu
without any extra logic — the source of truth stays in the workspace itself.
