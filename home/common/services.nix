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
  # oMLX - Apple Silicon native LLM inference
  # ─────────────────────────────────────────────────────────────────────────────
  # Listens on http://127.0.0.1:8000/v1. CLI installed via brew tap
  # (jundot/omlx); see modules/brew.nix and home/common/programs/omlx/.
  #
  # Disabled on megabookpro (32GB): ProcessMemoryEnforcer only tracks Metal
  # allocations, not true RSS — causes Jetsam OOM kills. See oMLX #702.
  # Works on rxbookpro (64GB) where headroom is sufficient.
  launchd.agents.omlx = {
    enable = config.programs.omlx.enable;
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
        OLLAMA_HOME = "${config.xdg.dataHome}/ollama";  # ~/.local/share/ollama/
        OLLAMA_HOST = "127.0.0.1:11434"; # localhost only (security)
        OLLAMA_FLASH_ATTENTION = "1";     # Flash attention (default 0.21.1+, explicit)
        OLLAMA_KV_CACHE_TYPE = "q8_0";    # Halve KV cache memory (requires flash attn)
        OLLAMA_NUM_PARALLEL = "1";        # Single user, single KV alloc
        OLLAMA_KEEP_ALIVE = "30m";        # Keep model loaded 30min (avoid reload latency)
      } // config.services.ollamaAgent.extraEnv;
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
