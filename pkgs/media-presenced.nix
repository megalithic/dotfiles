# media-presenced — meeting/AV presence daemon (see tools/media-presenced).
#
# Zero-dependency SwiftPM package, so we compile the sources directly with
# swiftc (nixpkgs swift + apple-sdk_26) instead of running SwiftPM — that avoids
# the network/SDK issues the nix sandbox imposes on `swift build`. Mirrors the
# swift/apple-sdk approach used by pkgs/handy.nix.
{
  lib,
  stdenv,
  swift,
  apple-sdk_26,
}:
stdenv.mkDerivation {
  pname = "media-presenced";
  version = "0.1.0";

  # In-repo first-party source. The overlay does not pass `self`, so use a path
  # relative to this file (pkgs/ packages do not move).
  src = lib.cleanSource ../tools/media-presenced;

  nativeBuildInputs = [
    swift
    apple-sdk_26
  ];

  dontConfigure = true;

  buildPhase = ''
    runHook preBuild
    ${lib.getExe' swift "swiftc"} -O -swift-version 5 \
      -o media-presenced \
      $(find Sources -name '*.swift' | sort)
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    cp media-presenced $out/bin/media-presenced
    # Ad-hoc sign so the daemon has a stable code identity for TCC.
    /usr/bin/codesign --force --sign - $out/bin/media-presenced || true
    runHook postInstall
  '';

  meta = {
    description = "Meeting/AV presence daemon (mic/camera + Google Meet via CDP) serving Hammerspoon";
    homepage = "https://github.com/sethmlarson"; # placeholder; first-party
    license = lib.licenses.mit;
    platforms = [ "aarch64-darwin" ];
    mainProgram = "media-presenced";
  };
}
