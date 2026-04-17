# Disk layout for the main workstation — used by NixOS Anywhere.
#
# Layout: GPT + EFI + btrfs with subvolumes
#   /dev/sda (or replace with actual disk path before installing)
#     ├─ sda1  EFI  512 MiB
#     └─ sda2  btrfs
#           ├─ @           → /
#           ├─ @home       → /home
#           ├─ @nix        → /nix
#           ├─ @var-log    → /var/log
#           └─ @snapshots  → /snapshots (btrfs snapshots, not mounted by default)
#
# Replace "/dev/sda" with the actual target disk before running NixOS Anywhere.
# See docs/nixos-anywhere.md for the full install procedure.
{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        # IMPORTANT: replace with the actual target disk (e.g. /dev/nvme0n1)
        device = "/dev/sda";
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
