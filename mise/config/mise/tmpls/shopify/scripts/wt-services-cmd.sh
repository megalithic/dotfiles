#!/usr/bin/env bash
# The per-worktree `services` command, installed into the worktree's PRIVATE
# git dir (.git/worktrees/<name>/wt-services-cmd) by the wt.toml pre-start hook
# and run in the tmux `services` window by wt-tmux-target.
#
# Keep the window usable when the dev server exits/crashes: bootstrap, install
# deps, start the theme dev server, then drop to an interactive shell.
mise run bootstrap
mise run install
mise run start:server
echo "[services] start:server exited ($?) - dropping to shell"
exec fish
