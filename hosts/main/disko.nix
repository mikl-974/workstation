# Disk layout for the main workstation — used by NixOS Anywhere.
#
# BEFORE INSTALLING: replace "/dev/CHANGEME" below with the actual disk device.
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
# Replace "/dev/sda" with the actual target disk before running NixOS Anywhere.
# See docs/nixos-anywhere.md for the full install procedure.
{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        # IMPORTANT: replace with the actual target disk before running NixOS Anywhere.
        # Use `lsblk` on the target machine to identify the correct device.
        # Examples: /dev/nvme0n1, /dev/sda, /dev/vda
        device = "/dev/CHANGEME";
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
