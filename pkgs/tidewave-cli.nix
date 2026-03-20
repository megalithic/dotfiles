{mkApp}:

mkApp {
  pname = "tidewave-cli";
  version = "latest";
  src = {
    url = "https://github.com/tidewave-ai/tidewave_app/releases/latest/download/tidewave-cli-aarch64-apple-darwin";
    sha256 = "sha256-WSNcptqqM5jpMiQ65mQ3y5f+YImfNn8kriqcxL8Nu4I=";
  };
  artifactType = "binary";
  binaries = ["tidewave"];
  desc = "Tidewave MCP CLI for web app development";
  homepage = "https://tidewave.ai";
}
