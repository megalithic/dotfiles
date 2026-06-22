{ pkgs, ... }:
{
  programs.mise = {
    enable = true;
    package = pkgs.mise;
    enableFishIntegration = true;
    enableZshIntegration = true;
    globalConfig.settings = {
      auto_install = true;
      experimental = true;
      verbose = false;
    };
  };
}
