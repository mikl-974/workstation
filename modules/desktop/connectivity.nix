{ ... }:
{
  # Local workstation connectivity and device integration.
  #
  # Scope:
  #   - Wi-Fi / Ethernet desktop management via NetworkManager
  #   - Bluetooth system stack + desktop manager
  #   - Logitech receiver/device integration for Solaar
  #
  # This remains in workstation because these are user-workstation concerns:
  # applets, desktop pairing flows, and local device management.

  # Local desktop networking
  networking.networkmanager.enable = true;
  programs.nm-applet.enable = true;

  # Bluetooth stack + desktop manager
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  services.blueman.enable = true;

  # Logitech wireless devices + Solaar GUI
  # Kept here intentionally: Solaar requires the NixOS hardware module for
  # proper udev rules and graphical integration, not just a package install.
  hardware.logitech.wireless.enable = true;
  hardware.logitech.wireless.enableGraphical = true;
}
