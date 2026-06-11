---
id: dot-80iw
status: open
deps: []
links: []
created: 2026-06-11T13:23:04Z
type: feature
priority: 2
assignee: Seth Messer
parent: dot-d5j1
tags: [shade-next, phase-3, ready-for-development]
---

# shade-next: introduce PanelInputHost and native Nvim-backed input

Refactor the panel input boundary so PanelController no longer depends directly on NSTextField. Add a PanelInputHost abstraction with the existing NSTextField-backed host plus a first Nvim-backed host that uses NvimSocketAdapter and a native AppKit text surface for early progress. This is phase 1 for dot-d5j1 and should preserve current Raycast-like compact calc/search behavior while enabling Nvim lifecycle and text semantics behind a feature flag/config switch. Relevant files: ~/code/shade-next/Sources/ShadeNextApp/PanelController.swift, Sources/ShadeNextCore/Editor/EditorAdapter.swift, Sources/ShadeNextCore/Editor/NvimSocketAdapter.swift, Tests/ShadeNextCoreTests/EditorAdapterTests.swift, and likely new ShadeNextApp input host files.

## Acceptance Criteria

1. PanelController reads, writes, focuses, and observes input through a PanelInputHost-style interface instead of direct NSTextField access in routing/commit paths.
2. Existing NSTextField-backed input remains the default and current calc/search/note behavior is unchanged.
3. A Nvim-backed host can start Nvim through NvimSocketAdapter, expose text for routing/commit, support setText/prefill, and clean up its process/socket.
4. Compact launcher keeps Enter=commit/copy; composer or multiline/Nvim-backed mode preserves Enter as editor input and uses cmd+enter (or configured app command) for commit.
5. Tests cover host text round trips, multiline buffer behavior, routing/commit reads through the host boundary, and existing EditorAdapterTests still pass.
6. Verification commands pass: cd ~/code/shade-next && devenv shell -- just test; cd ~/code/shade-next && devenv shell -- swift build.
