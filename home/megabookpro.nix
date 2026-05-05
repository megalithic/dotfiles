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
  # oMLX tuning (M2 Max, 32GB unified memory) — dot-8arp Phase 2.3
  # ===========================================================================
  programs.omlx.settings = {
    model.max_model_memory = "20GB";
    cache.hot_cache_max_size = "2GB";
    cache.ssd_cache_max_size = "40GB";
    memory.max_process_memory = "75%";
  };

  # Pin only Qwen (primary), TTL Gemma (secondary) — 32GB limit
  programs.omlx.modelSettings.models = {
    "Qwen3.6-35B-A3B-4bit" = {
      is_pinned = true;
      ttl_seconds = null;  # Never auto-unload
      max_context_window = 32768;
    };
    "gemma-4-26b-a4b-it-4bit" = {
      is_pinned = false;
      ttl_seconds = 600;  # Unload after 10min idle
    };
  };

  # Host-specific home-manager overrides go here
  # Example: different shell aliases, extra packages, etc.
}
