{ pkgs, ... }:
{
  programs.codex = {
    enable = true;
    package = pkgs.openai-codex;
  };
}
