{ pkgs, ... }:
{
  imports = [
    ../modules/apps/editors.nix
  ];

  environment.systemPackages = with pkgs; [
    git
    curl
    jq
  ];
}
