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

1. Pi exposes `/review [scope]` with supported scopes `uncommitted`, `unpushed`, `branch`, `pr`, `ticket`, and `worktrees`.
2. Nvim editor service supports a `review.open` RPC method that delegates to `require("pinvim.review").run(scope, opts)`.
3. `/review` calls the active paired editor service when connected and reports a clear fallback when no editor service is connected.
4. `/review pr` routes to the Nvim PR review flow; local scopes route to CodeDiff through `:PiReview`.
5. The command never broad-scans manifests or steals another Nvim pair.
6. `devenv shell -- just home` succeeds.
7. `devenv shell -- nvim --headless '+lua require("pinvim").setup()' +qa` exits 0.
8. `devenv shell -- bin/pinvim-protocol-smoke` passes.
9. Manual verification: from Pi, `/review uncommitted` opens the paired Nvim review surface; `/review pr` reports a clear message or opens Guh based on PR availability.
10. lat.md documents `/review` and editor-service `review.open`; `lat_check` passes.
