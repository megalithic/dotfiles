# Helium Browser — thin consumer of a signed DMG.
#
# Architecture: Widevine CDM injection and Developer ID signing happen in the
# source fork (megalithic/helium-macos). This derivation only fetches a signed
# DMG, extracts it, and provides the app + CLI wrapper. No codesign, no
# Widevine download, no helper re-signing.
#
# Until dot-w2ut publishes the first megalithic signed release, this consumes
# the upstream imputnet 0.12.5.1 DMG (no Widevine — DRM regresses temporarily,
# by design, per dot-gx9h "keep current version 0.12.5.1 until release task
# updates it"). dot-w2ut bumps `version` + `src` to the megalithic release.
#
# Local iteration: override `localSrc` to point at a built DMG, e.g.
#   pkgs.helium-browser.override { localSrc = /path/to/helium_X_signed.dmg; }
{
  lib,
  pkgs,
  stdenvNoCC,
  fetchurl,
  localSrc ? null,
}:
let
  version = "0.12.5.1";
  remoteSrc = fetchurl {
    url = "https://github.com/imputnet/helium-macos/releases/download/${version}/helium_${version}_arm64-macos.dmg";
    sha256 = "1pcrb1nxmcdpjrgc65066nsvf89mx5cshicdiv2aymzj8hwkl2xv";
  };
in
stdenvNoCC.mkDerivation {
  pname = "helium-browser";
  inherit version;

  # Wrapper is provided by mkChromiumBrowser; don't double-install via home.packages.
  passthru.appLocation = "wrapper";
  # Expose the override seam for introspection / dot-w2ut local-dev iteration.
  passthru.localSrc = localSrc;

  src = if localSrc != null then localSrc else remoteSrc;

  # 7zz extracts Helium.app into $NIX_BUILD_TOP; keep the source root at the
  # top so installPhase can reference ./Helium.app (stdenv otherwise cd's into
  # the single unpacked Helium.app dir).
  sourceRoot = ".";

  nativeBuildInputs = with pkgs; [
    _7zz
    makeWrapper
  ];

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/Applications" "$out/bin"
    cp -R Helium.app "$out/Applications/Helium.app"
    makeWrapper "$out/Applications/Helium.app/Contents/MacOS/Helium" "$out/bin/helium"
    runHook postInstall
  '';

  meta = with lib; {
    description = "Helium browser (Apple Silicon) — thin consumer of signed DMG";
    homepage = "https://helium.computer/";
    license = licenses.gpl3Only;
    platforms = [ "aarch64-darwin" ];
    mainProgram = "helium";
  };
}
