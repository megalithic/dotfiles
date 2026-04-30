# Helium Browser with Widevine DRM (Apple Silicon only)
# Usage: programs.helium-browser.enable = true;
#
# ============================================================================
# OPTION-C ASYMMETRIC SIGNATURE STRATEGY (tk dot-7tgz)
# ============================================================================
#
# Goal: Helium with BOTH Widevine DRM (Netflix HD, Spotify, etc.) AND
# 1Password desktop integration (extension auto-unlock).
#
# Tension: Helium ships notarized DMGs signed by imput LLC (team S4Q33XPHB4)
# but does NOT bundle Widevine. Google-signed (team EQHXZ8M8AV) Widevine CDM
# must be injected post-extraction, which breaks the bundle's sealed-resource
# hashes (`_CodeSignature/CodeResources`). Yet 1P validates the connecting
# browser process via SecCodeCheckValidity using the imput LLC Developer ID
# requirement, which requires the main exec's embedded LC_CODE_SIGNATURE to
# stay imput-signed.
#
# Resolution (verified working 2026-05-01):
#   - postUnpack:  inject Widevine into Helium Framework Libraries/WidevineCdm/.
#                  Strip _CodeSignature ONLY from helper .app bundles.
#                  Preserve outer Helium.app + framework + Sparkle seals.
#                  Preserve Contents/MacOS/Helium and framework primary binary
#                  (their embedded LC_CODE_SIGNATURE remains imput-signed).
#   - postFixup:   re-sign ONLY the helper bundles inside Helpers/. Drop the
#                  `library` flag from the base helper's --options (upstream
#                  bug; mirrors fix submitted to imputnet/helium-macos) so
#                  AMFI honours the disable-library-validation entitlement
#                  when the chromium CDM utility process dlopen()s the
#                  Google-signed Widevine dylib.
#
# Validators that pass (proven via disassembly of
# /Applications/1Password.app/Contents/Frameworks/libop_sdk_lib_core.dylib
# function `verifyClient(_:satisfies:)`):
#   - kSecCSDefaultFlags         (1P final-acceptance check)  -> OK
#   - kSecCSConsiderExpiration   (1P first/cert-expiry check) -> OK
# Validators that fail (the bundle seal IS broken — by design):
#   - kSecCSStrictValidate                                    -> FAIL
#   - kSecCSCheckGatekeeperArchitectures                      -> FAIL  <-- Gatekeeper
#
# ----------------------------------------------------------------------------
# GATEKEEPER "OPEN ANYWAY" GOTCHA (first launch after every rebuild)
# ----------------------------------------------------------------------------
#
# Because the bundle seal is intentionally broken, macOS Gatekeeper
# (`spctl -a -t exec`) reports `a sealed resource is missing or invalid` and
# refuses to launch the bundle via LaunchServices (Finder, `open`, NSWorkspace).
# The first launch after every rebuild that changes the bundle's cdhash will
# show:
#
#   "Helium.app" is damaged and can't be opened. You should move it to the Trash.
#
# Resolution path (one-time per cdhash):
#   1. CLICK CANCEL — never "Move to Trash". macOS auto-quarantines the bundle
#      to ~/.Trash/ on the first GK rejection regardless of which button is
#      clicked. If already trashed:
#        mv ~/.Trash/Helium.app* /Applications/Helium.app
#   2. Trigger a fresh launch:  open /Applications/Helium.app
#   3. macOS Settings -> Privacy & Security -> "Helium.app was blocked from
#      use because it is not from an identified developer" -> Open Anyway ->
#      Touch ID auth.
#   4. syspolicyd records the override keyed by cdhash:
#        syspolicyd: Allowing code due to user override
#        syspolicyd: Clearing Gatekeeper denial breadcrumb
#   5. All subsequent launches (Finder, Dock, NSWorkspace) succeed.
#
# `spctl --add` is API-deprecated since macOS 13+ (returns "operation no
# longer supported" at runtime). The Privacy & Security "Open Anyway" path
# is the only user-mode approval mechanism available without an Apple
# Developer ID + notarization.
#
# Possible automation paths for the override (UNEXPLORED — see tk dot-7tgz):
#   - Profile-based SystemPolicyRule MDM payload (likely requires MDM-enrolled
#     device).
#   - Direct syspolicyd database manipulation (cdhash insertion); SIP and the
#     System Integrity Protection of /var/db/SystemPolicy* makes this fragile.
#   - Sign the bundle with a fixed Apple Developer ID + notarize ($99/yr) —
#     eliminates the override step entirely. This is the upstream-equivalent fix.
#   - Land upstream PR (megalithic/helium-macos -> imputnet/helium-macos) so
#     imput's signed releases include the helper-signing fix; downstream just
#     stops re-signing helpers and avoids breaking the seal.
#
# Tools that helped during investigation (kept for future debug):
#   - Swift probe at /tmp/codesign-probe2.swift drives Sec*CodeCheckValidity
#     with multiple flag combos to characterise validators.
#   - `lsof -p <CdmServiceBroker pid>` to confirm libwidevinecdm.dylib is
#     mapped as TXT segment.
#   - `log show --predicate 'process == "syspolicyd"'` to observe GK
#     evaluateScanResult / Prompt / Allowing-code-due-to-user-override.
# ============================================================================
{
  lib,
  pkgs,
  stdenvNoCC,
  fetchurl,
}:
let
  version = "0.11.6.1";
