# Empty Home Manager composition for the headless `homelab` VM.
#
# The operator account (`admin`) is provisioned by modules/users/admin.nix at
# the system level. No desktop/user-space composition is needed on this server.
{ ... }:
{ }
