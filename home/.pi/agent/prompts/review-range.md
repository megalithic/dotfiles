---
description: Light review of a commit range — reviewer-correctness, reviewer-security and the project's reviewer-* in parallel, findings merged
argument-hint: "<base>..<head> | <worktree-path> | <branch> [criteria…]"
---

Review the range, worktree or branch `$1` with the light reviewer team, read-only. Acceptance criteria or focus from the caller: `${@:2}` (empty means none). For a pull request use `/code-review` instead.

## 1. Pin the range (one bash call)

- Empty `$1` → ask for a range, worktree path or branch, then stop.
- If `$1` contains `..`, resolve both ends to full SHAs: `git rev-parse --verify <base>^{commit}` and `git rev-parse --verify <head>^{commit}`, one call each. Otherwise run `review-snapshot "$1"` in one bash call; take `base`/`head` from its JSON. Either route fails → say which and stop. Never substitute another range.
- For `dirty: true`, record `worktree` and the snapshot time from `git show -s --format=%B <head>`; label the head as a snapshot of `<worktree>` in the status and report header. Include this instruction in every reviewer/arbiter task: "The head <sha> is a snapshot commit of <worktree> taken at <time>; the worktree keeps changing, so read files at the head with `git show <head>:<path>` / `git grep <pattern> <head>`, never from the working tree."
- `git log --oneline <base>..<head>` empty → say there is nothing to review and stop. Run reviewers and arbiter with cwd = `git rev-parse --show-toplevel`.

## 2. Start the reviewers, then end the turn

The team is `reviewer-correctness`, `reviewer-security`, and every other `reviewer-*` agent the project defines in `.pi/agents/` of the current working directory (`ls .pi/agents/reviewer-*.md`; pi loads project agents only from there, so from a worktree without `.pi/agents/` only the two global reviewers run: say so in the report). One codemode call: `Promise.allSettled` one `subagent` call per reviewer, with the same task and cwd = the repo (the snapshot's objects are shared by all worktrees):

```
Review the immutable range <base-sha>..<head-sha> in <cwd>.
Commits:
<git log --oneline output>
Acceptance criteria: <from the caller, or "none given: review for correctness and regressions">
```

Never give one reviewer's report to the other. Then end the turn with a one-line status. Do not poll, sleep, or read session files: results arrive as messages.

## 3. Merge, when both have answered

A reviewer that failed or ended without a report is `missing`; say so, never fill its part yourself. Report each issue once, naming every reviewer that raised it. Add none and drop none; where they disagree, show both positions. The verdict is APPROVED only when every blocking reviewer approved (a reviewer that describes itself as advisory never blocks).

```text
Verdict: APPROVED | NEEDS CHANGES
Reviewed range: <base>..<head> — <if dirty: snapshot of worktree at time>
Reviewers:
- reviewer-<name> — APPROVED | NEEDS CHANGES | missing (one line each)
Blocking:
- [P0|P1|P2] Title — path:line; impact, evidence, suggested fix. (reviewer-…)
- None
Non-blocking:
- [P2|P3] Title — path:line; impact, suggested fix. (reviewer-…)
- None
Disagreements:
- None | the finding and each reviewer's position.
Residual risks:
- None | the reviewers' residual risks, merged.
```

## 4. Arbiter, only on a blocking disagreement

When one reviewer marks a finding blocking and another reviewer's report explicitly contradicts it (says the code is correct there, or approves with reasoning that covers it), spawn `review-arbiter` once with the repo as cwd and only the disputed findings: the range, each finding with its path:line, and each reviewer's position verbatim. Never send it agreed findings. Ask it to read the code and answer per finding `upheld` or `rejected` with file:line evidence. Then end the turn; on its answer, put its ruling under each disputed item in `Disagreements`. A `rejected` finding moves to `Non-blocking`; an `upheld` one stays blocking. Then recompute the verdict: a reviewer whose blocking findings were all rejected counts as approved; a missing reviewer still fails the verdict as in step 3. Without such a dispute, never run it.

Do not fix anything in this turn. Offer to fix the blocking items; the user decides.
