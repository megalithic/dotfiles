{
  description = "🗿 dots";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
    homebrew-services = {
      url = "github:homebrew/homebrew-services";
      flake = false;
    };
    homebrew-bundle = {
      url = "github:homebrew/homebrew-bundle";
      flake = false;
    };
    homebrew-felixkratz = {
      url = "github:FelixKratz/homebrew-formulae";
      flake = false;
    };

    # brew-nix: nix overlay for homebrew casks (replaces nix-homebrew casks)
    brew-api = {
      url = "github:BatteredBunny/brew-api";
      flake = false;
    };
    brew-nix = {
      url = "github:BatteredBunny/brew-nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.brew-api.follows = "brew-api";
      inputs.nix-darwin.follows = "nix-darwin";
    };

    opnix = {
      url = "github:brizzbuzz/opnix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # NOTE: you can pin to a specific show with neovim-nightly-overlay/<sha>
    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";

    devenv.url = "github:cachix/devenv";
    nh.url = "github:nix-community/nh";
    kanata-darwin = {
      url = "github:not-in-stock/kanata-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # FIXME: Shade build broken - GhosttyKit extraction issue (see overlays/default.nix)
    # shade.url = "github:megalithic/shade";
    # shade.inputs.nixpkgs.follows = "nixpkgs";
    yazi.url = "github:sxyazi/yazi";
    yazi-plugins = {
      url = "github:yazi-rs/plugins";
      flake = false;
    };
  };

  outputs =
    { nixpkgs, ... }@inputs:
    let
      arch = "aarch64-darwin";
      version = "25.11";
      username = "seth";
      lib = nixpkgs.lib.extend (import ./lib/default.nix inputs);
      overlays = import ./overlays { inherit inputs lib; };
      brew_config =
        { username }:
        {
          nix-homebrew = {
            enable = true;
            enableRosetta = true;
            autoMigrate = true;
            mutableTaps = false;
            user = username;
            taps = {
              "homebrew/homebrew-core" = inputs.homebrew-core;
              "homebrew/homebrew-cask" = inputs.homebrew-cask;
              "homebrew/homebrew-services" = inputs.homebrew-services;
              "homebrew/homebrew-bundle" = inputs.homebrew-bundle;
              "felixkratz/homebrew-formulae" = inputs.homebrew-felixkratz;
            };
          };
        };

      mkInit = import ./lib/mkInit.nix { inherit nixpkgs; };

      mkDarwin = import ./lib/mkDarwin.nix {
        inherit
          inputs
          lib
          overlays
          brew_config
          version
          ;
      };

      mkHome = import ./lib/mkHome.nix {
        inherit
          inputs
          lib
          overlays
          version
          ;
      };
    in
    {
      apps."${arch}".default = mkInit {
        inherit arch;
        script = builtins.readFile scripts/${arch}_bootstrap.sh;
      };
      darwinConfigurations.megabookpro = mkDarwin {
        hostname = "megabookpro";
        inherit username;
      };
      darwinConfigurations.rxbookpro = mkDarwin {
        hostname = "rxbookpro";
        inherit username;
      };
      homeConfigurations."${username}@megabookpro" = mkHome {
        hostname = "megabookpro";
        inherit username;
      };
      homeConfigurations."${username}@rxbookpro" = mkHome {
        hostname = "rxbookpro";
        inherit username;
      };
    };
}
