{
  lib,
  stdenvNoCC,
  fetchurl,
}:

let
  version = "2026.6.12";

  asset =
    {
      aarch64-darwin = {
        platform = "macos-arm64";
        hash = "sha256-0SwH8OJw08xlwluk63x4n9fuU4CWWz+jFCa+HQud7tk=";
      };
      x86_64-darwin = {
        platform = "macos-x64";
        hash = "sha256-fdgKkHNA+jGc5Rw1G2fG5NK6QBe/WMoNu+wg44r2Fgc=";
      };
    }
    .${stdenvNoCC.hostPlatform.system}
      or (throw "mise binary package unsupported on ${stdenvNoCC.hostPlatform.system}");
in
stdenvNoCC.mkDerivation {
  pname = "mise";
  inherit version;

  src = fetchurl {
    url = "https://github.com/jdx/mise/releases/download/v${version}/mise-v${version}-${asset.platform}.tar.gz";
    inherit (asset) hash;
  };

  sourceRoot = "mise";

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -R . $out/

    runHook postInstall
  '';

  meta = {
    description = "Polyglot tool version manager";
    homepage = "https://mise.jdx.dev";
    changelog = "https://github.com/jdx/mise/releases/tag/v${version}";
    license = lib.licenses.mit;
    mainProgram = "mise";
    platforms = [
      "aarch64-darwin"
      "x86_64-darwin"
    ];
  };
}
