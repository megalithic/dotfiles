# Worktrunk: Git worktree management CLI
# https://github.com/max-sixty/worktrunk
{
  config,
  pkgs,
  inputs,
  lib,
  ...
}: {
  programs.worktrunk = {
    enable = true;
    package = inputs.worktrunk.packages.${pkgs.stdenv.hostPlatform.system}.worktrunk;
    enableBashIntegration = true;
    enableZshIntegration = true;
    enableFishIntegration = true;
  };

  # Also install the git-wt variant as an alternative (git wt <command>)
  home.packages = [
    inputs.worktrunk.packages.${pkgs.stdenv.hostPlatform.system}.worktrunk-with-git-wt
  ];
}