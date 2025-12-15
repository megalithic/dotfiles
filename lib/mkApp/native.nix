# mkApp/native.nix - Native PKG installer method
#
# For apps that MUST use the official PKG installer due to:
#   - System extension requirements (DriverKit, kernel extensions)
#   - Code signature validation against install paths
#   - PKG postinstall scripts that handle privileged operations
#
# This method:
#   1. Stores the source DMG/PKG in the nix store (declarative, reproducible)
#   2. Generates install/uninstall scripts
#   3. Provides passthru attributes for activation module to discover and run
#
# The actual installation happens during nix-darwin activation, NOT during derivation build.
{
  pkgs,
  lib ? pkgs.lib,
  stdenvNoCC ? pkgs.stdenvNoCC,
  ...
}: {
  pname,
  version,
  url,
  sha256,
  appName ? "${pname}.app",
  desc ? null,
  homepage ? null,
  pkgName ? null, # PKG file inside DMG (e.g., "Karabiner-Elements.pkg"), null if URL is .pkg directly
  postNativeInstall ? "", # Script to run after installer completes
  uninstallScript ? null, # Custom uninstall script (optional)
}: let
  # Determine if source is DMG containing PKG, or direct PKG
  isDmg = lib.strings.hasSuffix ".dmg" url;
  isPkgDirect = lib.strings.hasSuffix ".pkg" url;

  # Download the source artifact
  sourceArtifact = pkgs.fetchurl {
    inherit url sha256;
  };

  # Metadata directory for tracking installed versions
  metadataDir = "/var/lib/nix-native-pkgs/${pname}";
  metadataFile = "${metadataDir}/version";

  # Generate the install script
  installScript = pkgs.writeShellScript "install-${pname}" ''
    set -e

    PNAME="${pname}"
    VERSION="${version}"
    SOURCE="${sourceArtifact}"
    METADATA_DIR="${metadataDir}"
    METADATA_FILE="${metadataFile}"
    PKG_NAME="${if pkgName != null then pkgName else ""}"
    IS_DMG="${if isDmg then "1" else "0"}"

    mkdir -p "$METADATA_DIR"

    # Check if already installed at this version
    if [ -f "$METADATA_FILE" ]; then
      INSTALLED_VERSION=$(cat "$METADATA_FILE")
      if [ "$INSTALLED_VERSION" = "$VERSION" ]; then
        echo "[native-pkg] $PNAME $VERSION already installed"
        exit 0
      fi
      echo "[native-pkg] Upgrading $PNAME from $INSTALLED_VERSION to $VERSION"
    else
      echo "[native-pkg] Installing $PNAME $VERSION..."
    fi

    if [ "$IS_DMG" = "1" ]; then
      # Mount DMG and find PKG
      MOUNT_POINT=$(mktemp -d)
      trap "hdiutil detach '$MOUNT_POINT' 2>/dev/null || true; rm -rf '$MOUNT_POINT'" EXIT

      echo "[native-pkg] Mounting DMG..."
      hdiutil attach "$SOURCE" -mountpoint "$MOUNT_POINT" -nobrowse -quiet

      if [ -n "$PKG_NAME" ]; then
        PKG_PATH="$MOUNT_POINT/$PKG_NAME"
      else
        # Try to find a .pkg file
        # fd: -d 1 = max depth 1, -e pkg = extension .pkg, -1 = first match only
        PKG_PATH=$(${pkgs.fd}/bin/fd -d 1 -e pkg . "$MOUNT_POINT" | head -1)
      fi

      if [ ! -f "$PKG_PATH" ]; then
        echo "[native-pkg] ERROR: PKG not found in DMG"
        exit 1
      fi

      echo "[native-pkg] Running PKG installer: $PKG_PATH"
      /usr/sbin/installer -pkg "$PKG_PATH" -target / -verboseR
    else
      # Direct PKG file
      echo "[native-pkg] Running PKG installer: $SOURCE"
      /usr/sbin/installer -pkg "$SOURCE" -target / -verboseR
    fi

    # Record installed version
    echo "$VERSION" > "$METADATA_FILE"

    ${lib.optionalString (postNativeInstall != "") ''
      echo "[native-pkg] Running post-install script..."
      ${postNativeInstall}
    ''}

    echo "[native-pkg] $PNAME $VERSION installation complete"
  '';

  # Generate default uninstall script if not provided
  defaultUninstallScript = ''
    echo "[native-pkg] Uninstalling ${pname}..."

    # Remove the app
    if [ -d "/Applications/${appName}" ]; then
      rm -rf "/Applications/${appName}"
    fi

    # Remove metadata
    rm -rf "${metadataDir}"

    echo "[native-pkg] ${pname} uninstalled"
  '';

  finalUninstallScript = pkgs.writeShellScript "uninstall-${pname}" (
    if uninstallScript != null
    then uninstallScript
    else defaultUninstallScript
  );
in
  stdenvNoCC.mkDerivation {
    inherit pname version;

    # Don't actually build anything - just create the marker package
    dontUnpack = true;

    installPhase = ''
      mkdir -p $out/src
      mkdir -p $out/bin

      # Store reference to source artifact
      ln -s ${sourceArtifact} $out/src/source${if isDmg then ".dmg" else ".pkg"}

      # Store install/uninstall scripts
      ln -s ${installScript} $out/bin/install-${pname}
      ln -s ${finalUninstallScript} $out/bin/uninstall-${pname}

      # Store metadata as JSON for the activation module
      cat > $out/meta.json << EOF
      {
        "pname": "${pname}",
        "version": "${version}",
        "appName": "${appName}",
        "pkgName": ${if pkgName != null then "\"${pkgName}\"" else "null"},
        "isDmg": ${if isDmg then "true" else "false"}
      }
      EOF
    '';

    # Passthru attributes for activation module discovery
    passthru = {
      # Flag for activation module to find this package
      isNativeInstaller = true;
      inherit appName;
      inherit version;

      # Scripts for activation module to run
      inherit installScript;
      uninstallScript = finalUninstallScript;

      # Source artifact path (for debugging/inspection)
      src = sourceArtifact;

      # Post-install hook (stored for reference)
      inherit postNativeInstall;

      installMethod = "native";
    };

    meta = {
      description = if desc != null then desc else "macOS application (native installer)";
      homepage = if homepage != null then homepage else "";
      platforms = lib.platforms.darwin;
    };
  }
