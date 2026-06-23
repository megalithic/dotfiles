---
id: dot-jl46
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

# Include review metadata in pinvim annotation flushes

Attach review scope metadata to existing pinvim annotations so flushed comments tell Pi which worktree/diff/ticket they belong to.

Relevant files:

- config/nvim/lua/pinvim.lua (compose queue / `:PiFlush` formatting)
- config/nvim/lua/pinvim/review.lua (active review state metadata)
- home/common/programs/pi-coding-agent/extensions/pinvim.ts only if Pi-side rendering needs to recognize review metadata
- lat.md/programs/neovim-pinvim.md

Current annotation primitives already exist: `gpc`, visual `gpc`, `:PiComment`, `:PiComments`, `:PiFlush`, and `:PiClear`. This ticket should not replace them; it should enrich their output when a `:PiReview` session is active.

## Acceptance Criteria

1. `pinvim.review` exposes active review metadata: scope, worktree path, branch, upstream/base, PR number/url when known, and ticket id/title when known.
2. `:PiFlush` includes a concise `Review scope` header when active review metadata exists.
3. `gpc`, visual `gpc`, `:PiComment`, `:PiComments`, and `:PiClear` still work outside review mode with unchanged behavior except for harmless metadata absence.
4. Ticket metadata is derived from branch naming and/or `tk` only when cheap and available; failure to detect a ticket does not block review.
5. The flushed prompt clearly separates review metadata, code context, and human comments.
6. `devenv shell -- just home` succeeds.
7. `devenv shell -- nvim --headless '+lua require("pinvim").setup()' +qa` exits 0.
8. `devenv shell -- bin/pinvim-protocol-smoke` passes.
9. Manual verification: open `:PiReview uncommitted`, add normal and visual `gpc` comments, run `:PiFlush`, and confirm Pi receives review metadata plus comments.
10. lat.md documents enriched review flush semantics; `lat_check` passes.

## Notes

**2026-06-23T20:50:00Z**

Implemented in `config/nvim/lua/pinvim.lua` (`review_scope_header` added to `compose_flush`) reading `require("pinvim.review").metadata()`. Verified headless: `run("uncommitted")` populates `metadata()` with scope/worktree/branch/upstream/base/ticket; the flush path calls `review_scope_header()` before queued context (confirmed by grep at `pinvim.lua:3088`). Outside review mode `metadata()` is nil so `gpc`/`:PiComment`/`:PiComments`/`:PiClear` behave unchanged. `just home`, `nvim --headless ... +qa`, `bin/pinvim-protocol-smoke`, and `lat_check` pass. Criterion 9 (live `:PiFlush` to a running Pi) requires a connected Pi socket and is a human gate.
