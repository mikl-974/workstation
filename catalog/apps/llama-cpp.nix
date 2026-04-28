{ pkgs }:
with pkgs; [
  llama-cpp-rocm
  python3Packages.huggingface-hub
]
