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

    # Sidebar width when in sidebar mode (percentage of screen)
    sidebar_width = 0.4;

    # Mode cycle for toggle - cycles through these modes in order
    # Options: "floating", "sidebar-left", "sidebar-right"
    mode_cycle = ["floating" "sidebar-left" "sidebar-right"];

    # Focus border - visual indicator when Shade panel has keyboard focus
    # Uses NSVisualEffectView + CALayer for native macOS appearance
    focus_border = {
      enabled = true;
      width = 2.0; # Border thickness in points
      corner_radius = 0.0; # Rounded corners (0 = square)
      color = "#83A598"; # Everforest aqua (hex: RGB, RRGGBB, or RRGGBBAA)
      opacity = 0.2; # Border opacity (0.0 - 1.0)
      animated = true; # Animate border appearance/disappearance
      animation_duration = 0.15; # Animation duration in seconds
      menubar_stroke_color = "#E68C59"; # Menubar icon stroke when focused (Everforest orange)
    };
  };

  # ===========================================================================
  # Notes Configuration
  # ===========================================================================
  # Vault paths for image capture handling
  # Shade copies images to assets dir, obsidian.nvim templates reference them
  notesConfig = {
    # Root of the notes vault (supports ~ expansion)
    # Falls back to $NOTES_HOME env var, then ~/iclouddrive/Documents/_notes
    home = "~/iclouddrive/Documents/_notes";
    # Assets directory for images (null = {home}/assets)
    assets_dir = null;
    # Captures directory (null = {home}/captures)
    captures_dir = null;
  };

  # Combined config
  shadeConfig = {
    llm = llmConfig;
    capture = captureConfig;
    window = windowConfig;
    notes = notesConfig;
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
