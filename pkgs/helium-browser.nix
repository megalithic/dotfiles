# Helium Browser with Widevine DRM (Apple Silicon only)
# Usage: programs.helium-browser.enable = true;
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
      /usr/bin/xattr -cr "$HELIUM"
      /usr/bin/codesign --force --deep -s - "$HELIUM"
    '';

    installPhase = ''
      HELIUM=$(fd --type d --glob 'Helium.app' "$NIX_BUILD_TOP" --max-results 1)
      mkdir -p "$out/Applications"
      cp -R "$HELIUM" "$out/Applications/Helium.app"
      mkdir -p "$out/bin"
      makeWrapper "$out/Applications/Helium.app/Contents/MacOS/Helium" "$out/bin/helium"
    '';

    meta = with lib; {
      description = "Helium browser with Widevine DRM (Apple Silicon)";
      homepage = "https://helium.computer/";
      license = licenses.gpl3Only;
      platforms = ["aarch64-darwin"];
      mainProgram = "helium";
    };
  }
