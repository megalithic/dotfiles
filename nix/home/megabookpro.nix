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

  # llama.cpp: ownership flipped to mise (com.megadots.llama-cpp launchd agent
  # + mise/tasks/llama-server-launchd + mise/config/llama-cpp/models.ini),
  # mirroring the same conservative 32GB defaults. The HM module
  # (programs.llamaCppLocal) stays available but disabled here.

  # Host-specific home-manager overrides go here
  # Example: different shell aliases, extra packages, etc.
}
