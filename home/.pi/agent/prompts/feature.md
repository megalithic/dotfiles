---
description: Build a feature end to end — scout assessment, plan with binary criteria, your go, workers, /review-range, fix
argument-hint: "<what to build>"
---

Build this feature: $@

You coordinate: you own the understanding, the plan's acceptance, and the final verdict. Delegate reconnaissance, planning and implementation to subagents; never delegate judgment. Empty request → ask what to build, then stop.

## 1. Assess (scouts, in parallel)

Split what you need to know into one to three independent questions (where the code lives, what it already does, what the change touches, how it is tested). Start one `scout` per question in one codemode call (`Promise.allSettled`), then end the turn; answers arrive as messages. Check the citations you rely on.

## 2. Plan (planner)

Start one `planner` with the request, the scouts' findings verbatim, and the repository's AGENTS.md rules that apply. Its plan has binary acceptance criteria, each with the command that proves it, and ordered steps of one commit each. Save it to `~/.local/share/pi/docs/$(basename "$(git rev-parse --show-toplevel)")/<slug>-plan.md`.

Read the plan against the code yourself. Send it back to the planner with concrete objections until you would sign it.

## 3. Seth's go (the only stop)

Show the plan's request, approach, acceptance criteria, steps and decisions, and ask for Seth's go, with his answers to any decisions. End the turn. This is the only time you ask: after the go, run to the end without stopping, unless a decision comes up that changes behaviour or scope. Record `base=$(git rev-parse HEAD)` once he says go.

## 4. Implement (workers, one at a time)

All workers share this checkout, so writing workers run strictly one at a time; scouts and reviewers may run in parallel. Per step, start one `worker` and wait for its report. Its brief states: the goal and why, the exact files it may touch, what you already know, the step's acceptance criteria with their commands, "Do not expand scope. Report problems instead of working around them.", and "one focused commit; never push".

On each report, read the commit's diff and the evidence for each criterion; a worker's DONE is a claim, not proof. Re-run a criterion's command yourself when the evidence is thin. A PARTIAL or BLOCKED step gets a tighter brief or a decision, never silent acceptance.

## 5. Review (/review-range), then fix

When every step is committed, run the `/review-range` flow on `<base>..HEAD` with the plan's acceptance criteria. Verify each blocking finding against the code. Fix the real ones through one worker per fix (still one at a time), then review the new range `<previous head>..HEAD` the same way. Stop when the review comes back APPROVED, or after two rounds, and report what is left.

## 6. Finish

Run the repository's full checks (AGENTS.md, `mise.toml`, `hk.pkl`) and fix what fails. Then report: what was built, each acceptance criterion with its evidence, the review verdict and range, and divergence from the plan (or "None"). Never push or open a PR without Seth's explicit OK.

**provider_portal** (`~/code/work/strive/provider_portal`): the full check is `mise exec -- mix check --no-parallel --no-retry`. After Seth's OK, push the branch as `sm-<short-topic>` (kebab-case and descriptive, never generic like `sm-fix`) with `git push -u origin HEAD:refs/heads/sm-<short-topic>`, and open the PR with `gh pr create --base main --head sm-<short-topic> --body-file <file>`. Follow `~/code/work/strive/AGENTS.md`: a Conventional Commits title; a body that opens with what changed and why, then how it was verified (screenshots inline with `--attach`; for auth changes, the security review's result); no mention of agents, harnesses or plans anywhere in commits, branch, title or body. Show Seth the title and body before creating the PR.
