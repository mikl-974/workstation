{ pkgs, ... }:
{
  programs.bash.completion.enable = true;
  environment.shells = [ pkgs.bashInteractive ];
  users.defaultUserShell = pkgs.bashInteractive;
}
