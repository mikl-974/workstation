# Disk layout for `sandbox` — KVM/QEMU VM with a virtio block device.
#
# Device is read from vars.nix (field `disk`, default /dev/vda) so it can be
# adjusted if the hypervisor presents the disk under a different name.
{ hostVars, ... }:
{
  disko.devices = {
    disk.main = {
      type   = "disk";
      device = hostVars.disk;
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            size = "512M";
            type = "EF00";
            content = {
              type        = "filesystem";
              format      = "vfat";
              mountpoint  = "/boot";
              mountOptions = [ "umask=0077" ];
            };
          };
          root = {
            size = "100%";
            content = {
              type       = "filesystem";
              format     = "ext4";
              mountpoint = "/";
            };
          };
        };
      };
    };
  };
}
