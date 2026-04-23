{ ... }:
{
  imports = [ ../../../../modules/users/mikl.nix ];

  # docker is used on the laptop for local container workflows.
  users.users.mikl.extraGroups = [ "docker" ];
}
