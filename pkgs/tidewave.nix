{mkApp}: let
  version = "0.4.2";
  hash = "sha256-6gPXUahSRmrs3DF0YWqFEWuP2tZdB9A1CIRQDd4EtDE=";
in
  mkApp {
    pname = "tidewave";
    version = "${version}";
    appName = "Tidewave.app";
    src = {
      url = "https://github.com/tidewave-ai/tidewave_app/releases/download/v${version}/tidewave-app-aarch64.dmg";
      sha256 = hash;
    };
    binaries = []; # No CLI in app bundle; use tidewave-cli for CLI
    desc = "Tidewave is the coding agent for full-stack web app development. Integrate Claude Code, OpenAI Codex, and other agents with your web app and web framework at every layer, from UI to database.";
    homepage = "https://tidewave.ai";
  }
