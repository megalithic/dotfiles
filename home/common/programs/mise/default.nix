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
      # Global tasks: copy a language template from mise/config/mise/tmpls/
      # into a project as mise.local.toml. Run from a project root:
      # `mise run gen:shopify` or `mise run gen:elixir -- /path/to/project`.
      # Script lives in repo bin/ (on PATH in both nix and mise worlds).
      # Duplicated in mise/config/mise/global_config.toml (mise twin).
      tasks."gen:elixir" = {
        description = "Copy the elixir mise template to [target-dir]/mise.local.toml (default: cwd)";
        dir = "{{cwd}}";
        run = "mise-tmpl-gen elixir";
      };
      tasks."gen:shopify" = {
        description = "Copy the shopify mise template to [target-dir]/mise.local.toml (default: cwd)";
        dir = "{{cwd}}";
        run = "mise-tmpl-gen shopify";
      };
    };
  };

  # Standalone Igniter-based patcher, owned here and exposed on PATH.
  home.file.".local/bin/elixir-worktree-isolation" = {
    source = ./scripts/elixir-worktree-isolation;
    executable = true;
  };

}
