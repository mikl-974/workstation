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
  username = "DEFINE_USERNAME"; # system username — must be a valid Unix username
  hostname = "gaming";          # hostname — matches nixosConfigurations key in flake.nix
  timezone = "Europe/Paris";    # see: timedatectl list-timezones
  locale   = "fr_FR.UTF-8";    # system locale
}
