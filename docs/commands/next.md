---
description: Complete current work and find next task - ensures clean handoff before moving on
allowed-tools: Bash(jj:*), Bash(bd:*), Bash(git:*), Bash(preview-ai:*), Read, AskUserQuestion
---

Complete current work and transition to next task. This command ensures nothing is left half-done.

**CRITICAL**: Do NOT push without explicit user approval. Do NOT proceed to next task until current work is properly closed out.

## Phase 1: Completion Checklist

Run this checklist and report status for each item:

```
[ ] 1. jj status              - Check for uncommitted changes
[ ] 2. jj log -r 'main..@'    - Check for undocumented commits
[ ] 3. jj describe            - Ensure current work is described
[ ] 4. bd sync --from-main    - Pull latest beads state
[ ] 5. bd list --status=in_progress - Check for open tasks to close
```

### Step 1: Check Version Control State

```bash
jj status
jj log -r 'main..@' --no-pager
```

**If uncommitted changes exist:**
- Summarize what changed (don't dump full diff)
- Ask if work is complete or needs more time

**If commits exist ahead of main:**
- Check each has a meaningful description
- If description is empty/poor, propose one with `jj describe`

### Step 2: Check Task Tracking

```bash
bd list --status=in_progress
bd show  # if there's a current task
```

**For each in-progress task:**
- Is it actually complete? → Close with `bd close <id>`
- Is it blocked/deferred? → Update status
- Is it still actively being worked? → Leave open, but note it

**Ask:** "Are there tasks that should be closed before we move on?"

### Step 3: Sync State

```bash
bd sync --from-main
bd repo sync
jj git fetch
jj log -r 'main' -r 'main@origin' --no-pager
```

Report sync status:
- Is main ahead of origin? (unpushed work)
- Is origin ahead of main? (need to rebase)
- Are beads in sync?

## Phase 2: Push Decision

**Only if there's unpushed work**, present:

```
## Ready to Push?

**Commits to push:**
- [list commits with descriptions]

**Commands that will run:**
```bash
jj bookmark set main -r @
jj git push --bookmark main
```

**Push to origin/main? (yes/no)**
```

**WAIT FOR EXPLICIT USER APPROVAL BEFORE PUSHING.**

If user approves:
```bash
jj bookmark set main -r @
jj git push --bookmark main
jj new  # Start fresh
```

If user declines:
- Note that work remains unpushed
- Continue to Phase 3 anyway

## Phase 3: Find Next Work

Query available work across repos:

```bash
# Current repo tasks
bd ready
bd list --status=open | head -20

# Show blocked tasks (for context)
bd blocked | head -10
```

### Present Candidates

Format the output as:

```
## Available Work

### Ready (no blockers)
| Priority | Type | ID | Title |
|----------|------|-------|-------|
| P1 | bug | shade-xyz | Fix something |
| P2 | task | .dotfiles-abc | Add feature |

### In Progress (carried over)
- [any tasks still marked in_progress]

### Blocked (FYI)
- [tasks waiting on dependencies]
```

**Ask:** "What would you like to work on next?"

If user selects a task:
```bash
jj new -m "Brief description matching selected task"
bd update <task-id> --status=in_progress
```

## Phase 4: Handoff Summary

Present final state:

```
## Session Handoff

### Completed This Session
- [list of closed tasks/commits]

### Pushed to Origin
- ✅ Yes / ❌ No (unpushed work remains)

### Next Task
- [selected task or "none selected"]

### jj State
[output of jj log -r '::@' -n 3]
```

## Commands Reference

| Command | Purpose |
|---------|---------|
| `jj status` | Check uncommitted changes |
| `jj log -r 'main..@'` | Commits ahead of main |
| `jj describe` | Document current work |
| `bd sync --from-main` | Pull beads from main |
| `bd repo sync` | Hydrate cross-repo issues |
| `bd list --status=in_progress` | Find open tasks |
| `bd close <id>` | Mark task complete |
| `bd ready` | Show available work |
| `jj bookmark set main -r @` | Move main to current |
| `jj git push --bookmark main` | Push to origin |
| `jj new -m "..."` | Start fresh change |
