{ pkgs, ... }:
{
  home.packages = [ pkgs.chromium ];

  xdg.mimeApps.defaultApplications = {
    "text/html" = [ "chromium-browser.desktop" ];
    "x-scheme-handler/http" = [ "chromium-browser.desktop" ];
    "x-scheme-handler/https" = [ "chromium-browser.desktop" ];
  };

  home.sessionVariables.BROWSER = "chromium";
}
