{ hostVars, ... }:
{
  homebrew = {
    enable = true;
    onActivation.cleanup = "zap";
  };

  nix-homebrew = {
    enable = true;
    enableRosetta = true;
    user = hostVars.username;
    autoMigrate = true;
  };
}
