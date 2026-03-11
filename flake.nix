# REF: Some useful resources
#
# https://nix.dev/
# https://nixos.org/guides/nix-pills/
# https://nix-community.github.io/awesome-nix/
# https://serokell.io/blog/practical-nix-flakes
# https://zero-to-nix.com/
# https://wiki.nixos.org/wiki/Flakes
# https://rconybea.github.io/web/nix/nix-for-your-own-project.html
{
  description = "🗿 megadotfiles (nix'd)";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-darwin = {
      url = "github:LnL7/nix-darwin/nix-darwin-25.11";
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
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.darwin.follows = "nix-darwin";
    };

    # NOTE: you can pin to a specific show with neovim-nightly-overlay/<sha>
    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";

    llm-agents.url = "github:numtide/llm-agents.nix";
    mcp-servers-nix.url = "github:natsukium/mcp-servers-nix";
    expert.url = "github:elixir-lang/expert";
    nur.url = "github:nix-community/nur";
    op-shell-plugins.url = "github:1Password/shell-plugins";
    jujutsu.url = "github:jj-vcs/jj?tag=v0.39.0";
    devenv.url = "github:cachix/devenv";
    nh.url = "github:nix-community/nh";
    kanata-darwin = {
      url = "github:not-in-stock/kanata-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # FIXME: Shade build broken - GhosttyKit extraction issue (see overlays/default.nix)
    # shade.url = "github:megalithic/shade";
    # shade.inputs.nixpkgs.follows = "nixpkgs";
    # opnix = {
    #   url = "github:brizzbuzz/opnix";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
    # yazi.url = "github:sxyazi/yazi";
    # yazi-plugins = {
    #   url = "github:yazi-rs/plugins";
    #   flake = false;
    # };
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-unstable,
    nix-darwin,
    home-manager,
    agenix,
    nix-homebrew,
    ...
  } @ inputs: let
    arch = "aarch64-darwin";
    version = "25.11";
    username = "seth";
    lib = nixpkgs.lib.extend (import ./lib/default.nix inputs);
    overlays = import ./overlays {inherit inputs lib;};
    brew_config = {username}: {
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

    mkInit = import ./lib/mkInit.nix {inherit nixpkgs;};

    mkDarwin = import ./lib/mkDarwin.nix {
      inherit inputs lib overlays brew_config version;
    };

    mkHome = import ./lib/mkHome.nix {
      inherit inputs lib overlays version;
    };
  in {
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
