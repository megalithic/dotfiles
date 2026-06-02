{ config, ... }:
{
  home.file."Library/Application Support/espanso".source = config.lib.mega.linkConfig "espanso";
}
