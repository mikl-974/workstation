{ pkgs, ... }:
{
  imports = [
    ./dev.nix
  ];

  environment.systemPackages = with pkgs; [
    git
    curl
    jq
  ];
}
