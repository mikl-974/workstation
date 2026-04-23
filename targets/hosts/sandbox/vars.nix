# Machine-specific variables for the `sandbox` VM.
#
# `sandbox` is a local KVM/QEMU virtual machine for testing applications
# before deployment. It mirrors the production environment closely so that
# integration tests run in realistic conditions.
#
# After editing, validate before installing:
#   nix run .#validate-install -- sandbox
{
  system   = "x86_64-linux";
  username = "admin";          # operator account — see modules/users/admin.nix
  hostname = "sandbox";
  disk     = "/dev/vda";       # standard virtio block device for KVM/QEMU VMs
  timezone = "Asia/Bangkok";
  locale   = "en_US.UTF-8";
}
