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

  config = {
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
        "--disable-features=OutdatedBuildDetector"
      ];

      dictionaries = [ pkgs.hunspellDictsChromium.en_US ];

      # Helium strips `prodversion=` from extension update requests for
      # fingerprint protection, and CWS returns `noupdate` without it, so
      # bake the current Chromium version into the update URL. Read the
      # version from the framework directory so it stays in sync with the
      # package automatically.
      extensions =
        let
          pkg = config.programs.helium-browser.package;
          fwVersions = builtins.readDir "${pkg}/Applications/Helium.app/Contents/Frameworks/Helium Framework.framework/Versions";
          prodversion = lib.head (
            lib.filter (n: builtins.match "[0-9].*" n != null) (builtins.attrNames fwVersions)
          );
          helium-update-url = "https://clients2.google.com/service/update2/crx?prodversion=${prodversion}";
          ext = id: {
            inherit id;
            updateUrl = helium-update-url;
          };
        in
        [
          (ext "gfbliohnnapiefjpjlpjnehglfpaknnc") # Surfingkeys
          (ext "egpjdkipkomnmjhjmdamaniclmdlobbo") # Firenvim
          (ext "gmdfnfcigbfkmghbjeelmbkbiglbmbpe") # LiveDebugger DevTools
          (ext "cfcmijalplpjkfihjkdjdkckkglehgcf") # Clear Downloads
          (ext "ponfpcnoihfmfllpaingbgckeeldkhle") # Enhancer for YouTube
        ];

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
    home.packages = lib.mkIf config.programs.helium-browser.enable [
      config.programs.helium-browser.package
    ];

    # Chromium `ExtensionDeveloperModeSettings` policy did not surface in
    # chrome://policy via NSUserDefaults, so mutate Secure Preferences directly.
    home.activation.heliumBrowserEnableDeveloperMode = lib.mkIf config.programs.helium-browser.enable (
      lib.hm.dag.entryAfter [ "writeBoundary" ] ''
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

    # Install Helium.app to /Applications/ via rsync, then sign with Developer ID.
    #
    # The nix build strips all code signatures (build users can't access the
    # keychain). This activation runs as the real user, so it signs the
    # bundle inside-out with "Developer ID Application: Seth Messer (3ZJ3F5RFBZ)".
    #
    # Unquarantined (rsync install, no quarantine xattr) + Developer-ID-signed
    # = Gatekeeper accepts without notarization. No "Open Anyway" needed.
    #
    # rsync flags:
    #   - default tempfile+rename (NOT --inplace): keeps the bundle dir inode
    #     stable, sidesteps the read-only nix-store file mode that App
    #     Management TCC can prevent us from chmod'ing.
    #   - --checksum: required. Nix mtime is always epoch, and Chromium's
    #     launcher stub is the same byte size across minor Helium versions,
    #     so the default size+mtime quick-check skips the main exec on a
    #     version bump → half-updated bundle → SIGABRT on dlopen of the old
    #     framework path.
    #   - --delete: removes stale Versions/<old> dirs.
    #   - --chmod=u+w: replaced files don't inherit nix-store read-only mode.
    home.activation.heliumBrowserInstallToApplications =
      lib.mkIf config.programs.helium-browser.enable
        (
          lib.hm.dag.entryAfter [ "writeBoundary" ] ''
                    SRC="${config.programs.helium-browser.package}/Applications/Helium.app"
                    DST="/Applications/Helium.app"
                    SIGN_ID="Developer ID Application: Seth Messer (3ZJ3F5RFBZ)"

                    if [ ! -d "$SRC" ]; then
                      echo "helium-browser: source bundle missing at $SRC; skipping"
                    elif [ ! -w /Applications ] && ! groups | tr ' ' '\n' | grep -qx admin; then
                      echo "helium-browser: cannot write to /Applications/ (user not in admin group); skipping"
                    else
                      $DRY_RUN_CMD ${pkgs.rsync}/bin/rsync -a --checksum --delete --chmod=u+w \
                        "$SRC/" "$DST/" || {
                          echo "helium-browser: rsync to /Applications/ failed; existing bundle left in place"
                          exit 0
                        }

                      # --- Developer ID signing (inside-out) ---
                      FW_ROOT="$DST/Contents/Frameworks/Helium Framework.framework"
                      VER=$(ls "$FW_ROOT/Versions" 2>/dev/null | ${pkgs.coreutils}/bin/head -1)

                      # Entitlements for the base helper (disable library validation so
                      # Google-signed Widevine CDM loads in our Developer-ID-signed helper).
                      HELPER_ENTS=$(mktemp)
                      cat > "$HELPER_ENTS" <<'PLIST'
            <?xml version="1.0" encoding="UTF-8"?>
            <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
            <plist version="1.0">
            <dict>
              <key>com.apple.security.cs.disable-library-validation</key>
              <true/>
            </dict>
            </plist>
            PLIST

                      # Entitlements for the main app (camera, microphone, etc. — matches
                      # Chrome/Brave so macOS TCC prompts fire for getUserMedia).
                      APP_ENTS=$(mktemp)
                      cat > "$APP_ENTS" <<'PLIST'
            <?xml version="1.0" encoding="UTF-8"?>
            <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
            <plist version="1.0">
            <dict>
              <key>com.apple.security.device.camera</key>
              <true/>
              <key>com.apple.security.device.audio-input</key>
              <true/>
              <key>com.apple.security.device.bluetooth</key>
              <true/>
              <key>com.apple.security.device.usb</key>
              <true/>
              <key>com.apple.security.personal-information.location</key>
              <true/>
            </dict>
            </plist>
            PLIST

                      echo "helium-browser: signing with Developer ID..."

                      # Sign inside-out: deepest nested bundles first, outermost last.
                      # Each codesign seals the content below it, so order matters.

                      # 1. Sparkle Updater.app (deepest nested .app)
                      SPARKLE="$FW_ROOT/Versions/$VER/Frameworks/Sparkle.framework"
                      if [ -d "$SPARKLE/Versions/B/Updater.app" ]; then
                        /usr/bin/codesign --force --sign "$SIGN_ID" \
                          "$SPARKLE/Versions/B/Updater.app"
                      fi

                      # 2. Sparkle.framework
                      if [ -d "$SPARKLE" ]; then
                        /usr/bin/codesign --force --sign "$SIGN_ID" "$SPARKLE"
                      fi

                      # 3. Helper .app bundles
                      for helper in "$FW_ROOT/Versions/$VER/Helpers/"*.app; do
                        name=$(basename "$helper" .app)
                        if [ "$name" = "Helium Helper" ]; then
                          # Base helper: drop library-validation so Google-signed
                          # Widevine CDM loads in this Developer-ID-signed process.
                          /usr/bin/codesign --force --sign "$SIGN_ID" \
                            --options=runtime,kill,restrict \
                            --entitlements "$HELPER_ENTS" \
                            "$helper"
                        else
                          /usr/bin/codesign --force --sign "$SIGN_ID" "$helper"
                        fi
                      done

                      # 4. Standalone executables in Helpers/ (crashpad, app_mode_loader, etc.)
                      for exe in "$FW_ROOT/Versions/$VER/Helpers/"*; do
                        [ -d "$exe" ] && continue  # skip .app dirs
                        [ -f "$exe" ] && [ -x "$exe" ] && \
                          /usr/bin/codesign --force --sign "$SIGN_ID" "$exe"
                      done

                      # 5. Helium Framework.framework (seals Widevine + helpers + Sparkle)
                      /usr/bin/codesign --force --sign "$SIGN_ID" "$FW_ROOT"

                      # 6. Main app bundle (outermost seal, with device entitlements)
                      /usr/bin/codesign --force --sign "$SIGN_ID" \
                        --options=runtime,kill,restrict,library-validation \
                        --entitlements "$APP_ENTS" \
                        "$DST"

                      rm -f "$HELPER_ENTS" "$APP_ENTS"

                      # Verify
                      echo "helium-browser: verifying bundle seal..."
                      if /usr/bin/codesign --verify --deep --strict "$DST" 2>&1; then
                        echo "helium-browser: ✓ bundle seal valid (Developer ID: Seth Messer)"
                      else
                        echo "helium-browser: ✗ bundle seal verification failed"
                        /usr/bin/codesign -dv "$DST" 2>&1 || true
                      fi
                    fi
          ''
        );
  };
}
