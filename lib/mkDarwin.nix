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
  ...
}:
{
  hostname,
  username,
  version,
  system,
  extraModules ? [ ],
}:
let
  paths = import ./paths.nix username;
in
inputs.nix-darwin.lib.darwinSystem {
  inherit lib;

  specialArgs = {
    inherit
      inputs
      username
      hostname
      version
      lib
      paths
      ;
    arch = system;
    inherit system;
    inherit (inputs) self;
  };

  modules = [
    { system.configurationRevision = inputs.self.rev or inputs.self.dirtyRev or null; }
    ../hosts/common.nix
    ../hosts/${hostname}.nix
    ../modules/system.nix
    ../modules/darwin/services.nix
    ../modules/darwin/spotlight.nix
    ../modules/darwin/_1password.nix
    ../modules/darwin/okta-verify.nix
    inputs.kanata-darwin.darwinModules.default
    ../modules/darwin/kanata.nix
  ]
  ++ extraModules;
}
