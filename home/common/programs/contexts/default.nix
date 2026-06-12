{ pkgs, ... }:
{
  home.packages = [ pkgs.brewCasks.contexts ];
}
