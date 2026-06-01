{ config, ... }:
{
  home.sessionVariables.RIPGREP_CONFIG_PATH = "${config.xdg.configHome}/ripgrep/rc";
  xdg.configFile."ripgrep/rc".source = ./rc;

  programs.ripgrep.enable = true;
}
