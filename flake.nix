{
  description = "🗿 dots";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    brew-nix = {
      url = "github:BatteredBunny/brew-nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.brew-api.follows = "brew-api";
    };
    brew-api = {
      url = "github:BatteredBunny/brew-api";
      flake = false;
    };
    opnix = {
      url = "github:brizzbuzz/opnix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    neovim-nightly-overlay = {
      url = "github:nix-community/neovim-nightly-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
      # Track Neovim's moving nightly tag instead of overlay's raw default branch.
      inputs.neovim-src.url = "github:neovim/neovim/nightly";
    };
    pi-nix = {
      url = "github:lukasl-dev/pi.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # espanso: pinned to last-good nixpkgs. Jul 2026 unstable (clang 21 /
    # cctools bump) crashes cctools ld (Trace/BPT trap 5) linking espanso
    # on aarch64-darwin. Drop this pin once upstream espanso links again.
    nixpkgs-espanso.url = "github:nixos/nixpkgs/89570f24e97e614aa34aa9ab1c927b6578a43775";
    worktrunk = {
      url = "github:max-sixty/worktrunk";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nh.url = "github:nix-community/nh";
    kanata-darwin = {
      url = "github:not-in-stock/kanata-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    yazi.url = "github:sxyazi/yazi";
    yazi-plugins = {
      url = "github:yazi-rs/plugins";
      flake = false;
    };
  };

  outputs =
    {
      nixpkgs,
      ...
    }@inputs:
    let
      system = "aarch64-darwin";
      version = "26.05";
      arch = system;
      username = "seth";
      lib = nixpkgs.lib.extend (import ./lib/default.nix inputs);
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        config.allowUnfreePredicate = _: true;
        overlays = (import ./overlays { inherit inputs; }) ++ [
          (import ./pkgs { inherit lib; })
        ];
      };

      mkInit = import ./lib/mkInit.nix { inherit nixpkgs; };
      mkDarwin = import ./lib/mkDarwin.nix { inherit inputs lib; };
      mkHome = import ./lib/mkHome.nix { inherit inputs lib; };
    in
    {
      apps."${arch}".default = mkInit {
        inherit arch;
        script = builtins.readFile scripts/${arch}_bootstrap.sh;
      };
      darwinConfigurations.megabookpro = mkDarwin {
        hostname = "megabookpro";
        inherit
          username
          version
          system
          ;
      };
      darwinConfigurations.workbookpro = mkDarwin {
        hostname = "workbookpro";
        inherit
          username
          version
          system
          ;
      };
      homeConfigurations."${username}@megabookpro" = mkHome {
        hostname = "megabookpro";
        inherit
          username
          pkgs
          version
          system
          ;
      };
      homeConfigurations."${username}@workbookpro" = mkHome {
        hostname = "workbookpro";
        inherit
          username
          pkgs
          version
          system
          ;
      };
    };
}
