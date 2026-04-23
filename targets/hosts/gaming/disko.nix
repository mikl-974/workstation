# Disk layout for the gaming workstation — used by NixOS Anywhere.
#
# The target disk is read from targets/hosts/gaming/vars.nix (field: disk).
# Run `lsblk` on the target machine to identify the correct device.
# Examples: /dev/nvme0n1, /dev/sda, /dev/vda
#
# Layout: GPT + EFI + btrfs with the same workstation subvolumes as `main`.
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
