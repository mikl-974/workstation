{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    gitkraken
  ];
}
