{ pkgs, ... }:
{
  home.packages = [ pkgs.brewCasks."okta-verify" ];
}
