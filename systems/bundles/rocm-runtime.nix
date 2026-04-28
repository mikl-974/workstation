{ pkgs, ... }:
{
  environment.systemPackages = import ../../catalog/bundles/rocm-runtime.nix { inherit pkgs; };
}
