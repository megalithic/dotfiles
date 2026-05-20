# megabookpro home-manager configuration
# Imports shared config + adds host-specific overrides
{
  ...
}:
{
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

  # Host-specific home-manager overrides go here
  # Example: different shell aliases, extra packages, etc.
}
