{ pkgs, ... }:
{
  imports = [
    ../apps/editors.nix
    ../apps/dev.nix
    ../containers/podman.nix
  ];

  workstation.containers.podman.enable = true;

  environment.systemPackages = with pkgs; [
    git
    curl
    jq
  ];
}
