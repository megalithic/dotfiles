{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
}:
buildNpmPackage {
  pname = "pi-mcp-adapter";
  version = "2.6.0";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-mcp-adapter";
    rev = "v2.6.0";
    hash = "sha256-An8T5HCzofCZ0iNDaUPu8NDk+8ndPgAm+owm6F9kmYM=";
  };

  npmDepsHash = "sha256-WAsJ9/qvFz+QNX9w9dnXmrqhod+z+ruVkFY65YSfVaI=";

  postPatch = ''
    cp ${./pi-mcp-adapter-package-lock.json} package-lock.json
  '';

  dontNpmBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -r . $out/
    runHook postInstall
  '';

  meta = {
    description = "MCP adapter extension for pi coding agent";
    homepage = "https://github.com/nicobailon/pi-mcp-adapter";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}
