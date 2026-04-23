{ ... }:
{
  imports = [ ../../../../modules/users/mfo.nix ];

  # docker is used on the main workstation for local container workflows.
  users.users.mfo.extraGroups = [ "docker" ];
}
