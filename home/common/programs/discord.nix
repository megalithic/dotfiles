# Discord - Chat platform
# Migrated from homebrew to nix (2026-02-13)
{
  config,
  lib,
  pkgs,
  ...
}: {
  programs.discord = {
    enable = true;
    settings = {
      # Existing settings preserved from ~/Library/Application Support/discord/settings.json
      offloadAdmControls = true;
      chromiumSwitches = {};
      # HM sets SKIP_HOST_UPDATE = true by default (prevents update nags)
    };
  };
}
