_: {
  xdg.configFile."karabiner/karabiner.json" = {
    text = builtins.readFile ./karabiner.json;
    force = true;
  };
}
