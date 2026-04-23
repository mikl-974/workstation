# NixOS system user for mikl (gaming / laptop workstations).
# Password set interactively after install with `passwd mikl`.
{ ... }:
{
  users.users.mikl = {
    isNormalUser = true;
    description  = "Mickaël";
    extraGroups  = [ "wheel" "networkmanager" "video" "audio" ];
  };
}
