{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
}:
buildNpmPackage {
  pname = "pi-subagents";
  version = "0.27.0";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "v0.27.0";
    hash = "sha256-AcKy/FF6FcL6eBa8DOFFxwMd5in2Z5Z4tbEqmxJucBo=";
  };

  npmDepsHash = "sha256-kAwkwpX9mYcoDFZwtQVvsE+QYHLUfvHAMWnkxg0V+XY=";

  postPatch = ''
    cp ${./pi-subagents-package-lock.json} package-lock.json
  '';

  dontNpmBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -r . $out/
    runHook postInstall
  '';

  meta = {
    description = "Subagent delegation extension for pi coding agent";
    homepage = "https://github.com/nicobailon/pi-subagents";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}
