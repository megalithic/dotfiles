# Ghostty - GPU-accelerated terminal emulator
# Migrated from homebrew ghostty@tip to nix ghostty-bin (2026-02-13)
#
# Config file: config/ghostty/config (raw ghostty format, not converted to nix)
# This approach preserves comments and allows easy editing without nix rebuild.
{
  config,
  pkgs,
  ...
}:
{
  programs.ghostty = {
    enable = true;
    package = pkgs.ghostty-bin; # Use pre-built binary (darwin), not ghostty (linux-only)

    # Don't use settings - we symlink the raw config file instead.
    # This preserves comments and allows editing without rebuild.
    # Home Manager's fish integration sources $GHOSTTY_RESOURCES_DIR without
    # checking the file exists. Keep our guarded source in the fish module instead
    # so stale dev Ghostty paths do not break shell startup.
    enableFishIntegration = false;
  };

  # Ghostty on macOS supports XDG config, so keep one canonical live link.
  xdg.configFile."ghostty" = {
    source = config.lib.mega.linkConfig "ghostty";
    force = true;
  };
}
