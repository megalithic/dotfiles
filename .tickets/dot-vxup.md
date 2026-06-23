---
id: dot-vxup
status: open
deps: [dot-i5fq]
links: []
created: 2026-06-23T20:16:52Z
type: feature
priority: 2
assignee: Seth Messer
parent: dot-a9wd
tags: [ready-for-development]
---

# Add worktree picker and tmux review launcher

Add worktree review discovery and optional tmux launch support so review/diff workflows are tuned for one-ticket/one-agent worktrees.

Relevant files:

- config/nvim/lua/pinvim/review.lua
- optional new bin/pireview or bin/pinvim-review launcher
- config/tmux/ only if adding keybindings or layout hooks
- lat.md/programs/neovim-pinvim.md

The workflow should list git worktrees with branch, path, dirty/staged/untracked counts, upstream/ahead state when cheap, and any ticket id derivable from branch/path. Selecting a worktree should open the requested review in that worktree without crossing pinvim pair ownership.

## Acceptance Criteria

1. `:PiReview worktrees` lists selectable git worktrees for the current repository using `git worktree list --porcelain`.
2. Each worktree entry shows path, branch or detached ref, and at least dirty/staged/untracked summary or a clear `unknown` fallback.
3. Selecting a worktree opens or instructs a review for that worktree with cwd scoped to that worktree.
4. If a tmux launcher is added, it creates a new window named like `review:<branch-or-ticket>` in the current tmux session and starts Nvim with `+PiReview <scope>` in the selected worktree.
5. The launcher does not pass a stale `PI_SOCKET` or `PINVIM_PAIR_ID` that would steal another Nvim/Pi pair.
6. Missing tmux, missing git worktree data, or non-git repos produce clear messages instead of crashes.
7. `devenv shell -- just home` succeeds.
8. `devenv shell -- nvim --headless '+lua require("pinvim").setup()' +qa` exits 0.
9. Manual verification covers at least two worktrees and confirms reviews open in the selected cwd.
10. lat.md documents the worktree-aware review behavior and isolation rules; `lat_check` passes.
