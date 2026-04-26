# Machine-specific variables for host `ms-s1-max`.
#
# `ms-s1-max` is the main NixOS workstation of this repo.
# Its local AI/dev capability map is declared in:
#   targets/hosts/ms-s1-max/config/capabilities.nix
{
  system   = "x86_64-linux";
  username = "mfo";            # primary interactive user / install operator
  hostname = "ms-s1-max";
  timezone = "Asia/Bangkok";
  locale   = "en_US.UTF-8";
}
