# Custom packages overlay
#
# This directory contains YOUR custom package definitions.
# Each package is either:
#   - A callPackage derivation (tools, CLI apps)
#   - A mkApp derivation (macOS .app bundles from DMG/ZIP)
#
# This file exports a single overlay that exposes all custom packages
# into the nixpkgs namespace (e.g., pkgs.helium, pkgs.chrome-devtools-mcp).
#
# For external overlays, package sets (stable/unstable), and input aliases,
# see overlays/default.nix instead.
#
{lib}: final: prev: let
  mkApp =
    import ../lib/mkApp.nix {
      pkgs = prev;
      inherit lib;
      stdenvNoCC = prev.stdenvNoCC;
    };
in {
  # ===========================================================================
  # CLI Tools & Utilities
  # ===========================================================================
  chrome-devtools-mcp = prev.callPackage ./chrome-devtools-mcp.nix {};

  # ===========================================================================
  # macOS Apps (mkApp - DMG/ZIP extraction)
  # ===========================================================================
  # REF:
  # - https://github.com/ayla6/nixcfg/blob/main/modules/home/programs/helium/default.nix
  # - https://github.com/isabelroses/dotfiles/blob/main/modules/home/programs/chromium.nix
  # - https://github.com/will-lol/.dotfiles/blob/main/overlays/helium.nix

  brave-browser-nightly = mkApp {
    pname = "brave-browser-nightly";
    version = "1.87.61.0";
    appName = "Brave Browser Nightly.app";
    src = {
      url = "https://updates-cdn.bravesoftware.com/sparkle/Brave-Browser/nightly-arm64/187.61/Brave-Browser-Nightly-arm64.dmg";
      sha256 = "0i8j94d9b24djv3wpnx1rszxrn0h4r0md2djx8104by1kyi11vby";
    };
    desc = "Privacy-focused web browser - Nightly build";
    homepage = "https://brave.com/download-nightly/";
  };

  fantastical = mkApp {
    pname = "fantastical";
    version = "4.1.5";
    appName = "Fantastical.app";
    src = {
      url = "https://cdn.flexibits.com/Fantastical_4.1.5.zip";
      sha256 = "095747c4f1b1syyzfhcv651rmy6y4cx4pm9qy4sdqsxp8kqgrm97";
    };
    desc = "Calendar and tasks app";
    homepage = "https://flexibits.com/fantastical";
  };

  helium = mkApp {
    pname = "helium";
    version = "0.4.13.1";
    appName = "Helium.app";
    src = {
      url = "https://github.com/imputnet/helium-macos/releases/download/0.4.13.1/helium_0.4.13.1_arm64-macos.dmg";
      sha256 = "sha256-3j4souWY+4EGPSQR6uURjyqu3bkB5G9xuJbvOk9cZd8=";
    };
    desc = "Privacy-focused web browser based on ungoogled-chromium";
    homepage = "https://github.com/imputnet/helium-chromium";
  };
}
