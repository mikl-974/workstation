# Placement of stack instances onto declared targets.
#
# Rules enforced by `./validation.nix`:
# - every target referenced here must exist in `./topology.nix`;
# - every stack referenced must exist in `stacks/<name>/stack.nix`;
# - the stack's `supportedTargets` must include the target's `kind`;
# - `singleton` stacks may appear at most once across the whole inventory;
# - `perTarget` stacks may appear at most once per target;
# - if `role` is provided, it must be declared by the stack contract;
# - instance names must be unique within a target.
#
# `ms-s1-max` is intentionally empty here: local AI/dev capabilities are mapped
# directly in the host configuration, not modeled as deployable stacks.
#
# The cloud workspaces `cloudflare-ext` and `gcp-ext` are provisioned but
# currently host no stack instance.
let
  topology = import ./topology.nix;
in
{
  inherit (topology) targets;

  assignments = {
    ms-s1-max = [ ];

    contabo = [
      { stack = "homepage"; instance = "homepage-main"; role = "portal"; }
      { stack = "beszel"; instance = "beszel-hub"; role = "hub"; }
      { stack = "tsdproxy"; instance = "tsdproxy-contabo"; role = "edge-proxy"; }
      { stack = "kopia"; instance = "kopia-contabo"; role = "backup-client"; }
      { stack = "nextcloud"; instance = "nextcloud-qtalk"; role = "main"; }
    ];

    mac-mini = [ ];

    azure-ext = [
      { stack = "uptime-kuma"; instance = "uptime-kuma-public"; }
    ];

    cloudflare-ext = [ ];
    gcp-ext = [ ];
  };
}
