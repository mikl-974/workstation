# Topology of `infra` targets that participate in the stack-deployment model.
#
# A target listed here is one of:
# - a NixOS host that can host stack instances (`kind = "nixosHost"`);
# - a cloud target provisioned via OpenTofu (`kind = "azureContainerApps"`,
#   `gcpCloudRun`, `cloudflareContainers`).
#
# Workstations (`main`, `laptop`, `gaming`) are listed but currently host no
# stack: they remain pure NixOS workstations. They are kept in the topology so
# the validation can also detect mistakes in their inventory entries.
#
# The Darwin host `macmini` is intentionally NOT modeled here: it is not a
# stack-bearing target in this repo.
#
# `contabo` and the cloud targets land in subsequent migration lots (C3/C4).
{
  targets = {
    main = {
      kind = "nixosHost";
      runtime = "nixos-systemd";
      address = "main";
      region = "home-lan";
    };

    laptop = {
      kind = "nixosHost";
      runtime = "nixos-systemd";
      address = "laptop";
      region = "home-lan";
    };

    gaming = {
      kind = "nixosHost";
      runtime = "nixos-systemd";
      address = "gaming";
      region = "home-lan";
    };

    ms-s1-max = {
      kind = "nixosHost";
      runtime = "nixos-systemd";
      address = "ms-s1-max";
      region = "home-lan";
    };

    openclaw-vm = {
      kind = "nixosHost";
      runtime = "nixos-systemd";
      address = "openclaw-vm";
      region = "home-lan";
    };
  };
}
