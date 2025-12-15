{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
  inherit (lib) literalExpression mkOption types mkEnableOption;

  supportedBrowsers = {
    helium = "Helium";
    brave-browser-nightly = "Brave Browser Nightly";
  };

  # Helper to create a macOS wrapper .app bundle that launches the real app with command-line args
  mkWrapperApp = {
    name, # Display name for the wrapper app (e.g., "Brave Browser Nightly (Debug)")
    originalApp, # Path to the original .app bundle
    appName, # Original app name (e.g., "Brave Browser Nightly")
    executableName, # Name of executable in MacOS folder
    args, # Command-line arguments to pass
    iconFile ? "app.icns", # Icon filename in Resources
    bundleId ? "com.wrapper.app", # Bundle identifier for wrapper
  }:
    pkgs.runCommand "${lib.strings.sanitizeDerivationName name}" {
      nativeBuildInputs = [pkgs.imagemagick];
    } ''
      mkdir -p "$out/Applications/${name}.app/Contents/MacOS"
      mkdir -p "$out/Applications/${name}.app/Contents/Resources"

      # Create the launcher script
      cat > "$out/Applications/${name}.app/Contents/MacOS/launcher" << 'LAUNCHER'
      #!/bin/bash
      # Wrapper launcher for ${name}
      # Launches the original app with custom command-line arguments

      ORIGINAL_APP="${originalApp}"
      EXECUTABLE="$ORIGINAL_APP/Contents/MacOS/${executableName}"

      if [ ! -x "$EXECUTABLE" ]; then
        osascript -e 'display alert "App Not Found" message "Could not find ${appName} at: '$ORIGINAL_APP'"'
        exit 1
      fi

      exec "$EXECUTABLE" ${lib.escapeShellArgs args} "$@"
      LAUNCHER
      chmod +x "$out/Applications/${name}.app/Contents/MacOS/launcher"

      # Create Info.plist
      cat > "$out/Applications/${name}.app/Contents/Info.plist" << 'PLIST'
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
      <dict>
        <key>CFBundleDevelopmentRegion</key>
        <string>en</string>
        <key>CFBundleDisplayName</key>
        <string>${name}</string>
        <key>CFBundleExecutable</key>
        <string>launcher</string>
        <key>CFBundleIconFile</key>
        <string>AppIcon</string>
        <key>CFBundleIdentifier</key>
        <string>${bundleId}</string>
        <key>CFBundleInfoDictionaryVersion</key>
        <string>6.0</string>
        <key>CFBundleName</key>
        <string>${name}</string>
        <key>CFBundlePackageType</key>
        <string>APPL</string>
        <key>CFBundleShortVersionString</key>
        <string>1.0</string>
        <key>CFBundleVersion</key>
        <string>1</string>
        <key>LSMinimumSystemVersion</key>
        <string>10.13</string>
        <key>NSHighResolutionCapable</key>
        <true/>
      </dict>
      </plist>
      PLIST

      # Copy icon from original app (with fallback)
      if [ -f "${originalApp}/Contents/Resources/${iconFile}" ]; then
        cp "${originalApp}/Contents/Resources/${iconFile}" "$out/Applications/${name}.app/Contents/Resources/AppIcon.icns"
      else
        # Create a simple placeholder icon if original not found
        echo "Warning: Could not find icon at ${originalApp}/Contents/Resources/${iconFile}"
      fi

      # Create PkgInfo
      echo -n "APPL????" > "$out/Applications/${name}.app/Contents/PkgInfo"
    '';

  browserModule = browser: name: visible: let
    isProprietaryChrome = lib.hasPrefix "Google Chrome" name;
    # Brave needs special handling since it uses a custom mkApp derivation
    isBrave = lib.hasPrefix "brave" browser;
  in
    {
      enable = mkOption {
        inherit visible;
        type = types.bool;
        default = false;
        example = true;
        description = "Whether to enable ${name}.";
      };

      package = mkOption {
        inherit visible;
        type = types.nullOr types.package;
        default =
          if isBrave
          then null # Brave package must be explicitly provided (pkgs.brave-browser-nightly)
          else pkgs.${browser} or null;
        defaultText = literalExpression "pkgs.${browser}";
        description = "The ${name} package to use.";
      };

      bundleId = mkOption {
        inherit visible;
        type = types.nullOr types.str;
        default = null;
        example = "net.imput.helium";
        description = ''
          The macOS bundle identifier for ${name}.
          Used to determine the Application Support directory path.
          If not set, defaults to the browser name.
        '';
      };

      commandLineArgs = mkOption {
        inherit visible;
        type = types.listOf types.str;
        default = [];
        example = [
          "--enable-logging=stderr"
          "--ignore-gpu-blocklist"
        ];
        description = ''
          List of command-line arguments to be passed to ${name}.

          For a list of common switches, see
          [Chrome switches](https://chromium.googlesource.com/chromium/src/+/refs/heads/main/chrome/common/chrome_switches.cc).

          To search switches for other components, see
          [Chromium codesearch](https://source.chromium.org/search?q=file:switches.cc&ss=chromium%2Fchromium%2Fsrc).
        '';
      };

      # macOS app bundle configuration
      appName = mkOption {
        inherit visible;
        type = types.str;
        default = "${name}.app";
        example = "Brave Browser Nightly.app";
        description = ''
          The .app bundle name within the package's Applications directory.
        '';
      };

      executableName = mkOption {
        inherit visible;
        type = types.str;
        default = name;
        example = "Brave Browser Nightly";
        description = ''
          The executable name inside Contents/MacOS of the app bundle.
        '';
      };

      iconFile = mkOption {
        inherit visible;
        type = types.str;
        default = "app.icns";
        description = ''
          The icon filename inside Contents/Resources of the app bundle.
        '';
      };

      # macOS-specific: Create a wrapper .app for GUI launching with args
      darwinWrapperApp = {
        enable = mkEnableOption "Create a wrapper .app bundle for macOS that launches with commandLineArgs";

        name = mkOption {
          type = types.str;
          default = "${name} (Custom)";
          example = "Brave Browser Nightly (Debug)";
          description = "Display name for the wrapper application.";
        };

        bundleId = mkOption {
          type = types.str;
          default = "com.nix.wrapper.${lib.strings.sanitizeDerivationName browser}";
          description = "Bundle identifier for the wrapper application.";
        };
      };
    }
    // lib.optionalAttrs (!isProprietaryChrome) {
      # Extensions do not work with Google Chrome
      # see https://github.com/nix-community/home-manager/issues/1383
      extensions = mkOption {
        inherit visible;
        type = with types; let
          extensionType = submodule {
            options = {
              id = mkOption {
                type = strMatching "[a-zA-Z]{32}";
                description = ''
                  The extension's ID from the Chrome Web Store url or the unpacked crx.
                '';
                default = "";
              };

              updateUrl = mkOption {
                type = str;
                default = "https://clients2.google.com/service/update2/crx";
                description = ''
                  URL of the extension's update manifest XML file. Linux only.
                '';
              };

              crxPath = mkOption {
                type = nullOr path;
                default = null;
                description = ''
                  Path to the extension's crx file. Linux only.
                '';
              };

              version = mkOption {
                type = nullOr str;
                default = null;
                description = ''
                  The extension's version, required for local installation. Linux only.
                '';
              };
            };
          };
        in
          listOf (coercedTo str (v: {id = v;}) extensionType);
        default = [];
        example = literalExpression ''
          [
            { id = "cjpalhdlnbpafiamejdnhcphjbkeiagm"; } # ublock origin
            {
              id = "dcpihecpambacapedldabdbpakmachpb";
              updateUrl = "https://raw.githubusercontent.com/iamadamdev/bypass-paywalls-chrome/master/updates.xml";
            }
            {
              id = "aaaaaaaaaabbbbbbbbbbcccccccccc";
              crxPath = "/home/share/extension.crx";
              version = "1.0";
            }
          ]
        '';
        description = ''
          List of ${name} extensions to install.
          To find the extension ID, check its URL on the
          [Chrome Web Store](https://chrome.google.com/webstore/category/extensions).

          To install extensions outside of the Chrome Web Store set
          `updateUrl` or `crxPath` and
          `version` as explained in the
          [Chrome
          documentation](https://developer.chrome.com/docs/extensions/mv2/external_extensions).
        '';
      };

      dictionaries = mkOption {
        inherit visible;
        type = types.listOf types.package;
        default = [];
        example = literalExpression ''
          [
            pkgs.hunspellDictsChromium.en_US
          ]
        '';
        description = ''
          List of ${name} dictionaries to install.
        '';
      };
      nativeMessagingHosts = mkOption {
        type = types.listOf types.package;
        default = [];
        example = literalExpression ''
          [
            pkgs.kdePackages.plasma-browser-integration
          ]
        '';
        description = ''
          List of ${name} native messaging hosts to install.
        '';
      };
    };

  browserConfig = browser: cfg: let
    isProprietaryChrome = lib.hasPrefix "google-chrome" browser;
    browserName = supportedBrowsers.${browser};

    # Use bundleId if provided, otherwise fall back to browser name
    darwinDir = if cfg.bundleId != null then cfg.bundleId else browser;
    linuxDir = browser;

    configDir =
      if pkgs.stdenv.isDarwin
      then "Library/Application Support/${darwinDir}"
      else "${config.xdg.configHome}/${linuxDir}";

    extensionJson = ext:
      assert ext.crxPath != null -> ext.version != null;
      with builtins; {
        name = "${configDir}/External Extensions/${ext.id}.json";
        value.text = toJSON (
          if ext.crxPath != null
          then {
            external_crx = ext.crxPath;
            external_version = ext.version;
          }
          else {
            external_update_url = ext.updateUrl;
          }
        );
      };

    dictionary = pkg: {
      name = "${configDir}/Dictionaries/${pkg.passthru.dictFileName}";
      value.source = pkg;
    };

    nativeMessagingHostsJoined = pkgs.symlinkJoin {
      name = "${browser}-native-messaging-hosts";
      paths = cfg.nativeMessagingHosts or [];
    };

    # Path to the original .app bundle
    originalAppPath = "${cfg.package}/Applications/${cfg.appName}";

    # Create wrapper .app for macOS GUI launching with command-line args
    wrapperApp = mkWrapperApp {
      name = cfg.darwinWrapperApp.name;
      originalApp = originalAppPath;
      appName = browserName;
      executableName = cfg.executableName;
      args = cfg.commandLineArgs;
      iconFile = cfg.iconFile;
      bundleId = cfg.darwinWrapperApp.bundleId;
    };

    # CLI wrapper for terminal usage with custom args
    # Uses a different binary name to avoid collision with base package
    # e.g., "helium-custom" instead of "helium"
    cliWrapperName = "${cfg.package.pname or browser}-custom";
    cliWrapper =
      if cfg.commandLineArgs != [] && cfg.package ? pname
      then
        pkgs.runCommand "${cfg.package.name or cfg.package.pname}-cli-wrapped"
          {
            nativeBuildInputs = [pkgs.makeWrapper];
            passthru = cfg.package.passthru or {};
            meta = cfg.package.meta or {};
          }
          ''
            # Only create wrapper if source bin exists
            if [ -x "${cfg.package}/bin/${cfg.package.pname}" ]; then
              mkdir -p $out/bin
              # Use different name to avoid collision with base package
              makeWrapper ${cfg.package}/bin/${cfg.package.pname} $out/bin/${cliWrapperName} \
                --add-flags "${lib.escapeShellArgs cfg.commandLineArgs}"
              echo "Created CLI wrapper: ${cliWrapperName}"
            else
              # Create empty output for packages without bin/
              mkdir -p $out
            fi
          ''
      else null;
  in
    lib.mkIf cfg.enable {
      home.packages = lib.mkIf (cfg.package != null) (
        # Always include the base package
        [cfg.package]
        # Add CLI wrapper if applicable
        ++ lib.optional (cliWrapper != null) cliWrapper
        # Add macOS wrapper .app if enabled
        ++ lib.optional (pkgs.stdenv.isDarwin && cfg.darwinWrapperApp.enable && cfg.commandLineArgs != []) wrapperApp
      );
      home.file = lib.optionalAttrs (!isProprietaryChrome) (
        lib.listToAttrs ((map extensionJson (cfg.extensions or [])) ++ (map dictionary (cfg.dictionaries or [])))
        // lib.optionalAttrs ((cfg.nativeMessagingHosts or []) != []) {
          "${configDir}/NativeMessagingHosts" = {
            source = "${nativeMessagingHostsJoined}/etc/chromium/native-messaging-hosts";
            recursive = true;
          };
        }
      );
    };
in {
  options.programs =
    builtins.mapAttrs (
      browser: name:
        browserModule browser name (
          if browser == "chromium"
          then true
          else false
        )
    )
    supportedBrowsers;

  config = lib.mkMerge (
    builtins.map (browser: browserConfig browser config.programs.${browser}) (
      builtins.attrNames supportedBrowsers
    )
  );
}
