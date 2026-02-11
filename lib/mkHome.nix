# Standalone home-manager configuration builder
# Creates a home-manager configuration that can be used independently of darwin-rebuild
#
# Usage:
#   mkHome {
#     hostname = "megabookpro";
#     username = "seth";
#     system = "aarch64-darwin";  # optional
#   }
#
# Rebuild with:
#   home-manager switch --flake .#seth@megabookpro
{
  inputs,
  lib,
  overlays,
  version,
}:
{
  hostname,
  username,
  system ? "aarch64-darwin",
}:
let
  paths = import ./paths.nix username;
  pkgs = import inputs.nixpkgs {
    inherit system;
    inherit overlays;
    config = {
      allowUnfree = true;
      allowUnfreePredicate = _: true;
    };
  };
in
  inputs.home-manager.lib.homeManagerConfiguration {
    inherit pkgs;

    modules = [../home/${hostname}.nix];

    extraSpecialArgs = {
      inherit inputs username hostname version overlays lib paths;
      arch = system;
    };
  }
