# Chrome DevTools MCP Server
# Adapted from: https://github.com/aster-void/nix-repository/blob/main/packages/chrome-devtools-mcp/package.nix
{
  lib,
  fetchFromGitHub,
  buildNpmPackage,
}:

buildNpmPackage {
  pname = "chrome-devtools-mcp";
  version = "0.11.0";

  src = fetchFromGitHub {
    owner = "ChromeDevTools";
    repo = "chrome-devtools-mcp";
    tag = "chrome-devtools-mcp-v0.11.0";
    hash = "sha256-TkFCyjPADyG2DgfdmzAXyX/uEirMmZAbyw1He5WWxgw=";
  };

  npmDepsHash = "sha256-rkqBhRWDy8yLibqZE6PHo2WZ8TvzAag68bTulRmm0wo=";

  # Skip puppeteer browser download - use system Chrome
  env.PUPPETEER_SKIP_DOWNLOAD = "true";

  buildPhase = ''
    runHook preBuild
    npm run bundle
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib/node_modules/chrome-devtools-mcp
    cp -r build $out/lib/node_modules/chrome-devtools-mcp/
    cp package.json $out/lib/node_modules/chrome-devtools-mcp/
    chmod +x $out/lib/node_modules/chrome-devtools-mcp/build/src/index.js
    mkdir -p $out/bin
    ln -s $out/lib/node_modules/chrome-devtools-mcp/build/src/index.js $out/bin/chrome-devtools-mcp
    runHook postInstall
  '';

  meta = {
    description = "Chrome DevTools for coding agents - MCP server giving AI assistants access to Chrome DevTools";
    homepage = "https://github.com/ChromeDevTools/chrome-devtools-mcp";
    changelog = "https://github.com/ChromeDevTools/chrome-devtools-mcp/releases";
    license = lib.licenses.asl20;
    maintainers = [];
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
    mainProgram = "chrome-devtools-mcp";
  };
}
