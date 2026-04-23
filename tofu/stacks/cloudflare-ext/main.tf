# Workspace skeleton for the `cloudflare-ext` cloud target
# (kind = "cloudflareContainers" in deployments/topology.nix).
#
# The provider is declared but credentials are NOT committed: configure
# `CLOUDFLARE_API_TOKEN` (or `CLOUDFLARE_API_KEY` + `CLOUDFLARE_EMAIL`)
# in the operator's environment before `tofu plan` / `tofu apply`.
#
# No resources are declared yet: no stack from this repo is currently
# assigned to `cloudflare-ext` in `deployments/inventory.nix`. The workspace
# is kept here so the convention is uniform across the three cloud targets.
provider "cloudflare" {}
