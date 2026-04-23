{ pkgs, ... }:
{
  # Gaming applications — system packages for a desktop gaming workstation.
  #
  # Steam itself is configured via programs.steam in modules/roles/gaming.nix
  # because it requires a NixOS-native option (not just a package install).
  #
  # Battle.net: no native Linux client exists. The recommended approach is
  # Bottles (Flatpak-friendly Wine environment manager) or Lutris with a
  # Battle.net installer script. Both tools are included below.
  environment.systemPackages = with pkgs; [
    # In-game performance overlay — shows FPS, GPU, CPU, frametime
    mangohud

    # Micro-compositor for games — resolution scaling, FPS cap, HDR emulation
    gamescope

    # Multi-platform game launcher — GOG, Epic, itch.io, Battle.net via scripts
    lutris

    # 64+32-bit Wine build — required by Lutris and other Wine-based launchers
    wineWow64

    # Wine dependency installer — installs VC runtimes, DirectX, codecs, etc.
    winetricks

    # Sandboxed Wine environment manager — recommended path for Battle.net
    # After enabling: open Bottles, create a Gaming bottle, install Battle.net
    bottles
  ];
}
