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
# The empty lists for workstations are intentional: those hosts currently
# carry no service stack — they remain pure NixOS workstations.
let
  topology = import ./topology.nix;
in
{
  inherit (topology) targets;

  assignments = {
    main = [ ];
    laptop = [ ];
    gaming = [ ];
    ms-s1-max = [ ];

    openclaw-vm = [
      { stack = "openclaw"; instance = "openclaw-main"; role = "gateway"; }
    ];
  };
}
