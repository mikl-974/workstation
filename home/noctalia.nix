# Noctalia Shell — home-manager configuration.
# See https://docs.noctalia.dev/getting-started/nixos/
{ inputs, pkgs, ... }:
{
  # Import the official Noctalia home-manager module.
  imports = [
    inputs.noctalia.homeModules.default
  ];

  programs.noctalia-shell = {
    enable = true;

    # Shell settings — bar position, density, widgets, etc.
    settings = {
      bar.position = "top";
    };

    # Material 3 color scheme — ALL keys are required.
    # Noctalia palette: Rose Pine inspired.
    colors = {
      mSurface          = "#191724";
      mSurfaceVariant   = "#1f1d2e";
      mHover            = "#26233a";
      mPrimary          = "#c4a7e7"; # iris (purple)
      mSecondary        = "#31748f"; # pine (teal)
      mTertiary         = "#9ccfd8"; # foam (light teal)
      mOnSurface        = "#e0def4";
      mOnSurfaceVariant = "#908caa";
      mOnPrimary        = "#191724";
      mOnSecondary      = "#191724";
      mOnTertiary       = "#191724";
      mOnHover          = "#e0def4";
      mOutline          = "#6e6a86";
      mError            = "#eb6f92"; # love (pink)
      mOnError          = "#191724";
      mShadow           = "#000000";
    };
  };
}
