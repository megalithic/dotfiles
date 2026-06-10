---
id: dot-7ioi
status: open
deps: []
links: []
created: 2026-06-10T16:42:30Z
type: feature
priority: 2
assignee: Seth Messer
tags: [shade-next, phase-3, ready-for-development]
---

# Define shade-next panel workflow and native UI states

Add a prerequisite before dot-d5j1 that settles the shade-next panel's core user workflow and native UI state model before replacing the text field with an embedded Nvim surface. Focus on interaction shape, mode transitions, chrome, routing, and draft lifecycle rather than editor implementation. Relevant files: home/common/programs/shade-next/default.nix for configurable UI/key defaults, config/hammerspoon/shade_next.lua for launch/prefill chords, and the shade-next app repo at ~/code/shade-next for SwiftUI/AppKit panel implementation.

## Acceptance Criteria

1. Document compact launcher, expanded composer, search/results, and route-prefill states, including transitions and default key behavior.
2. Implement or ticket any missing native UI/workflow primitives needed before Nvim embedding: panel chrome, focus behavior, route indicator, commit/search affordances, and draft persistence boundary.
3. Verify compact launcher keeps Enter=commit while expanded composer reserves cmd+enter for commit in the design, without requiring Nvim embedding yet.
4. Confirm current shade workflow and existing shade-next Hammerspoon bindings remain untouched unless explicitly covered.
5. Run the narrowest available shade-next validation or document why validation must wait for the app repo/build context.
