{ pkgs, ... }:
{
  programs.bat = {
    enable = true;
    # bat-extras disabled — all of them pull in nushell as a build dep
    # extraPackages = with pkgs.bat-extras; [ batgrep prettybat batman ];
    config = {
      theme = "everforest";
    };
    themes = {
      everforest = {
        src =
          pkgs.fetchFromGitHub {
            owner = "neuromaancer";
            repo = "everforest_collection";
            rev = "ec3936e65699f38f8a9b1468d6ac20a25423d5af";
            sha256 = "HQQzmSYcQY4jYyk7zyxdOSJylqJl4aBobT37pST6AXE=";
          }
          + "/bat";

        file = "everforest-soft.tmtheme";
      };
    };
  };
}
