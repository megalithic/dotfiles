{mkApp}: let
  version = "0.4.4";
in {
  tidewave = mkApp {
    pname = "tidewave";
    version = "${version}";
    appName = "Tidewave.app";
    src = {
      url = "https://github.com/tidewave-ai/tidewave_app/releases/download/v${version}/tidewave-app-aarch64.dmg";
      sha256 = "sha256-M36V/MfaD7ShoJ0RiwzW/OfXs+re+5Z2BeVFvS+yJz4=";
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
      sha256 = "sha256-N/r8X7xouFAPm57Sb5jqO3bTpVD7R9ykRuooY+K5qD8=";
    };
    artifactType = "binary";
    binaries = ["tidewave"];
    desc = "Tidewave MCP CLI for web app development";
    homepage = "https://tidewave.ai";
  };
}
