# Darwin host builder
# Creates a darwin system configuration (system-only, no home-manager)
# Home-manager runs separately via homeConfigurations for true independence
#
# Usage:
#   mkDarwin {
#     hostname = "megabookpro";
#     username = "seth";
#     system = "aarch64-darwin";  # optional, defaults to aarch64-darwin
#     extraModules = [];          # optional, additional modules
#   }
{
  inputs,
  lib,
  overlays,
  brew_config,
  version,
}: {
  hostname,
  username,
  system ? "aarch64-darwin",
  extraModules ? [],
}: let
  paths = import ./paths.nix username;
in
  inputs.nix-darwin.lib.darwinSystem {
    inherit lib;

    specialArgs = {
      inherit inputs username hostname version overlays lib paths;
      arch = system;
      self = inputs.self;
    };

    modules =
      [
        {system.configurationRevision = inputs.self.rev or inputs.self.dirtyRev or null;}
        {nixpkgs.overlays = overlays;}
        {nixpkgs.config.allowUnfree = true;}
        {nixpkgs.config.allowUnfreePredicate = _: true;}
        ../hosts/common.nix
        ../hosts/${hostname}.nix
        ../modules/system.nix
        ../modules/darwin/services.nix
        inputs.kanata-darwin.darwinModules.default
        inputs.komorebi-for-mac.darwinModules.default
        ../modules/darwin/kanata.nix
        inputs.agenix.darwinModules.default
        inputs.nix-homebrew.darwinModules.nix-homebrew
        (brew_config {inherit username;})
        ({config, ...}: {
          homebrew.taps = map (key: builtins.replaceStrings ["homebrew-"] [""] key) (builtins.attrNames config.nix-homebrew.taps);
        })
        (import ../modules/brew.nix)
      ]
      ++ extraModules;
  }
