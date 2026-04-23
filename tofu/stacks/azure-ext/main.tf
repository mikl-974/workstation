# Workspace skeleton for the `azure-ext` cloud target
# (kind = "azureContainerApps" in deployments/topology.nix).
#
# The provider is declared but credentials are NOT committed: configure them
# via the standard `azurerm` provider environment variables (ARM_*) or via a
# `terraform.tfvars` file kept out of git, before `tofu plan` / `tofu apply`.
#
# Resource declarations are intentionally absent: this stack will be filled
# in when its first assignment in `deployments/inventory.nix` is rolled out
# (currently `uptime-kuma-public`). Until then, the workspace stays empty so
# `tofu plan` only verifies the provider configuration.
provider "azurerm" {
  features {}
}
