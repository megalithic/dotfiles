---
description: Light review of a commit range — reviewer-correctness + reviewer-security in parallel, findings merged
argument-hint: "<base>..<head> [acceptance criteria or focus…]"
---

Review the commit range `$1` with the light reviewer team, read-only. Acceptance criteria or focus from the caller: `${@:2}` (empty means none). For a pull request use `/code-review` instead.

## 1. Pin the range (one bash call)

- Empty `$1`, or no `..` in it → ask for `<base>..<head>`, then stop.
- Resolve both ends to full SHAs: `git rev-parse --verify <base>^{commit} <head>^{commit}`. Either fails → say which and stop. Never substitute another range.
- `git log --oneline <base>..<head>` empty → say there is nothing to review and stop.

## 2. Start both reviewers, then end the turn

One codemode call: `Promise.allSettled` two `subagent` calls, `agent: "reviewer-correctness"` and `agent: "reviewer-security"`, with the same task and the current working directory:

```
Review the immutable range <base-sha>..<head-sha> in <cwd>.
Commits:
<git log --oneline output>
Acceptance criteria: <from the caller, or "none given: review for correctness and regressions">
```

Never give one reviewer's report to the other. Then end the turn with a one-line status. Do not poll, sleep, or read session files: results arrive as messages.

## 3. Merge, when both have answered

A reviewer that failed or ended without a report is `missing`; say so, never fill its part yourself. Report each issue once, naming every reviewer that raised it. Add none and drop none; where they disagree, show both positions. The verdict is APPROVED only when both approved.

```text
Verdict: APPROVED | NEEDS CHANGES
Reviewed range: <base>..<head>
Reviewers:
- reviewer-correctness — APPROVED | NEEDS CHANGES | missing
- reviewer-security — APPROVED | NEEDS CHANGES | missing
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

Do not fix anything in this turn. Offer to fix the blocking items; the user decides.
