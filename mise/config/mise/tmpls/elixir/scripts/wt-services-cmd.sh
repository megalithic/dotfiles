#!/usr/bin/env bash
# The per-worktree `services` command, installed into the worktree's PRIVATE
# git dir (.git/worktrees/<name>/wt-services-cmd) by the wt.toml pre-start hook
# and run in the tmux `services` window by wt-tmux-target.
#
# Output is captured to .local/log/services.log (gitignored) via `tmux
# pipe-pane`, which taps the pane's output stream WITHOUT touching the process
# TTY — so the Phoenix iex console stays fully interactive. Inspect after a
# failed boot with `mise run logs` (strips ANSI) or `mise run logs:follow`.
#
# Heavy setup (`mise run setup` → `mix ecto.reset` wipes + reseeds the DB) runs
# only ONCE per worktree, guarded by .local/state/setup-complete. Reopening the
# services window then just re-bootstraps and restarts the server. Remove the
# marker (or run `mise run setup`) to force a full re-setup.
#
# The tmux window is renamed to services-<port> at script start (see below).
# wt-tmux-target always creates the window as plain `services` — deriving the
# port there consulted the invoking shell's env, so titles showed the
# previous worktree's port.
log_dir=".local/log"
mkdir -p "$log_dir"
LOG="$PWD/$log_dir/services.log"
if [ -n "${TMUX_PANE:-}" ] && command -v tmux >/dev/null 2>&1; then
  : >"$LOG"
  tmux pipe-pane -t "$TMUX_PANE" "cat >> \"$LOG\""
fi

# Append the derived Phoenix port to this window's title (services-<port>)
# immediately — it's knowable at script start: tmux spawns the pane with the
# worktree's mise env (PHX_PORT already resolved), and .config/ exists by now
# (wt switch runs its hooks before wt-tmux-target creates the window).
# Prefer phx-port.sh (authoritative — mirrors dev.exs PORT-override
# semantics); fall back to $PHX_PORT. Deriving this in wt-tmux-target at
# window-creation time consulted the invoking shell's PORT/PHX_PORT, so the
# title showed the previous worktree's port.
if [ -n "${TMUX_PANE:-}" ] && command -v tmux >/dev/null 2>&1; then
  port="$(bash .config/scripts/phx-port.sh 2>/dev/null | tail -n 1 || true)"
  [ -n "$port" ] || port="${PHX_PORT:-}"
  if [ -n "$port" ]; then
    tmux rename-window -t "$TMUX_PANE" "services-${port}" 2>/dev/null || true
  fi
fi

marker=".local/state/setup-complete"
mkdir -p "$(dirname "$marker")"

echo "[services] $(date '+%F %T') start in $PWD (PHX_PORT=${PHX_PORT:-?})"
mise run bootstrap
if [ -f "$marker" ]; then
  echo "[services] setup already complete ($(cat "$marker")) - skipping (rm $marker to force)"
else
  echo "[services] first run - mise run setup"
  if mise run setup; then
    date '+%F %T' >"$marker"
  else
    echo "[services] setup FAILED - leaving unmarked so it retries on next open"
  fi
fi
echo "[services] starting server: mise run start:server"
mise run start:server
echo "[services] start:server exited ($?) - dropping to shell (mise run logs)"
exec fish
