---
id: dot-xwa4
status: closed
deps: 4:1:deps: [, dot-6fon]
links: []
created: 2026-06-09T15:10:56Z
type: task
priority: 2
assignee: Seth Messer
tags: [ready-for-development, shade-next]
---

# Add Hammerspoon bindAppChord helper and default shade-next bindings

In ~/.dotfiles, add Hammerspoon binding support so Hyper chords translate into app-native chords for shade-next. File hints: config/hammerspoon/hyper.lua for bindAppChord, config/hammerspoon/bindings.lua for default bindings, and config/hammerspoon/lib/interop/shade.lua as current architectural reference. Keep Hammerspoon responsible for hotkeys and app launch/focus, not business logic.

## Acceptance Criteria

1. Hammerspoon exposes bindAppChord(mods, key, app, targetMods, targetKey) or equivalent helper.
2. Default binding path supports hyper+enter opening or toggling shade-next launcher presentation.
3. Hyper translation sends clean app-native chords instead of raw Hyper chord handling inside shade-next.
4. timeout 600 just validate home passes after dotfiles changes.
5. Existing current-shade workflow remains available until migration is explicitly changed.
