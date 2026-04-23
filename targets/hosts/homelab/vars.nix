# Machine-specific variables for the `homelab` VM.
#
# `homelab` is a local KVM/QEMU virtual machine dedicated to self-hosted
# services (monitoring, media, home automation, etc.). Stacks are assigned
# to this target in deployments/inventory.nix.
#
# After editing, validate before installing:
#   nix run .#validate-install -- homelab
{
  system   = "x86_64-linux";
  username = "admin";          # operator account — see modules/users/admin.nix
  hostname = "homelab";
  disk     = "/dev/vda";       # standard virtio block device for KVM/QEMU VMs
  timezone = "Asia/Bangkok";
  locale   = "en_US.UTF-8";
}
