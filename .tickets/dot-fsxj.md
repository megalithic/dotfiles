---
id: dot-fsxj
status: open
deps: []
links: []
parent: dot-0fjk
created: 2026-04-22T15:57:56Z
type: epic
priority: 1
assignee: Seth Messer
tags: [epic, tickets, pi-coding-agent, jj, subagents]
---
# Align tk/tickets workflow with otahontas/nix parity + jj-first integration

Investigate and align the full tk/tickets ecosystem from otahontas/nix. Multiple subsystems have drifted or are missing. Audit, plan, then land as subtasks under this epic.

## Scope

Compare our pi-coding-agent config against https://github.com/otahontas/nix (ref we forked from). Parity audit + adapt to our jj-first workflow (git fallback when no .jj dir).

## Source snapshot compared

Cloned /tmp/otahontas-nix (main @ 2026-04-22). Baseline for diffs below.

## Gap inventory

### Missing files (copy + adapt)

- home/common/programs/ai/pi-coding-agent/extensions/restricted-write.ts
  - Registers write-task / write-plan tools scoped to plans/task.md and plans/plan.md
  - Used by researcher/planner subagents so they write output themselves (no main-agent roundtrip)
- home/common/programs/ai/pi-coding-agent/extensions/guardrails.ts
  - Blocks: non-conventional commits, npx/bunx, rm/rmdir, non-standard worktree paths, pass/gpg
  - Our sentinel.ts covers some of this; decide: merge into sentinel-rules.json vs port as standalone
- home/common/programs/ai/pi-coding-agent/scripts/work-tickets.sh
  - Main runner: loops 'tk ready -T ready-for-development', spawns pi worker + verification pass + final review
  - Auto-enters devenv shell if tk not on PATH
  - Logs to .tickets/logs/<timestamp>.log
- home/common/programs/ai/pi-coding-agent/skills/git-commit/SKILL.md (or rename jj-commit)
  - Conventional-commit reference skill
  - MUST be rewritten jj-first: 'jj desc -m' / 'jj dm' aliases, fall back to 'git commit -S -m' only when no .jj dir

### Drifted files (review then sync-or-keep)

- skills/ticket-creator/SKILL.md
  - otahontas added auto-commit steps after create/refine/decompose
  - MUST convert to jj: 'jj desc -m "feat(tickets): ..."' (+ 'jj new' for multi-phase) when .jj exists; fallback to 'git add .tickets && git commit -m' otherwise
- skills/task-pipeline/SKILL.md
  - Ours is longer/more prescriptive; otahontas leaner — subagents do their own writes via write-task/write-plan tools
  - Decision: adopt his model (reduces main-agent context) or keep ours
- agents/planner.md, agents/researcher.md
  - otahontas versions declare 'tools: read, grep, find, ls, bash, write-{task,plan}' and instruct agent to write output itself
  - Ours declare READ-ONLY and main agent saves output
  - Tied to restricted-write.ts decision above
- extensions/task-pipeline.ts
  - Behavior diverges in lockstep with skills/task-pipeline/SKILL.md — sync together
- extensions/stop-hook.ts
  - Ours: dual local+cloud gatekeeper with GATEKEEPER_PREFERENCE switch
  - Otahontas: single gatekeeper (zai/glm-4.5-air)
  - Keep ours — more robust. Document divergence.
- extensions/custom-footer.ts, extensions/notify.ts
  - Minor drifts (58 / 203 lines). Audit, cherry-pick useful changes.

### Seth-only (keep, but integrate)

