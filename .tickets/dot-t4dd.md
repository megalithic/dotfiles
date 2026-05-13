---
id: dot-t4dd
status: open
deps: [dot-fpev]
links: []
created: 2026-05-13T20:48:05Z
type: feature
priority: 2
assignee: Seth Messer
parent: dot-dylm
tags: [ready-for-development]
---
# Receive review bundles in pi bridge and pinvim UX

Implement Step 8 from ~/.local/share/pi/plans/dotfiles/nvim-pi-custom-vision_PLAN.md. Teach home/common/programs/pi-coding-agent/extensions/bridge.ts and home/common/programs/pi-coding-agent/extensions/pinvim.ts to accept `review_bundle` payloads, format them for pi, retain latest bundle state, and expose a command or status hint for the active review context.

## Acceptance Criteria

1. Bridge accepts `review_bundle` payloads without breaking existing message types.
2. Pinvim formats review bundles into pi-facing context that includes diff summary, annotations, and requested action.
3. Latest review bundle state is stored per pi process and exposed through a command or status hint such as `/pinvim-review`.
4. `just validate home` passes and a bundle sent from nvim is visible inside pi with the expected metadata.

