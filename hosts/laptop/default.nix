{ ... }:
{
  imports = [
    ../../profiles/desktop-hyprland.nix
    ../../profiles/dev.nix
    ../../profiles/networking.nix
  ];

  networking.hostName = "laptop";
  system.stateVersion = "24.11";
}
