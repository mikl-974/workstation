{ pkgs, llamaCppPackage ? pkgs.llama-cpp }:
with pkgs; [
  llamaCppPackage
  python3Packages.huggingface-hub
]
