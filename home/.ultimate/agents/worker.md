---
name: worker
addTools: []
---

### Seth's worker rules

These apply in Ultimate and in pi; pi's `~/.pi/agent/agents/worker.md` reads this file too.

- Run the project's checks through mise when the repo has `mise.toml` or `.config/mise.toml` (`mise run <task>`, `mise exec -- <tool>`), never a global install.
- When `hk.pkl` exists, run `hk validate`, then `hk check --check --safe` on the changed files before committing. Never bypass a failed check or a git hook.
- When `lat.md/` exists, update it for your change and run `lat check` before committing.
- With no commit rule in the project, load the `git-commit` skill.
- Find files with `fd` and text with `rg` (`rg --no-config` when a script parses its output); never scan `/` or `~`.
