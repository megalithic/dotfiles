# mkApp - macOS application builder
#
# Extracts DMG/ZIP/PKG to nix store, symlinks to /Applications
#
# ══════════════════════════════════════════════════════════════════════════════
# CHOOSING THE RIGHT METHOD
# ══════════════════════════════════════════════════════════════════════════════
#
# PREFER "extract" (default) for most apps. It works with:
#   - DMG files containing .app bundles
#   - ZIP files containing .app bundles
#   - PKG files that simply contain .app bundles (most apps!)
#
# For apps requiring DriverKit, system extensions, or privileged installers,
# use Homebrew instead (that's literally what it's for).
#
# ══════════════════════════════════════════════════════════════════════════════
# APP LOCATION OPTIONS
# ══════════════════════════════════════════════════════════════════════════════
#
# appLocation controls where the .app bundle is installed:
#
#   "home-manager"  (default) Let home-manager handle it → ~/Applications/Home Manager Apps/
#   "symlink"       Symlink to /Applications (for apps that need /Applications path)
#   "copy"          Copy to /Applications (for code-signed apps like Fantastical)
#
# Use "copy" when an app:
#   - Has strict code signing that breaks with symlinks
#   - Needs to write to its own bundle (updates, plugins)
#   - Validates its installation path
#
# ══════════════════════════════════════════════════════════════════════════════
# USAGE EXAMPLES
# ══════════════════════════════════════════════════════════════════════════════
#
#   # Simple app from DMG (most common) - goes to ~/Applications/Home Manager Apps/
#   mkApp { pname = "mailmate"; version = "5673"; src = { url = "..."; sha256 = "..."; }; }
#
#   # App needing /Applications with code signing (Fantastical, etc.)
#   mkApp { pname = "fantastical"; src = { ... }; appLocation = "copy"; }
#
#   # App from PKG (extracts .app, no installer needed)
#   mkApp { pname = "talktastic"; src = { ... }; artifactType = "pkg"; }
#
#   # Mac App Store apps are handled separately in home/common/mas.nix
{
  pkgs,
  lib ? pkgs.lib,
  stdenvNoCC ? pkgs.stdenvNoCC,
  ...
}: args @ {
  pname,
  version ? null,
  src, # { url, sha256 }
  appName ? "${pname}.app",
  desc ? null,
  homepage ? null,
  # Extract method options
  artifactType ? "app", # "app", "pkg", or "binary"
  binaries ? [pname], # CLI commands to expose in ~/.local/bin (defaults to pname)
  appLocation ? "home-manager", # "home-manager" | "symlink" | "copy"

  ...
}: let
  mkExtract = import ./mkApp/extract.nix {inherit pkgs lib stdenvNoCC;};
in
  mkExtract {
    inherit
      pname
      version
      appName
      desc
      homepage
      artifactType
      binaries
      appLocation
      ;
    url = src.url;
    sha256 = src.sha256;
  }
