---
id: dot-1u0w
status: open
deps: []
links: []
created: 2026-06-24T20:32:00Z
type: feature
priority: 2
assignee: Seth Messer
tags: [ready-for-development]
---

# Configure Worktrunk hooks for devenv and mise worktrees

Research and implement Worktrunk configuration for this dotfiles repo so `wt switch` creates and re-enters worktrees with predictable setup, server/session startup, and cleanup.

Research findings to preserve:

- Worktrunk project config lives at `.config/wt.toml`; user config lives at `~/.config/worktrunk/config.toml`.
- `pre-start` and `post-start` run only when a worktree is created.
- `post-switch` runs on every switch result: newly created worktree, existing worktree, or current worktree.
- Use `pre-start` for blocking one-time setup required before work can begin.
- Use `post-start` for background first-start work such as dev servers/watchers.
- Use `post-switch` for idempotent "ensure session/server exists" behavior when switching to an already-created worktree.
- `pre-remove` / `post-remove` should stop worktree services and sessions.
- Project hooks require Worktrunk approval once; changed hook commands or moved project paths require re-approval. `wt config approvals add` pre-approves current project hooks.
- `mise trust` is separate from Worktrunk approval. It is per config file/path; every new worktree path with `mise.toml` or `.mise.toml` needs one-time trust. Existing trusted worktrees do not need repeated trust unless moved/untrusted or trust-relevant config changes.
- Worktrunk docs recommend directory env managers (mise/direnv) activate naturally after `wt switch` cd; Worktrunk deliberately should not bypass trust prompts except via explicit user-owned hook/script.
- `wt step tether` can manage dev server process groups and kill them when the worktree is removed, but `post-start` alone will not restart missing servers when switching back to existing worktrees.

Implementation target:

- Add tracked `.config/wt.toml` for project-level hooks and list URL config.
- Add helper scripts under `scripts/worktrunk/`, likely `bootstrap`, `ensure-services`, `ensure-session`, and `teardown`.
- Keep both environment paths working:
  - current `devenv.nix` / `devenv.yaml` flow
  - `.worktrees/mise-bootstrap-migration` `mise.toml` flow
- `bootstrap` should copy needed generated/ignored core files where applicable, trust mise once when `mise.toml` or `.mise.toml` exists, run `devenv tasks run worktree:setup` when available, and run `mise run worktree:setup` when available.
- `ensure-services` should be idempotent and prefer `mise run worktree:services` when available, otherwise fall back to `devenv tasks run worktree:services` when available.
- `ensure-session` should create or reuse a worktree-specific tmux/session primitive without duplicating existing sessions.
- `teardown` should stop services/sessions and run `mise run worktree:teardown` or `devenv tasks run worktree:teardown` when available.
- Validate against current dotfiles branch and `.worktrees/mise-bootstrap-migration`.

Relevant files/directories:

- `home/common/programs/worktrunk/default.nix` enables Worktrunk shell integration through Home Manager.
- `devenv.nix`, `devenv.yaml`, `devenv.lock` define current devenv behavior.
- `.worktrees/mise-bootstrap-migration/mise.toml` and `mise/projects/*.mise.toml` show proposed mise bootstrap tasks, including `worktree:setup`, `worktree:services`, and `worktree:teardown` examples.
- `home/common/programs/pi-coding-agent/skills/git-worktrees/SKILL.md` has current manual worktree setup conventions that should be translated or superseded by Worktrunk hooks.
- `lat.md/architecture.md` and `lat.md/home-configs.md` document devenv activation and Worktrunk/Home Manager ownership; update them if implementation changes behavior.

## Acceptance Criteria

1. `.config/wt.toml` exists and defines hooks for new-worktree setup, switch-time session/service ensure, and removal cleanup.
2. Hook scripts under `scripts/worktrunk/` are idempotent: repeated `wt switch` to an existing worktree does not duplicate servers or tmux sessions.
3. New worktrees with `mise.toml` or `.mise.toml` are trusted once non-interactively via `mise trust`; existing trusted worktrees do not re-prompt during switch.
4. New worktrees with `devenv.nix` run `worktree:setup` when the devenv task exists, with clear logs/errors when task discovery fails.
5. New or switched-to worktrees with mise tasks run `worktree:services` when available; devenv `worktree:services` remains the fallback.
6. Removal cleanup runs `worktree:teardown` when available and stops any worktree-specific session/server resources.
7. Behavior is verified in both the current dotfiles checkout and `.worktrees/mise-bootstrap-migration`.
8. Worktrunk approvals and mise trust behavior are documented in the ticket implementation notes or `lat.md` as appropriate.
9. Relevant `lat.md` sections are updated for any changed architecture docs and `lat_check` passes if docs changed.
10. Existing validation still passes with the narrowest applicable command, likely `devenv shell -- just validate home` or documented equivalent if implementation is script-only.