- extensions/checkpoint.ts (570 lines) — jj-bookmark-aware. This is the glue for ticket↔bookmark automation. See Integration section.
- extensions/sentinel.ts + sentinel-rules.json — may subsume guardrails.ts. Decide.
- extensions/pinvim.ts, bridge.ts, preview.ts, file-size-guard.ts, claude-code-use.ts, answer.ts, execute-command.ts, files.ts, loop.ts, review.ts
- prompts/ — we have double-check.md, double-check-plan.md, humanize.md, plan.md, simplify.md, task.md, tickets.md (otahontas only has merge-worktree.md)
- skills/ — chrome-cdp, git-worktrees, github, handoff, mcpctl, preview, tell, tmux, web-browser, web-search
- packages/ — pi, pi-agent-browser, pi-internet, pi-mcp-adapter, pi-multi-pass, pi-synthetic-provider

## Subagent strategy decision

Currently: installed pi-interactive-subagents (HazAT) via 'pi install'.

Problems:
1. Too heavy — bundles planner/scout/worker/reviewer/visual-tester agents that conflict with our researcher/planner
2. Async tmux-pane model doesn't fit our ticket-worker flow (work-tickets.sh needs synchronous pi -p calls)
3. No hook into tk lifecycle — doesn't know about tickets/bookmarks
4. Competes with task-pipeline.ts /plan command

Options to evaluate:
- A. Remove pi-interactive-subagents entirely, use bundled extensions/subagent/ (synchronous, matches work-tickets.sh)
- B. Keep pi-interactive-subagents ONLY for exploratory /iterate work, add ticket-aware agents (ticket-worker, ticket-verifier)
- C. Fork HazAT extension to add tk integration (auto-pass ticket id, bookmark handoff)

Recommend A for now: simpler, already aligned with our subagent/ ext and task-pipeline flow.

## jj integration (CRITICAL)

Everything ticket-related assumes git. Convert to jj-first with git fallback. Detection:

    if [ -d .jj ]; then VCS=jj; else VCS=git; fi

Affected surfaces:
- skills/ticket-creator — commit-after-create logic
- skills/ticket-worker — 'commit and close' step (currently says 'git commit -S -m')
- scripts/work-tickets.sh — no commit logic today, but verification pass runs 'git diff HEAD~1'; use 'jj diff -r @-' when jj
- prompts/merge-worktree.md — git-only today, document jj equivalent (jj rebase + jj bookmark move)
- extensions/guardrails.ts — 'blockNonConventionalCommits' parses 'git commit -m'; add 'jj desc -m' and 'jj dm' patterns
- extensions/checkpoint.ts — already jj-aware ✓ (good reference impl)

### jj command mapping

| Purpose | jj | git |
|---|---|---|
| Commit message | jj desc -m / jj dm | git commit -S -m |
| New change | jj new | (implicit) |
| Branch/bookmark | jj bookmark create/move | git checkout -b |
| Diff last change | jj diff -r @- | git diff HEAD~1 |
| Show log | jj log --limit N | git log --oneline -N |
| Worktree | jj workspace add | git worktree add |
| Rebase | jj rebase -d main | git rebase main |

## Ticket ↔ jj bookmark automation (new extension)

New extension: extensions/ticket-vcs.ts. Hooks:

- on tool_call 'bash' where command matches 'tk start <id>':
  - detect .jj; if jj: create/switch bookmark named <ticket-id> ('jj feat <ticket-id>')
  - if git: create branch
  - seed a work note in .tickets/<id>.md with bookmark name
- on tool_call 'bash' where command matches 'tk close <id>':
  - check current jj description; if empty/default, suggest 'jj desc -m "feat(<type>): <title> (closes <id>)"'
  - do NOT auto-push
- on stop_hook / session end:
  - if an in-progress ticket exists (tk list --status=in_progress), write state file .pi/state/current-ticket.json with {id, bookmark, started_at}
  - on session start, read state file and echo 'Resuming ticket <id> on bookmark <bookmark>'
- extend checkpoint.ts 'first write on main' prompt to suggest 'jj feat <ticket-id>' when a ticket is in progress

## Verification / acceptance

