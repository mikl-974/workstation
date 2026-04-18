# Machine-specific variables for host 'main'.
#
# Edit this file to configure this machine.
# No other file needs to be modified for installation.
#
# After editing, validate before installing:
#   nix run .#validate-install -- main
#
# To generate this file interactively:
#   nix run .#init-host -- main
{
  username = "DEFINE_USERNAME"; # system username — must be a valid Unix username
  hostname = "main";            # hostname — matches nixosConfigurations key in flake.nix
  disk     = "/dev/DEFINE_DISK"; # target disk — run `lsblk` on the target (e.g. /dev/nvme0n1)
  timezone = "Europe/Paris";    # see: timedatectl list-timezones
  locale   = "fr_FR.UTF-8";    # system locale
}
