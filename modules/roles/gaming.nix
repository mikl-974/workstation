{ ... }:
{
  # Gaming role — desktop gaming environment for a user workstation.
  #
  # This role is:
  #   - for user workstations, NOT servers
  #   - dependent on a desktop environment (modules/profiles/desktop-hyprland.nix)
  #   - not suitable for headless or server contexts
  #
  # Compose this role via modules/profiles/gaming.nix in a host that already imports
  # modules/profiles/desktop-hyprland.nix.

  imports = [
    ../apps/gaming.nix
  ];

  # Steam: NixOS-native integration with Proton and hardware support.
  # gamescopeSession allows launching Steam directly in a gamescope compositor.
  programs.steam = {
    enable = true;
    # Proton-GE and other compatibility tools are managed from within Steam.
    # remotePlay and dedicatedServer firewall rules are opt-in per host.
    remotePlay.openFirewall    = false;
    dedicatedServer.openFirewall = false;
    gamescopeSession.enable    = true;
  };

  # Gamemode: allows games to request performance governor and CPU/GPU tuning.
  # The gamemode group is created automatically; PAM handles privilege escalation.
  programs.gamemode.enable = true;
}
