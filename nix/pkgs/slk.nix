{
  fetchurl,
  lib,
  stdenvNoCC,
}:

let
  version = "0.8.11";
  system = stdenvNoCC.hostPlatform.system;
  releases = {
    aarch64-darwin = {
      os = "darwin";
      arch = "arm64";
      hash = "sha256-ePSgpgCL++EUxjVGcatW0qqqCKMDdRiEQkfFqYo9UmE=";
    };
    x86_64-darwin = {
      os = "darwin";
      arch = "x86_64";
      hash = "sha256-lWWoO9rrWGzAr4IdIzY/ZCF4JapSiVJ9M2krUiEjNGw=";
    };
    aarch64-linux = {
      os = "linux";
      arch = "arm64";
      hash = "sha256-8ps1Wr+WoHmp4GHEzbFVMMEpdW5is5Syl+Is3hyvt5c=";
    };
    x86_64-linux = {
      os = "linux";
      arch = "x86_64";
      hash = "sha256-aOsWmJ1zc9Ca7vSLWTLI2Qn9bvnmSVX+4JDAKAGLpBI=";
    };
  };
  release = releases.${system} or (throw "slk: unsupported system ${system}");
in
stdenvNoCC.mkDerivation {
  pname = "slk";
  inherit version;

  src = fetchurl {
    url = "https://github.com/gammons/slk/releases/download/v${version}/slk_${version}_${release.os}_${release.arch}.tar.gz";
    inherit (release) hash;
  };

  sourceRoot = ".";

  installPhase = ''
    runHook preInstall

    install -Dm755 slk "$out/bin/slk"

    runHook postInstall
  '';

  meta = {
    description = "Fast Slack TUI";
    homepage = "https://github.com/gammons/slk";
    license = lib.licenses.mit;
    mainProgram = "slk";
    platforms = builtins.attrNames releases;
  };
}
