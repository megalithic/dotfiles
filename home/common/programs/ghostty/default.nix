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
    # Ghostty handles fish shell integration itself; no Home Manager or fish
    # module sourcing is needed here.
    enableFishIntegration = false;
  };

  # Ghostty on macOS supports XDG config, so keep one canonical live link.
  xdg.configFile."ghostty" = {
    source = config.lib.mega.linkConfig "ghostty";
    force = true;
  };
}
