# Machine-specific variables for host 'laptop'.
#
# Edit this file to configure this machine.
# No other file needs to be modified for installation.
#
# After editing, validate before installing:
#   nix run .#validate-install -- laptop
#
# To generate this file interactively:
#   nix run .#init-host -- laptop
{
  system   = "x86_64-linux";    # target architecture
  username = "DEFINE_USERNAME"; # system username — must be a valid Unix username
  hostname = "laptop";          # hostname — matches nixosConfigurations key in flake.nix
  timezone = "Europe/Paris";    # see: timedatectl list-timezones
  locale   = "fr_FR.UTF-8";    # system locale
}
