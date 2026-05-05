# Ollama - Local LLM inference (legacy, opt-in via services.ollama.enable)
#
# Epic: shade-cgn (Image capture intelligence - now using MLX)
# Status: Opt-in via `services.ollama.enable = true;` — defaults OFF.
# Migration: Replaced by oMLX (dot-8arp). Keep for fallback only.
#
# To re-enable:
#   home/<hostname>.nix: services.ollama.enable = true;
#
# Model installation (if re-enabled):
#   ollama pull llava:13b      # Vision, ~7.4GB
#   ollama pull llama3.2       # Text, ~2GB
#
# Check status:
#   ollama list
#   curl http://localhost:11434/api/tags
{
  config,
  pkgs,
  lib,
  ...
}: {
  options.services.ollamaAgent = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable ollama launchd agent (opt-in, default OFF).";
    };
  };
}