Split into child tickets for each bullet below. Acceptance for this epic = all children closed + end-to-end dry run of work-tickets.sh on a trivial ticket in this repo produces a jj commit on a feature bookmark and closes the ticket.

## Child tickets to create (in task-pipeline/plan phase)

1. Port extensions/restricted-write.ts (unchanged from upstream)
2. Port or merge extensions/guardrails.ts into sentinel-rules.json
3. Port extensions/task-pipeline.ts + skills/task-pipeline/SKILL.md (sync together)
4. Port agents/planner.md + agents/researcher.md (with write-task/write-plan tool refs)
5. Port scripts/work-tickets.sh (adapt 'git diff HEAD~1' → jj-aware)
6. Rewrite skills/ticket-creator/SKILL.md commit steps to jj-first + git fallback
7. Rewrite skills/ticket-worker/SKILL.md commit steps to jj-first + git fallback
8. Create skills/jj-commit/SKILL.md (port from git-commit, jj-first)
9. Rewrite prompts/merge-worktree.md jj variant or dual-track
10. Decide + execute: remove or keep pi-interactive-subagents (Option A recommended)
11. New extension: extensions/ticket-vcs.ts — tk↔jj bookmark hooks + session state persistence
12. Extend extensions/checkpoint.ts with ticket-awareness (cross-ref current in-progress ticket)
13. Rebuild via 'just validate' + 'just home'; smoke test work-tickets.sh end-to-end

## Sources

- /tmp/otahontas-nix (cloned via 'gh repo clone otahontas/nix')
- ~/.dotfiles/home/common/programs/ai/pi-coding-agent/
- ~/.pi/agent/ (symlink target)
- tk --help output
- pi-interactive-subagents README: https://github.com/HazAT/pi-interactive-subagents

## Acceptance Criteria

1. All 13 child tickets created with dependencies wired (use ticket-creator Mode 3 after plan phase)
2. Decision recorded in plan: pi-interactive-subagents kept vs removed + rationale
3. Decision recorded: guardrails.ts ported standalone vs merged into sentinel-rules.json
4. Every child ticket's acceptance criteria references jj-first + git-fallback where VCS is involved
5. 'just validate' passes after all children land
6. End-to-end smoke test: create trivial ticket (say 'add comment to README'), run work-tickets.sh, observe: jj bookmark created from ticket id, jj commit with conventional message closes it, tk close runs, verification pass runs, tk show <id> shows closed status
7. 'tk dep cycle' clean; 'tk ready -T ready-for-development' shows at least one child unblocked when work begins
8. Epic closed only when all 13 children closed


## Notes

**2026-04-22T15:59:03Z**

## Update: sentinel.ts vs guardrails.ts (per user)

We use extensions/sentinel.ts (1062 lines) + extensions/sentinel-rules.json, NOT a separate guardrails.ts. Any missing guards get added to sentinel, not ported as-is.

### Current sentinel coverage (confirmed via rg)

- ✅ npx/bunx blocked (sentinel.ts:639 'npx-bunx')
- ✅ pass/gpg blocked (sentinel.ts:373)
- ✅ jj commit without -m flagged (sentinel.ts:337 'jj-commit-no-msg')
- ✅ interactive jj squash/split/commit/restore blocked (sentinel-rules.json:17-18)
- ✅ rm/rmdir → trash (sentinel-rules.json tool_corrections)
- ✅ find → fd, grep → rg, git → jj (sentinel-rules.json tool_corrections)
- ✅ ticket_gate toggle exists (sentinel-rules.json:11, currently false)

### Gaps vs otahontas guardrails.ts

- ❌ Non-conventional commits — NOT enforced. otahontas regex checks 'git commit -m "..."' against /^(feat|fix|docs|...)(\(scope\))?: /. We need jj-aware version: match both 'jj desc -m', 'jj dm', 'jj commit -m' AND 'git commit -m'
- ❌ Non-standard worktree paths — NOT enforced. otahontas blocks 'git worktree add' unless path contains '.worktrees/'. Add to sentinel with jj workspace add support too
- ⚠️  commented-out rules — user mentioned some guards may exist commented-out. rg didn't find obvious ones; do a second pass reading sentinel.ts top-to-bottom during implementation

