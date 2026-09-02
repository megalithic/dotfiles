{ config, ... }:
{
  programs.nh = {
    enable = true;
    flake = "${config.home.homeDirectory}/.dotfiles/";
    clean = {
      enable = true;
      extraArgs = "--keep-since 8d";
    };
  };
}
