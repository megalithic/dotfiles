# Bootstrap app builder
# Creates a nix app that runs a bootstrap script for initial system setup
#
# Usage:
#   mkInit {
#     arch = "aarch64-darwin";
#     script = builtins.readFile ./scripts/bootstrap.sh;
#   }
#
# Run with: nix run github:megalithic/dotfiles
{ nixpkgs }:
{
  arch,
  script ? ''
    echo "no default app init script set."
  '',
}:
let
  pkgs = nixpkgs.legacyPackages.${arch};
  init = pkgs.writeShellApplication {
    name = "init";
    text = script;
  };
in {
  type = "app";
  program = "${init}/bin/init";
}
