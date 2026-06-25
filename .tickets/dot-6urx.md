---
id: dot-6urx
status: closed
deps: [dot-5095]
links: []
created: 2026-06-25T20:12:53Z
type: task
priority: 2
assignee: Seth Messer
tags: [ready-for-development]
---

# Validate smart Worktrunk wrapper end to end

Run final build, activation, docs, and runtime checks for the smart Worktrunk wrapper. This ticket should verify Home Manager builds/applies, lat docs pass, normal Worktrunk behavior still works, and tmux target flows work inside and outside tmux where practical.

File hints: `justfile`, `home/common/programs/worktrunk/default.nix`, `home/common/programs/fish/functions.nix`, `home/common/programs/fish/completions.nix`, `bin/wt-tmux-target`, `bin/wt-tail-logs`, `lat.md/home-configs.md`.

## Verification notes (2026-06-25)

- `just validate home` passes (builds config.fish + wt.fish + home-manager-files).
- `just home` activates cleanly (run outside the devenv shell because devenv overrides `$HOME`).
- `lat check` → All checks passed.
- Fresh fish: `wt switch @` (cd to worktree), `wt @` (implicit switch), `wt list`, `wt config show`, `wt hook show` all work; `wt --help`/`wt -V`/`wt --version` pass through (not switched). Fixed a `contains` arg-order bug that made `--version` become `switch --version`.
- Tmux (tested via a real detached host session + send-keys): `wt -t session @`, `wt switch -t session @`, `wt @ -t session` all create session `main` with `code`+`services` windows rooted at the worktree, idempotent on re-run, current shell cwd preserved. `wt -t window @` creates/reuses one current-session window rooted at the worktree. `services` window runs `wt-tail-logs` (pane shows "watching post-start/post-switch hook logs…").
- Completions: `wt switch <TAB>` and `wt <TAB>` offer worktree branches; `wt -t <TAB>` offers window/session; subcommands remain listed.
- NOT headless-tested (attach blocks without a tty): outside-tmux `wt -t window @` fallback to session behavior. Code path verified by inspection (`do_window` delegates to `do_session` when `$TMUX` unset). Manual check later: from a non-tmux shell run `wt switch -t window @` and confirm it attaches/creates the worktree session.

## Acceptance Criteria

1. `devenv shell -- just validate home` passes.
2. `devenv shell -- just home` completes successfully after Home Manager changes.
3. `lat check` passes.
4. Fresh fish shell verifies `wt switch @`, `wt @`, `wt list`, `wt config show`, and `wt hook show`.
5. Tmux checks verify `wt switch -t session @`, `wt -t session @`, inside-tmux `wt switch -t window @` reuse, and outside-tmux window-to-session fallback, or document any manual checks that cannot be automated.
