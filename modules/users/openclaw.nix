# NixOS service account for the openclaw-vm operator.
# This is a minimal operator account (wheel only — no desktop groups).
{ ... }:
{
  users.users.openclaw = {
    isNormalUser = true;
    description  = "OpenClaw VM operator";
    extraGroups  = [ "wheel" ];
  };
}
