---
id: dot-ayje
status: open
deps: 4:1:deps: [, dot-80iw]
links: []
created: 2026-06-11T13:23:04Z
type: feature
priority: 3
assignee: Seth Messer
parent: dot-d5j1
tags: [shade-next, phase-3, ready-for-development]
---

# shade-next: spike libghostty or GhosttyKit renderer for Nvim input host

Evaluate and, if viable, add a second PanelInputHost renderer that embeds a real terminal surface for Nvim using libghostty-spm, GhosttyKit, or the least-risk Ghostty-compatible path. This is phase 2 for dot-d5j1 and depends on the PanelInputHost boundary from phase 1, so the panel can switch renderers without rewriting routing, sizing, or commit behavior. Relevant files: ~/code/shade-next Package.swift/devenv.nix if dependencies are needed, Sources/ShadeNextApp input host/view files, Sources/ShadeNextCore/Editor/EditorAdapter.swift, Sources/ShadeNextCore/Editor/NvimSocketAdapter.swift, and docs/comments explaining the renderer decision.

## Acceptance Criteria

1. A short renderer decision note is added in code or docs comparing libghostty-spm, GhosttyKit, and the native Nvim-backed host fallback for packaging, focus, lifecycle, and API stability.
2. If a terminal renderer is viable in one session, it is implemented behind the same PanelInputHost interface without changing PanelController routing/commit logic; if not viable, the ticket records the blocker and leaves the native host as the selected production path.
3. Focus, startup, and teardown are manually verified: Hyper+Enter opens the panel, editor receives input, Nvim starts in insert mode, and closing/reopening does not leak processes.
4. Key behavior is verified: Esc/Enter go to Nvim in composer mode, while app-level commit/search/copy remain reachable.
5. Packaging changes, if any, are Nix/devenv-compatible and do not break the existing shade-next app bundle.
6. Verification commands pass: cd ~/code/shade-next && devenv shell -- just test; cd ~/code/shade-next && devenv shell -- swift build.
