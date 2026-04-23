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
      # configure noctalia here
      bar = {
        position = "top";
        barType = "floating";
        marginVertical = 4;
        marginHorizontal = 200;
        showCapsule = false;
        widgets = {
          left = [
            {
              id = "ControlCenter";
              useDistroLogo = true;
            }
            {
              id = "Network";
            }
            {
              id = "Bluetooth";
            }
          ];
          center = [
            {
              hideUnoccupied = false;
              id = "Workspace";
              labelMode = "none";
            }
          ];
          right = [
            {
              alwaysShowPercentage = false;
              id = "Battery";
              warningThreshold = 30;
            }
            {
              formatHorizontal = "HH:mm";
              formatVertical = "HH mm";
              id = "Clock";
              useMonospacedFont = true;
              usePrimaryColor = true;
            }
          ];
        };
      };
      colorSchemes.predefinedScheme = "Rose Pine";
      general = {
        radiusRatio = 0.2;
      };
      location = {
        monthBeforeDay = false;
        name = "Bangkok, Thailande";
      };
    };

  };
}
