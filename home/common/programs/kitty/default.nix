{ config, ... }:
{
  xdg.configFile."kitty" = {
    source = config.lib.mega.linkConfig "kitty";
    force = true;
  };
}