### Amended subtask list

Replace subtask #2 ('Port or merge guardrails.ts into sentinel-rules.json') with:

2a. Audit sentinel.ts for commented-out rules — uncomment + tune anything useful
2b. Add 'conventional-commit-msg' rule to sentinel.ts (covers jj desc -m, jj dm, jj commit -m, git commit -m)
2c. Add 'worktree-path' rule to sentinel.ts (covers git worktree add AND jj workspace add — require '.worktrees/' in path)

### Confirmation: work-tickets.sh genuinely missing

rg/fd across ~/.dotfiles, ~/bin, ~/.pi returned zero hits. Only references in session history. Subtask #5 still valid — need to port from otahontas.

**2026-04-22T16:12:56Z**

## Update 2: worktrees disabled (per user)

Not using git worktrees / jj workspace add at this time.

- DROP subtask 2c (worktree-path sentinel rule) — not needed
- skills/git-worktrees still exists but is dormant; do not modify as part of this epic
- prompts/merge-worktree.md — keep as-is; worktree flow revisit is out of scope
- extensions/checkpoint.ts jj bookmark logic still applies (bookmarks != worktrees)
- work-tickets.sh port: confirmed missing. Keep subtask #5. Adapt to run in current checkout (no worktree setup), as otahontas's script already does.

**2026-04-22T16:17:10Z**

## Decisions locked

- Q1: A — abandon pi-interactive-subagents (HazAT), use bundled extensions/subagent/. Add any needed updates there to support ticket workflow.
- Q2: A — adopt otahontas model. Port restricted-write.ts. Researcher/planner subagents write plans/{task,plan}.md themselves via write-task/write-plan tools.
- Q3: C — skip new jj-commit skill. Rely on sentinel conventional-commit rule instead.
- Q4: A — hard block (CONFIRM + override required), matching existing sentinel philosophy.
- Q5: A — new extensions/ticket-vcs.ts. ALSO: extensions/checkpoint.ts is not working properly → remove it.
- Q6: B — skip task-pipeline research phase. Create child tickets now.

## Final child ticket list (12)

1. ticket-port-restricted-write: port extensions/restricted-write.ts
2. ticket-sentinel-audit: audit sentinel.ts for commented-out rules, uncomment useful ones
3. ticket-sentinel-conventional-commit: add jj-aware conventional-commit rule (hard block, CONFIRM)
4. ticket-port-task-pipeline: sync extensions/task-pipeline.ts + skills/task-pipeline/SKILL.md with otahontas (leaner subagent-writes-own-output model)
5. ticket-port-agents: port agents/planner.md + agents/researcher.md (reference write-task/write-plan tools). Depends on #1.
6. ticket-port-work-tickets: port scripts/work-tickets.sh, adapt 'git diff HEAD~1' → jj-aware when .jj present
7. ticket-rewrite-creator-jj: rewrite skills/ticket-creator/SKILL.md commit steps jj-first / git fallback
8. ticket-rewrite-worker-jj: rewrite skills/ticket-worker/SKILL.md commit steps jj-first / git fallback
9. ticket-remove-hazat: pi uninstall pi-interactive-subagents, purge any residual state
10. ticket-remove-checkpoint: remove extensions/checkpoint.ts (broken, replaced by ticket-vcs.ts)
11. ticket-new-ticket-vcs: new extensions/ticket-vcs.ts — tk↔jj bookmark hooks + session state persistence (tk start → jj feat, tk close → jj desc suggestion, stop-hook → .pi/state/current-ticket.json)
12. ticket-smoke-test: just validate + just home + end-to-end work-tickets.sh dry run. Depends on 1-11.
