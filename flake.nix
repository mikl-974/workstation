{
  description = "Infra monorepo for machines, users, stacks, dotfiles, and reusable Nix modules";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    foundation = {
      url = "github:mikl-974/foundation";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Declarative disk partitioning — required for NixOS Anywhere installations.
    # See docs/nixos-anywhere.md and targets/hosts/main/disko.nix.
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Home Manager — manages user dotfiles and per-user packages.
    # Intentionally kept on the 24.11 release branch for stability while
    # nixpkgs itself tracks nixos-unstable for package selection.
    home-manager = {
      url = "github:nix-community/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, foundation, disko, home-manager, sops-nix, ... }:
    let
      lib = nixpkgs.lib;
      systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin" ];

      # Shared building blocks used by all infra targets.
      sharedModules = [
        foundation.nixosModules.networkingTailscale
        home-manager.nixosModules.home-manager
        sops-nix.nixosModules.sops
        ./modules/security/sops.nix
      ];

      # Prefer an explicit per-host Home Manager composition when it exists.
      # Fall back to the legacy single-user file for older hosts not yet migrated.
      mkHomeUsers = vars:
        let
          homeTargetPath = ./. + "/home/targets/${vars.hostname}.nix";
          fallbackMessage =
            if vars ? users && builtins.length vars.users > 1 then
              "legacy home-manager fallback active for ${vars.hostname}: multi-user host still using single-user home/users/default.nix"
            else
              "legacy home-manager fallback active for ${vars.hostname}: using home/users/default.nix";
        in
        if builtins.pathExists homeTargetPath then
          import homeTargetPath
        else
          builtins.trace fallbackMessage {
            ${vars.username} = import ./home/users/default.nix;
          };

      # Build a NixOS host from its vars.nix and host-specific modules.
      # vars   — attrset imported from targets/hosts/<name>/vars.nix
      # modules — list of NixOS modules specific to the target
      mkHost = { vars, modules }:
        lib.nixosSystem {
          system = vars.system or "x86_64-linux";
          specialArgs = { hostVars = vars; };
          modules = sharedModules ++ [
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.extraSpecialArgs = {
                hostVars = vars;
                targetName = vars.hostname;
              };
              home-manager.users = mkHomeUsers vars;
            }
          ] ++ modules;
        };
    in
    {
      nixosConfigurations = {
        main = mkHost {
          vars   = import ./targets/hosts/main/vars.nix;
          modules = [ disko.nixosModules.disko ./targets/hosts/main/default.nix ];
        };

        laptop = mkHost {
          vars   = import ./targets/hosts/laptop/vars.nix;
          modules = [ ./targets/hosts/laptop/default.nix ];
        };

        gaming = mkHost {
          vars   = import ./targets/hosts/gaming/vars.nix;
          modules = [ ./targets/hosts/gaming/default.nix ];
        };

        ms-s1-max = mkHost {
          vars   = import ./targets/hosts/ms-s1-max/vars.nix;
          modules = [ ./targets/hosts/ms-s1-max/default.nix ];
        };
      };

      # .NET devShell is defined locally — this is an infra-local dev
      # environment, not a generic shared primitive. See modules/devshells/dotnet.nix.
      devShells = lib.genAttrs systems (system:
        let pkgs = import nixpkgs { inherit system; };
        in {
          dotnet = import ./modules/devshells/dotnet.nix { inherit pkgs; };
        }
      );

      # Installation and validation scripts exposed as nix run .#<name> apps.
      # These scripts orchestrate, verify, and guide — they do not redefine
      # the configuration, which remains in flake.nix, targets/hosts/, home/, stacks/, and modules/.
      apps = lib.genAttrs systems (system:
        let pkgs = import nixpkgs { inherit system; };
            mkApp = script: {
              type = "app";
              # Preserve the original shebang so BASH_SOURCE/path resolution
              # inside the script body keeps behaving like the checked-in file.
              program = "${pkgs.writeTextFile {
                name = builtins.baseNameOf script;
                text = builtins.readFile script;
                executable = true;
              }}";
            };
        in {
          init-host          = mkApp ./scripts/init-host.sh;
          show-config        = mkApp ./scripts/show-config.sh;
          validate-install   = mkApp ./scripts/validate-install.sh;
          doctor             = mkApp ./scripts/doctor.sh;
          install-anywhere   = mkApp ./scripts/install-anywhere.sh;
          install-manual     = mkApp ./scripts/install-manual.sh;
          post-install-check = mkApp ./scripts/post-install-check.sh;
        }
      );
    };
}
