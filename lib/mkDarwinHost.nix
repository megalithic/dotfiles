# Darwin host builder
# Creates a darwin system configuration (system-only, no home-manager)
# Home-manager runs separately via homeConfigurations for true independence
#
# Usage:
#   mkDarwinHost {
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
}:
{
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

        # Shared darwin configuration (minimal system packages, common settings)
        ../hosts/common.nix

        # Host-specific configuration
        ../hosts/${hostname}.nix

        # System modules
        ../modules/system.nix
        ../modules/native-pkg-installer.nix

        # Secrets (system-level)
        inputs.agenix.darwinModules.default

        # Homebrew
        inputs.nix-homebrew.darwinModules.nix-homebrew
        (brew_config {inherit username;})
        ({config, ...}: {
          homebrew.taps = map (key: builtins.replaceStrings ["homebrew-"] [""] key) (builtins.attrNames config.nix-homebrew.taps);
        })
        (import ../modules/brew.nix)

        # NOTE: Home-manager is NOT included here.
        # Use `just home` or `home-manager switch --flake .#user@host` separately.
        # This allows independent darwin and home-manager rebuilds.
      ]
      ++ extraModules;
  }
