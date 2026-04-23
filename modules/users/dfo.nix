# NixOS system user for Delphine Folio (dfo).
# Used on ms-s1-max. Password is managed via per-host sops secret.
{ ... }:
{
  users.users.dfo = {
    isNormalUser = true;
    description  = "Delphine Folio";
    extraGroups  = [ "wheel" "networkmanager" "video" "audio" ];
  };
}
