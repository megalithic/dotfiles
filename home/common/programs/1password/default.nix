{ pkgs, ... }:
{
  home.packages = [
    pkgs.brewCasks."1password"
    pkgs.brewCasks."1password-cli"
  ];
}
