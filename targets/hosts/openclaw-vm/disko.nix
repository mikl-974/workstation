# Disk layout for the concrete VM host `openclaw-vm` — used by NixOS Anywhere.
#
# The target disk is read from targets/hosts/openclaw-vm/vars.nix (field: disk).
# In a VM this is commonly /dev/vda, but the real device still has to be checked
# on the target before installation.
#
# Layout: GPT + EFI + btrfs with service-oriented subvolumes.
{ hostVars, ... }:
{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = hostVars.disk;
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "512M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "defaults" ];
              };
            };
            root = {
              size = "100%";
              content = {
                type = "btrfs";
                extraArgs = [ "-f" ];
                subvolumes = {
                  "@" = {
                    mountpoint = "/";
                    mountOptions = [ "compress=zstd" "noatime" ];
                  };
                  "@home" = {
                    mountpoint = "/home";
                    mountOptions = [ "compress=zstd" "noatime" ];
                  };
                  "@nix" = {
                    mountpoint = "/nix";
                    mountOptions = [ "compress=zstd" "noatime" ];
                  };
                  "@var-lib" = {
                    mountpoint = "/var/lib";
                    mountOptions = [ "compress=zstd" "noatime" ];
                  };
                  "@var-log" = {
                    mountpoint = "/var/log";
                    mountOptions = [ "compress=zstd" "noatime" ];
                  };
                };
              };
            };
          };
        };
      };
    };
  };
}
