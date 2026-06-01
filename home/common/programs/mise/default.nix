_: {
  programs.mise = {
    enable = true;
    enableFishIntegration = true;
    enableZshIntegration = true;
    globalConfig.settings = {
      auto_install = true;
      experimental = true;
      verbose = false;
    };
  };
}
