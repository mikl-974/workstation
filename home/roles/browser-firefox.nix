{ ... }:
{
  programs.firefox = {
    enable = true;
    profiles.default = {
      id = 0;
      isDefault = true;
      settings = {
        "browser.startup.page" = 3;
        "browser.toolbars.bookmarks.visibility" = "never";
        "browser.newtabpage.enabled" = false;
      };
    };
  };

  xdg.mimeApps.defaultApplications = {
    "text/html" = [ "firefox.desktop" ];
    "x-scheme-handler/http" = [ "firefox.desktop" ];
    "x-scheme-handler/https" = [ "firefox.desktop" ];
  };

  home.sessionVariables.BROWSER = "firefox";
}
