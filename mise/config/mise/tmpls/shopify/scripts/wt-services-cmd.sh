#!/usr/bin/env bash
# The per-worktree `services` command, installed into the worktree's PRIVATE
# git dir (.git/worktrees/<name>/wt-services-cmd) by the wt.toml pre-start hook
# and run in the tmux `services` window by wt-tmux-target.
#
# Output is captured to .local/log/services.log (gitignored) via `tmux
# pipe-pane`, which taps the pane's output stream WITHOUT touching the process
# TTY — so the dev server stays fully interactive. Inspect after a failed boot
# with `mise run logs` (strips ANSI) or `mise run logs:follow`.
log_dir=".local/log"
mkdir -p "$log_dir"
LOG="$PWD/$log_dir/services.log"
if [ -n "${TMUX_PANE:-}" ] && command -v tmux >/dev/null 2>&1; then
  : >"$LOG"
  tmux pipe-pane -t "$TMUX_PANE" "cat >> \"$LOG\""
fi

echo "[services] $(date '+%F %T') start in $PWD"
mise run bootstrap
mise run install
echo "[services] starting server: mise run start:server"
mise run start:server
echo "[services] start:server exited ($?) - dropping to shell (mise run logs)"
exec fish
