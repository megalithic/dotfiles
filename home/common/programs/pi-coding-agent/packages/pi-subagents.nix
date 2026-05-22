{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
}:
buildNpmPackage {
  pname = "pi-subagents";
  version = "0.24.2";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "v0.24.2";
    hash = "sha256-yBWgnZYw4OjSxKOmiQOltdM/jSbnHa/tdOBwUgNDkXU=";
  };

  npmDepsHash = "sha256-GKgXtaZwvrLUzfvrw5BMDZ9IE4b44xobAU0vvdDtam4=";

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
