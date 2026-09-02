{ pkgs, ... }:
# NOTE: The devenv sandbox-$HOME wrapper below (added in fe950dfe5) is disabled.
# It caused more harm than good, so we're back to plain `pkgs.devenv`.
#
# Why it existed: devenv ships its own bundled nix that fetches `github:` flake
# inputs via a libgit2 git-clone. Our global gitconfig rewrites
# https://github.com/ to ssh://git@github.com/ (url.insteadOf), so that clone is
# forced onto ssh and fails with "authentication required but no callback set".
# devenv only reads gitconfig from $HOME (it ignores GIT_CONFIG_GLOBAL /
# NIX_USER_CONF_FILES), so the wrapper ran it under a sandbox $HOME that mirrored
# the real one via symlinks but dropped the github insteadOf rewrite.
#
# let
#   devenvWrapped = pkgs.writeShellScriptBin "devenv" ''
#     set -euo pipefail
#
#     real_devenv="${pkgs.devenv}/bin/devenv"
#     git="${pkgs.git}/bin/git"
#     coreutils="${pkgs.coreutils}/bin"
#
#     sb="$("$coreutils/mktemp" -d)"
#     trap '"$coreutils/rm" -rf "$sb"' EXIT
#
#     # Mirror every top-level entry of the real $HOME into the sandbox via
#     # symlinks, so caches/state/config all read and write through to the real
#     # home. Only .gitconfig is overridden below.
#     shopt -s nullglob dotglob
#     for e in "$HOME"/*; do
#       n="$("$coreutils/basename" "$e")"
#       [ "$n" = ".gitconfig" ] && continue
#       "$coreutils/ln" -sfn "$e" "$sb/$n"
#     done
#     shopt -u nullglob dotglob
#
#     # Sanitized gitconfig: copy the real one, then strip only the github
#     # insteadOf rewrite so fetches stay on plain (anonymous) https.
#     if [ -e "$HOME/.gitconfig" ]; then
#       "$coreutils/cp" -L "$HOME/.gitconfig" "$sb/.gitconfig"
#       "$coreutils/chmod" u+w "$sb/.gitconfig"
#       "$git" config --file "$sb/.gitconfig" \
#         --unset-all "url.ssh://git@github.com/.insteadOf" 2>/dev/null || true
#     fi
#
#     exec "$coreutils/env" HOME="$sb" "$real_devenv" "$@"
#   '';
# in
{
  home.packages = [ pkgs.devenv ];

  home.sessionVariables.DEVENV_TUI = "false";

  # Fish completion for `devenv tasks run <task>`
  xdg.configFile."fish/conf.d/devenv-tasks-run.fish".text = builtins.readFile ./devenv-tasks-run.fish;
}
