{ hostVars, ... }:
{
  users.users.${hostVars.username} = {
    isNormalUser = true;
    description = "OpenClaw VM operator";
    extraGroups = [ "wheel" ];
  };
}
