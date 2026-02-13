{
  config,
  pkgs,
  lib,
  ...
}: {
  # Ollama - Local LLM inference for Shade image capture intelligence
  # Epic: shade-cgn (Image capture intelligence: OCR + AI summarization)
  # Task: shade-cgn.1 (Setup Ollama with optimal models for M2 Max)
  #
  # NOTE: Launchd agent moved to home/common/services.nix
  # This file now only contains documentation for model installation.

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
