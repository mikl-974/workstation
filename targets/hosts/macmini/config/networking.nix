{ ... }:
{
  # MAS stays explicit for macOS-native distribution when Nix is not the right adapter.
  homebrew.masApps = {
    "NordVPN" = 905953485;
    "Tailscale" = 1475387142;
  };
}
