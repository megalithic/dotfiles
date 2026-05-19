# megabookpro home-manager configuration
# Imports shared config + adds host-specific overrides
{
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./common
  ];

  # ===========================================================================
  # App Settings Sync
  # ===========================================================================
  # Syncs app settings to iCloud for backup/restore across machines.
  # Usage: settings-sync export|import|status [app|all]
  settings-sync = {
    enable = true;
    # Default: ~/Library/Mobile Documents/com~apple~CloudDocs/Sync/app-settings
    # syncDir = "~/iclouddrive/Sync/app-settings";  # Alternative path

    apps = {
      brave-nightly = {
        enable = true;
        # Opt-in sensitive data (disabled by default)
        # cookies = true;   # Session cookies
        # history = true;   # Browsing history
        # logins = true;    # Saved passwords (use 1Password instead!)
      };

      mailmate = {
        enable = true;
        # database = true;  # Include full mail database (large!)
      };

      # fantastical = {
      #   enable = true;
      # };
    };
  };

  # ===========================================================================
  # llama.cpp — primary local inference for 32GB (conservative defaults)
  # ===========================================================================
  # Migration from Ollama/oMLX: use llama-server router mode with one loaded
  # GGUF model at a time. 8K context, q8_0 KV cache, and flash attention keep
  # memory predictable on 32GB while leaving headroom for OS/browser/nvim.
  programs.llamaCppLocal = {
    enable = true;
    modelsMax = 1;
    ctxSize = 8192;
    parallel = 1;
    cacheTypeK = "q8_0";
    cacheTypeV = "q8_0";
    flashAttn = "on";
  };

  # Legacy local inference backends disabled while llama.cpp replaces them.
  # oMLX stays off: its memory guard missed true RSS and caused Jetsam kills
  # when a second model loaded alongside pinned Qwen27B on 32GB.
  services.ollamaAgent.enable = false;
  programs.omlx.enable = false;

  # Preserved oMLX tuning until obsolete wiring cleanup.
  programs.omlx.settings = {
    model.max_model_memory = "24GB";
    cache.hot_cache_max_size = "2GB";
    cache.ssd_cache_max_size = "40GB";
    memory.max_process_memory = "75%";
  };
  programs.omlx.modelSettings.models = {
    "Qwen3.6-27B-4bit" = {
      is_pinned = true;
      ttl_seconds = null;
      max_context_window = 32768;
    };
    "DeepSeek-R1-Distill-Qwen-14B-4bit" = {
      is_pinned = false;
      ttl_seconds = 600;
    };
    "gemma-4-e4b-it-4bit" = {
      is_pinned = false;
      ttl_seconds = 600;
    };
  };

  # Host-specific home-manager overrides go here
  # Example: different shell aliases, extra packages, etc.
}
