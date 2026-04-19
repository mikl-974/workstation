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
  system          = "aarch64-linux";   # target architecture — aarch64-linux for Apple Silicon VMs, x86_64-linux for Intel/AMD
  username        = "mickael";          # system username — must be a valid Unix username
  hostname        = "main";             # hostname — matches nixosConfigurations key in flake.nix
  disk            = "/dev/nvme0n1";     # target disk (whole device, not a partition) — run `lsblk` on the target
  timezone        = "Asia/Bangkok";     # see: timedatectl list-timezones
  locale          = "en_US.UTF-8";     # system locale
  initialPassword = "dswkq5V2";        # temporary password — change after first login with `passwd`
}
