# Helium Browser with Widevine DRM (Apple Silicon).
#
# Strategy (tk dot-7tgz, "option C"):
#   - Inject Google-signed Widevine CDM into the imput LLC Helium framework.
#   - Strip + re-sign ONLY helper bundles (drop the `library` cs-flag so the
#     helper's `disable-library-validation` entitlement actually takes effect
#     and Widevine loads). Mirrors the fix submitted to imputnet/helium-macos.
#   - Leave main exec + framework + Sparkle signatures untouched so the
#     embedded LC_CODE_SIGNATURE on Contents/MacOS/Helium stays imput LLC
#     (TeamIdentifier=S4Q33XPHB4), which 1Password's `verifyClient` validates
#     via SecCodeCheckValidity / kSecCSDefaultFlags.
#
# Side-effect: the outer bundle's _CodeSignature/CodeResources is no longer
# valid, so Gatekeeper marks the bundle "damaged" on first launch after every
# rebuild that changes the cdhash. User clears it once via System Settings →
# Privacy & Security → "Open Anyway". The override is keyed on the bundle
# directory inode in /var/db/SystemPolicyConfiguration/ExecPolicy, so the
# install activation in home/common/programs/helium-browser/default.nix uses
# rsync (NOT --inplace) with --checksum to preserve that inode across rebuilds.
{
  lib,
  pkgs,
  stdenvNoCC,
  fetchurl,
}:
let
  version = "0.12.5.1";
in
stdenvNoCC.mkDerivation {
  pname = "helium-browser";
  inherit version;

  # Wrapper is provided by mkChromiumBrowser; don't double-install via home.packages.
  passthru.appLocation = "wrapper";

  src = fetchurl {
    url = "https://github.com/imputnet/helium-macos/releases/download/${version}/helium_${version}_arm64-macos.dmg";
    sha256 = "1pcrb1nxmcdpjrgc65066nsvf89mx5cshicdiv2aymzj8hwkl2xv";
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

          # Strip _CodeSignature from helper bundles only so postFixup can
          # re-sign them. Outer Helium.app + framework + Sparkle seals stay.
          for helper in "$FW/$VER/Helpers/"*.app; do
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
          HELIUM="$out/Applications/Helium.app"
          FW_ROOT="$HELIUM/Contents/Frameworks/Helium Framework.framework"
          VER=$(ls "$FW_ROOT/Versions" 2>/dev/null | grep -E '^[0-9]+\.' | head -1)

          # Matches upstream entitlements/helper-entitlements.plist.
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

          # Re-sign helpers ONLY. Main exec + framework + Sparkle keep their
          # original imput LLC Developer ID signatures (required for 1P).
          for helper in "$FW_ROOT/Versions/$VER/Helpers/"*.app; do
            name=$(basename "$helper" .app)
            if [ "$name" = "Helium Helper" ]; then
              # Base helper: drop `library` from --options so the
              # disable-library-validation entitlement applies and Widevine
              # (team EQHXZ8M8AV) loads in this imput-signed (S4Q33XPHB4) process.
              /usr/bin/codesign --force --sign - \
                --options=runtime,kill,restrict \
                --entitlements "$ENTS" \
                "$helper"
            else
              /usr/bin/codesign --force --sign - "$helper"
            fi
          done

          echo "--- Main exec (must report imput LLC / S4Q33XPHB4) ---"
          /usr/bin/codesign -dv "$HELIUM/Contents/MacOS/Helium" 2>&1 | grep -E 'TeamIdentifier|Authority|Identifier' || true
          echo "--- Framework primary binary (must report imput LLC / S4Q33XPHB4) ---"
          /usr/bin/codesign -dv "$FW_ROOT/Versions/$VER/Helium Framework" 2>&1 | grep -E 'TeamIdentifier|Authority|Identifier' || true
          echo "--- Base helper flags (expect 0x10a00) ---"
          /usr/bin/codesign -dv "$FW_ROOT/Versions/$VER/Helpers/Helium Helper.app" 2>&1 | grep -E 'flags|Identifier' || true
  '';

  meta = with lib; {
    description = "Helium browser with Widevine DRM (Apple Silicon)";
    homepage = "https://helium.computer/";
    license = licenses.gpl3Only;
    platforms = [ "aarch64-darwin" ];
    mainProgram = "helium";
  };
}
