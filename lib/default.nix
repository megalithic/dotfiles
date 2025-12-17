# Custom lib extensions
# All custom helpers are namespaced under lib.mega
inputs: lib: _:
{
  # ===========================================================================
  # lib.mega - Custom helper functions namespace
  # ===========================================================================
  mega = {
    # Helper to easily import modules in home/system configs
    imports = let
      modulePath = path:
        if builtins.isPath path
        then
          # Handle explicit paths
          path
        else if (! builtins.isString path)
        then
          # If the path is not a string nor an explicit path try to import it directly
          path
        else if builtins.substring 0 1 (toString path) == "/"
        then
          # Handle absolute paths, including concatenated ones
          path
        else if builtins.pathExists ./modules/${path}
        then
          # Handle directory modules
          ./modules/${path}
        else
          # Otherwise assume it's a nix file
          ./modules/${path}.nix;
    in
      builtins.map modulePath;

    # On macOS creates a simple package that symlinks to a package installed by homebrew
    # REF: https://github.com/KubqoA/dotfiles/blob/main/lib.nix#L36
    brewAlias = pkgs: name:
      lib.mkIf pkgs.stdenv.isDarwin
      (pkgs.stdenv.mkDerivation {
        name = "${name}-brew";
        version = "1.0.0";
        dontUnpack = true;
        installPhase = ''
          mkdir -p $out/bin
          ln -s /opt/homebrew/bin/${name} $out/bin/${name}
        '';
        meta = with pkgs.lib; {
          mainProgram = "${name}";
          description = "Wrapper for Homebrew-installed ${name}";
          platforms = platforms.darwin;
        };
      });

    # String utilities
    capitalize = str: lib.toUpper (lib.substring 0 1 str) + lib.substring 1 (-1) str;
    compactAttrs = lib.filterAttrs (_: value: value != null);

    # mkApp - Unified macOS application builder
    # Supports three installation methods:
    #   - "extract" (default): Extract DMG/ZIP/PKG to nix store
    #   - "native": Run native PKG installer during activation
    #   - "mas": Install from Mac App Store
    #
    # Usage:
    #   lib.mega.mkApp { pname = "mailmate"; version = "5673"; src = { url = "..."; sha256 = "..."; }; }
    #   lib.mega.mkApp { pname = "karabiner"; installMethod = "native"; src = { ... }; pkgName = "Karabiner.pkg"; }
    #   lib.mega.mkApp { pname = "xcode"; installMethod = "mas"; appStoreId = 497799835; }
    mkApp = import ./mkApp.nix;

    # mkApps - Build multiple apps from a list
    # Usage: lib.mega.mkApps { inherit pkgs lib; } [
    #   { pname = "mailmate"; version = "5673"; src = { url = "..."; sha256 = "..."; }; }
    #   { pname = "karabiner"; installMethod = "native"; src = { ... }; pkgName = "..."; }
    # ]
    mkApps = {
      pkgs,
      lib ? pkgs.lib,
      stdenvNoCC ? pkgs.stdenvNoCC,
    }: appDefinitions:
      builtins.map (
        appDef: (import ./mkApp.nix) {inherit pkgs lib stdenvNoCC;} appDef
      ) appDefinitions;

    # mkAppActivation - Generate home-manager activation scripts for apps requiring /Applications
    # Also handles CLI binary symlinks in ~/.local/bin/
    # Usage: Add to home.activation:
    #   home.activation.linkSystemApplications = lib.hm.dag.entryAfter ["writeBoundary"] (
    #     lib.mega.mkAppActivation { inherit pkgs; packages = config.home.packages; }
    #   );
    mkAppActivation = {pkgs, packages}: let
      # Filter packages that need /Applications (symlink or copy)
      appsNeedingSystemFolder = builtins.filter (
        pkg: let
          location = (pkg.passthru or {}).appLocation or "home-manager";
        in
          location == "symlink" || location == "copy"
      ) packages;

      # Filter packages that have CLI binaries to expose (must be a list)
      packagesWithBinaries = builtins.filter (
        pkg: let
          binaries = (pkg.passthru or {}).binaries or null;
        in
          binaries != null && builtins.isList binaries && binaries != []
      ) packages;

      # Build list of current app names for cleanup
      currentAppNames = builtins.map (pkg: pkg.passthru.appName) appsNeedingSystemFolder;
      currentAppsString = lib.strings.concatStringsSep "\n" currentAppNames;

      # Build list of current binary names for cleanup
      currentBinaryNames = lib.flatten (builtins.map (pkg: pkg.passthru.binaries) packagesWithBinaries);
      currentBinariesString = lib.strings.concatStringsSep "\n" currentBinaryNames;

      # Cleanup script for orphaned apps and binaries
      cleanupScript = ''
        # Cleanup orphaned nix-managed apps
        METADATA_DIR="$HOME/.local/share/nix-apps"
        mkdir -p "$METADATA_DIR"

        # Current apps that should be installed
        CURRENT_APPS=$(cat <<'APPS_EOF'
        ${currentAppsString}
        APPS_EOF
        )

        # Check each metadata file and remove apps no longer in config
        if [[ -d "$METADATA_DIR" ]]; then
          for metadata_file in "$METADATA_DIR"/*.nixpath; do
            if [[ -f "$metadata_file" ]]; then
              app_name=$(basename "$metadata_file" .nixpath)
              # rg: -q = quiet, -F = fixed string, -x = match whole line
              if ! echo "$CURRENT_APPS" | ${pkgs.ripgrep}/bin/rg -qFx "$app_name"; then
                echo "Removing orphaned app: $app_name"
                if [[ -e "/Applications/$app_name" ]]; then
                  chmod -R u+w "/Applications/$app_name" 2>/dev/null || true
                  rm -rf "/Applications/$app_name"
                fi
                rm -f "$metadata_file"
              fi
            fi
          done
        fi

        # Cleanup orphaned nix-managed binaries in ~/.local/bin
        BIN_DIR="$HOME/.local/bin"
        BIN_METADATA_DIR="$HOME/.local/share/nix-bins"
        mkdir -p "$BIN_DIR" "$BIN_METADATA_DIR"

        # Current binaries that should be installed
        CURRENT_BINS=$(cat <<'BINS_EOF'
        ${currentBinariesString}
        BINS_EOF
        )

        # Check each metadata file and remove binaries no longer in config
        if [[ -d "$BIN_METADATA_DIR" ]]; then
          for metadata_file in "$BIN_METADATA_DIR"/*.nixpath; do
            if [[ -f "$metadata_file" ]]; then
              bin_name=$(basename "$metadata_file" .nixpath)
              if ! echo "$CURRENT_BINS" | ${pkgs.ripgrep}/bin/rg -qFx "$bin_name"; then
                echo "Removing orphaned binary: $bin_name"
                rm -f "$BIN_DIR/$bin_name"
                rm -f "$metadata_file"
              fi
            fi
          done
        fi
      '';

      # Generate activation script for each cask
      mkActivationScript = pkg: let
        appName = pkg.passthru.appName;
        appPath = "${pkg}/Applications/${appName}";
        appLocation = pkg.passthru.appLocation or "home-manager";
        shouldCopy = appLocation == "copy";
      in
        if shouldCopy
        then ''
          echo "Copying ${appName} to /Applications..."

          # Use a metadata directory outside the app bundle to avoid breaking code signatures
          METADATA_DIR="$HOME/.local/share/nix-apps"
          mkdir -p "$METADATA_DIR"
          METADATA_FILE="$METADATA_DIR/${appName}.nixpath"

          # Check if the app in /Applications is already from this Nix store path
          SHOULD_COPY=1
          if [[ -f "$METADATA_FILE" ]]; then
            CURRENT_PATH=$(cat "$METADATA_FILE")
            if [[ "$CURRENT_PATH" == "${appPath}" ]] && [[ -e "/Applications/${appName}" ]]; then
              echo "✓ ${appName} is already up to date in /Applications"
              SHOULD_COPY=0
            else
              echo "  Removing outdated version..."
              chmod -R u+w "/Applications/${appName}" 2>/dev/null || true
              rm -rf "/Applications/${appName}"
            fi
          elif [[ -e "/Applications/${appName}" ]]; then
            echo "  Removing existing app..."
            chmod -R u+w "/Applications/${appName}" 2>/dev/null || true
            rm -rf "/Applications/${appName}"
          fi

          # Copy the app bundle to /Applications
          if [[ $SHOULD_COPY -eq 1 ]]; then
            if [[ -e "${appPath}" ]]; then
              echo "  Copying app bundle..."
              cp -R "${appPath}" "/Applications/${appName}"

              # Store the Nix store path for future updates (outside the bundle to preserve code signature)
              echo "${appPath}" > "$METADATA_FILE"

              # Clear ALL extended attributes to prevent "damaged app" errors
              # This includes: com.apple.quarantine, com.apple.provenance, com.apple.macl
              xattr -cr "/Applications/${appName}" 2>/dev/null || true

              echo "✓ ${appName} copied to /Applications"
            else
              echo "Warning: Could not find ${appPath}"
            fi
          fi
        ''
        else ''
          echo "Symlinking ${appName} to /Applications..."

          # Remove existing symlink or app if it exists
          if [[ -L "/Applications/${appName}" ]] || [[ -e "/Applications/${appName}" ]]; then
            rm -rf "/Applications/${appName}"
          fi

          # Create symlink from Nix store to /Applications
          if [[ -e "${appPath}" ]]; then
            ln -sf "${appPath}" "/Applications/${appName}"
            echo "✓ ${appName} linked to /Applications"
          else
            echo "Warning: Could not find ${appPath}"
          fi
        '';

      # Generate activation script for binaries
      mkBinaryScript = pkg: let
        binaries = pkg.passthru.binaries;
        pname = pkg.pname or pkg.name or "unknown";
      in
        lib.strings.concatMapStringsSep "\n" (binName: ''
          # Link ${binName} from ${pname}
          BIN_PATH="${pkg}/bin/${binName}"
          BIN_METADATA_FILE="$BIN_METADATA_DIR/${binName}.nixpath"

          if [[ -x "$BIN_PATH" ]]; then
            # Check if already linked to current store path
            if [[ -f "$BIN_METADATA_FILE" ]] && [[ "$(cat "$BIN_METADATA_FILE")" == "$BIN_PATH" ]] && [[ -L "$BIN_DIR/${binName}" ]]; then
              echo "✓ ${binName} already up to date"
            else
              rm -f "$BIN_DIR/${binName}"
              ln -sf "$BIN_PATH" "$BIN_DIR/${binName}"
              echo "$BIN_PATH" > "$BIN_METADATA_FILE"
              echo "✓ ${binName} linked to ~/.local/bin"
            fi
          else
            echo "Warning: Binary $BIN_PATH not found for ${binName}"
          fi
        '') binaries;

      activationScripts = builtins.map mkActivationScript appsNeedingSystemFolder;
      binaryScripts = builtins.map mkBinaryScript packagesWithBinaries;
      allScripts = [cleanupScript] ++ activationScripts ++ binaryScripts;
    in
      lib.strings.concatStringsSep "\n\n" allScripts;

    # mkMas - Install Mac App Store applications
    # Usage: lib.mega.mkMas { "Xcode" = 497799835; "Keynote" = 409183694; }
    # Returns an attrset with:
    #   - script: A shell script that can be run directly
    #   - activationScript: Script content for use in system.activationScripts
    mkMas = import ./mkMas.nix;
  };
}
# Make sure to add lib extensions from inputs
// inputs.home-manager.lib
// inputs.nix-darwin.lib
