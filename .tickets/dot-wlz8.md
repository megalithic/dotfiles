---
id: dot-wlz8
status: open
deps: []
links: []
parent: dot-fsxj
created: 2026-04-17T16:48:11Z
type: task
priority: 3
assignee: Seth Messer
---
# Investigate otahontas/nix tk/ticket config updates

otahontas/nix repo (github.com/otahontas/nix) has evolved its tk/ticket pipeline.
Compare his current config against ours and identify useful updates.

Key areas to review:

1. **work-tickets.sh** — his version adds:
   - Auto-enter devenv if tk not on PATH
   - Verification pass after each ticket close (runs pi again to review git diff + acceptance criteria)
   - Context file loading from plans/.ticket-context.md
   - Full run logging to .tickets/logs/ with timestamps
   - Final review pass that analyzes the full log
   - Note: his uses git, ours would need jj equivalents

2. **ticket-creator skill** — his adds:
   - Mode 4: refine (turn vague backlog tickets into workable ones, add ready-for-development tag)
   - Context seeding (plans/.ticket-context.md with verification commands, key dirs, conventions)
   - Self-validation step (mandatory after Mode 2/3: check deps, cycles, ready tickets)
   - lat.md integration (skip context seeding if lat.md/ exists)

3. **task-pipeline skill** — his adds:
   - Fixed filename convention (task.md, plan.md) since worktrees isolate
   - Explicit phase transition table
   - Rule: plan steps must be small enough for one agent session (~30 min)

4. **task-pipeline.ts extension** — registers /task, /plan, /tickets commands
   that use subagent tool (researcher/planner agents) and pi.sendUserMessage

5. **Extensions of interest**:
   - model-quota.ts — rate limiting/quota tracking
   - stop-hook.ts — hook on agent stop
   - search-sessions.ts — session search
   - restricted-write.ts — restricted write tools for subagents
   - subagent/ — custom subagent agents (agents.ts + index.ts)
   - non-interactive.ts — non-interactive mode support

Repo cloned at: /Users/seth/.cache/pi-internet/github-repos/otahontas/nix/

Our equivalents live in:
- home/common/programs/ai/pi-coding-agent/extensions/
- ~/.pi/agent/skills/

## Acceptance Criteria

1. Document which updates are worth adopting
2. Document which updates conflict with our conventions (jj vs git, etc)
3. List concrete action items as follow-up tickets if any are worth implementing


## Notes

**2026-04-17T17:29:30Z**

## Rebuild hint after ticket completion

After completing work, agent should detect what nix rebuild (if any) is needed based on changed files:
- `home/` touched → `just home`
- `hosts/`, `modules/` touched → `just darwin`  
- Both → `just rebuild`
- Neither (scripts, tickets, docs) → nothing needed

### Implementation options

1. **AGENTS.md 'Session Completion' section** — add 'run rebuild hint' step so ALL sessions do it
2. **ticket-worker skill** — add to its completion checklist
3. **Standalone script** (e.g. `bin/nix-rebuild-hint.sh`) — reads `jj diff --stat`, prints recommendation. Referenced from AGENTS.md and/or skills.

Preferred: option 3 (reusable script) + reference from both AGENTS.md and ticket-worker skill.

Currently the agent just free-forms a summary at end of work — no automated mechanism detects what rebuild is needed. This should be deterministic, not vibes.
