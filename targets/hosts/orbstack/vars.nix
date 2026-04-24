# Machine-specific variables for the `orbstack` host.
#
# `orbstack` is a NixOS VM provisioned by OrbStack on macOS. OrbStack handles
# the disk layout itself (no disko, no nixos-install needed) — the repo only
# applies its config via `nixos-rebuild switch`.
#
# Use case: developer VM mirroring `sandbox` for local app testing on Mac.
#
# After editing, validate before applying:
#   nix run .#validate-install -- orbstack
{
  system   = "aarch64-linux";   # OrbStack on Apple Silicon. Use x86_64-linux on Intel Macs.
  username = "mfo";
  hostname = "orbstack";
  timezone = "Asia/Bangkok";
  locale   = "en_US.UTF-8";
}
