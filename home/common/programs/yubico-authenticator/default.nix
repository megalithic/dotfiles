{ pkgs, ... }:
{
  home.packages = [ pkgs.brewCasks.yubico-authenticator ];
}
