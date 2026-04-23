# Machine-specific variables for host 'openclaw-vm'.
#
# Edit this file to configure this VM target.
# The VM context itself is modeled by the host imports, not by vars.nix.
{
  system   = "x86_64-linux";     # NixOS platform
  username = "openclaw";         # operator account for this VM
  hostname = "openclaw-vm";      # hostname — matches nixosConfigurations key in flake.nix
  disk     = "/dev/DEFINE_DISK"; # target disk for disko / NixOS Anywhere — often /dev/vda in a VM
  timezone = "Europe/Paris";     # see: timedatectl list-timezones
  locale   = "fr_FR.UTF-8";      # system locale
}
