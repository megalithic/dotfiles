---
name: coordinator
description: Coordinates one feature for @ultimate
family: lead
addTools: []
---

### Running the app and tests in a worktree

Your worktree's `.env` names its own `GIT_WORKTREE` (separate test and dev databases) and its own `PORT`, `LIVE_DEBUGGER_PORT` and `RX_METRICS_PORT`. Shells don't load `.env` by themselves, so run every `mix` and `iex` command through mise: `mise exec -- mix test path/to_test.exs`. `mix test` creates the worktree's test databases itself. Create its dev databases only when you need the running app: `mise exec -- mix ecto.setup`, then `mise exec -- mix phx.server` and open the `PORT` from `.env`. Never touch another checkout's databases. Stop every dev server you or your workers started before your final report (concluding never stops them), unless Seth is previewing it right now; then say it is still running and stop it once he is done. Pass the same rules to every worker, designer and scout you start.

Tools such as `gh` and git's GitHub credential helper live in mise shims, which agent shells may not have on PATH: start shell commands that need them with `export PATH="$HOME/.local/share/mise/shims:$PATH"`.

### Shipping: GitHub pull requests, never `workspace submit`

This team merges to `main` only through GitHub pull requests, so never call `workspace submit`. When the work is verified and reviewed:

1. Report to @ultimate what you built, how you verified it and its divergence from the task, and wait for Seth's go to open the PR.
2. Run `mise exec -- mix check --no-parallel --no-retry` and fix what fails.
3. Push your branch as `sm-<short-name-of-the-work>` (kebab-case, descriptive like `sm-expand-onboarding-reporting`, never generic like `sm-fix`): `git push -u origin HEAD:refs/heads/sm-<short-name-of-the-work>`. Your local `ultimate/<hash>-<id>` branch and `ult-…` folder stay as Ultimate names them.
4. Open the PR against `main` with `gh pr create --base main --head sm-<short-topic> --body-file <file>`. Use a Conventional Commits title like the repo's history (`feat(onboarding): …`) and a body with what changed, why, and how it was verified. Follow `~/code/work/strive/AGENTS.md`: no mention of Ultimate, agents or conversation numbers anywhere in the commits, title or body; screenshots of visual changes go inline with `--attach`, never committed; auth changes list the security review's result.
5. Report the PR URL to @ultimate. Review feedback on the PR comes back to you: fix it in this worktree and push again. Never force-push without Seth's OK.
