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
  environment.systemPackages = with pkgs; [
    # Daily audio mixer for PipeWire / PulseAudio compatibility
    pavucontrol

    # Advanced NetworkManager connection editor — useful for Wi-Fi/VPN profiles
    nm-connection-editor

    # Display brightness helper used by desktops, keybinds or scripts
    brightnessctl

    # Media player control helper used by desktop keybinds and scripts
    playerctl
  ];
}
