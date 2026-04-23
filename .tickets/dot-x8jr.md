---
id: dot-x8jr
status: open
deps: []
links: []
parent: dot-pv7z
created: 2026-04-17T19:08:49Z
type: bug
priority: 2
assignee: Seth Messer
---
# Investigate ftm + tmux session management: custom icons and colors not updating

Session icons and colors configured for tmux sessions aren't updating/changing.
Investigate the full pipeline: ftm session creation, tmux status line rendering,
and whatever mechanism maps sessions to custom icons/colors.

Relevant code:
- bin/ftm — session creation and switching
- config/tmux/ — tmux config, status line, layouts
- SESSION_ICON variable in ftm (currently 󰢩)

Need to understand:
- How session icons/colors are supposed to be set and displayed
- Why changes aren't taking effect
- Whether this is a tmux status-line config issue, ftm issue, or both

## Acceptance Criteria

1. Document how session icons and colors are currently configured
2. Identify why changes aren't reflected in the tmux status line
3. Determine if SESSION_ICON in ftm is actually used anywhere downstream
4. Trace the full path from session creation to status line rendering
5. Write up root cause and proposed fix

