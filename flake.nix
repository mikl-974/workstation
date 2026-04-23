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

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-homebrew.url = "github:zhaofengli/nix-homebrew";

    # Kept available for future Darwin tap pinning if/when the repo needs it.
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };

    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
  };

  outputs = inputs@{ self, nixpkgs, foundation, disko, home-manager, sops-nix, nix-darwin, nix-homebrew, ... }:
    let
      lib = nixpkgs.lib;
      systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin" ];

      # Shared building blocks used by all infra NixOS targets.
      sharedModules = [
        foundation.nixosModules.networkingTailscale
        home-manager.nixosModules.home-manager
        sops-nix.nixosModules.sops
        ./modules/security/sops.nix
      ];

      # Shared building blocks used by Darwin targets.
      sharedDarwinModules = [
        nix-homebrew.darwinModules.nix-homebrew
      ];

      # Each NixOS host must now expose its explicit Home Manager composition
      # through home/targets/<hostname>.nix.
      mkHomeUsers = vars:
        let
          homeTargetPath = ./. + "/home/targets/${vars.hostname}.nix";
        in
        if builtins.pathExists homeTargetPath then
          import homeTargetPath
        else
          throw "missing Home Manager composition for ${vars.hostname}: expected home/targets/${vars.hostname}.nix";

      # Build a NixOS host from its vars.nix and host-specific modules.
      mkHost = { vars, modules }:
        lib.nixosSystem {
          system = vars.system or "x86_64-linux";
          specialArgs = {
            hostVars = vars;
            flakeSelf = self;
          };
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

      # Build a Darwin host from its vars.nix and host-specific modules.
      mkDarwinHost = { vars, modules }:
        nix-darwin.lib.darwinSystem {
          system = vars.system or "aarch64-darwin";
          specialArgs = {
            hostVars = vars;
            flakeSelf = self;
          };
          modules = sharedDarwinModules ++ modules;
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

      darwinConfigurations = {
        # Retained as-is for now: it is already the working flake entrypoint and
        # there is no stronger durable naming signal in the repo yet.
        macmini = mkDarwinHost {
          vars = import ./targets/hosts/macmini/vars.nix;
          modules = [ ./targets/hosts/macmini/default.nix ];
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
