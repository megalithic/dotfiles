---
id: dot-0fve
status: open
deps: []
links: []
created: 2026-04-17T19:07:22Z
type: task
priority: 2
assignee: Seth Messer
---
# Investigate Hammerspoon window management with hyperkey/hypermodal

Re-open investigation into window movement and control via Hammerspoon using
the existing hyperkey and hypermodal setups. Scope includes:

- Window placement: move/resize windows with hyper-key combos (halves, thirds, quarters, maximize)
- Browser tab manipulation: switch/move/close tabs via Hammerspoon
- Auto window placement: rules based on app name, window title, display, or other conditions
  (e.g., Slack always on display 2, terminals tiled left, etc.)
- Integration with existing hypermodal system for discoverable multi-step bindings

Relevant code in config/hammerspoon/. Look at existing hyperkey.lua, hypermodal.lua,
and any window management Spoons already configured.
Consider hs.window, hs.window.filter, hs.layout, hs.grid, hs.screen.

## Acceptance Criteria

1. Audit existing window management code in config/hammerspoon/
2. Document what hyper-key bindings are available vs already used
3. Prototype basic window placement bindings (halves, maximize, move to display)
4. Research browser tab control APIs (accessibility, AppleScript, CDP)
5. Document auto-placement rule approach (hs.window.filter + hs.layout or custom)
6. Write up findings and proposed keybinding scheme

