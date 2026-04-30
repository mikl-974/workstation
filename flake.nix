{
  description = "Infra monorepo for machines, users, stacks, dotfiles, and reusable Nix modules";

  nixConfig = {
    extra-substituters      = [ "https://noctalia.cachix.org" ];
    extra-trusted-public-keys = [ "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4=" ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-llama.url = "github:NixOS/nixpkgs/1c3fe55ad329cbcb28471bb30f05c9827f724c76";

    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Declarative disk partitioning — required for hosts that are installed
    # through NixOS Anywhere in this repo.
    # See docs/nixos-anywhere.md and targets/hosts/contabo/disko.nix.
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Home Manager — manages user dotfiles and per-user packages.
    # Track a recent release branch so it stays compatible with the
    # nixpkgs snapshot used by this flake.
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Colmena — push-based NixOS deployment for server-class hosts.
    # Used by `deployments/colmena.nix` and the `deploy-*` apps.
    # Workstations are still installed/updated locally; Colmena is opt-in for
    # the hosts listed in the hive (currently only `contabo`).
    colmena = {
      url = "github:zhaofengli/colmena";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-homebrew.url = "github:zhaofengli/nix-homebrew";

    mango = {
      url = "github:mangowm/mango";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nixpkgs, disko, home-manager, sops-nix, nix-darwin, nix-homebrew, noctalia, colmena, mango, ... }:
    let
      lib = nixpkgs.lib;
      systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin" ];

      # Shared building blocks used by all infra NixOS targets.
      sharedModules = [
        ./systems/networking/tailscale.nix
        home-manager.nixosModules.home-manager
        sops-nix.nixosModules.sops
        mango.nixosModules.mango
        ./systems/security/sops.nix
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
        let
          hostSystem = if vars ? system then vars.system else "x86_64-linux";
        in
        lib.nixosSystem {
          system = vars.system or "x86_64-linux";
          specialArgs = {
            hostVars = vars;
            flakeSelf = self;
            flakeInputs = inputs;
            inherit inputs;
          };
          modules = sharedModules ++ [
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.extraSpecialArgs = {
                hostVars = vars;
                targetName = vars.hostname;
                inherit inputs;
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
            flakeInputs = inputs;
          };
          modules = sharedDarwinModules ++ modules;
        };

      # Build a minimal disko configuration for the CLI without evaluating the
      # full host system graph.
      mkDiskoConfig = { vars, diskoModule }:
        import diskoModule { hostVars = vars; };
    in
    {
      nixosConfigurations = {
        ms-s1-max = mkHost {
          vars   = import ./targets/hosts/ms-s1-max/vars.nix;
          modules = [
            disko.nixosModules.disko
            ./targets/hosts/ms-s1-max/default.nix
            ./targets/hosts/ms-s1-max/disko.nix
          ];
        };

        contabo = mkHost {
          vars   = import ./targets/hosts/contabo/vars.nix;
          modules = [ disko.nixosModules.disko ./targets/hosts/contabo/default.nix ./targets/hosts/contabo/disko.nix ];
        };
      };

      diskoConfigurations = {
        ms-s1-max = mkDiskoConfig {
          vars = import ./targets/hosts/ms-s1-max/vars.nix;
          diskoModule = ./targets/hosts/ms-s1-max/disko.nix;
        };

        contabo = mkDiskoConfig {
          vars = import ./targets/hosts/contabo/vars.nix;
          diskoModule = ./targets/hosts/contabo/disko.nix;
        };
      };

      darwinConfigurations = {
        mac-mini = mkDarwinHost {
          vars = import ./targets/hosts/mac-mini/vars.nix;
          modules = [ ./targets/hosts/mac-mini/default.nix ];
        };
      };

      # .NET devShell is defined locally — this is an infra-local dev
      # environment, not a generic shared primitive. See systems/devshells/dotnet.nix.
      devShells = lib.genAttrs systems (system:
        let pkgs = import nixpkgs { inherit system; };
        in {
          dotnet = import ./systems/devshells/dotnet.nix { inherit pkgs; };
        }
      );

      # Installation and validation scripts exposed as nix run .#<name> apps.
      # These scripts orchestrate, verify, and guide — they do not redefine
      # the configuration, which remains in flake.nix, targets/hosts/, home/, stacks/, and systems/.
      apps = lib.genAttrs systems (system:
        let pkgs = import nixpkgs { inherit system; };

            # Bundle all scripts + lib/ into a single store path so that
            # `source "$_SCRIPT_DIR/lib/workstation-install.sh"` resolves
            # correctly when the script runs from /nix/store.
            scriptsDrv = pkgs.runCommand "infra-scripts" {} ''
              mkdir -p $out/scripts/lib
              cp ${./scripts}/*.sh $out/scripts/
              cp ${./scripts}/lib/*.sh $out/scripts/lib/
              chmod +x $out/scripts/*.sh
            '';

            # Wrap a script with declared runtime dependencies in PATH.
            # writeShellApplication uses bash, adds runtimeInputs to PATH,
            # and enables shellcheck during build.
            mkApp = runtimeInputs: scriptBase: {
              type = "app";
              program = "${pkgs.writeShellApplication {
                name = lib.removeSuffix ".sh" scriptBase;
                runtimeInputs = runtimeInputs;
                text = ''exec "${scriptsDrv}/scripts/${scriptBase}" "$@"'';
              }}/bin/${lib.removeSuffix ".sh" scriptBase}";
            };
        in {
          init-keys          = mkApp [ pkgs.bash pkgs.openssh pkgs.age ] "init-keys.sh";
          init-host          = mkApp [ pkgs.bash ] "init-host.sh";
          show-config        = mkApp [ pkgs.bash pkgs.nix ] "show-config.sh";
          validate-install   = mkApp [ pkgs.bash pkgs.nix ] "validate-install.sh";
          doctor             = mkApp [ pkgs.bash pkgs.nix ] "doctor.sh";
          install-anywhere   = mkApp [ pkgs.bash pkgs.nix pkgs.openssh ] "install-anywhere.sh";
          install-manual         = mkApp [ pkgs.bash pkgs.nix ] "install-manual.sh";
          install-from-live      = mkApp [ pkgs.bash pkgs.git pkgs.nix pkgs.util-linux pkgs.rsync ] "install-from-live.sh";
          install-from-existing  = mkApp [ pkgs.bash pkgs.git pkgs.nix pkgs.util-linux pkgs.rsync ] "install-from-existing.sh";
          reconfigure            = mkApp [ pkgs.bash pkgs.nix ] "reconfigure.sh";
          post-install-check = mkApp [ pkgs.bash pkgs.nix pkgs.openssh ] "post-install-check.sh";
          validate-inventory = mkApp [ pkgs.bash pkgs.nix ] "validate-inventory.sh";
          deploy-contabo     = mkApp [ pkgs.bash pkgs.colmena ] "deploy-contabo.sh";
          deploy-all-hosts   = mkApp [ pkgs.bash pkgs.colmena ] "deploy-all-hosts.sh";
          plan-azure-ext         = mkApp [ pkgs.bash pkgs.opentofu ] "plan-azure-ext.sh";
          deploy-azure-ext       = mkApp [ pkgs.bash pkgs.opentofu ] "deploy-azure-ext.sh";
          plan-cloudflare-ext    = mkApp [ pkgs.bash pkgs.opentofu ] "plan-cloudflare-ext.sh";
          deploy-cloudflare-ext  = mkApp [ pkgs.bash pkgs.opentofu ] "deploy-cloudflare-ext.sh";
          plan-gcp-ext           = mkApp [ pkgs.bash pkgs.opentofu ] "plan-gcp-ext.sh";
          deploy-gcp-ext         = mkApp [ pkgs.bash pkgs.opentofu ] "deploy-gcp-ext.sh";
        }
      );

      # Deployment model — strict, machine-readable target → stack assignments.
      # `inventoryValidation` throws when the inventory violates any contract;
      # downstream consumers (CI, scripts, agents) can rely on `inventory`,
      # `topology`, and `stacks` only after this evaluation has succeeded.
      # Imported once and reused to avoid redundant evaluations.
      inventoryValidation = import ./deployments/validation.nix;
      inventory = (import ./deployments/validation.nix).inventory;
      topology = (import ./deployments/validation.nix).topology;
      stacks = (import ./deployments/validation.nix).stacks;

      # Expose inventory validation as a flake check so `nix flake check`
      # catches any contract violation at evaluation time.
      checks = lib.genAttrs systems (system:
        let pkgs = import nixpkgs { inherit system; };
            _validated = import ./deployments/validation.nix;
        in {
          inventory-validation = pkgs.runCommand "inventory-validation-check" {} ''
            echo 'targets: ${toString _validated.summary.targetCount}, stacks: ${toString _validated.summary.stackCount}, assignments: ${toString _validated.summary.assignmentCount}' > $out
          '';
        }
      );

      # Colmena hive — server-class NixOS hosts pushed via `colmena apply`.
      # Workstations are NOT in the hive: they are installed via NixOS Anywhere
      # and reconfigured locally with `nixos-rebuild`.
      colmenaHive = import ./deployments/colmena.nix {
        inherit nixpkgs colmena;
        flakeSelf = self;
      };
    };
}
