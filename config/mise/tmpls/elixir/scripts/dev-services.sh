#!/usr/bin/env bash
# Foreground services runner for the tmux services window (dev:services task).
# Titles the window services-<phoenix port> and mirrors pane output to
# .local/log/services.log (consumed by the `logs` task), then runs the
# Phoenix server (m s). Port derivation stays in phx-port.sh — authoritative,
# mirrors dev.exs PORT-override semantics; $PHX_PORT is the fallback.
#
# m s runs the OTP shell (iex), which pushes the kitty/CSI-u keyboard
# protocol and bracketed paste onto the pane. When the BEAM dies abruptly
# (Ctrl+C on the raw mise task SIGINTs the whole process group) it never
# sends its restore sequences, leaving the pane's key encoding stuck. So we
# run m s as a child (not exec) and always restore terminal state on the way
# out — normal exit, failure, SIGINT, SIGTERM, or SIGHUP.
set -euo pipefail

cleanup() {
  rc=$?
  # Pop kitty keyboard flags, disable modifyOtherKeys, disable bracketed
  # paste. Harmless no-ops when the BEAM already restored them itself.
  printf '\033[<u\033[>4;0m\033[?2004l' || true
  # BEAM leaves the pty in raw mode; put termios back.
  stty sane 2>/dev/null || true
  if [ -n "${TMUX_PANE:-}" ] && command -v tmux >/dev/null 2>&1; then
    # Detach the log mirror started below (bare pipe-pane = off).
    tmux pipe-pane -t "$TMUX_PANE" 2>/dev/null || true
  fi
  exit "$rc"
}
# Fatal signals only run the EXIT trap if they are themselves trapped.
trap 'exit 130' INT
trap 'exit 143' TERM
trap 'exit 129' HUP
trap cleanup EXIT

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

m s
