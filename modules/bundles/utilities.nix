{ pkgs, ... }:
{
  # Desktop utilities — user-facing workstation tools.
  #
  # Scope:
  #   - small daily desktop helpers
  #   - GUI tools launched by the user
  #   - no system service logic here
  #
  # Connectivity/system integration (Bluetooth stack, NetworkManager applet,
  # Logitech udev rules) lives in modules/desktop/connectivity.nix.
  environment.systemPackages = import ../../catalog/bundles/utilities.nix { inherit pkgs; };
}
