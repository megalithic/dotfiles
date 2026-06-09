---
id: dot-mv1h
status: open
deps: 4:1:deps: [, dot-r80v]
links: []
created: 2026-06-09T15:10:55Z
type: task
priority: 2
assignee: Seth Messer
tags: [ready-for-development, shade-next]
---

# Implement note fallback commit flow and Obsidian template path

In ~/code/shade-next, implement committed-note fallback that writes captures into Obsidian flow using separate shade-next templates. Preserve current Shade behavior. File hints: new note/capture adapters in ~/code/shade-next plus reference behavior in ~/.dotfiles/config/nvim/after/plugin/notes.lua and ~/.dotfiles/home/common/programs/shade/default.nix. Ensure daily-note linking still targets ## Captures semantics.

## Acceptance Criteria

1. Committed fallback note writes to captures flow using separate shade-next template path.
2. Daily note receives capture link under ## Captures, matching current notes integration behavior.
3. Uncommitted drafts remain out of Obsidian markdown files.
4. Current shade templates and current shade config remain untouched.
5. Verification includes file-path evidence or automated/manual notes showing capture creation and daily-note linking.
