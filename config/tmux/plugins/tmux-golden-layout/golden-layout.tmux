#!/usr/bin/env bash
# tmux-golden-layout entrypoint (TPM-compatible).
#
# Registers indexed hooks (slot 188) for focus/layout/resize events and binds
# the resume key. Safe to re-source: indexed set-hook slots and bind-key are
# replaced in place, never appended.
#
# Options (set before sourcing):
#   @gl-enabled      on|off   (default on)
#   @gl-min-width    cells    (default 4)
#   @gl-min-height   cells    (default 2)
#   @gl-resume-key   key      (default =)
#   @gl-debug        on|off   (default off; logs to $TMPDIR/tmux-gl-<uid>/)

set -u

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GL="$CURRENT_DIR/bin/gl"
HOOK_INDEX=188

# Resolve bun once at load; hooks reuse it through TMUX_GL_BUN.
BUN="$(command -v bun 2>/dev/null || true)"
if [ -z "$BUN" ] && command -v mise >/dev/null 2>&1; then
  BUN="$(mise which bun 2>/dev/null || true)"
fi
if [ -z "$BUN" ]; then
  tmux display-message "tmux-golden-layout: bun not found; plugin disabled" 2>/dev/null || true
  exit 0
fi
tmux set-option -g @gl-bun "$BUN"

# Pin the server socket so every hook invocation talks to this server even if
# the child environment is unusual (tests, nested tmux).
SOCKET="$(tmux display-message -p '#{socket_path}' 2>/dev/null || true)"

ENV_PREFIX="TMUX_GL_BUN='$BUN'"
if [ -n "$SOCKET" ]; then
  ENV_PREFIX="GL_TMUX_SOCKET='$SOCKET' $ENV_PREFIX"
fi

hook() {
  tmux set-hook -g "$1[$HOOK_INDEX]" "run-shell -b \"$ENV_PREFIX '$GL' $2\""
}

if [ "$(tmux show-options -gqv @gl-enabled)" = "off" ]; then
  # Unregister our slots on reload when disabled.
  tmux set-hook -gu "after-select-pane[$HOOK_INDEX]" 2>/dev/null || true
  tmux set-hook -gu "after-split-window[$HOOK_INDEX]" 2>/dev/null || true
  tmux set-hook -gu "after-resize-pane[$HOOK_INDEX]" 2>/dev/null || true
  tmux set-hook -gu "window-layout-changed[$HOOK_INDEX]" 2>/dev/null || true
  tmux set-hook -gu "window-resized[$HOOK_INDEX]" 2>/dev/null || true
  exit 0
fi

hook "after-select-pane" "event focus '#{window_id}' '#{pane_id}'"
hook "after-split-window" "event topology '#{window_id}'"
hook "after-resize-pane" "event manual '#{window_id}'"
hook "window-layout-changed" "event layout '#{window_id}'"
hook "window-resized" "event resized '#{window_id}'"

RESUME_KEY="$(tmux show-options -gqv @gl-resume-key)"
RESUME_KEY="${RESUME_KEY:-=}"
tmux bind-key "$RESUME_KEY" run-shell -b "$ENV_PREFIX '$GL' resume '#{window_id}'"
