{ lib, config, pkgs, ... }:
let
  cfg = config.workstation.desktop.warp;
in
{
  # Cloudflare WARP is intentionally kept in the desktop layer of `infra`.
  # WARP is a desktop/user VPN client, not a generic server-side network
  # primitive. It belongs to `modules/desktop/`, not to the systemwide
  # networking primitives in `modules/networking/`.
  options.workstation.desktop.warp.enable =
    lib.mkEnableOption "Cloudflare WARP desktop client";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.cloudflare-warp ];
    systemd.packages = [ pkgs.cloudflare-warp ];
    systemd.services."warp-svc".wantedBy = [ "multi-user.target" ];
  };
}
