{ pkgs }:
with pkgs.rocmPackages; [
  rocm-runtime
  rocminfo
  rocm-smi
  amdsmi
]
