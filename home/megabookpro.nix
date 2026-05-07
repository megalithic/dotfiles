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

      fantastical = {
        enable = true;
      };
    };
  };

  # ===========================================================================
  # Ollama — safe local inference for 32GB (sequential model swap, no OOM)
  # Metal GPU: 100% offload, flash attention, q8_0 KV cache
  # ===========================================================================
  services.ollamaAgent.enable = true;
  services.ollamaAgent.extraEnv = {
    OLLAMA_MAX_LOADED_MODELS = "1";       # Prevent dual-load on 32GB
    OLLAMA_GPU_OVERHEAD = "4294967296";   # Reserve 4GB for OS/browser/nvim
    OLLAMA_CONTEXT_LENGTH = "8192";       # Default ctx (auto was 4096, too small for coding)
  };

  # ===========================================================================
  # oMLX — DISABLED on megabookpro (32GB insufficient for multi-model)
  # ===========================================================================
  # ProcessMemoryEnforcer only tracks Metal allocations, not true RSS.
  # Loading a second model alongside pinned Qwen27B (~18.7GB) causes macOS
  # Jetsam to SIGKILL the process (vm-compressor-space-shortage).
  # See: oMLX Issue #702, #1060 (VLM memory leak on unload).
  # Config preserved for rxbookpro (64GB) or future oMLX fixes.
  programs.omlx.enable = false;
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
