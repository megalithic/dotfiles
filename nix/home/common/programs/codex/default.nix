{ pkgs, ... }:
{
  programs.codex = {
    enable = true;
    package = pkgs.codex;
  };
}
