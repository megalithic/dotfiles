{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
}:
buildNpmPackage {
  pname = "pi-acp";
  version = "0.0.27";

  src = fetchFromGitHub {
    owner = "svkozak";
    repo = "pi-acp";
    rev = "v0.0.27";
    hash = "sha256-Bb7qQkELDY175ZNmJD70LzmkcmoQL1LWAnfIxN+ttso=";
  };

  npmDepsHash = "sha256-EmzhcvVzrirlKh57Tl4BKVG4XLkAgdaYgdhMfpZVbRI=";

  patches = [
    ../patches/pi-acp-tidewave.patch
  ];

  meta = {
    description = "ACP adapter for pi coding agent";
    homepage = "https://github.com/svkozak/pi-acp";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
    mainProgram = "pi-acp";
  };
}
