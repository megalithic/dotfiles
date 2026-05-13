---
id: dot-l8f0
status: open
deps: [dot-t4dd]
links: []
created: 2026-05-13T20:48:05Z
type: feature
priority: 2
assignee: Seth Messer
parent: dot-dylm
tags: [ready-for-development]
---
# Inject editor-aware persona and tool policy into pinvim

Implement Step 9 from ~/.local/share/pi/plans/dotfiles/nvim-pi-custom-vision_PLAN.md. Add editor-aware persona and tool policy mapping in a new extension module such as home/common/programs/pi-coding-agent/extensions/pinvim-policy.ts, wired through home/common/programs/pi-coding-agent/extensions/pinvim.ts and config/nvim/after/plugin/pi.lua. Start with diff/review buffers, markdown notes paths, and Elixir/Phoenix files.

## Acceptance Criteria

1. Pinvim selects distinct policy/persona behavior for diff-review buffers, markdown notes contexts, and Elixir/HEEx/Surface/Phoenix files.
2. Policy selection influences pi-facing instructions or preferred tools without breaking manual user control.
3. A command such as `/pinvim-policy` or equivalent status surface shows the active policy and why it was chosen.
4. `just validate home` passes and manual checks from diff, markdown, and Elixir buffers show the expected policy.

