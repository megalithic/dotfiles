# mkApp - Unified macOS application builder
#
# Supports three installation methods:
#   - "extract" (default): Extract DMG/ZIP/PKG to nix store, symlink/copy to /Applications
#   - "native": Run native PKG installer during activation (requires sudo, use sparingly!)
#   - "mas": Install from Mac App Store (delegates to mkMas)
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
# Use "native" ONLY when the app TRULY requires it. Signs you need native:
#   - App has DriverKit system extensions (e.g., virtual HID devices)
#   - App has kernel extensions (kexts) - rare on modern macOS
#   - App installs to /Library/ or requires privileged postinstall scripts
#   - App fails to launch when extracted (code signing path validation issues)
#
# ══════════════════════════════════════════════════════════════════════════════
# HOW TO VERIFY IF AN APP NEEDS NATIVE INSTALL
# ══════════════════════════════════════════════════════════════════════════════
#
# 1. Download the PKG and inspect its contents:
#      pkgutil --payload-files /path/to/installer.pkg | head -30
#
# 2. If it ONLY contains ./Applications/SomeApp.app/* → use "extract"
#
# 3. If it contains any of these → likely needs "native":
#      - ./Library/SystemExtensions/*
#      - ./Library/LaunchDaemons/*
#      - ./Library/PrivilegedHelperTools/*
#      - ./usr/local/bin/* (privileged binaries)
#
# 4. Check for postinstall scripts:
#      pkgutil --expand /path/to/installer.pkg /tmp/pkg-expanded
#      cat /tmp/pkg-expanded/*/Scripts/postinstall
#    If it runs systemextensionsctl, launchctl, or other privileged ops → native
#
# Example: TalkTastic.pkg only contains ./Applications/TalkTastic.app/* → extract
# Example: Karabiner.pkg contains DriverKit extensions and postinstall → native
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
#   # App requiring native PKG installer (rare - verify first!)
#   mkApp { pname = "karabiner"; installMethod = "native"; src = { ... }; pkgName = "Karabiner.pkg"; }
#
#   # Mac App Store app
#   mkApp { pname = "xcode"; installMethod = "mas"; appStoreId = 497799835; }
{
  pkgs,
  lib ? pkgs.lib,
  stdenvNoCC ? pkgs.stdenvNoCC,
  ...
}: args @ {
  pname,
  version ? null,
  src ? null, # { url, sha256 } - not needed for mas
  installMethod ? "extract", # "extract" | "native" | "mas"
  appName ? "${pname}.app",
  desc ? null,
  homepage ? null,
  # Extract method options
  artifactType ? "app", # "app", "pkg", or "binary"
  binaries ? [pname], # CLI commands to expose in ~/.local/bin (defaults to pname)
  appLocation ? "home-manager", # "home-manager" | "symlink" | "copy"
  # Native method options
  pkgName ? null, # Name of PKG file inside DMG (e.g., "Karabiner-Elements.pkg")
  postNativeInstall ? "", # Script to run after native installer completes
  uninstallScript ? null, # Custom uninstall script (optional)
  # MAS method options
  appStoreId ? null,
  ...
}: let
  # Import the extract implementation (current mkCask logic)
  mkExtract = import ./mkApp/extract.nix {inherit pkgs lib stdenvNoCC;};

  # Import the native installer implementation
  mkNative = import ./mkApp/native.nix {inherit pkgs lib stdenvNoCC;};

  # Import mkMas for App Store apps
  mkMasImpl = import ./mkMas.nix {inherit pkgs lib;};
in
  if installMethod == "extract"
  then
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
  else if installMethod == "native"
  then
    mkNative {
      inherit
        pname
        version
        appName
        desc
        homepage
        pkgName
        postNativeInstall
        uninstallScript
        ;
      url = src.url;
      sha256 = src.sha256;
    }
  else if installMethod == "mas"
  then
    # For mas, we return a "marker" derivation with passthru
    # The actual installation happens via activation script
    let
      masResult = mkMasImpl {"${pname}" = appStoreId;};
    in
      stdenvNoCC.mkDerivation {
        inherit pname;
        version = "mas";
        dontUnpack = true;
        installPhase = "mkdir -p $out";

        passthru = {
          isMasApp = true;
          inherit appStoreId;
          activationScript = masResult.activationScript;
        };

        meta = {
          description = if desc != null then desc else "Mac App Store application";
          platforms = lib.platforms.darwin;
        };
      }
  else
    throw "mkApp: Unknown installMethod '${installMethod}'. Must be 'extract', 'native', or 'mas'."
