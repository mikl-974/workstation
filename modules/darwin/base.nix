{ flakeSelf, hostVars, ... }:
{
  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = "nix-command flakes";

  # The target decides which Darwin platform it runs on; the shared base only
  # reads that value from the concrete host vars.
  nixpkgs.hostPlatform = hostVars.system;

  system.configurationRevision = flakeSelf.rev or flakeSelf.dirtyRev or null;
  system.stateVersion = 6;
}
