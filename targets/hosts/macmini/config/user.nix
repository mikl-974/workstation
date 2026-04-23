{ hostVars, ... }:
{
  system.primaryUser = hostVars.username;
}
