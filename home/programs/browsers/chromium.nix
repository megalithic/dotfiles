{
  config,
  pkgs,
  lib,
  inputs,
  ...
}: let
  # Helper to create extension with local CRX file
  mkExtension = {
    id,
    version,
    sha256,
  }: {
    inherit id version;
    crxPath = pkgs.fetchurl {
      url = "https://clients2.google.com/service/update2/crx?response=redirect&acceptformat=crx3&prodversion=120.0.0.0&x=id%3D${id}%26installsource%3Dondemand%26uc";
      inherit sha256;
      name = "${id}-${version}.crx";
    };
  };

  # ===========================================================================
  # Shared Extension List
  # ===========================================================================
  # Both Helium and Brave Browser Nightly use the same extensions.
  # Update hashes with: nix-prefetch-url "<crx-url>" --name "<name>.crx"
  #
  # NOTE: 1Password (aeblfdkhhhdcdjpifhhbdiojplfjncoa) not available via
  # Chrome Web Store API - install manually in each browser.
  extensions = [
    (mkExtension {
      id = "ponfpcnoihfmfllpaingbgckeeldkhle"; # Enhancer for YouTube
      version = "2.0.131";
      sha256 = "0mdqa9w1p6cmli6976v4wi0sw9r4p5prkj7lzfd1877wk11c9c73";
    })
    (mkExtension {
      id = "gfbliohnnapiefjpjlpjnehglfpaknnc"; # SurfingKeys
      version = "1.17.11";
      sha256 = "sha256-JO4w4a7ASorWMwITy7YtJgI3if3NcrWBijpABnQAi0c=";
    })
    (mkExtension {
      id = "egpjdkipkomnmjhjmdamaniclmdlobbo"; # Firenvim
      version = "0.2.16";
      sha256 = "sha256-QFQjBG7fOyj7rRNSby7enwCIhjXqyRPpm+AwqBM9sv4=";
    })
    (mkExtension {
      id = "gmdfnfcigbfkmghbjeelmbkbiglbmbpe"; # LiveDebugger DevTools
      version = "0.6.3";
      sha256 = "1jdm92arkrsj8l0g03g66ml86inn75i91bcxxajdg87s25lls9f4";
    })
    (mkExtension {
      id = "cdglnehniifkbagbbombnjghhcihifij"; # Kagi Search
      version = "1.2.2.5";
      sha256 = "sha256-weiUUUiZeeIlz/k/d9VDSKNwcQtmAahwSIHt7Frwh7E=";
    })
    (mkExtension {
      id = "dpaefegpjhgeplnkomgbcmmlffkijbgp"; # Kagi Summarizer
      version = "1.0.1";
      sha256 = "sha256-BnnCPisSxlhTSoQQeZg06Re8MhgwztRKmET9D93ghiw=";
    })
    (mkExtension {
      id = "cfcmijalplpjkfihjkdjdkckkglehgcf"; # Clear Downloads
      version = "1.4";
      sha256 = "14wg8bcjbwvr9mmp4rhhfk8hnbaibclav2gqjnfi5lx78dppaic4";
    })
  ];

  # ===========================================================================
  # Shared Keyboard Shortcuts
  # ===========================================================================
  # macOS NSUserKeyEquivalents for both browsers
  # Format: ^ = Ctrl, $ = Shift, ~ = Option, @ = Cmd
  sharedKeyEquivalents = {
    "Close Tab" = "^w";
    # "Find..." = "^f";  # collides with surfingkeys
    "New Private Window" = "^$n";
    "New Tab" = "^t";
    "Select Previous Tab" = "^h";
    "Select Next Tab" = "^l";
    "Reload This Page" = "^r";
    "Reopen Closed Tab" = "^$t";
    "Reset zoom" = "^0";
    "Zoom In" = "^=";
    "Zoom Out" = "^-";
  };

  # ===========================================================================
  # Shared Command-Line Arguments
  # ===========================================================================
  # Common args for both browsers
  sharedCommandLineArgs = [
    # Remote debugging for browser automation (MCP servers, etc.)
    # Verify at: http://localhost:9222/json/version
    "--remote-debugging-port=9222"

    # Performance
    "--ignore-gpu-blocklist"

    # Startup behavior
    "--no-first-run"
    "--no-default-browser-check"
    "--hide-crashed-bubble"

    # Privacy enhancements
    "--disable-breakpad" # Disable crash reporter
    "--disable-wake-on-wifi"
    "--no-pings" # Disable hyperlink auditing pings

    # Disable auto-update checks - we manage updates via nix
    # REF: https://github.com/NixOS/nixpkgs/issues/289020
    "--disable-features=OutdatedBuildDetector"
  ];
