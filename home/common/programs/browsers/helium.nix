# Helium-specific config + dev-mode activation on top of mkChromiumBrowser.
# Install/option plumbing comes from mkChromiumBrowser.nix.
#
# Bundle ID note:
#   - `bundleId = "net.imput.helium"` is Helium's actual CFBundleIdentifier.
#     This is used as `effectiveBundleId` in mkChromiumBrowser, so
#     `targets.darwin.defaults` writes to ~/Library/Preferences/net.imput.helium.plist
#     (which Helium's NSUserDefaults reads). NOT a custom ID.
#   - `darwinWrapperApp.bundleId = "com.nix.helium-browser"` is the SEPARATE
#     wrapper .app's Info.plist ID. It only identifies the wrapper to macOS;
#     does not affect prefs read by Helium itself.
#
# Extension install mechanism:
#   - mkChromiumBrowser writes External Extensions JSON to
#     ~/Library/Application Support/net.imput.helium/External Extensions/<id>.json
#     with `external_update_url = https://clients2.google.com/service/update2/crx`
#     (default). Chromium fetches + installs from CWS on launch.
#   - `external_crx` (local CRX file) is blocked on macOS since Chrome 44, so
#     we rely on the update URL path. Works for any CWS-published extension.
#   - 1Password is intentionally omitted: it requires interactive desktop-app
#     pairing on first use, which can't be automated declaratively.
{config, pkgs, lib, ...}: {
  config = {
    programs.helium-browser = {
      enable = true;
      bundleId = "net.imput.helium";
      applicationSupportDir = "net.imput.helium";

      commandLineArgs = [
        # Remote debugging for browser automation.
        # Brave uses 9222; using 9223 here so both can run concurrently.
        "--remote-debugging-port=9223"
        # Startup behavior
        "--no-first-run"
        "--no-default-browser-check"
        "--hide-crashed-bubble"
        # Performance
        "--ignore-gpu-blocklist"
        # Privacy
        "--disable-breakpad"
        "--disable-wake-on-wifi"
        "--no-pings"
        # Disable auto-update nag (managed by nix)
        "--disable-features=OutdatedBuildDetector"
      ];

      dictionaries = [pkgs.hunspellDictsChromium.en_US];

      # Extensions auto-install on first launch via External Extensions JSON.
      #
      # IMPORTANT: Helium strips `prodversion=` from extension update requests
      # for fingerprint protection. Google's CRX endpoint returns
      # `<updatecheck status="noupdate"/>` without prodversion, so we must bake
      # it into the update URL ourselves. Helium's proxy patch only redirects
      # CWS-UI installs, NOT External Extensions sideloads, so requests go to
      # clients2.google.com directly.
      #
      # Update prodversion to match Helium's underlying Chromium version on
      # major upgrades (check Helium.app/Contents/Frameworks/Helium\ Framework
      # .framework/Versions/).
      extensions = let
        helium-update-url = "https://clients2.google.com/service/update2/crx?prodversion=147.0.7727.116";
        ext = id: { inherit id; updateUrl = helium-update-url; };
      in [
        (ext "gfbliohnnapiefjpjlpjnehglfpaknnc") # Surfingkeys
        (ext "egpjdkipkomnmjhjmdamaniclmdlobbo") # Firenvim
        (ext "gmdfnfcigbfkmghbjeelmbkbiglbmbpe") # LiveDebugger DevTools
        (ext "cfcmijalplpjkfihjkdjdkckkglehgcf") # Clear Downloads
        (ext "ponfpcnoihfmfllpaingbgckeeldkhle") # Enhancer for YouTube
      ];

      # macOS keyboard shortcuts (NSUserKeyEquivalents)
      # Format: ^ = Ctrl, $ = Shift, ~ = Option, @ = Cmd
      keyEquivalents = {
        "Close Tab" = "^w";
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

      # Wrapper .app so Finder launches apply commandLineArgs.
      # The wrapper's bundleId is separate from Helium's actual ID
      # (net.imput.helium remains the prefs/defaults target).
      darwinWrapperApp = {
        enable = true;
        name = "Helium";
        bundleId = "com.nix.helium-browser";
      };
    };

    home.activation.heliumBrowserEnableDeveloperMode = lib.mkIf config.programs.helium-browser.enable (
      lib.hm.dag.entryAfter ["writeBoundary"] ''
        HELIUM_PREFS="${config.home.homeDirectory}/Library/Application Support/net.imput.helium/Default/Secure Preferences"
        if [ -f "$HELIUM_PREFS" ]; then
          if [ "$(${pkgs.jq}/bin/jq -r '.extensions.ui.developer_mode // false' "$HELIUM_PREFS")" != "true" ]; then
            echo "Enabling developer mode for Helium..."
            $DRY_RUN_CMD cp "$HELIUM_PREFS" "$HELIUM_PREFS.bak"
            $DRY_RUN_CMD ${pkgs.jq}/bin/jq '.extensions.ui.developer_mode = true' "$HELIUM_PREFS" > "$HELIUM_PREFS.tmp"
            $DRY_RUN_CMD mv "$HELIUM_PREFS.tmp" "$HELIUM_PREFS"
          fi
        fi
      ''
    );
  };
}
