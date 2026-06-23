---
id: dot-xooa
status: open
deps: [dot-i5fq]
links: []
created: 2026-06-23T20:16:53Z
type: feature
priority: 2
assignee: Seth Messer
parent: dot-a9wd
tags: [ready-for-development]
---

# Expose Pi /review through the paired Nvim editor service

Add Pi-side `/review` command support that asks the paired Neovim editor service to open `:PiReview` for a requested scope.

Relevant files:

- home/common/programs/pi-coding-agent/extensions/review.ts or an extension to pinvim.ts if that is the existing pattern
- config/nvim/lua/pinvim.lua (editor_rpc method registration)
- config/nvim/lua/pinvim/review.lua
- lat.md/programs/pi-coding-agent.md
- lat.md/programs/neovim-pinvim.md

The first implementation should preserve pairing: Pi sends `review.open` to its active paired Nvim editor service; it must not discover or control unrelated Nvim instances.

## Acceptance Criteria

1. Pi exposes `/piview [scope]` with supported scopes `uncommitted`, `unpushed`, `branch`, `pr`, `ticket`, and `worktrees`.
2. Nvim editor service supports a `review.open` RPC method that delegates to `require("pinvim.review").run(scope, opts)`.
3. `/piview` calls the active paired editor service when connected and reports a clear fallback when no editor service is connected.
4. `/piview pr` routes to the Nvim PR review flow; local scopes route to CodeDiff through `:PiReview`.
5. The command never broad-scans manifests or steals another Nvim pair.
6. `devenv shell -- just home` succeeds.
7. `devenv shell -- nvim --headless '+lua require("pinvim").setup()' +qa` exits 0.
8. `devenv shell -- bin/pinvim-protocol-smoke` passes.
9. Manual verification: from Pi, `/piview uncommitted` opens the paired Nvim review surface; `/piview pr` reports a clear message or opens Guh based on PR availability.
10. lat.md documents `/piview` and editor-service `review.open`; `lat_check` passes.

## Notes

**2026-06-23T20:50:00Z**

Naming change: the Pi command is `/piview`, not `/review`. `extensions/review.ts` already owns `/review` as the active pi-review-loop (agent-driven checkout/snapshot reviews, see open ticket dot-am3n). To avoid clobbering it, the Nvim-routing command was registered as `/piview` in the new `extensions/nvim-review.ts`. Documented in lat.md.

Implemented: `extensions/nvim-review.ts` queries `globalThis.pinvimEditorService.query("review.open", {scope})`; `EditorMethod` in `extensions/pinvim.ts` extended with `review.open`; Nvim handler in `config/nvim/lua/pinvim.lua` delegates to `require("pinvim.review").run`.

Verified headless: extension loads in pi with no startup errors; `api.editor_rpc("review.open", {scope="uncommitted"})` returns `{ok=true, ran=true, metadata.scope="uncommitted"}`. `just home`, `nvim --headless ... +qa`, `bin/pinvim-protocol-smoke`, and `lat_check` all pass.

Remaining human gate: criterion 9 requires a live paired Pi↔Nvim tmux session to confirm `/piview uncommitted` opens the Nvim review surface and `/piview pr` reports/opens Guh.
