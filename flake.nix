# REF:
# - https://github.com/evantravers/dotfiles/blob/master/flake.nix
# - https://github.com/ahmedelgabri/dotfiles/blob/refactor/flake.nix
# - https://github.com/ahmedelgabri/dotfiles/blob/5ceb4f3220980f95bc674b0785c920fbd9fc45ed/install#L140-L148
# - https://github.com/elliottminns/dotfiles/blob/main/nix/flake.nix
# - https://github.com/omerxx/dotfiles/blob/master/nix-darwin/flake.nix
# - https://noghartt.dev/blog/set-up-nix-on-macos-using-flakes-nix-darwin-and-home-manager/
# - https://nixos-and-flakes.thiscute.world/nixos-with-flakes/start-using-home-manager
# - https://carlosvaz.com/posts/declarative-macos-management-with-nix-darwin-and-home-manager/
# - https://davi.sh/til/nix/nix-macos-setup/

{
  description = "🗿 megadotfiles";

  # inputs = {
  #   nixpkgs.url = "github:NixOS/nixpkgs";

  #   nix-darwin.url = "github:lnl7/nix-darwin/master";
  #   nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

  #   home-manager.url = "github:nix-community/home-manager";
  #   home-manager.inputs.nixpkgs.follows = "nixpkgs";
  # };

  inputs = {
    # Lix - A modern Nix implementation
    lix-module = {
      url = "https://git.lix.systems/lix-project/nixos-module/archive/2.90.0.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Nixpkgs
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    # nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    # nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";

    # Unstable Packages
    nixpkgs-unstable.url = "github:nixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    darwin = {
      url = "github:LnL7/nix-darwin";
      # or "github:LnL7/nix-darwin/master"
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # https://github.com/NixOS/nixpkgs/issues/327836#issuecomment-2292084100
    darwin-nixpkgs.url = "github:nixos/nixpkgs?rev=2e92235aa591abc613504fde2546d6f78b18c0cd";

    nix-homebrew = {
      url = "github:zhaofengli-wip/nix-homebrew";
      inputs = {
        nix-darwin.follows = "darwin";
        flake-utils.follows = "flake-utils";
        nixpkgs.follows = "nixpkgs";
      };
    };

    flake-utils.url = "github:numtide/flake-utils";

    weechat-scripts = {
      url = "github:weechat/scripts";
      flake = false;
    };

    spoons = {
      url = "github:Hammerspoon/Spoons";
      flake = false;
    };
  };

  outputs =
    { self
    , nixpkgs
    , nixpkgs-unstable
    , home-manager
    , nix-homebrew
    , darwin
    , ...
    } @ inputs:
    let
      inherit (self) outputs;

      darwinSystem = { user, hostname, arch ? "aarch64-darwin" }:
        darwin.lib.darwinSystem {
          system = arch;
          modules = [
            inputs.lix-module.nixosModules.default
            ./config/nix/darwin/darwin.nix
            home-manager.darwinModules.home-manager
            {
              _module.args = { inherit inputs; };
              home-manager = {
                users.${user} = import ./config/nix/hostnames/${hostname}.nix;
              };
              users.users.${user}.home = "/Users/${user}";
              nix.settings.trusted-users = [ user ];
            }
          ];
        };

      # systems = [
      #   "aarch64-linux"
      #   "i686-linux"
      #   "x86_64-linux"
      #   "aarch64-darwin"
      #   "x86_64-darwin"
      # ];

      # hosts = [
      #   { name = "megaookpro"; }
      # ];

      # forAllSystems = fn: nixpkgs.lib.genAttrs systems (system: fn { pkgs = import nixpkgs { inherit system; }; });
    in
    {
      # nixosConfigurations = {
      #   nixos = nixpkgs.lib.nixosSystem {
      #     system = "x86_64-linux";
      #     modules = [
      #       nixos-wsl.nixosModules.wsl
      #       ./nixos/configuration.nix
      #       ./.config/wsl
      #       home-manager.nixosModules.home-manager
      #       {
      #         home-manager = {
      #           users.nixos = import ./home-manager;
      #         };
      #         nix.settings.trusted-users = [ "nixos" ];
      #       }
      #     ];
      #   };
      # };
      darwinConfigurations = {
        "megabookpro" = darwinSystem {
          user = "seth";
          hostname = "megabookpro";
          arch = "aarch64-darwin";
        };
        "oldmbpro" = darwinSystem {
          user = "seth";
          hostname = "oldmbpro";
          arch = "x86_64-darwin";
        };
      };

      # overlays = import ./overlays { inherit inputs; };

      # formatter = forAllSystems ({ pkgs }: pkgs.alejandra);

      # packages = forAllSystems (system: import ./pkgs nixpkgs.legacyPackages.${system});

      # nixosConfigurations = builtins.listToAttrs (map
      #   (host: {
      #     inherit (host) name;
      #     value = nixpkgs.lib.nixosSystem {
      #       specialArgs = {
      #         inherit inputs outputs;
      #         meta = {
      #           hostname = host.name;
      #         };
      #       };
      #       system = "x86_64-linux";
      #       modules = [
      #         # Modules
      #         # disko.nixosModules.disko
      #         # System Specific
      #         ./machines/${host.name}/hardware-configuration.nix
      #         # ./machines/${host.name}/disko-config.nix
      #         # General
      #         ./configuration.nix
      #         # Home Manager
      #         home-manager.nixosModules.home-manager
      #         {
      #           home-manager.useGlobalPkgs = true;
      #           home-manager.useUserPackages = true;
      #           home-manager.users.elliott = import ./home/home.nix;
      #           home-manager.extraSpecialArgs = {
      #             inherit inputs;
      #             meta = host;
      #           };
      #         }
      #       ];
      #     };
      #   })
      #   hosts);
    };

  # outputs = inputs @ { self, nix-homebrew, home-manager }:
  #   let
  #     nixpkgsConfig = {
  #       config.allowUnfree = true;
  #     };
  #   in
  #   {
  #     darwinConfigurations =
  #       let
  #         inherit (inputs.nix-darwin.lib) darwinSystem;
  #       in
  #       {
  #         machine = darwinSystem {
  #           system = "aarch64-darwin";

  #           specialArgs = { inherit inputs; };

  #           modules = [
  #             ./hosts/mbp/configuration.nix
  #             inputs.home-manager.darwinModules.home-manager
  #             {
  #               nixpkgs = nixpkgsConfig;

  #               home-manager.useGlobalPkgs = true;
  #               home-manager.useUserPackages = true;
  #               home-manager.users.noghartt = import ./home/home.nix;
  #             }
  #           ];
  #         };
  #       };
  #   };
}
