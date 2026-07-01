# Helium-specific config on top of mkChromiumBrowser.
#
# `bundleId = "net.imput.helium"` is Helium's real CFBundleIdentifier and is
# used by `targets.darwin.defaults` to write NSUserDefaults to
# ~/Library/Preferences/net.imput.helium.plist.
{
  config,
  pkgs,
  lib,
  self,
  ...
}:
{
  imports = [ "${self}/lib/builders/mkChromiumBrowser.nix" ];

  config =
    let
      heliumCfg = config.programs.helium-browser;
      pkg = heliumCfg.package;
      # Helium strips `prodversion=` from extension update requests for
      # fingerprint protection, and CWS returns `noupdate` without it, so
      # bake the current Chromium version into the update URL. Read the
      # version from the framework directory so it stays in sync with the
      # package automatically. Shared by the External Extensions JSON
      # (mkChromiumBrowser.extensions) and the managed-preferences plist
      # (ExtensionSettings.update_url) below.
      fwVersions = builtins.readDir "${pkg}/Applications/Helium.app/Contents/Frameworks/Helium Framework.framework/Versions";
      prodversion = lib.head (
        lib.filter (n: builtins.match "[0-9].*" n != null) (builtins.attrNames fwVersions)
      );
      helium-update-url = "https://clients2.google.com/service/update2/crx?prodversion=${prodversion}";

      # Extensions to install. Used both for the External Extensions JSON
      # (via mkChromiumBrowser.extensions) and for the managed-preferences
      # ExtensionSettings force-install (policy-enforced, survives profile
      # resets). Both mechanisms target the same ids; policy force-install is
      # authoritative, so the External Extensions JSON is a redundant
      # fallback kept until a follow-up prunes it.
      forcedExtensions = [
        {
          id = "gfbliohnnapiefjpjlpjnehglfpaknnc";
          name = "Surfingkeys";
        }
        {
          id = "egpjdkipkomnmjhjmdamaniclmdlobbo";
          name = "Firenvim";
        }
        {
          id = "gmdfnfcigbfkmghbjeelmbkbiglbmbpe";
          name = "LiveDebugger DevTools";
        }
        {
          id = "cfcmijalplpjkfihjkdjdkckkglehgcf";
          name = "Clear Downloads";
        }
        {
          id = "ponfpcnoihfmfllpaingbgckeeldkhle";
          name = "Enhancer for YouTube";
        }
      ];
      ext = e: {
        inherit (e) id;
        updateUrl = helium-update-url;
      };

      # Managed preferences plist (Chromium policy) written to
      # ~/Library/Managed Preferences/net.imput.helium.plist. Key names and
      # types verified against chromium/src
      # components/policy/resources/policy_templates.json:
      #   ExtensionSettings          dict; keyed by extension id; fields
      #                              installation_mode ("force_installed"),
      #                              update_url (string).
      #   DeveloperToolsAvailability  int-enum; 1 = DeveloperToolsAllowed
      #                              (allow devtools everywhere, including on
      #                              force-installed extensions — needed for
      #                              LiveDebugger). 0 = disallow on forced
      #                              ext (default), 2 = disallow everywhere.
      #   CommandLineFlagSecurityWarningsEnabled  bool; false suppresses the
      #                              "you are using an unsupported flag"
      #                              banner for --remote-debugging-port etc.
      #   DefaultSearchProviderEnabled            bool; with Name + SearchURL
      #                              it pins the default search engine.
      # Sparkle SUAutomaticallyUpdate / SUEnableAutomaticChecks are NOT
      # Chromium policies — they stay in targets.darwin.defaults
      # (NSUserDefaults) via mkChromiumBrowser.
      extensionSettingsEntries = lib.concatStringsSep "\n            " (
        map (e: ''
          <key>${e.id}</key>
          <dict>
            <key>installation_mode</key>
            <string>force_installed</string>
            <key>update_url</key>
            <string>${helium-update-url}</string>
          </dict>'') forcedExtensions
      );
      managedPlist = pkgs.writeText "net.imput.helium-managed-preferences.plist" ''
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
          <key>ExtensionSettings</key>
          <dict>${extensionSettingsEntries}
          </dict>
          <key>DeveloperToolsAvailability</key>
          <integer>1</integer>
          <key>CommandLineFlagSecurityWarningsEnabled</key>
          <false/>
          <key>DefaultSearchProviderEnabled</key>
          <true/>
          <key>DefaultSearchProviderName</key>
          <string>Kagi</string>
          <key>DefaultSearchProviderSearchURL</key>
          <string>https://kagi.com/search?q={searchTerms}</string>
          <key>DefaultSearchProviderKeyword</key>
          <string>kagi</string>
        </dict>
        </plist>
      '';
    in
    {
      programs.helium-browser = {
        enable = true;
        bundleId = "net.imput.helium";
        applicationSupportDir = "net.imput.helium";

        commandLineArgs = [
          "--no-first-run"
          "--no-default-browser-check"
          "--hide-crashed-bubble"
          "--ignore-gpu-blocklist"
          "--disable-breakpad"
          "--disable-wake-on-wifi"
          "--no-pings"
        ];

        # CDP for media-presence browser meeting detection (lobby/joined DOM,
        # tab lookup). Port 9223 to avoid clashing with Brave Nightly's 9222.
        # Runtime-only flag (generated by mkChromiumBrowser): does not touch the
        # bundle, so Gatekeeper / codesign / TCC identity / Widevine / 1Password
        # are unaffected.
        remoteDebuggingPort = 9223;

        # Helium 0.12.x ships an OutdatedBuildDetector that nags on non-upstream
        # builds; disable it declaratively via the experimentalFeatures option
        # (generates --disable-features=OutdatedBuildDetector).
        experimentalFeatures.disable = [ "OutdatedBuildDetector" ];

        dictionaries = [ pkgs.hunspellDictsChromium.en_US ];

        # External Extensions JSON side-load (redundant fallback alongside the
        # managed-preferences ExtensionSettings force-install; see above).
        extensions = map ext forcedExtensions;

        # NSUserKeyEquivalents: ^ = Ctrl, $ = Shift, ~ = Option, @ = Cmd.
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

        darwinWrapperApp.enable = false;
      };

      # The base package has appLocation = "wrapper" so mkChromiumBrowser skips
      # it in home.packages (preventing the unsigned .app from being symlinked).
      # Add it explicitly for its bin/helium CLI wrapper on PATH.
      home.packages = lib.mkIf heliumCfg.enable [
        heliumCfg.package
      ];

      # Do not mutate Chromium profile JSON during activation. "Secure Preferences"
      # is user data with integrity metadata; rewriting it outside Helium risks
      # preference/profile resets. Enable extension developer mode manually if needed.

      # Install Helium.app to /Applications/ via rsync. The DMG is signed at
      # build time in the source fork (megalithic/helium-macos) and consumed as
      # a thin nix package — no ad-hoc signing or Widevine mutation happens in
      # nix. Keep the bundle and existing executable inodes stable for
      # Gatekeeper/TCC caches: use --inplace with --checksum so nix-store epoch
      # mtimes do not skip changed Chromium stubs; --delete removes stale
      # Versions/; --chmod=u+w drops nix-store read-only bits for the next
      # activation.
      home.activation.heliumBrowserInstallToApplications = lib.mkIf heliumCfg.enable (
        lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          SRC="${heliumCfg.package}/Applications/Helium.app"
          DST="/Applications/Helium.app"

          if [ ! -d "$SRC" ]; then
            echo "helium-browser: source bundle missing at $SRC; skipping"
          elif [ ! -w /Applications ] && ! groups | tr ' ' '\n' | grep -qx admin; then
            echo "helium-browser: cannot write to /Applications/ (user not in admin group); skipping"
          elif /usr/bin/pgrep -f '^/Applications/Helium\.app/Contents/MacOS/Helium$' >/dev/null 2>&1; then
            echo "helium-browser: /Applications/Helium.app is running; skipping bundle update to avoid changing code identity under a live TCC client"
          else
            $DRY_RUN_CMD ${pkgs.rsync}/bin/rsync -a --inplace --checksum --delete --chmod=u+w \
              "$SRC/" "$DST/" || {
                echo "helium-browser: rsync to /Applications/ failed; existing bundle left in place"
                exit 0
              }
          fi
        ''
      );

      # Managed preferences (Chromium policy) for Helium. Writes
      # ~/Library/Managed Preferences/net.imput.helium.plist from a nix-generated
      # XML plist so chrome://policy / helium://policy reflects the settings on
      # next launch. Policy key names/types verified against chromium/src
      # policy_templates.json (see managedPlist above for the enum details).
      home.activation.heliumManagedPrefs = lib.mkIf heliumCfg.enable (
        lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          DST="$HOME/Library/Managed Preferences/net.imput.helium.plist"
          mkdir -p "$(dirname "$DST")"
          $DRY_RUN_CMD ${pkgs.coreutils}/bin/install -m 0644 "${managedPlist}" "$DST"
        ''
      );
    };
}
