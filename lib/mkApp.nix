# mkApp - Unified macOS application builder
#
# Supports three installation methods:
#   - "extract" (default): Extract DMG/ZIP/PKG to nix store, symlink/copy to /Applications
#   - "native": Run native PKG installer during activation (for apps with system extensions, code signing requirements)
#   - "mas": Install from Mac App Store (delegates to mkMas)
#
# Usage:
#   mkApp { pname = "mailmate"; version = "5673"; src = { url = "..."; sha256 = "..."; }; }
#   mkApp { pname = "karabiner"; installMethod = "native"; src = { ... }; pkgName = "Karabiner.pkg"; }
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
  binaries ? [],
  requireSystemApplicationsFolder ? false,
  copyToApplications ? false,
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
        requireSystemApplicationsFolder
        copyToApplications
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
