# Helium Browser with Widevine DRM (Apple Silicon).
#
# Strategy (tk dot-7tgz):
#   - Inject Google-signed Widevine CDM into the Helium framework.
#   - Strip ALL code signatures (nix build runs as _nixbld user, no keychain).
#   - Signing with Developer ID happens in the home-manager activation script
#     (home/common/programs/helium-browser/default.nix) which runs as the real
#     user with keychain access to "Developer ID Application: Seth Messer".
#   - The activation signs inside-out: helpers → Sparkle → framework → main
#     app, producing a valid bundle seal. Base helper gets the
#     disable-library-validation entitlement so Widevine loads.
#   - Unquarantined + Developer-ID-signed = Gatekeeper accepts without
#     notarization and without "Open Anyway". No manual step needed.
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

          # Strip ALL _CodeSignature dirs. The nix build user (_nixbld) has no
          # keychain access; Developer ID signing happens in the HM activation.
          fd -t d _CodeSignature "$HELIUM" -x rm -rf {}
  '';

  installPhase = ''
    HELIUM=$(fd --type d --glob 'Helium.app' "$NIX_BUILD_TOP" --max-results 1)
    mkdir -p "$out/Applications"
    cp -R "$HELIUM" "$out/Applications/Helium.app"
    mkdir -p "$out/bin"
    makeWrapper "$out/Applications/Helium.app/Contents/MacOS/Helium" "$out/bin/helium"
  '';

  # No postFixup signing. Developer ID signing happens in the HM activation
  # script because the nix daemon's _nixbld users cannot access the keychain.

  meta = with lib; {
    description = "Helium browser with Widevine DRM (Apple Silicon)";
    homepage = "https://helium.computer/";
    license = licenses.gpl3Only;
    platforms = [ "aarch64-darwin" ];
    mainProgram = "helium";
  };
}
