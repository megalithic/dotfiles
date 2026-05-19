---
id: dot-hdzl
status: closed
deps: []
links: []
created: 2026-05-19T15:30:40Z
type: bug
priority: 2
assignee: Seth Messer
tags: [ready-for-development]
---
# Replace tmux yank multi-key bindings with key table

Implement the tmux-multi-key-keymaps plan. In config/tmux/tmux.conf, replace invalid literal copy-mode-vi multi-key bindings (yy, yl, yL, yV) with a transient copy-yank key table using switch-client -T. Keep the bindings in the existing post-TPM override block after plugins are sourced so they override tmux-yank and tmux-copycat. See ~/.local/share/pi/plans/.dotfiles/tmux-multi-key-keymaps_PLAN.md and .ticket-context.md.

## Acceptance Criteria

1. config/tmux/tmux.conf binds copy-mode-vi y to switch-client -T copy-yank.
2. copy-yank table defines y, l, L, and V actions matching the current intended yy, yl, yL, and yV behavior.
3. No literal copy-mode-vi bindings remain for yy, yl, yL, or yV.
4. Verification command succeeds: tmux -L tmux-conf-test -f /dev/null start-server \; source-file /Users/seth/.dotfiles/config/tmux/tmux.conf \; list-keys -T copy-mode-vi y \; list-keys -T copy-yank \; kill-server.
5. Confirm command finds switch-client -T copy-yank in copy-mode-vi and lists copy-yank bindings.

