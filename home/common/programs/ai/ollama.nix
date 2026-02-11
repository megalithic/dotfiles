{
  config,
  pkgs,
  lib,
  ...
}: {
  # Ollama - Local LLM inference for Shade image capture intelligence
  # Epic: shade-cgn (Image capture intelligence: OCR + AI summarization)
  # Task: shade-cgn.1 (Setup Ollama with optimal models for M2 Max)

  # Ensure ollama package is installed (already in home/packages.nix)
  # This module only handles the launch agent configuration

  # CRITICAL: Launch agent to auto-start Ollama server on login
  # Ollama runs as a persistent background service, listening on http://localhost:11434
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
        # Set Ollama home directory for models and configs
        OLLAMA_HOME = "${config.home.homeDirectory}/.ollama";
        # Listen on localhost only (security)
        OLLAMA_HOST = "127.0.0.1:11434";
      };
    };
  };

  # Create log directory
  home.activation.ollamaLogDir = lib.hm.dag.entryAfter ["writeBoundary"] ''
    mkdir -p ${config.home.homeDirectory}/Library/Logs/ollama
  '';

  # Instructions for model installation (run after rebuild)
  # These are LARGE downloads - user should confirm before pulling
  #
  # Vision models (can process images directly):
  #   ollama pull llava:13b      # Best quality, ~7.4GB, fits in 32GB
  #   ollama pull llava:7b       # Faster, ~4.7GB
  #   ollama pull bakllava       # Alternative, ~4.4GB
  #
  # Text summarization models:
  #   ollama pull llama3.2       # Excellent for summarization, ~2GB
  #   ollama pull mistral        # Fast, good quality, ~4.1GB
  #   ollama pull phi3:medium    # Compact but capable, ~7.9GB
  #
  # Check status:
  #   ollama list
  #   curl http://localhost:11434/api/tags
}
