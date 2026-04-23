{ ... }:
{
  imports = [
    ../../stacks/ai-server/default.nix
  ];

  infra.stacks.ai-server.enable = true;
}
