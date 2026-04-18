{ lib, config, pkgs, ... }:
let
  cfg = config.workstation.desktop.warp;
in
{
  # Cloudflare WARP is intentionally kept in workstation (not foundation).
  # WARP is a desktop/user VPN client, not a generic server-side network
  # primitive. It has no place in a shared infra foundation module.
  options.workstation.desktop.warp.enable =
    lib.mkEnableOption "Cloudflare WARP desktop client";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.cloudflare-warp ];
    systemd.packages = [ pkgs.cloudflare-warp ];
    systemd.services."warp-svc".wantedBy = [ "multi-user.target" ];
  };
}
