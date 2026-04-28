{ hostVars, ... }:
{
  imports = [
    ../../../../systems/darwin/base.nix
    ../../../../systems/darwin/homebrew.nix
    ./user.nix
    ./capabilities.nix
  ];

  networking.hostName = hostVars.hostname;
  time.timeZone = hostVars.timezone;

  system.defaults = {
    dock.autohide = true;
  };
}
