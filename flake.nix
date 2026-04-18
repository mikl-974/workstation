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
      systems = [ "x86_64-linux" "aarch64-darwin" "x86_64-darwin" ];

      # Foundation NixOS modules consumed by all workstation hosts.
      # Home Manager user binding is per-host (username lives in hosts/<name>/vars.nix).
      sharedModules = [
        foundation.nixosModules.networkingTailscale
        home-manager.nixosModules.home-manager
        {
          # Global home-manager settings applied to all hosts.
          # useGlobalPkgs avoids a second nixpkgs eval per user.
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
        }
      ];

      # Build a NixOS host from its vars.nix and host-specific modules.
      # vars   — attrset imported from hosts/<name>/vars.nix
      # modules — list of NixOS modules specific to the host
      mkHost = { vars, modules }:
        lib.nixosSystem {
          system = "x86_64-linux";
          # hostVars is available to every module in this host as a function argument.
          specialArgs = { hostVars = vars; };
          modules = sharedModules ++ [
            # Bind the Home Manager config to the username declared in vars.nix.
            { home-manager.users.${vars.username} = import ./home/default.nix; }
          ] ++ modules;
        };
    in
    {
      nixosConfigurations = {
        main = mkHost {
          vars   = import ./hosts/main/vars.nix;
          modules = [ disko.nixosModules.disko ./hosts/main/default.nix ];
        };

        laptop = mkHost {
          vars   = import ./hosts/laptop/vars.nix;
          modules = [ ./hosts/laptop/default.nix ];
        };

        gaming = mkHost {
          vars   = import ./hosts/gaming/vars.nix;
          modules = [ ./hosts/gaming/default.nix ];
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
          init-host          = mkApp ./scripts/init-host.sh;
          show-config        = mkApp ./scripts/show-config.sh;
          validate-install   = mkApp ./scripts/validate-install.sh;
          install-anywhere   = mkApp ./scripts/install-anywhere.sh;
          install-manual     = mkApp ./scripts/install-manual.sh;
          post-install-check = mkApp ./scripts/post-install-check.sh;
        }
      );
    };
}