in {
  # REFS:
  # - https://github.com/will-lol/.dotfiles/blob/main/home/extensions/chromium.nix
  # - https://github.com/isabelroses/dotfiles/blob/main/modules/home/programs/chromium.nix

  # ===========================================================================
  # Helium Browser Configuration
  # ===========================================================================
  # Privacy-focused browser based on ungoogled-chromium
  # Requires Widevine from Brave Browser Nightly for DRM content
  # - REF: https://github.com/scuggo/pkgs/blob/main/pkgs/by-name/he/helium-browser/helium-patcher.nix
  programs.helium-browser = {
    enable = true;
    package = pkgs.helium-browser;
    bundleId = "net.imput.helium"; # macOS bundle identifier for Application Support path
    dictionaries = [pkgs.hunspellDictsChromium.en_US];
    inherit extensions;

    # NOTE: appLocation="symlink" in pkgs/default.nix auto-prevents home-manager
    # from copying to ~/Applications/Home Manager Apps/ (mkChromiumBrowser checks this)

    # REFS: Command-line arguments for Helium:
    # https://peter.sh/experiments/chromium-command-line-switches/
    # REFS: ungoogled-chromium flags:
    # https://github.com/ungoogled-software/ungoogled-chromium/blob/master/docs/flags.md
    commandLineArgs =
      sharedCommandLineArgs
      ++ [
        # Helium-specific cache location
        "--disk-cache=${config.home.homeDirectory}/Library/Caches/helium"

        # Helium-specific privacy/performance
        "--disable-search-engine-collection" # Prevent automatic search engine scraping
        "--energy-saver-fps-limit=30" # Limit FPS when on battery

        # Feature flags (comma-separated)
        "--enable-features=TouchpadOverscrollHistoryNavigation,NoReferrers"

        # Widevine DRM - load from external location to preserve app signature
        # Widevine is copied to ~/Library/Application Support/ by activation script
        # REF: https://github.com/nickspaargaren/widevine/blob/main/widevine.sh
        "--widevine-cdm-path=${config.home.homeDirectory}/Library/Application Support/net.imput.helium/WidevineCdm"
      ];

    # Use shared keyboard shortcuts
    keyEquivalents = sharedKeyEquivalents;

    # Create a wrapper .app that launches with all commandLineArgs (including Widevine path)
    # This is needed because the symlinked app doesn't receive CLI args when launched from Finder
    darwinWrapperApp = {
      enable = true;
      name = "Helium"; # Use same name so it replaces the symlink in /Applications
      bundleId = "com.nix.helium-wrapper";
    };
  };

  # ===========================================================================
  # Brave Browser Nightly Configuration
  # ===========================================================================
  # Primary browser with remote debugging for MCP servers
  # Also provides Widevine DRM for Helium
  programs.brave-browser-nightly = {
    enable = true;
    package = pkgs.brave-browser-nightly;
    bundleId = "com.brave.Browser.nightly"; # For Application Support path
    appName = "Brave Browser Nightly.app";
    executableName = "Brave Browser Nightly";
    iconFile = "app.icns";
    dictionaries = [pkgs.hunspellDictsChromium.en_US];
    inherit extensions;

    commandLineArgs =
      sharedCommandLineArgs
      ++ [
        # Brave-specific cache location
        "--disk-cache=${config.home.homeDirectory}/Library/Caches/brave-browser-nightly"
      ];

    # Use shared keyboard shortcuts
    keyEquivalents = sharedKeyEquivalents;

    # Create a wrapper .app that can be launched from Dock/Spotlight with debug args
    darwinWrapperApp = {
      enable = true;
      name = "Brave Browser Nightly (Debug)";
      bundleId = "com.nix.brave-browser-nightly-debug";
    };
  };

  imports = [./mkChromiumBrowser.nix];

  # Extension files are managed by mkChromiumBrowser.nix
  # which correctly handles the browser-specific directory paths:
  # - Helium: Library/Application Support/net.imput.helium/External Extensions/
  # - Brave:  Library/Application Support/com.brave.Browser.nightly/External Extensions/

  # ===========================================================================
  # Developer Mode & User Scripts Configuration
  # ===========================================================================
  # Enable developer mode to allow user scripts (required for SurfingKeys Advanced Mode)
  # This ensures extensions.ui.developer_mode is set in each browser's Secure Preferences
  home.activation.heliumBrowserEnableDeveloperMode = lib.hm.dag.entryAfter ["writeBoundary"] ''
    HELIUM_PREFS="${config.home.homeDirectory}/Library/Application Support/net.imput.helium/Default/Secure Preferences"

    # Only modify if Helium profile exists
    if [ -f "$HELIUM_PREFS" ]; then
      # Check if developer_mode is already enabled
      CURRENT_VALUE=$(${pkgs.jq}/bin/jq -r '.extensions.ui.developer_mode // false' "$HELIUM_PREFS")

      if [ "$CURRENT_VALUE" != "true" ]; then
        $DRY_RUN_CMD echo "Enabling developer mode for Helium extensions..."
        if [ -z "''${DRY_RUN:-}" ]; then
          # Create backup
          cp "$HELIUM_PREFS" "$HELIUM_PREFS.backup"

          # Enable developer mode
          ${pkgs.jq}/bin/jq '.extensions.ui.developer_mode = true' "$HELIUM_PREFS" > "$HELIUM_PREFS.tmp"
          mv "$HELIUM_PREFS.tmp" "$HELIUM_PREFS"

          $DRY_RUN_CMD echo "✓ Developer mode enabled for Helium"
        fi
      else
        # $DRY_RUN_CMD echo "✓ Developer mode already enabled for Helium"
        :
      fi
    else
      $DRY_RUN_CMD echo "Helium profile not found - developer mode will be set on first run"
    fi
  '';

  # ===========================================================================
  # Widevine DRM Installation (Netflix, Amazon Prime, etc.)
  # ===========================================================================
  # Copies Widevine to ~/Library/Application Support/net.imput.helium/WidevineCdm
  # instead of modifying the app bundle (which breaks code signature on Sequoia).
  #
  # Helium loads Widevine via --widevine-cdm-path flag in commandLineArgs.
  # This preserves the notarized app signature while enabling DRM playback.
  home.activation.heliumBrowserInstallWidevine = lib.hm.dag.entryAfter ["writeBoundary"] ''
    WIDEVINE_DEST="${config.home.homeDirectory}/Library/Application Support/net.imput.helium/WidevineCdm"
    BRAVE_WIDEVINE_DIR="${config.home.homeDirectory}/Library/Application Support/BraveSoftware/Brave-Browser-Nightly/WidevineCdm"

    # Check if Widevine already exists at destination
    if [ -f "$WIDEVINE_DEST/_platform_specific/mac_arm64/libwidevinecdm.dylib" ]; then
      # $DRY_RUN_CMD echo "✓ Widevine already installed in Application Support"
      :
    else
      # Try to copy from Brave Browser Nightly
      if [ -d "$BRAVE_WIDEVINE_DIR" ]; then
        # Find the latest Widevine version directory
        LATEST_WIDEVINE=$(${pkgs.fd}/bin/fd -d 1 -t d '^[0-9]' "$BRAVE_WIDEVINE_DIR" 2>/dev/null | sort -V | tail -1)

        if [ -n "$LATEST_WIDEVINE" ] && [ -f "$LATEST_WIDEVINE/manifest.json" ]; then
          $DRY_RUN_CMD echo "Installing Widevine from Brave Nightly to Application Support..."
          if [ -z "''${DRY_RUN:-}" ]; then
            mkdir -p "$WIDEVINE_DEST"
            cp -R "$LATEST_WIDEVINE"/* "$WIDEVINE_DEST/"
          fi
          $DRY_RUN_CMD echo "✓ Widevine installed to ~/Library/Application Support/net.imput.helium/"
        else
          $DRY_RUN_CMD echo "Brave Nightly found but Widevine not downloaded yet"
          $DRY_RUN_CMD echo "  → Open Brave Nightly, go to brave://settings/extensions"
          $DRY_RUN_CMD echo "  → Enable 'Google Widevine' and let it download"
          $DRY_RUN_CMD echo "  → Then run: just mac"
        fi
      else
        # Fall back to Google Chrome
        CHROME_WIDEVINE="/Applications/Google Chrome.app/Contents/Frameworks/Google Chrome Framework.framework/Libraries/WidevineCdm"

        if [ -d "$CHROME_WIDEVINE" ]; then
          $DRY_RUN_CMD echo "Installing Widevine from Google Chrome to Application Support..."
          if [ -z "''${DRY_RUN:-}" ]; then
            mkdir -p "$WIDEVINE_DEST"
            cp -R "$CHROME_WIDEVINE"/* "$WIDEVINE_DEST/"
          fi
          $DRY_RUN_CMD echo "✓ Widevine installed from Google Chrome"
        else
          $DRY_RUN_CMD echo "⚠ Widevine not found. To enable DRM content in Helium:"
          $DRY_RUN_CMD echo "  1. Open Brave Nightly → brave://settings/extensions"
          $DRY_RUN_CMD echo "  2. Enable 'Google Widevine' and let it download"
          $DRY_RUN_CMD echo "  3. Run: just mac"
        fi
      fi
    fi
  '';
}
