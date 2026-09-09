#!/usr/bin/env bash
# Foreground services runner for the tmux services window (dev:services task).
# Titles the window services-<phoenix port> and mirrors pane output to
# .local/log/services.log (consumed by the `logs` task), then execs the
# Phoenix server (m s). Port derivation stays in phx-port.sh — authoritative,
# mirrors dev.exs PORT-override semantics; $PHX_PORT is the fallback.
set -euo pipefail

if [ -n "${TMUX_PANE:-}" ] && command -v tmux >/dev/null 2>&1; then
  log_dir=".local/log"
  mkdir -p "$log_dir"
  : >"$log_dir/services.log"
  tmux pipe-pane -t "$TMUX_PANE" "cat >> \"$PWD/$log_dir/services.log\"" 2>/dev/null || true
  port="$(bash "$HOME/.dotfiles/config/mise/tmpls/elixir/scripts/phx-port.sh" 2>/dev/null | tail -n 1 || true)"
  [ -n "$port" ] || port="${PHX_PORT:-}"
  if [ -n "$port" ]; then
    tmux rename-window -t "$TMUX_PANE" "services-${port}" 2>/dev/null || true
  fi
fi

exec m s
