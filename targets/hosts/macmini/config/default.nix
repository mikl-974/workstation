{ hostVars, ... }:
{
  imports = [
    ../../../../modules/darwin/base.nix
    ../../../../modules/darwin/homebrew.nix
    ./user.nix
    ./apps.nix
    ./networking.nix
  ];

  networking.hostName = hostVars.hostname;

  system.defaults = {
    dock.autohide = true;
  };
}
