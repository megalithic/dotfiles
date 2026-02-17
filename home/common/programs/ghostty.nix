# Ghostty - GPU-accelerated terminal emulator
# Migrated from homebrew ghostty@tip to nix ghostty-bin (2026-02-13)
#
# Config file: config/ghostty/config (raw ghostty format, not converted to nix)
# This approach preserves comments and allows easy editing without nix rebuild.
{
  config,
  lib,
  pkgs,
  ...
}: {
  programs.ghostty = {
    enable = true;
    package = pkgs.ghostty-bin; # Use pre-built binary (darwin), not ghostty (linux-only)
    
    # Don't use settings - we symlink the raw config file instead
    # This preserves comments and allows editing without rebuild
    enableFishIntegration = true;
  };

  # Symlink our config to where Ghostty looks on macOS
  # Ghostty checks: ~/Library/Application Support/com.mitchellh.ghostty/config
  home.file."Library/Application Support/com.mitchellh.ghostty/config" = {
    source = config.lib.file.mkOutOfStoreSymlink 
      "${config.home.homeDirectory}/.dotfiles/config/ghostty/config";
  };
}
