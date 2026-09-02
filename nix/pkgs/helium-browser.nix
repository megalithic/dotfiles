# Helium Browser from the private megalithic/helium-macos-releases repo
# (Apple Silicon).
#
# Releases are built in CI from megalithic/helium-macos with Widevine already
# injected, then Developer ID signed (Seth Messer, 3ZJ3F5RFBZ) and notarized.
# So this package does no signing and no Widevine work — it only unpacks the
# DMG. (It replaced a legacy package that patched Widevine into imput's public
# DMG and ad-hoc re-signed helpers locally; see git history.)
#
# The repo is private and the nix-daemon cannot authenticate to GitHub
# (impureEnvVars/netrcPhase read the daemon's env, not the user's shell, and
# Determinate Nix ignores impure-env), so the DMG must be pre-seeded into the
# store as a fixed-output path before building:
#
#   bin/helium-prefetch <version>
#
# requireFile fails with that instruction when the store path is missing.
{
  lib,
  pkgs,
  stdenvNoCC,
  requireFile,
}:
let
  version = "0.14.2.1";
  dmgName = "helium_${version}_arm64-macos.dmg";
in
stdenvNoCC.mkDerivation {
  pname = "helium-browser";
  inherit version;

  # Wrapper is provided by mkChromiumBrowser; don't double-install via home.packages.
  passthru.appLocation = "wrapper";

  src = requireFile {
    name = dmgName;
    sha256 = "d6b2c304c2dbabf2e06822eab5a6e6fc18945d6f7e99d5e652280e3b08e52e04";
    message = ''
      ${dmgName} lives in the private repo
      github.com/megalithic/helium-macos-releases and cannot be fetched by the
      nix-daemon. Seed the store first (requires an authenticated gh CLI):

        bin/helium-prefetch ${version}
    '';
  };

  nativeBuildInputs = with pkgs; [
    _7zz
    fd
    makeWrapper
  ];

  # Keep upstream signatures byte-identical: no strip, no shebang patching,
  # no fixup. Any mutation would break the Developer ID seal / notarization.
  dontPatchShebangs = true;
  dontFixup = true;

  unpackPhase = ''
    7zz x -snld "$src"
  '';

  installPhase = ''
    APP=$(fd --type d --glob 'Helium.app' . --max-results 1)
    if [ -z "$APP" ]; then
      echo "Helium.app not found in DMG" >&2
      exit 1
    fi
    mkdir -p "$out/Applications"
    cp -R "$APP" "$out/Applications/Helium.app"

    mkdir -p "$out/bin"
    makeWrapper "$out/Applications/Helium.app/Contents/MacOS/Helium" "$out/bin/helium"
  '';

  meta = with lib; {
    description = "Helium browser, Developer ID signed + notarized, with Widevine (Apple Silicon)";
    homepage = "https://github.com/megalithic/helium-macos-releases";
    license = licenses.gpl3Only;
    platforms = [ "aarch64-darwin" ];
    mainProgram = "helium";
  };
}
