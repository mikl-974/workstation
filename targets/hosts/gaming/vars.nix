# Machine-specific variables for host 'gaming'.
#
# Edit this file to configure this machine.
# No other file needs to be modified for installation.
#
# After editing, validate before installing:
#   nix run .#validate-install -- gaming
#
# To generate this file interactively:
#   nix run .#init-host -- gaming
{
  system   = "x86_64-linux";    # NixOS platform
  username = "mikl";            # primary interactive user of the gaming workstation
  hostname = "gaming";          # hostname — matches nixosConfigurations key in flake.nix
  disk     = "/dev/DEFINE_DISK"; # target disk for disko / NixOS Anywhere — confirm with `lsblk` on the target
  timezone = "Asia/Bangkok";    # see: timedatectl list-timezones
  locale   = "en_US.UTF-8";    # system locale
}
