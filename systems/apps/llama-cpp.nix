{ pkgs, ... }:
let
  modelsDir = "/var/lib/llama-cpp/models";
in
{
  environment.systemPackages = import ../../catalog/apps/llama-cpp.nix { inherit pkgs; };

  systemd.tmpfiles.rules = [
    "d /var/lib/llama-cpp 2775 root render -"
    "d ${modelsDir} 2775 root render -"
  ];
}
