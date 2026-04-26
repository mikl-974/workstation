# Disk layout for `contabo` — Contabo VPS root disk (typically /dev/vda).
#
# The device is read from `targets/hosts/contabo/vars.nix` (field `disk`) so
# the same layout can be reused if the VPS image changes hardware presentation.
{ hostVars, ... }:
{
  disko.devices = {
    disk.main = {
      type = "disk";
      device = hostVars.disk;
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            size = "1G";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = [ "umask=0077" ];
            };
          };
          root = {
            size = "100%";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/";
            };
          };
        };
      };
    };
  };
}
