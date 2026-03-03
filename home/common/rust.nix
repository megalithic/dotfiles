{
  config,
  pkgs,
  lib,
  ...
}: {
  home.packages = with pkgs; [rustup];
  home.sessionPath = ["${config.home.homeDirectory}/.cargo/bin"];

  programs.bacon.enable = true;

  home.activation = let
    rustup = "${pkgs.rustup}/bin/rustup";
  in {
    rustup_setup = lib.hm.dag.entryAfter ["writeBoundary"] ''
      run ${rustup} default nightly
    '';
  };
}
