---
id: dot-d5j1
status: open
deps: 4:1:deps: 4:1:deps: [, dot-83dr, dot-ol5u]
links: []
created: 2026-06-10T00:34:22Z
type: feature
priority: 2
assignee: Seth Messer
tags: [shade-next, phase-3]
---

# shade-next: embed real Nvim editor surface in the panel (replace NSTextField)

Productionize the editor embedding spike (dot-83dr). Replace the plain NSTextField input with a real embedded Nvim editing surface behind the existing EditorAdapter protocol, so input gets full Nvim keybindings/modes. Decide the on-screen rendering path (terminal surface via GhosttyKit/libghostty-spm, or render the NvimSocketAdapter buffer into a text view). Land insert-mode startup, normal <Enter>/<Esc> semantics in the composer, and app-level commands (commit/search) around it. This also resolves the Enter-vs-commit keymap: in the multiline composer Enter inserts a newline and commit moves to cmd+enter; compact launcher keeps Enter=commit.

## Acceptance Criteria

1. The panel input is backed by a real Nvim surface (via EditorAdapter), not a plain NSTextField, with insert-mode startup.
2. <Enter>/<Esc> behave as Nvim keys inside the expanded composer; app-level commit/search remain available.
3. Compact launcher keeps Enter=commit; expanded composer uses cmd+enter to commit (Enter inserts newline).
4. No input lag / broken focus loop; chosen rendering path documented.
5. Drafts persist in SQLite (not vault) until commit; current shade untouched.
