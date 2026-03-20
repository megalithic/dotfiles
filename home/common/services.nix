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
  # Ollama - Local LLM inference server
  # ─────────────────────────────────────────────────────────────────────────────
  # Runs as a persistent background service, listening on http://localhost:11434
  # Used by: Shade (image capture intelligence), various AI tools
  #
  # Model management (run manually after rebuild):
  #   ollama list              # Show installed models
  #   ollama pull llava:13b    # Vision model (~7.4GB)
  #   ollama pull llama3.2     # Text model (~2GB)
  #
  launchd.agents.ollama = {
    enable = true;
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

  home.activation.makeEspansoLogDir = lib.hm.dag.entryAfter ["writeBoundary"] ''
    mkdir -p ${config.home.homeDirectory}/Library/Logs/espanso
  '';
}
