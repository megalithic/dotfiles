# Custom lib extensions
# All custom helpers are namespaced under lib.mega
inputs: lib: _:
{
  # ===========================================================================
  # lib.mega - Custom helper functions namespace
  # ===========================================================================
  mega = {
    # mkApp - macOS application builder
    # Extracts DMG/ZIP/PKG to nix store, symlinks to /Applications
    # For apps needing DriverKit/system extensions, use Homebrew instead.
    # For Mac App Store apps, use homebrew.masApps in modules/brew.nix
    #
    # Usage:
    #   lib.mega.mkApp { pname = "mailmate"; version = "5673"; src = { url = "..."; sha256 = "..."; }; }
    mkApp = import ./mkApp.nix;

    # mkAppActivation - Generate activation scripts for linking/copying apps to a target directory
    # Usage:
    #   system.activationScripts.linkApps.text = lib.mega.mkAppActivation {
    #     inherit pkgs;
    #     packages = config.environment.systemPackages;
    #     targetDir = "/Applications";
    #   };
    mkAppActivation = {
      pkgs,
      packages,
      targetDir, # e.g. "/Applications" or "~/Applications"
      metadataSubdir ? "apps",
    }: let
      # Filter packages that have an Applications/ subdirectory
      appsToProcess = builtins.filter (pkg: builtins.pathExists "${pkg}/Applications") packages;

      # For each package, find the app name and determine if it should be copied
      getAppInfo = pkg: let
        passthru = pkg.passthru or {};
        passthruAppName = passthru.appName or null;
        appLocation = passthru.appLocation or "symlink";
        
        foundAppName = let
          appsDir = "${pkg}/Applications";
          apps = builtins.attrNames (builtins.readDir appsDir);
        in if apps != [] then builtins.head apps else null;

        appName = if passthruAppName != null then passthruAppName else foundAppName;
      in {
        inherit pkg appName appLocation;
        appPath = "${pkg}/Applications/${appName}";
      };

      appsWithInfo = builtins.map getAppInfo (builtins.filter (pkg: (getAppInfo pkg).appName != null) appsToProcess);

      # Build list of current app names for cleanup
      currentAppNames = builtins.map (info: info.appName) appsWithInfo;
      currentAppsString = lib.strings.concatStringsSep "\n" currentAppNames;

      cleanupScript = ''
        # Resolve targetDir
        TARGET_DIR=$(eval echo "${targetDir}")
        mkdir -p "$TARGET_DIR"

        METADATA_DIR="$HOME/.local/share/nix-metadata/${metadataSubdir}"
        mkdir -p "$METADATA_DIR"

        CURRENT_APPS=$(cat <<'APPS_EOF'
        ${currentAppsString}
        APPS_EOF
        )

        if [[ -d "$METADATA_DIR" ]]; then
          for metadata_file in "$METADATA_DIR"/*.nixpath; do
            if [[ -f "$metadata_file" ]]; then
              app_name=$(basename "$metadata_file" .nixpath)
              if ! echo "$CURRENT_APPS" | ${pkgs.ripgrep}/bin/rg -qFx "$app_name"; then
                echo "Removing orphaned app: $app_name from $TARGET_DIR" 2>/dev/null
                if [[ -e "$TARGET_DIR/$app_name" ]]; then
                  # Use /usr/bin/sudo if targetDir is /Applications
                  # (darwin activation runs as root so sudo is no-op, but /usr/bin/sudo
                  # is used for robustness in case PATH is minimal)
                  if [[ "$TARGET_DIR" == "/Applications" ]]; then
                    /usr/bin/sudo chmod -R u+w "$TARGET_DIR/$app_name" 2>/dev/null || true
                    /usr/bin/sudo rm -rf "''${TARGET_DIR:?}/''${app_name}"
                  else
                    chmod -R u+w "$TARGET_DIR/$app_name" 2>/dev/null || true
                    rm -rf "''${TARGET_DIR:?}/''${app_name}"
                  fi
                fi
                rm -f "$metadata_file"
              fi
            fi
          done
        fi

        # Clean up legacy user-level directories
        LEGACY_HM_APPS="$HOME/Applications/Home Manager Apps"
        if [[ -d "$LEGACY_HM_APPS" ]]; then
          # Cleaning up legacy Home Manager Apps directory
          rm -rf "$LEGACY_HM_APPS"
        fi

        LEGACY_NIX_ALIASES="$HOME/Applications/Nix"
        if [[ -d "$LEGACY_NIX_ALIASES" ]]; then
          # Cleaning up legacy Nix alias directory
          rm -rf "$LEGACY_NIX_ALIASES"
        fi
      '';

      mkActivationScript = info: let
        inherit (info) pkg appName appPath appLocation;
        shouldCopy = appLocation == "copy";
      in
        if shouldCopy
        then ''
          METADATA_FILE="$METADATA_DIR/${appName}.nixpath"

          SHOULD_COPY=1
          if [[ -f "$METADATA_FILE" ]]; then
            CURRENT_PATH=$(cat "$METADATA_FILE")
            if [[ "$CURRENT_PATH" == "${appPath}" ]] && [[ -e "$TARGET_DIR/${appName}" ]]; then
              SHOULD_COPY=0
            else
              chmod -R u+w "$TARGET_DIR/$app_name" 2>/dev/null || true
              rm -rf "$TARGET_DIR/${appName}"
            fi
          elif [[ -e "$TARGET_DIR/${appName}" ]]; then
            if [[ -L "$TARGET_DIR/${appName}" ]]; then
               rm -f "$TARGET_DIR/${appName}"
            else
               # Take over existing unmanaged copy
               chmod -R u+w "$TARGET_DIR/${appName}" 2>/dev/null || true
               rm -rf "$TARGET_DIR/${appName}"
            fi
          fi

          if [[ $SHOULD_COPY -eq 1 ]]; then
            if [[ -e "${appPath}" ]]; then
              if [[ "$TARGET_DIR" == "/Applications" ]]; then
                /usr/bin/sudo cp -R "${appPath}" "$TARGET_DIR/${appName}"
                echo "${appPath}" | /usr/bin/sudo tee "$METADATA_FILE" > /dev/null
                /usr/bin/sudo xattr -cr "$TARGET_DIR/${appName}" 2>/dev/null || true
              else
                cp -R "${appPath}" "$TARGET_DIR/${appName}"
                echo "${appPath}" > "$METADATA_FILE"
                xattr -cr "$TARGET_DIR/${appName}" 2>/dev/null || true
              fi
            else
              echo "Warning: Could not find ${appPath} for copy"
            fi
          fi
        ''
        else ''
          METADATA_FILE="$METADATA_DIR/${appName}.nixpath"

          if [[ -L "$TARGET_DIR/${appName}" ]]; then
            if [[ "$TARGET_DIR" == "/Applications" ]]; then
              /usr/bin/sudo rm -f "$TARGET_DIR/${appName}"
            else
              rm -f "$TARGET_DIR/${appName}"
            fi
          elif [[ -e "$TARGET_DIR/${appName}" ]]; then
            echo "Warning: $TARGET_DIR/${appName} exists and is not a symlink. Skipping."
          fi

          if [[ ! -e "$TARGET_DIR/${appName}" ]]; then
            if [[ -e "${appPath}" ]]; then
              if [[ "$TARGET_DIR" == "/Applications" ]]; then
                /usr/bin/sudo ln -sf "${appPath}" "$TARGET_DIR/${appName}"
                echo "${appPath}" | /usr/bin/sudo tee "$METADATA_FILE" > /dev/null
              else
                ln -sf "${appPath}" "$TARGET_DIR/${appName}"
                echo "${appPath}" > "$METADATA_FILE"
              fi
            else
              echo "Warning: Could not find ${appPath} for linking"
            fi
          fi
        '';

      # Separate helper for binaries as they usually only go to ~/.local/bin
      mkBinaryScript = pkg: let
        passthru = pkg.passthru or {};
        binaries = passthru.binaries or [];
        pname = pkg.pname or pkg.name or "unknown";
        binDir = "$HOME/.local/bin";
        binMetadataDir = "$HOME/.local/share/nix-metadata/bins";
      in
        if !(builtins.isList binaries) || binaries == [] then "" else
        ''
          mkdir -p "${binDir}" "${binMetadataDir}"
          ${lib.strings.concatMapStringsSep "\n" (binName: ''
            BIN_PATH="${pkg}/bin/${binName}"
            BIN_METADATA_FILE="${binMetadataDir}/${binName}.nixpath"
            if [[ -x "$BIN_PATH" ]]; then
              if [[ -f "$BIN_METADATA_FILE" ]] && [[ "$(cat "$BIN_METADATA_FILE")" == "$BIN_PATH" ]] && [[ -L "${binDir}/${binName}" ]]; then
                : # Already up to date
              else
                rm -f "${binDir}/${binName}"
                ln -sf "$BIN_PATH" "${binDir}/${binName}"
                echo "$BIN_PATH" > "$BIN_METADATA_FILE"
                echo "✓ ${binName} linked to ${binDir}"
              fi
            fi
          '') binaries}
        '';

      activationScripts = builtins.map mkActivationScript appsWithInfo;
      binaryScripts = builtins.map mkBinaryScript packages;
    in
      lib.strings.concatStringsSep "\n\n" ([cleanupScript] ++ activationScripts ++ binaryScripts);

  };
}
# Make sure to add lib extensions from inputs
// inputs.home-manager.lib
// inputs.nix-darwin.lib
