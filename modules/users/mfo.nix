# NixOS system user for Mickaël Folio (mfo).
#
# Base declaration: standard workstation groups. Hosts that need extra groups
# (e.g. docker) or a sops-managed password add them on top — the NixOS module
# system merges list options across declarations.
#
# Password: set hashedPasswordFile per-host via sops (see modules/users/root.nix
# for the pattern). On workstations without sops, the user can set a password
# interactively after install with `passwd mfo`.
{ ... }:
let
  keys = import ./authorized-keys.nix;
in
{
  users.users.mfo = {
    isNormalUser = true;
    description  = "Mickaël Folio";
    extraGroups  = [ "wheel" "networkmanager" "video" "audio" ];
    openssh.authorizedKeys.keys = keys.mfo;
  };
}
