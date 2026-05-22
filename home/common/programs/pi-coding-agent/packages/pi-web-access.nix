{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
}:
buildNpmPackage {
  pname = "pi-web-access";
  version = "0.10.7";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-web-access";
    rev = "v0.10.7";
    hash = "sha256-D9no4SLigH/t3/WfirixMbTEjcEwZwJXld8j7pwBCew=";
  };

  npmDepsHash = "sha256-QKmgVmIvqLbqnUmKBKniT0CvNIgZWZ9mUkha0LJMMVQ=";

  dontNpmBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -r . $out/
    runHook postInstall
  '';

  meta = {
    description = "Web search, content extraction, and video understanding extension for pi coding agent";
    homepage = "https://github.com/nicobailon/pi-web-access";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}
