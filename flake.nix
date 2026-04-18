{
  description = "Personal workstation environments (NixOS, Hyprland, dotfiles, devshells)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";

    foundation = {
      url = "github:mikl-974/foundation";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Declarative disk partitioning — required for NixOS Anywhere installations.
    # See docs/nixos-anywhere.md and hosts/main/disko.nix.
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Home Manager — manages user dotfiles and per-user packages.
    # Pinned to the matching NixOS release branch.
    home-manager = {
      url = "github:nix-community/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, foundation, disko, home-manager, ... }:
    let
      lib = nixpkgs.lib;
      systems = [ "x86_64-linux" ];

      # Foundation NixOS modules consumed by all workstation hosts.
      sharedModules = [
        foundation.nixosModules.networkingTailscale
        home-manager.nixosModules.home-manager
        {
          # Global home-manager settings applied to all hosts.
          # useGlobalPkgs avoids a second nixpkgs eval per user.
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          # TODO: replace "CHANGEME_USERNAME" with the actual system username
          # before running nixos-rebuild or nixos-anywhere.
          home-manager.users.CHANGEME_USERNAME = import ./home/default.nix;
        }
      ];
    in
    {
      nixosConfigurations = {
        main = lib.nixosSystem {
          system = "x86_64-linux";
          modules = sharedModules ++ [
            disko.nixosModules.disko
            ./hosts/main/default.nix
          ];
        };

        laptop = lib.nixosSystem {
          system = "x86_64-linux";
          modules = sharedModules ++ [ ./hosts/laptop/default.nix ];
        };

        gaming = lib.nixosSystem {
          system = "x86_64-linux";
          modules = sharedModules ++ [ ./hosts/gaming/default.nix ];
        };
      };

      # .NET devShell is defined locally — this is a workstation-specific dev
      # environment, not a generic shared primitive. See devshells/dotnet.nix.
      devShells = lib.genAttrs systems (system:
        let pkgs = import nixpkgs { inherit system; };
        in {
          dotnet = import ./devshells/dotnet.nix { inherit pkgs; };
        }
      );

      # Installation and validation scripts exposed as nix run .#<name> apps.
      # These scripts orchestrate, verify, and guide — they do not redefine
      # the configuration, which remains in flake.nix, hosts/, profiles/, and modules/.
      apps = lib.genAttrs systems (system:
        let pkgs = import nixpkgs { inherit system; };
            mkApp = script: {
              type = "app";
              program = "${pkgs.writeShellScript (builtins.baseNameOf script) (builtins.readFile script)}";
            };
        in {
          validate-install  = mkApp ./scripts/validate-install.sh;
          install-anywhere  = mkApp ./scripts/install-anywhere.sh;
          install-manual    = mkApp ./scripts/install-manual.sh;
          post-install-check = mkApp ./scripts/post-install-check.sh;
        }
      );
    };
}
