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
        # CDP for media-presence meeting detection (lobby/joined DOM, tab
        # lookup). Port 9223 to avoid clashing with Brave Nightly's 9222.
        # Runtime-only flag: does not touch the bundle, so Gatekeeper /
        # codesign / TCC identity / Widevine / 1Password are unaffected.
        "--remote-debugging-port=9223"
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

    # Do not mutate Chromium profile JSON during activation. "Secure Preferences"
    # is user data with integrity metadata; rewriting it outside Helium risks
    # preference/profile resets. Enable extension developer mode manually if needed.

    # Install Helium.app to /Applications/ via rsync. All signing happens in
    # the nix derivation's postFixup (ad-hoc, helpers only). Keep the bundle
    # and existing executable inodes stable for Gatekeeper/TCC caches: use
    # --inplace with --checksum so nix-store epoch mtimes do not skip changed
    # Chromium stubs; --delete removes stale Versions/; --chmod=u+w drops
    # nix-store read-only bits for the next activation.
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

    # Helium's Info.plist claims com.adobe.pdf as a Viewer, and the bundle
    # re-registration above lets it reclaim the PDF default in LaunchServices.
    # The main Info.plist is sealed by Helium's Developer ID signature, so we
    # cannot strip the claim without breaking TCC/Widevine. Instead, re-assert
    # the preferred PDF handler after install. Idempotent.
    home.activation.heliumBrowserReassertPdfHandler = lib.mkIf config.programs.helium-browser.enable (
      lib.hm.dag.entryAfter [ "heliumBrowserInstallToApplications" ] ''
        PDF_HANDLER="com.apple.Preview"
        if [ -x "${pkgs.duti}/bin/duti" ]; then
          current="$(${pkgs.duti}/bin/duti -x pdf 2>/dev/null | tail -1 || true)"
          if [ "$current" != "$PDF_HANDLER" ]; then
            $DRY_RUN_CMD ${pkgs.duti}/bin/duti -s "$PDF_HANDLER" com.adobe.pdf all \
              && echo "helium-browser: re-asserted PDF handler to $PDF_HANDLER" \
              || echo "helium-browser: duti failed to set PDF handler (non-fatal)"
          fi
        else
          echo "helium-browser: duti not found; skipping PDF handler re-assert"
        fi
      ''
    );
  };
}
