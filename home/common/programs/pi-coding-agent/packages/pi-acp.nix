{
  lib,
  buildNpmPackage,
}:
buildNpmPackage {
  pname = "pi-acp";
  version = "0.0.27";

  src = ./pi-acp;

  npmDepsHash = "sha256-XwF45KUPQ0rKQFI1mikXNz172YenyysINe18sBegRXw=";

  meta = {
    description = "ACP adapter for pi coding agent (vendored with Tidewave patches)";
    homepage = "https://github.com/svkozak/pi-acp";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
    mainProgram = "pi-acp";
  };
}
