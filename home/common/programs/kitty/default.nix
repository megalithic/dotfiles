{
  config,
  pkgs,
  ...
}:
{
  home.packages = [ pkgs.brewCasks.kitty ];

  xdg.configFile."kitty" = {
    source = config.lib.mega.linkConfig "kitty";
    force = true;
  };
}
