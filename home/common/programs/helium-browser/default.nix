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
      # bake the current Chromium version into the update URL. Bump this
      # alongside `pkgs/helium-browser.nix` on Helium major upgrades.
      extensions =
        let
          helium-update-url = "https://clients2.google.com/service/update2/crx?prodversion=148.0.7778.215";
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

    # Install Helium.app to /Applications/ via rsync.
    #
    # The option-C build (Widevine inject + helper re-sign) breaks the
    # bundle's _CodeSignature seal, so Gatekeeper shows the "damaged" dialog
    # on first launch. The user clears that once via System Settings →
    # Privacy & Security → "Open Anyway". That approval is stored in
    # /var/db/SystemPolicyConfiguration/ExecPolicy keyed on the bundle
    # directory inode, so the rsync below must preserve it across rebuilds.
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

            if [ ! -d "$SRC" ]; then
              echo "helium-browser: source bundle missing at $SRC; skipping"
            elif [ ! -w /Applications ] && ! groups | tr ' ' '\n' | grep -qx admin; then
              echo "helium-browser: cannot write to /Applications/ (user not in admin group); skipping"
            else
              if [ ! -e "$DST" ]; then
                echo "helium-browser: first-time install; click 'Open Anyway' in"
                echo "helium-browser:   System Settings → Privacy & Security once after this run."
              fi
              $DRY_RUN_CMD ${pkgs.rsync}/bin/rsync -a --checksum --delete --chmod=u+w \
                "$SRC/" "$DST/" || {
                  echo "helium-browser: rsync to /Applications/ failed; existing bundle left in place"
                }
            fi
          ''
        );
  };
}
