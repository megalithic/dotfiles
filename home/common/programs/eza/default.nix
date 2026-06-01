_: {
  xdg.configFile."eza/theme.yml".source = ./theme.yml;

  programs.eza = {
    enable = true;
    enableZshIntegration = true;
    enableFishIntegration = true;
    colors = "always";
    git = true;
    icons = "always";
    extraOptions = [
      "-lah"
      "--group-directories-first"
      "--color-scale"
    ];
  };
}
