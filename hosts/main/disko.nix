# Disk layout for the main workstation — used by NixOS Anywhere.
#
# The target disk is read from hosts/main/vars.nix (field: disk).
# Run `lsblk` on the target machine to identify the correct device.
# Examples: /dev/nvme0n1, /dev/sda, /dev/vda
#
# Layout: GPT + EFI + btrfs with subvolumes
#     ├─ sda1  EFI  512 MiB
#     └─ sda2  btrfs
#           ├─ @           → /
#           ├─ @home       → /home
#           ├─ @nix        → /nix
#           ├─ @var-log    → /var/log
#           └─ @snapshots  → /snapshots (btrfs snapshots, not mounted by default)
#
# See docs/nixos-anywhere.md for the full install procedure.
{ hostVars, ... }:
{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        # Disk device read from hosts/main/vars.nix — set the `disk` field there.
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
