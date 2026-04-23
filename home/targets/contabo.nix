# Empty Home Manager composition for the headless server `contabo`.
#
# The host operator account (`admin`) is provisioned by
# `modules/users/admin.nix` at the system level; it has no Home Manager
# composition because there is no user-facing desktop on this target.
{ ... }:
{ }
