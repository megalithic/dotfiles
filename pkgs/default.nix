# Custom packages overlay
#
# This directory contains YOUR custom package definitions.
# Each package is either:
#   - A callPackage derivation (tools, CLI apps)
#   - A mkApp derivation (macOS .app bundles from DMG/ZIP)
#
# This file exports a single overlay that exposes all custom packages
# into the nixpkgs namespace (e.g., pkgs.fantastical, pkgs.chrome-devtools-mcp).
#
# For external overlays and input aliases, see overlays/default.nix instead.
#
{ lib }:
_final: prev:
let
  mkApp = import ../lib/mkApp.nix {
    pkgs = prev;
    inherit lib;
    inherit (prev) stdenvNoCC;
  };

  packageFiles =
    dir:
    lib.concatMapAttrs (
      name: type:
      let
        path = dir + "/${name}";
      in
      if type == "directory" then
        packageFiles path
      else if type == "regular" && lib.hasSuffix ".nix" name && name != "default.nix" then
        { ${lib.removeSuffix ".nix" name} = path; }
      else
        { }
    ) (builtins.readDir dir);

  callLocalPackage =
    _name: path:
    let
      args = builtins.functionArgs (import path);
    in
    prev.callPackage path (lib.optionalAttrs (args ? mkApp) { inherit mkApp; });
in
lib.mapAttrs callLocalPackage (packageFiles ./.)
