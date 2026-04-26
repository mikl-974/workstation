{ ... }:
{
  imports = [ ../../../../modules/users/mfo.nix ];

  users.users.mfo.extraGroups = [ "render" ];
}
