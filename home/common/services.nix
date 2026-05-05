# User services (launchd agents)
#
# This module consolidates user-level launchd agents that run per-user.
# For system-level daemons, see: modules/darwin/services.nix
#
# Usage:
#   imports = [ ./services.nix ];
#
# To add host-specific agents, add them in home/<user>/<hostname>.nix:
#   launchd.agents.my-agent = { ... };
#
{
  config,
  pkgs,
  lib,
  ...
}: {
  # ─────────────────────────────────────────────────────────────────────────────
  # oMLX - Apple Silicon native LLM inference (default ON)
  # ─────────────────────────────────────────────────────────────────────────────
  # Listens on http://127.0.0.1:8000/v1. CLI installed via brew tap
  # (jundot/omlx); see modules/brew.nix and home/common/programs/omlx/.
  #
  # Default ON. Ollama is now opt-in (services.ollama.enable = true).
  launchd.agents.omlx = {
    enable = true;
    config = {
      ProgramArguments = [
        "/opt/homebrew/bin/omlx"
        "serve"
      ];
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "${config.home.homeDirectory}/Library/Logs/omlx/stdout.log";
      StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/omlx/stderr.log";
      EnvironmentVariables = {
        OMLX_HOST = "127.0.0.1";
        OMLX_PORT = "8000";
      };
    };
  };

  # ─────────────────────────────────────────────────────────────────────────────
  # Ollama - Local LLM inference (legacy, opt-in via services.ollamaAgent.enable)
  # ─────────────────────────────────────────────────────────────────────────────
  # Listening on http://localhost:11434. Opt-in only — default OFF.
  # Enable with: services.ollamaAgent.enable = true; in home/<hostname>.nix
  launchd.agents.ollama = {
    enable = config.services.ollamaAgent.enable;
    config = {
      ProgramArguments = [
        "${pkgs.ollama}/bin/ollama"
        "serve"
      ];
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "${config.home.homeDirectory}/Library/Logs/ollama/stdout.log";
      StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/ollama/stderr.log";
      EnvironmentVariables = {
        OLLAMA_HOME = "${config.home.homeDirectory}/.ollama";
        OLLAMA_HOST = "127.0.0.1:11434"; # localhost only (security)
      };
    };
  };

  launchd.agents.espanso = {
    enable = true;
    config = {
      Label = "com.federicoterzi.espanso";
      ProgramArguments = [
        "${config.home.profileDirectory}/bin/espanso"
        "launcher"
      ];
      RunAtLoad = true;
      StandardOutPath = "${config.home.homeDirectory}/Library/Logs/espanso/stdout.log";
      StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/espanso/stderr.log";
    };
  };

  # Ensure log directories exist
  home.activation.makeOllamaLogDir = lib.hm.dag.entryAfter ["writeBoundary"] ''
    mkdir -p ${config.home.homeDirectory}/Library/Logs/ollama
  '';

  home.activation.makeOmlxLogDir = lib.hm.dag.entryAfter ["writeBoundary"] ''
    mkdir -p ${config.home.homeDirectory}/Library/Logs/omlx
  '';

  home.activation.makeEspansoLogDir = lib.hm.dag.entryAfter ["writeBoundary"] ''
    mkdir -p ${config.home.homeDirectory}/Library/Logs/espanso
  '';
}
