{pkgs, ...}: {
  home.packages = [pkgs.devenv];

  # Fish completion for `devenv tasks run <task>`
  xdg.configFile."fish/conf.d/devenv-tasks-run.fish".text = builtins.readFile ./devenv-tasks-run.fish;
}
