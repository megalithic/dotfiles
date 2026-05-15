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

Implement Step 6 from ~/.local/share/pi/plans/dotfiles/nvim-pi-custom-vision_PLAN.md. Define one structured context schema across `config/nvim/lua/pinvim.lua` and `home/common/programs/pi-coding-agent/extensions/pinvim.ts` for fresh explicit sends. Primary UX: select code or use cursor/word context, trigger a new keybinding such as `gps` if available, send structured context to the handshaked `pinvim.ts`, then focus the linked pi pane so the user can type additional prompt text. Live context can remain as secondary/background state, but explicit sends are the main user-facing workflow. Do not restore legacy `mega.p.pi` or legacy keymaps. If `bridge.ts` needs awareness for shimmed or transitional ingress, keep that involvement thin and compatibility-focused only.

## Acceptance Criteria

1. A structured context envelope exists for explicit visual-selection and cursor/word sends, with room for live/background and future batch modes.
2. Fresh user command(s) and a non-legacy keymap path send the envelope to the handshaked pi instance and focus the linked pi pane.
3. `pinvim.lua` and `pinvim.ts` can inspect peer metadata, editor state, selection/cursor context, and typed attachments from the new payload.
4. Any `bridge.ts` handling is limited to thin shim/compatibility forwarding, not semantic ownership of envelope meaning.
5. `just home`, `nvim --headless '+lua require("pinvim").setup()' +qa`, and `bin/pinvim-protocol-smoke` pass; manual send confirms pi receives structured context instead of ad-hoc text only.

## Verification

For any implementation change under this pinvim/vision workstream, run:

1. `just home`
2. `nvim --headless '+lua require("pinvim").setup()' +qa`
3. `bin/pinvim-protocol-smoke` — deterministic mock Unix-socket test that asserts nvim sends `hello`, receives `hello_ack`, sends `heartbeat`, receives heartbeat response, and `require("pinvim").setup().health()` reports `ok`.

For research-only tickets, run these before closing any downstream implementation ticket that uses the research.

