{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
}:
buildNpmPackage {
  pname = "pi-mcp-adapter";
  version = "2.8.0";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-mcp-adapter";
    rev = "v2.8.0";
    hash = "sha256-eHz/uivSIZ8HOalSCZgyCyOWodQJq5GapAqpT2ryn1k=";
  };

  npmDepsHash = "sha256-IWpV0qbJfp5EizfOcdEQXIyiP2ftc0auWK8cA5PYchU=";

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
