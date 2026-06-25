{ pkgs, ... }:
{
  programs.mise = {
    enable = true;
    package = pkgs.mise;
    enableFishIntegration = true;
    enableZshIntegration = true;
    globalConfig = {
      settings = {
        auto_install = true;
        experimental = true;
        verbose = false;
      };
      # Global task: apply per-worktree DB/port isolation to a Phoenix project.
      # Run from a project root: `mise run elixir-worktree-isolation` (dry-run)
      # or `mise run elixir-worktree-isolation -- --apply` to write.
      tasks.elixir-worktree-isolation = {
        description = "Apply per-worktree DB/port isolation to Phoenix config/dev.exs and config/test.exs";
        run = "elixir-worktree-isolation";
      };
    };
  };

  # Standalone Igniter-based patcher, owned here and exposed on PATH.
  home.file.".local/bin/elixir-worktree-isolation" = {
    source = ./scripts/elixir-worktree-isolation;
    executable = true;
  };
}
