{ config, ... }:
{
  # Kanata keyboard configs - out-of-store symlinks for dynamic switching
  # macbook.kbd: normal config with home row mods
  # macbook-disabled.kbd: blocks internal keyboard when external keyboard connected
  # kanata.kbd: active config, dynamically switched by Hammerspoon dock watcher
  #            (defaults to macbook.kbd, dock watcher switches based on external keyboard)
  # kanata config profiles - kanata.kbd symlink is managed by darwin activation
  # script and switched dynamically by Hammerspoon dock watcher
  xdg.configFile."kanata/macbook.kbd" = {
    source = config.lib.mega.linkConfig "kanata/macbook.kbd";
    force = true;
  };

  xdg.configFile."kanata/macbook-disabled.kbd" = {
    source = config.lib.mega.linkConfig "kanata/macbook-disabled.kbd";
    force = true;
  };
}
