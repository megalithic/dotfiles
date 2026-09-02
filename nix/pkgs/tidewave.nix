{ mkApp }:

mkApp {
  pname = "tidewave";
  version = "0.4.4";
  appName = "Tidewave.app";
  src = {
    url = "https://github.com/tidewave-ai/tidewave_app/releases/download/v0.4.4/tidewave-app-aarch64.dmg";
    sha256 = "sha256-M36V/MfaD7ShoJ0RiwzW/OfXs+re+5Z2BeVFvS+yJz4=";
  };
  binaries = [ ];
  desc = "Tidewave coding agent for full-stack web app development";
  homepage = "https://tidewave.ai";
}
