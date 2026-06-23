---
id: dot-i5fq
status: open
deps: [dot-p3kz]
links: []
created: 2026-06-23T20:16:51Z
type: feature
priority: 2
assignee: Seth Messer
parent: dot-a9wd
tags: [ready-for-development]
---

# Implement worktree-aware :PiReview scopes

Implement a Nvim-side `:PiReview` orchestrator that opens the right review surface for the requested scope and stays worktree-aware.

Relevant files:

- config/nvim/lua/pinvim.lua (command registration only)
- config/nvim/lua/pinvim/review.lua (new module for detection and orchestration)
- config/nvim/lua/plugins/codediff.lua (confirm command contracts only; avoid broad refactors)
- lat.md/programs/neovim-pinvim.md

Scopes:

- `uncommitted`: open CodeDiff for current worktree changes.
- `unpushed`: open CodeDiff for `@{u}..HEAD` or a clear fallback when no upstream exists.
- `branch`: open CodeDiff against PR base or default base (`origin/main...HEAD` fallback).
- `pr`: open `:Guh <current PR>` using `gh pr view` when available.
- `ticket`: choose branch/uncommitted scope and attach ticket metadata when derivable.

Preserve strict pinvim pairing. Do not make a new Nvim instance steal an existing Pi socket.

## Acceptance Criteria

1. `:PiReview` exists with completion for `uncommitted`, `unpushed`, `branch`, `pr`, `ticket`, and `worktrees` (worktrees may be stubbed with a clear message if split to a follow-up).
2. `config/nvim/lua/pinvim/review.lua` detects current worktree root, branch, upstream, and PR metadata without blocking the UI longer than necessary.
3. `:PiReview uncommitted` opens CodeDiff for the current worktree.
4. `:PiReview unpushed` opens CodeDiff for upstream-to-HEAD when upstream exists and reports a clear error/fallback when it does not.
5. `:PiReview branch` opens CodeDiff against PR base or default base.
6. `:PiReview pr` opens `:Guh` for the current PR when `gh` can resolve one, otherwise reports how to proceed.
7. Existing pinvim annotations still work: `gpc`, visual `gpc`, `:PiComments`, `:PiFlush`, and `:PiClear` behave as before.
8. `devenv shell -- just home` succeeds.
9. `devenv shell -- nvim --headless '+lua require("pinvim").setup()' +qa` exits 0.
10. `devenv shell -- bin/pinvim-protocol-smoke` passes.
11. lat.md documents the `:PiReview` command and strict-pairing constraint; `lat_check` passes.

## Notes

**2026-06-23T20:50:00Z**

Implemented in `config/nvim/lua/pinvim/review.lua` + `:PiReview` command + `<leader>gr{r,u,b,p,t,w}` keymaps in `config/nvim/lua/pinvim.lua`. Verified headless: completion returns all 6 scopes; worktree root/branch/upstream detection works; `run("uncommitted")` opens CodeDiff and sets `metadata().scope="uncommitted"`; `run("pr")` on `main` returns false with a warning (no PR) and no crash. `just home`, `nvim --headless ... +qa`, `bin/pinvim-protocol-smoke`, and `lat_check` pass.
