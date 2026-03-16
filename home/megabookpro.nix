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

  # Host-specific home-manager overrides go here
  # Example: different shell aliases, extra packages, etc.
}
