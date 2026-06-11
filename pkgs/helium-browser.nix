# Helium Browser with Widevine DRM (Apple Silicon).
#
# Inject Widevine CDM into the framework. Strip + ad-hoc re-sign only the
# helpers (base helper gets disable-library-validation so Widevine loads).
# Main exec, main app Info.plist, framework, and Sparkle keep imput's original
# signatures — required for 1Password desktop pairing (verifyClient allowlists
# imput's team ID), TCC identity stability, and hardened-runtime library
# validation between the main exec and the framework. The outer bundle
# CodeResources hashes the helpers' original _CodeSignature; replacing them
# breaks the outer seal, but the main executable's Developer ID signature stays
# valid.
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

          # Do not edit Contents/Info.plist here. It is sealed by the main app's
          # Developer ID signature; mutating it makes codesign report "invalid
          # Info.plist" and can destabilize TCC permissions across rebuilds.

          # Clear quarantine xattrs (does NOT affect embedded LC_CODE_SIGNATURE).
          /usr/bin/xattr -cr "$HELIUM"

          # Strip _CodeSignature from helpers only so postFixup can re-sign
          # them ad-hoc. Main exec, framework, and Sparkle seals stay intact.
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

          for helper in "$FW_ROOT/Versions/$VER/Helpers/"*.app; do
            name=$(basename "$helper" .app)
            if [ "$name" = "Helium Helper" ]; then
              /usr/bin/codesign --force --sign - \
                --options=runtime,kill,restrict \
                --entitlements "$ENTS" \
                "$helper"
            else
              /usr/bin/codesign --force --sign - "$helper"
            fi
          done
  '';

  meta = with lib; {
    description = "Helium browser with Widevine DRM (Apple Silicon)";
    homepage = "https://helium.computer/";
    license = licenses.gpl3Only;
    platforms = [ "aarch64-darwin" ];
    mainProgram = "helium";
  };
}
