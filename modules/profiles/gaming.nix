{ ... }:
{
  # Gaming profile — assembles the gaming role for a desktop workstation host.
  # Import this profile in hosts that are dedicated to or include a gaming setup.
  #
  # Requires: modules/profiles/desktop-hyprland.nix (hardware.graphics, audio, compositor)
  imports = [
    ../roles/gaming.nix
  ];
}
