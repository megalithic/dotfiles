{ mkApp }:

mkApp {
  pname = "tidewave-cli";
  version = "0.4.4";
  src = {
    url = "https://github.com/tidewave-ai/tidewave_app/releases/download/v0.4.4/tidewave-cli-aarch64-apple-darwin";
    sha256 = "sha256-N/r8X7xouFAPm57Sb5jqO3bTpVD7R9ykRuooY+K5qD8=";
  };
  artifactType = "binary";
  binaries = [ "tidewave" ];
  desc = "Tidewave MCP CLI for web app development";
  homepage = "https://tidewave.ai";
}