in
  stdenvNoCC.mkDerivation {
    pname = "helium-browser";
    inherit version;

    # Managed by mkChromiumBrowser via darwinWrapperApp; prevents the base
    # package from also being added to home.packages (would duplicate Helium.app).
    passthru.appLocation = "wrapper";

    src = fetchurl {
      url = "https://github.com/imputnet/helium-macos/releases/download/${version}/helium_${version}_arm64-macos.dmg";
      sha256 = "069fa3f70a44f0e31ead0bb5ac299778958dfb4c89d28454296f963352231397";
    };

    nativeBuildInputs = with pkgs; [
      _7zz
      cacert
      curl
      fd
      python3
      unzip
      makeWrapper
    ];

    SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";

    postUnpack = ''
      echo "Patching WidevineCdm..."
      WIDEVINE="$NIX_BUILD_TOP/widevine"
      mkdir -p "$WIDEVINE"

      curl --fail -sL "https://raw.githubusercontent.com/mozilla-firefox/firefox/main/toolkit/content/gmp-sources/widevinecdm.json" \
        | python3 -c '
import json, sys
d = json.loads(sys.stdin.read())
v = d["vendors"]["gmp-widevinecdm"]["platforms"]["Darwin_aarch64-gcc3"]
print(v["fileUrl"], v["hashValue"], d["vendors"]["gmp-widevinecdm"]["version"], sep="|")
' > "$WIDEVINE/info"

      IFS='|' read -r URL HASH VERSION < "$WIDEVINE/info"
      curl --fail -sL -o "$WIDEVINE/WidevineCdm.crx" "$URL"

      ACTUAL=$(sha512sum "$WIDEVINE/WidevineCdm.crx" | awk '{print $1}')
      if [ "$ACTUAL" != "$HASH" ]; then
        echo "Widevine hash mismatch"
        exit 1
      fi

      OFFSET=$(python3 -c "
import struct
with open('$WIDEVINE/WidevineCdm.crx', 'rb') as f:
  f.seek(8)
  print(12 + struct.unpack('<I', f.read(4))[0])")
      dd if="$WIDEVINE/WidevineCdm.crx" bs=1 skip="$OFFSET" of="$WIDEVINE/WidevineCdm.zip" 2>/dev/null
      unzip -o "$WIDEVINE/WidevineCdm.zip" -d "$WIDEVINE" > /dev/null

      HELIUM=$(fd --type d --glob 'Helium.app' "$NIX_BUILD_TOP" --max-results 1)
      FW="$HELIUM/Contents/Frameworks/Helium Framework.framework/Versions"
      VER=$(ls "$FW" 2>/dev/null | grep -E '^[0-9]+\.' | head -1)
      mkdir -p "$FW/$VER/Libraries/WidevineCdm"
      cp -R "$WIDEVINE"/* "$FW/$VER/Libraries/WidevineCdm/"

      # Clear quarantine xattrs (does NOT affect embedded LC_CODE_SIGNATURE).
      /usr/bin/xattr -cr "$HELIUM"

      # ASYMMETRIC SIGNATURE STRATEGY (option C from tk dot-7tgz):
      # Strip _CodeSignature ONLY from helper .app bundles so postFixup can
      # re-sign them with library-validation OFF for Widevine. Preserve:
      #   - $HELIUM/Contents/_CodeSignature/                  (main app seal)
      #   - Helium Framework.framework/Versions/$VER/_CodeSignature/
      #   - Contents/MacOS/Helium                              (main exec, embedded sig)
      #   - Helium Framework primary binary                    (embedded sig)
      #   - Sparkle.framework                                  (untouched)
      # AMFI at process launch validates Mach-O LC_CODE_SIGNATURE, not bundle
      # seal. 1Password (hypothesis: kSecCSDefaultFlags) checks main exec sig
      # only, so broken bundle seal does not affect 1P validation while main
      # exec retains TeamIdentifier=S4Q33XPHB4 (imput LLC).
      HELPERS_DIR="$FW/$VER/Helpers"
      for helper in "$HELPERS_DIR/"*.app; do
        rm -rf "$helper/Contents/_CodeSignature"
      done
    '';

    installPhase = ''
      HELIUM=$(fd --type d --glob 'Helium.app' "$NIX_BUILD_TOP" --max-results 1)
      mkdir -p "$out/Applications"
      cp -R "$HELIUM" "$out/Applications/Helium.app"
      mkdir -p "$out/bin"
      makeWrapper "$out/Applications/Helium.app/Contents/MacOS/Helium" "$out/bin/helium"
    '';

    postFixup = ''
      # ASYMMETRIC SIGNATURE EXPLOIT (option C from tk dot-7tgz):
      # Re-sign ONLY helper .app bundles with library-validation OFF (so the
      # Google-signed Widevine CDM dylib loads in the imput-signed helper).
      # Do NOT re-sign Sparkle.framework, Helium Framework, or the main app —
      # those keep their original imput LLC (TeamIdentifier=S4Q33XPHB4)
      # signatures so 1Password Add Browser validation passes.
      #
      # WIDEVINE FIX (mirrors fix submitted upstream to imputnet/helium-macos):
      # Upstream `sign_and_package_app.sh` signs the base `Helium Helper.app`
      # with --options=restrict,library,runtime,kill, which sets the cs-flag
      # library-validation (0x12a00). Library-validation in --options
      # OVERRIDES the `com.apple.security.cs.disable-library-validation`
      # entitlement, so the Google-signed (team EQHXZ8M8AV) Widevine dylib
      # cannot be loaded by the imput-signed (team S4Q33XPHB4) helper. Brave
      # uses 0x10a00 (no library-validation); Chrome gets away with 0x12a00
      # because Chrome and Widevine share team EQHXZ8M8AV. Fix: drop `library`
      # from --options and re-apply the disable-library-validation entitlement.
      HELIUM="$out/Applications/Helium.app"
      FW_ROOT="$HELIUM/Contents/Frameworks/Helium Framework.framework"
      VER=$(ls "$FW_ROOT/Versions" 2>/dev/null | grep -E '^[0-9]+\.' | head -1)

      # Inline the helper entitlements plist (matches upstream
      # entitlements/helper-entitlements.plist).
      ENTS="$NIX_BUILD_TOP/helper-entitlements.plist"
      cat > "$ENTS" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>com.apple.security.cs.disable-library-validation</key>
  <true/>
</dict>
</plist>
PLIST

      # Sign helpers (and ONLY helpers).
      for helper in "$FW_ROOT/Versions/$VER/Helpers/"*.app; do
        name=$(basename "$helper" .app)
        if [ "$name" = "Helium Helper" ]; then
          # Base helper: strip library-validation, apply disable-lib-val entitlement.
          /usr/bin/codesign --force --sign - \
            --options=runtime,kill,restrict \
            --entitlements "$ENTS" \
            "$helper"
        else
          # Other helpers (Renderer/GPU/Plugin/Alerts): default adhoc re-sign.
          /usr/bin/codesign --force --sign - "$helper"
        fi
      done

      # CRITICAL: do NOT re-sign Sparkle, Helium Framework, or main app.
      # Main exec ($HELIUM/Contents/MacOS/Helium) and framework primary binary
      # retain their imput LLC Developer ID signatures, which 1Password
      # validates via SecCodeCheckValidity / SecCodeCopySigningInformation.

      echo "--- Main exec (must report imput LLC / S4Q33XPHB4) ---"
      /usr/bin/codesign -dv "$HELIUM/Contents/MacOS/Helium" 2>&1 | grep -E 'TeamIdentifier|Authority|Identifier' || true
      echo "--- Framework primary binary (must report imput LLC / S4Q33XPHB4) ---"
      /usr/bin/codesign -dv "$FW_ROOT/Versions/$VER/Helium Framework" 2>&1 | grep -E 'TeamIdentifier|Authority|Identifier' || true
      echo "--- Base helper flags after fix (expect 0x10a00) ---"
      /usr/bin/codesign -dv "$FW_ROOT/Versions/$VER/Helpers/Helium Helper.app" 2>&1 | grep -E 'flags|Identifier' || true
      echo "--- Base helper entitlements ---"
      /usr/bin/codesign -d --entitlements - "$FW_ROOT/Versions/$VER/Helpers/Helium Helper.app" 2>&1 | grep -i library || true
    '';

    meta = with lib; {
      description = "Helium browser with Widevine DRM (Apple Silicon)";
      homepage = "https://helium.computer/";
      license = licenses.gpl3Only;
      platforms = ["aarch64-darwin"];
      mainProgram = "helium";
    };
  }
