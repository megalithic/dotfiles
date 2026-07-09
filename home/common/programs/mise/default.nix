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
      # Global tasks: copy project templates from mise/config/mise/tmpls/
      # into a project's .config/ dir. Run from a project root:
      # `mise run gen:shopify`, `mise run gen:elixir -- /path/to/project`,
      # or `mise run gen:wt-elixir` for Worktrunk's .config/wt.toml.
      # Script lives in repo bin/ (on PATH in both nix and mise worlds).
      # Duplicated in mise/config/mise/global_config.toml (mise twin).
      tasks."gen:elixir" = {
        description = "Copy the elixir mise template + scripts to [target-dir]/.config/ (default: cwd)";
        dir = "{{cwd}}";
        run = "mise-tmpl-gen elixir";
      };
      tasks."gen:shopify" = {
        description = "Copy the shopify mise template + scripts to [target-dir]/.config/ (default: cwd)";
        dir = "{{cwd}}";
        run = "mise-tmpl-gen shopify";
      };
      tasks."gen:wt-elixir" = {
        description = "Copy the elixir Worktrunk template + scripts to [target-dir]/.config/wt.toml (default: cwd)";
        dir = "{{cwd}}";
        run = "mise-tmpl-gen wt.elixir";
      };
      tasks."gen:wt-shopify" = {
        description = "Copy the shopify Worktrunk template + scripts to [target-dir]/.config/wt.toml (default: cwd)";
        dir = "{{cwd}}";
        run = "mise-tmpl-gen wt.shopify";
      };
    };
  };

  # Standalone Igniter-based patcher, owned here and exposed on PATH.
  home.file.".local/bin/elixir-worktree-isolation" = {
    source = ./scripts/elixir-worktree-isolation;
    executable = true;
  };

}
