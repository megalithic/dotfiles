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
    # NOTE: "Enhancer for YouTube" (ponfpcnoihfmfllpaingbgckeeldkhle) removed -
    # Google API returns 204 (no content), extension no longer available via CRX API.
    # Install manually from Chrome Web Store if needed.
    (mkExtension {
      id = "gfbliohnnapiefjpjlpjnehglfpaknnc"; # SurfingKeys
      version = "1.17.11";
      sha256 = "sha256-ITHfwWSqRxSwk2ignuHq5Bnl3H8abikOaBqmv/3/xn0=";
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
  # Brave Browser Nightly Configuration
  # ===========================================================================
  # Primary browser with remote debugging for MCP servers
  # Also provides Widevine DRM for Helium
  programs.brave-browser-nightly = {
    enable = true;
    package = pkgs.brave-browser-nightly;
    bundleId = "com.brave.Browser.nightly"; # For defaults/preferences
    applicationSupportDir = "BraveSoftware/Brave-Browser-Nightly"; # For extensions, dictionaries
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

    # Create a wrapper .app that launches with commandLineArgs (including remote debugging)
    # Named same as original so it effectively replaces it in ~/Applications/Home Manager Apps/
    darwinWrapperApp = {
      enable = true;
      name = "Brave Browser Nightly";
      bundleId = "com.nix.brave-browser-nightly";
    };
  };

  imports = [./mkChromiumBrowser.nix];

  # Extension files are managed by mkChromiumBrowser.nix
  # which correctly handles the browser-specific directory paths:
  # - Helium: Library/Application Support/net.imput.helium/External Extensions/
  # - Brave:  Library/Application Support/BraveSoftware/Brave-Browser-Nightly/External Extensions/

  # ===========================================================================
  # Developer Mode & User Scripts Configuration (Helium only)
  # ===========================================================================
  # Enable developer mode to allow user scripts (required for SurfingKeys Advanced Mode)
  # This ensures extensions.ui.developer_mode is set in each browser's Secure Preferences
  #
  # FIXME: can this be done for brave-browser-nightly, too?
  home.activation.heliumBrowserEnableDeveloperMode = lib.mkIf config.programs.helium-browser.enable (
    lib.hm.dag.entryAfter ["writeBoundary"] ''
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
    ''
  );
}
