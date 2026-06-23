# Worktrunk: Git worktree management CLI
# https://github.com/max-sixty/worktrunk
{ pkgs, ... }:
{
  programs.worktrunk = {
    enable = true;
    # Use nixpkgs' cached package; gitconfig maps `git wt <command>` to `wt <command>`.
    package = pkgs.worktrunk;
    enableBashIntegration = true;
    enableZshIntegration = true;
    enableFishIntegration = true;
  };
}
