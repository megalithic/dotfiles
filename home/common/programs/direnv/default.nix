{ config, ... }:
{
  programs.direnv = {
    enable = true;
    # mise's direnv wins PATH; the nix binary here is a deliberate dupe —
    # programs.direnv.package is not nullable and the module provides nix-direnv
    # + direnv.toml, which are worth more than the wasted store copy (2026-08).
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
