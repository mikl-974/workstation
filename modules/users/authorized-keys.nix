# Canonical SSH public keys for human users.
#
# Public keys only — safe to version. Used to populate
# `users.users.<name>.openssh.authorizedKeys.keys` on workstations and
# `infra.users.admin.sshAuthorizedKeys` on servers (so mfo can SSH to admin@).
{
  mfo = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP05gS+2iPdyDZcW5W1KrFqabVKzoWq6hRupIVe9C444 mfo@infra"
  ];
}
