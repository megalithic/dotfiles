---
id: dot-oiky
status: closed
deps: [dot-f6tr]
links: []
created: 2026-05-13T20:48:05Z
type: feature
priority: 2
assignee: Seth Messer
parent: dot-dylm
tags: [ready-for-development]
---
# Rank pi session discovery by root, tmux, and recency

Implement Step 3 from ~/.local/share/pi/plans/dotfiles/nvim-pi-custom-vision_PLAN.md. Replace exact-cwd-only discovery in `config/nvim/lua/pinvim.lua` with scored manifest candidates. Use root/cwd match, tmux session/window affinity, heartbeat freshness, and non-ephemeral status to rank candidates. Update `:PiSessions` to surface score or reason data so selection is explainable.

## Acceptance Criteria

1. Session discovery ranks candidates using at least cwd/root affinity, tmux identity, recent heartbeat/activity, and non-ephemeral preference.
2. `:PiSessions` shows enough metadata to explain why a candidate ranks where it does.
3. Ephemeral sockets remain explicit-only and are never auto-selected by ranked discovery.
4. Manual smoke test with multiple pi manifests in one repo confirms expected candidate wins.
5. `just home`, `nvim --headless '+lua require("pinvim").setup()' +qa`, and `bin/pinvim-protocol-smoke` pass.

## Verification

For any implementation change under this pinvim/vision workstream, run:

1. `just home`
2. `nvim --headless '+lua require("pinvim").setup()' +qa`
3. `bin/pinvim-protocol-smoke` — deterministic mock Unix-socket test that asserts nvim sends `hello`, receives `hello_ack`, sends `heartbeat`, receives heartbeat response, and `require("pinvim").setup().health()` reports `ok`.

For research-only tickets, run these before closing any downstream implementation ticket that uses the research.


## Notes

**2026-05-18T14:18:10Z**

Implemented ranked pinvim manifest discovery: cwd/root, tmux affinity, heartbeat/activity recency, non-ephemeral preference, explainable PiSessions metadata. Verified just home, nvim headless setup, pinvim protocol smoke, and temp multi-manifest ranking smoke.
