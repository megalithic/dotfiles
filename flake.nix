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
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.11";

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
    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
    mcp-hub.url = "github:ravitemer/mcp-hub";
    flake-parts.url = "github:hercules-ci/flake-parts";
    llm-agents.url = "github:numtide/llm-agents.nix";
    llm-agents.inputs.nixpkgs.follows = "nixpkgs";
    mcp-servers-nix = {
      url = "github:natsukium/mcp-servers-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nur = {
      url = "github:nix-community/nur";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    expert.url = "github:elixir-lang/expert";
    nh = {
      url = "github:nix-community/nh";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    shade.url = "github:megalithic/shade";
    shade.inputs.nixpkgs.follows = "nixpkgs";
    # opnix = {
    #   url = "github:brizzbuzz/opnix";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
    # op-shell-plugins = {
    #   url = "github:1password/shell-plugins";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
    # firefox-addons.url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
    # firefox-addons.inputs.nixpkgs.follows = "nixpkgs";
    # zen-browser.url = "github:0xc000022070/zen-browser-flake";
    # zen-browser.inputs.nixpkgs.follows = "nixpkgs";
    # zen-browser.inputs.home-manager.follows = "home-manager";
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
    username = "seth";
    arch = "aarch64-darwin";
    version = "25.11";

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

    mkInit = import ./lib/mkInit.nix { inherit nixpkgs; };

    mkDarwinHost = import ./lib/mkDarwinHost.nix {
      inherit inputs lib overlays brew_config version;
    };

    mkHome = import ./lib/mkHome.nix {
      inherit inputs lib overlays version;
    };
  in {
    inherit (self) outputs;

    # Bootstrap nix install per arch
    apps."${arch}".default = mkInit {
      inherit arch;
      script = builtins.readFile scripts/${arch}_bootstrap.sh;
    };

    # Darwin system configurations (includes home-manager)
    darwinConfigurations.megabookpro = mkDarwinHost {
      hostname = "megabookpro";
      username = "seth";
    };

    darwinConfigurations.rxbookpro = mkDarwinHost {
      hostname = "rxbookpro";
      username = "seth";
    };

    # Standalone home-manager configurations
    homeConfigurations."seth@megabookpro" = mkHome {
      hostname = "megabookpro";
      username = "seth";
    };

    homeConfigurations."seth@rxbookpro" = mkHome {
      hostname = "rxbookpro";
      username = "seth";
    };
  };
}
