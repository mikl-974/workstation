{ lib, ... }:
{
  imports = [ ./base.nix ];

  home.username = "mfo";
  home.homeDirectory = "/home/mfo";

  programs.noctalia-shell.settings = lib.mkForce ../../dotfiles/noctalia/mfo/settings.json;

  home.file = {
    ".config/noctalia/plugins.json".source = ../../dotfiles/noctalia/mfo/plugins.json;
    ".config/noctalia/plugins/tailscale/TailscaleIcon.qml".source = ../../dotfiles/noctalia/local-plugins/tailscale/TailscaleIcon.qml;
    ".config/noctalia/plugins/cloudflare-warp/CloudflareIcon.qml".source = ../../dotfiles/noctalia/local-plugins/cloudflare-warp/CloudflareIcon.qml;
    ".config/opencode/opencode.json".source = ../../dotfiles/opencode/opencode.json;
  };
}
