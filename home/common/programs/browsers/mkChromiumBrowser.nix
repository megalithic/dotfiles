{
  config,
  lib,
  pkgs,
  inputs,
  self,
  ...
}: let
  inherit (lib) literalExpression mkOption types mkEnableOption;

  supportedBrowsers = {
    helium-browser = "Helium";
    brave-browser-nightly = "Brave Browser Nightly";
  };

  # Wrapper .app builder - extracted to lib/builders/mkWrapperApp.nix
  mkWrapperApp = import "${self}/lib/builders/mkWrapperApp.nix" { inherit pkgs lib; };

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

      # macOS keyboard shortcuts (NSUserKeyEquivalents)
      # These are set via targets.darwin.defaults using the browser's bundleId
      # Key format: ^ = Ctrl, $ = Shift, ~ = Option, @ = Cmd
      keyEquivalents = mkOption {
        inherit visible;
        type = types.attrsOf types.str;
        default = {};
        example = {
          "Close Tab" = "^w";
          "New Tab" = "^t";
          "Select Previous Tab" = "^h";
          "Select Next Tab" = "^l";
        };
        description = ''
          macOS keyboard shortcut overrides for ${name} menu items.
          Uses NSUserKeyEquivalents format:
            ^ = Control, $ = Shift, ~ = Option, @ = Command
          Example: "^$n" = Ctrl+Shift+N
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
    darwinDir =
      if cfg.bundleId != null
      then cfg.bundleId
      else browser;
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
      inherit (cfg.darwinWrapperApp) name;
      originalApp = originalAppPath;
      appName = browserName;
      inherit (cfg) executableName;
      args = cfg.commandLineArgs;
      inherit (cfg) iconFile;
      inherit (cfg.darwinWrapperApp) bundleId;
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
    # Determine if this package should be managed by home-manager's copyApps
    # Check package's passthru.appLocation - if "symlink" or "copy", mkAppActivation handles it
    # Only "home-manager" (default) should be added to home.packages
    appLocation = (cfg.package.passthru or {}).appLocation or "home-manager";
    shouldAddToHomePackages = appLocation == "home-manager";
  in
    lib.mkIf cfg.enable {
      # Add packages to home.packages with smart handling:
      # - Base package: only if appLocation is "home-manager" (avoid duplicates with mkAppActivation)
      # - CLI wrapper: always (it's a CLI tool, not an .app)
      # - Darwin wrapper .app: always if enabled (needed to launch with command line args from Finder)
      home.packages =
        # Base package - only if managed by home-manager
        lib.optionals (cfg.package != null && shouldAddToHomePackages) [cfg.package]
        # CLI wrapper - always add if available
        ++ lib.optional (cliWrapper != null) cliWrapper
        # macOS wrapper .app - always add if enabled (this is how Finder launches with args)
        ++ lib.optional (pkgs.stdenv.isDarwin && cfg.darwinWrapperApp.enable && cfg.commandLineArgs != []) wrapperApp;
      home.file = lib.optionalAttrs (!isProprietaryChrome) (
        lib.listToAttrs ((map extensionJson (cfg.extensions or [])) ++ (map dictionary (cfg.dictionaries or [])))
        // lib.optionalAttrs ((cfg.nativeMessagingHosts or []) != []) {
          "${configDir}/NativeMessagingHosts" = {
            source = "${nativeMessagingHostsJoined}/etc/chromium/native-messaging-hosts";
            recursive = true;
          };
        }
      );

      # Set macOS keyboard shortcuts via targets.darwin.defaults
      # Uses bundleId to target the correct application preferences
      targets.darwin.defaults = lib.mkIf (pkgs.stdenv.isDarwin && cfg.keyEquivalents != {}) {
        "${darwinDir}".NSUserKeyEquivalents = cfg.keyEquivalents;
      };
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
