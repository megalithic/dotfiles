---
id: dot-qsa8
status: closed
deps: [dot-slr0]
links: []
created: 2026-05-19T16:12:17Z
type: feature
priority: 2
assignee: Seth Messer
parent: dot-dylm
tags: [ready-for-development]
---
# pinvim review: jj/git current-change diff source

Plan step 2. Add VCS helpers for default `scope=commit` (current working change) with jj preferred when a `.jj` workspace is present and git fallback when only a git worktree is present. Populate the `nui.tree` from changed-file names and load read-only per-file diffs into the diff buffer when a file is selected.

VCS behavior:

- Detect repo type from Neovim/Lua without assuming `jj` exists: prefer `.jj`/`jj root` when available; otherwise use git when `.git`/`git rev-parse --show-toplevel` succeeds; otherwise show a clear “no supported VCS” review message.
- jj commands for commit scope: `jj diff -r @ --name-only` and `jj diff -r @ --git -- <file>`.
- git commands for commit scope: `git diff --name-only --no-ext-diff --` for the working tree file list, and `git diff --no-ext-diff -- <file>` for a per-file patch. Include staged changes too: merge `git diff --cached --name-only --no-ext-diff --` into the file list, and when selecting a file show both staged (`git diff --cached --no-ext-diff -- <file>`) and unstaged (`git diff --no-ext-diff -- <file>`) sections if both exist.
- Use repo-root-relative paths in the tree and pass file paths after `--` to protect pathspecs.
- Keep helpers inline in `config/nvim/lua/pinvim/review.lua` for now (single-file dev mode); splitting into `config/nvim/lua/pinvim/review/vcs.lua` is deferred.

Research notes:

- `jj diff` defaults to `-r @`; docs support `--name-only`, `--git`, and path/file set restriction.
- `git diff` docs support `--name-only`, `--no-ext-diff`, path restriction after `--`, and `--cached` for staged changes. `git rev-parse --show-toplevel` detects the worktree root.

## Acceptance Criteria

1. Commit-scope VCS helpers are implemented inline in `config/nvim/lua/pinvim/review.lua` (single-file dev mode), with jj preferred and git fallback.
2. Opening review (`gds`/`:PiReview`) in a jj repo populates the file tree from `jj diff -r @ --name-only`.
3. Opening review (`gds`/`:PiReview`) in a git-only repo populates the file tree from git working-tree and staged changes using `git diff --name-only --no-ext-diff --` plus `git diff --cached --name-only --no-ext-diff --`.
4. Pressing `<CR>` on a tree entry loads a read-only diff buffer rendered from `jj diff -r @ --git -- <file>` in jj repos.
5. Pressing `<CR>` on a tree entry in a git-only repo loads a read-only diff buffer with staged and/or unstaged patch sections from `git diff --cached --no-ext-diff -- <file>` and `git diff --no-ext-diff -- <file>`.
6. If neither jj nor git is available for the current root, review mode opens with a clear no-supported-VCS message instead of failing.
7. Tree-local maps for refresh, next file, previous file, select, close, and `g?` help are registered with `desc`.
8. `stylua --check config/nvim/lua/pinvim/review.lua` passes.
9. `nvim --headless '+lua require("pinvim").setup()' '+qa'` exits 0.
10. `bin/pinvim-protocol-smoke` passes.

## Notes

**2026-05-19T18:42:59Z**

Expanded scope after research: review diff source must support jj-first and git-only repositories. jj uses jj diff --name-only/--git. git fallback uses rev-parse --show-toplevel for detection, git diff --name-only --no-ext-diff for unstaged files, git diff --cached --name-only --no-ext-diff for staged files, and per-file git diff sections after -- pathspec separator.

**2026-05-19T18:53:59Z**

Implemented inline jj/git review diff source in config/nvim/lua/pinvim/review.lua. Review now detects jj first and git fallback, renders changed files in nui.tree, loads read-only per-file diffs, handles no-supported-VCS, and registers tree maps with descriptions. Verified stylua, headless pinvim setup, protocol smoke, and headless jj/git/no-VCS map checks.
