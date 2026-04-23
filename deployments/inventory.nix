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
# Empty lists are intentional: `main`, `laptop` and `gaming` are pure NixOS
# workstations with no service stack. The cloud workspaces `cloudflare-ext` and
# `gcp-ext` are provisioned but currently host no stack instance.
let
  topology = import ./topology.nix;
in
{
  inherit (topology) targets;

  assignments = {
    main = [ ];
    laptop = [ ];
    gaming = [ ];

    ms-s1-max = [
      { stack = "ai-server"; instance = "ai-server-ms-s1-max"; role = "ollama"; }
    ];

    openclaw-vm = [
      { stack = "openclaw"; instance = "openclaw-main"; role = "gateway"; }
    ];

    contabo = [
      { stack = "homepage"; instance = "homepage-main"; role = "portal"; }
      { stack = "beszel"; instance = "beszel-hub"; role = "hub"; }
      { stack = "tsdproxy"; instance = "tsdproxy-contabo"; role = "edge-proxy"; }
      { stack = "kopia"; instance = "kopia-contabo"; role = "backup-client"; }
      { stack = "nextcloud"; instance = "nextcloud-qtalk"; role = "main"; }
    ];

    azure-ext = [
      { stack = "uptime-kuma"; instance = "uptime-kuma-public"; }
    ];

    cloudflare-ext = [ ];
    gcp-ext = [ ];
  };
}
