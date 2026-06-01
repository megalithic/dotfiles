{ config, ... }:
{
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
    mise.enable = true;
    config = {
      global.load_dotenv = true;
      global.warn_timeout = 0;
      global.hide_env_diff = true;
      whitelist.prefix = [ config.home.homeDirectory ];
    };
  };
}
