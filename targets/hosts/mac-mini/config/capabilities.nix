{ ... }:
{
  # Host-local capability map for `mac-mini`.
  #
  # This file is the authoritative place to answer:
  # "What does this machine have?"
  imports = [
    ./nix-apps.nix
    ./casks.nix
    ./mas-apps.nix
  ];
}
