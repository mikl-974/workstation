# Topology of `infra` targets that participate in the stack-deployment model.
#
# A target listed here is one of:
# - a NixOS host that can host stack instances (`kind = "nixosHost"`);
# - a Darwin host managed via nix-darwin (`kind = "darwinHost"`);
# - a cloud target provisioned via OpenTofu (`kind = "azureContainerApps"`,
#   `gcpCloudRun`, `cloudflareContainers`).
#
# The repo is intentionally centered on three concrete hosts only:
# - `mac-mini`   : Darwin workstation
# - `ms-s1-max`  : main NixOS workstation with local AI/dev tooling
# - `contabo`    : server-class VPS operated via Dokploy
#
# Cloud targets remain modeled separately because they are part of the
# deployment inventory, but they are not workstation/host entries.
{
  targets = {
    ms-s1-max = {
      kind    = "nixosHost";
      runtime = "nixos-systemd";
      address = "ms-s1-max";
      region  = "home-lan";
    };

    contabo = {
      kind    = "nixosHost";
      runtime = "dokploy";
      address = "contabo";
      region  = "eu-central";
    };

    mac-mini = {
      kind    = "darwinHost";
      runtime = "nix-darwin";
      address = "mac-mini";
      region  = "home-lan";
    };

    azure-ext = {
      kind    = "azureContainerApps";
      runtime = "tofu";
      address = "azure-ext";
      region  = "westeurope";
    };

    cloudflare-ext = {
      kind    = "cloudflareContainers";
      runtime = "tofu";
      address = "cloudflare-ext";
      region  = "global";
    };

    gcp-ext = {
      kind    = "gcpCloudRun";
      runtime = "tofu";
      address = "gcp-ext";
      region  = "europe-west1";
    };
  };
}
