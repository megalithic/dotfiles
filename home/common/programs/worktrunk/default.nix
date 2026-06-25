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
    # Fish integration is owned locally by a Home Manager `wt` fish function
    # (home/common/programs/fish/functions.nix) that vendors upstream directive
    # handling and adds implicit switch + tmux target modes. Disabling the
    # upstream fish init avoids two competing `wt` functions racing.
    enableFishIntegration = false;
  };
}
