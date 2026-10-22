#!/usr/bin/env bash
# tmux-golden-layout entrypoint (TPM-compatible).
#
# Requires tmux 3.8 (JSON layouts, #{hook} and #{hook_window}). Registers
# indexed hooks (slot 188) for focus, layout, and unzoom events and binds the
# resume key. Safe to re-source: indexed set-hook slots and bind-key are
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
HOOKS="window-pane-changed window-layout-changed window-unzoomed"
# Registered by pre-3.8 versions of this plugin; removed on every load.
OLD_HOOKS="after-select-pane after-split-window after-resize-pane window-resized"
BOUND_RESUME_KEY="$(tmux show-options -gqv @gl-bound-resume-key)"

unregister() {
  for h in $HOOKS $OLD_HOOKS; do
    tmux set-hook -gu "${h}[$HOOK_INDEX]" 2>/dev/null || true
  done
  if [ -n "$BOUND_RESUME_KEY" ]; then
    tmux unbind-key "$BOUND_RESUME_KEY" 2>/dev/null || true
  fi
  tmux set-option -gu @gl-bound-resume-key 2>/dev/null || true
  tmux set-option -gu @gl-bun 2>/dev/null || true
}

if [ "$(tmux show-options -gqv @gl-enabled)" = "off" ]; then
  # Disabling must work even when bun has disappeared since the last load.
  unregister
  exit 0
fi

# Resolve bun once at load; hooks reuse it through TMUX_GL_BUN.
BUN="$(command -v bun 2>/dev/null || true)"
if [ -z "$BUN" ] && command -v mise >/dev/null 2>&1; then
  BUN="$(mise which bun 2>/dev/null || true)"
fi
if [ -z "$BUN" ]; then
  unregister
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

for h in $OLD_HOOKS; do
  tmux set-hook -gu "${h}[$HOOK_INDEX]" 2>/dev/null || true
done
# window-pane-changed: any focus change (keys, mouse, last-pane, kill, split).
# window-layout-changed: splits, kills, outer resizes, manual resizes, and
# other tools' select-layout. window-unzoomed: settle after a zoom.
for h in $HOOKS; do
  tmux set-hook -g "${h}[$HOOK_INDEX]" "run-shell -b \"$ENV_PREFIX '$GL' event '#{hook}' '#{hook_window}'\""
done

RESUME_KEY="$(tmux show-options -gqv @gl-resume-key)"
RESUME_KEY="${RESUME_KEY:-=}"
if [ -n "$BOUND_RESUME_KEY" ] && [ "$BOUND_RESUME_KEY" != "$RESUME_KEY" ]; then
  tmux unbind-key "$BOUND_RESUME_KEY" 2>/dev/null || true
fi
tmux bind-key "$RESUME_KEY" run-shell -b "$ENV_PREFIX '$GL' resume '#{window_id}'"
tmux set-option -g @gl-bound-resume-key "$RESUME_KEY"
