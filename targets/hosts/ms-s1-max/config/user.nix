{ ... }:
{
  imports = [ ../../../../systems/users/mfo.nix ];

  users.users.mfo.extraGroups = [ "render" ];
}
