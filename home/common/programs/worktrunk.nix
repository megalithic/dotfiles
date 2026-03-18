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
    # Use worktrunk-with-git-wt to install as git-wt subcommand (git wt <command>)
    package = inputs.worktrunk.packages.${pkgs.stdenv.hostPlatform.system}.worktrunk-with-git-wt;
    enableBashIntegration = true;
    enableZshIntegration = true;
    enableFishIntegration = true;
  };
}