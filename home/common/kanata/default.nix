{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.homeModules.kanata;
in {
  options.homeModules.kanata = {
    enable =
      mkEnableOption "kanata configuration"
      // {
        default = true;
      };
  };

  config = mkIf cfg.enable {
    home.packages = [pkgs.kanata];

    xdg.configFile = {
      "kanata/leeloo.kbd".source = ./leeloo.kbd;
      "kanata/internal.kbd".source = ./internal.kbd;
    };

    # Create initial active profile symlink (defaults to internal keyboard)
    home.activation.kanataActiveProfile = lib.hm.dag.entryAfter ["writeBoundary"] ''
      $DRY_RUN_CMD ln -sf $VERBOSE_ARG \
        ${config.xdg.configHome}/kanata/internal.kbd \
        ${config.xdg.configHome}/kanata/active.kbd
    '';
  };
}
