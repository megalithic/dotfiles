# Shade Configuration
# Generates ~/.config/shade/config.json for Shade app
# Epic: .dotfiles-42y (Dotfiles support for Shade MLX/LLM integration)
# Task: .dotfiles-4zt (Create shade.nix home-manager module)
# Cross-repo: shade-ahf.14 (Shade MLX Integration)
{
  config,
  pkgs,
  lib,
  ...
}: let
  # ===========================================================================
  # LLM Configuration
  # ===========================================================================
  # Backend options: "mlx" (native, default), "ollama" (local server)
  # Model presets:
  #   quality:  mlx-community/Qwen3-8B-Instruct-4bit (best results, fits M2 Max)
  #   balanced: mlx-community/Qwen3-4B-Instruct-4bit (faster, still good)
  #   fast:     mlx-community/Qwen3-1.7B-Instruct-4bit (quickest, basic)
  llmConfig = {
    enabled = true;
    backend = "mlx";
    model = "mlx-community/Qwen3-8B-Instruct-4bit";
    preset = "quality";
    max_tokens = 512;
    temperature = 0.7;
    top_p = 0.9;
    idle_timeout = 300; # 5 minutes before unloading model
  };

  # ===========================================================================
  # Capture Configuration
  # ===========================================================================
  # Async enrichment: OCR happens immediately, LLM runs in background
  # Placeholders are inserted and replaced when LLM completes
  captureConfig = {
    # null = use $notes_home/captures from environment
    working_directory = null;
    async_enrichment = true;
    placeholder_prefix = "<!-- shade:pending:";
    placeholder_suffix = " -->";
  };

  # ===========================================================================
  # Window Configuration
  # ===========================================================================
  # Panel sizing and position
  windowConfig = {
    width_percent = 0.4;
    height_percent = 0.6;
    position = "center"; # "center", "right", "left"
  };

  # Combined config
  shadeConfig = {
    llm = llmConfig;
    capture = captureConfig;
    window = windowConfig;
  };
in {
  # ===========================================================================
  # Generate config.json
  # ===========================================================================
  # Shade reads from ~/.config/shade/config.json (XDG compliant)
  # CLI arguments override config file values
  home.file.".config/shade/config.json" = {
    text = builtins.toJSON shadeConfig;
    # Force overwrite - this is 100% Nix-managed
    force = true;
  };

  # ===========================================================================
  # Usage Notes
  # ===========================================================================
  # After rebuild, Shade will auto-load config on next launch.
  # To reload without restart: Shade reads config at startup only.
  #
  # CLI overrides (take precedence over config):
  #   shade --no-llm              # Disable LLM features
  #   shade --llm-backend ollama  # Use Ollama instead of MLX
  #   shade --llm-model <model>   # Override model
  #
  # Model download happens on first use with progress indicator.
  # ~4-8GB for 4-bit models depending on size.
}
