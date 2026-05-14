---
id: dot-vnmm
status: open
deps: [dot-8n53]
links: []
created: 2026-05-13T20:48:05Z
type: feature
priority: 2
assignee: Seth Messer
parent: dot-dylm
tags: [ready-for-development]
---
# Send structured editor context envelopes to pi

Implement Step 6 from ~/.local/share/pi/plans/dotfiles/nvim-pi-custom-vision_PLAN.md. Define one structured context schema across `config/nvim/lua/pinvim.lua` and `home/common/programs/pi-coding-agent/extensions/pinvim.ts`. The schema should represent live, explicit, and compose sends with peer metadata, editor state, and typed attachments while keeping legacy commands as wrappers. If `bridge.ts` needs awareness for shimmed or transitional ingress, keep that involvement thin and compatibility-focused only.

## Acceptance Criteria

1. A single structured context envelope exists for `live`, `explicit`, and `compose` send modes.
2. Existing selection/cursor/file commands continue to work by translating into the new envelope format.
3. `pinvim.lua` and `pinvim.ts` can inspect peer metadata, editor state, and typed attachments from the new payload.
4. Any `bridge.ts` handling is limited to thin shim/compatibility forwarding, not semantic ownership of envelope meaning.
5. `just validate home` passes and a manual send confirms pi receives the structured context instead of ad-hoc text only.
