{ ... }:
{
  imports = [ ../../../../modules/users/mfo.nix ];

  # docker is used on the laptop for local container workflows.
  users.users.mfo.extraGroups = [ "docker" ];
}
