# Starship - cross-shell prompt
# Config (TOML) lives next to this file; written via xdg.configFile.
{...}: {
  programs.starship.enable = true;

  xdg.configFile."starship.toml".text = builtins.readFile ./starship.toml;
}
