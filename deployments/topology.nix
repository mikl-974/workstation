# Topology of `infra` targets that participate in the stack-deployment model.
#
# A target listed here is one of:
# - a NixOS host that can host stack instances (`kind = "nixosHost"`);
# - a Darwin host managed via nix-darwin (`kind = "darwinHost"`);
# - a cloud target provisioned via OpenTofu (`kind = "azureContainerApps"`,
#   `gcpCloudRun`, `cloudflareContainers`).
#
# `main`, `laptop` and `gaming` are listed but currently host no stack:
# they remain pure NixOS workstations. They are kept in the topology so
# the validation can also detect mistakes in their inventory entries.
#
# `ms-s1-max` is a workstation that additionally hosts the local AI server
# stack (`ai-server`). `openclaw-vm` is a service VM hosting the `openclaw`
# gateway. `contabo` is a server-class VPS operated via Dokploy.
#
# `mac-mini` is the Darwin workstation managed via nix-darwin. It currently
# hosts no stack but is modeled here for completeness and future assignments.
#
# `homelab` is a local KVM VM dedicated to self-hosted services.
# `sandbox` is a local KVM VM for testing apps before deployment.
{
  targets = {
    main = {
      kind    = "nixosHost";
      runtime = "nixos-systemd";
      address = "main";
      region  = "home-lan";
    };

    laptop = {
      kind    = "nixosHost";
      runtime = "nixos-systemd";
      address = "laptop";
      region  = "home-lan";
    };

    gaming = {
      kind    = "nixosHost";
      runtime = "nixos-systemd";
      address = "gaming";
      region  = "home-lan";
    };

    ms-s1-max = {
      kind    = "nixosHost";
      runtime = "nixos-systemd";
      address = "ms-s1-max";
      region  = "home-lan";
    };

    openclaw-vm = {
      kind    = "nixosHost";
      runtime = "nixos-systemd";
      address = "openclaw-vm";
      region  = "home-lan";
    };

    homelab = {
      kind    = "nixosHost";
      runtime = "nixos-systemd";
      address = "homelab";
      region  = "home-lan";
    };

    sandbox = {
      kind    = "nixosHost";
      runtime = "nixos-systemd";
      address = "sandbox";
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
