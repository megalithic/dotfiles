{mkApp}: let
  version = "0.4.3";
in {
  tidewave = mkApp {
    pname = "tidewave";
    version = "${version}";
    appName = "Tidewave.app";
    src = {
      url = "https://github.com/tidewave-ai/tidewave_app/releases/download/v${version}/tidewave-app-aarch64.dmg";
      sha256 = "sha256-qT2GT6yvhFol7hbwViq8LVzLzEQ0xc53es/oENEHLFQ";
    };
    binaries = [];
    desc = "Tidewave coding agent for full-stack web app development";
    homepage = "https://tidewave.ai";
  };

  tidewave-cli = mkApp {
    pname = "tidewave-cli";
    inherit version;
    src = {
      url = "https://github.com/tidewave-ai/tidewave_app/releases/download/v${version}/tidewave-cli-aarch64-apple-darwin";
      sha256 = "sha256-CXEV/DesGClwWejgNQv1pkrqEW+72+XjBYV1TFiH2PY=";
    };
    artifactType = "binary";
    binaries = ["tidewave"];
    desc = "Tidewave MCP CLI for web app development";
    homepage = "https://tidewave.ai";
  };
}
