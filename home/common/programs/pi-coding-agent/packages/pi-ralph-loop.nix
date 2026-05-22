{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
}:
buildNpmPackage {
  pname = "pi-ralph-loop";
  version = "1.8.0";

  src = fetchFromGitHub {
    owner = "lnilluv";
    repo = "pi-ralph-loop";
    rev = "v1.8.0";
    hash = "sha256-0Yhgg+u194pCrWt0Ycf6ceSw10kolxuT0DpaOnc1iYM=";
  };

  npmDepsHash = "sha256-wvQfo5JJtKDlSrYZpwFXka5/gLdnNbm3DIT6JdckdBg=";
  dontNpmBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -r . $out/
    runHook postInstall
  '';

  meta = {
    description = "Autonomous coding loops for pi";
    homepage = "https://github.com/lnilluv/pi-ralph-loop";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}
