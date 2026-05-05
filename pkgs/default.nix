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
# For external overlays, package sets (stable/unstable), and input aliases,
# see overlays/default.nix instead.
#
{lib}: final: prev: let
  mkApp = import ../lib/mkApp.nix {
    pkgs = prev;
    inherit lib;
    inherit (prev) stdenvNoCC;
  };
  callMkApp = file: import file {inherit mkApp;};
in {
  # ===========================================================================
  # CLI Tools & Utilities
  # ===========================================================================
  chrome-devtools-mcp = prev.callPackage ./chrome-devtools-mcp.nix {};
  whisperkit-cli = prev.callPackage ./cli/whisperkit-cli.nix {};

  # ===========================================================================
  # macOS Apps (mkApp - DMG/ZIP extraction)
  # ===========================================================================
  fantastical = callMkApp ./fantastical.nix;
  bloom = callMkApp ./bloom.nix;
  brave-browser-nightly = callMkApp ./brave-browser-nightly.nix;
  helium-browser = prev.callPackage ./helium-browser.nix {};
  inherit (import ./tidewave.nix {inherit mkApp;}) tidewave tidewave-cli;
}
