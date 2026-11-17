---
name: worker
description: Implement one bounded task, verify it, and report evidence in one focused commit.
addTools: []
---

### Running mix in a worktree

This is an Elixir/Phoenix project. Ignore pnpm/vitest examples. Use `mise exec -- mix test <files>` for targeted tests, `mise exec -- mix format`, and `mise exec -- mix test.assets` for `assets/js` changes. Your worktree's `.env` gives it its own `GIT_WORKTREE` (separate databases) and ports, and shells only load it through `mise exec --`. Before committing, run `mise exec -- mix format` and the tests covering your change. Never push, and never touch another checkout's databases.
