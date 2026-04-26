{ pkgs, ... }:
{
  environment.systemPackages = with pkgs.rocmPackages; [
    rocm-runtime
    rocminfo
    rocm-smi
    amdsmi
  ];
}
