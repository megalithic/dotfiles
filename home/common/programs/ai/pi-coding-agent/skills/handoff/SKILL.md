---
name: handoff
description: "Save session state for later pickup. Use /handoff when context is degrading, /pickup to resume in a new session."
commands:
  - handoff
  - pickup
---

# Handoff / Pickup

Save and restore session context across pi sessions. Use when context window is full and model quality is degrading.

## Commands

### /handoff - Save current session state

When the user says `/handoff`:

1. Write a temp file with the handoff content
2. Run the script with `--file`

```bash
# Write content to temp file, then save handoff
cat > /tmp/handoff-content.md << 'HANDOFF'
## What I was working on

{Clear description of the task/goal}

## Current state

{Where things stand - what's done, what's in progress}

## Key files

- `path/to/file.ts` - Description of changes
- `path/to/other.ts` - What was done here

## Decisions made

- Decision 1 and why
- Decision 2 and reasoning

## Next steps

1. [ ] First thing to do next
2. [ ] Second thing
3. [ ] Third thing

## Blockers / Concerns

- Any issues or things to watch out for

## Context for pickup

{Any additional context that would help understand the situation}
HANDOFF

{baseDir}/scripts/handoff.sh --file /tmp/handoff-content.md --title "Brief title"
rm /tmp/handoff-content.md
```

The script auto-captures:
- Current bookmark (for pickup verification)
- jj status (working copy state)
- Recent commits
- Uncommitted changes (diff stat)

### /pickup - Resume from last handoff

When the user says `/pickup`:

```bash
# Get the latest handoff for current session
{baseDir}/scripts/pickup.sh

# Or specify a session
{baseDir}/scripts/pickup.sh mega
{baseDir}/scripts/pickup.sh rx
```

After retrieving the handoff:

1. **Check bookmark verification section** (at end of output)
   - If "Bookmarks match" → Proceed, but still confirm with user
   - If "Bookmark mismatch" → Present options to user, wait for response
   - If "No bookmark was set" → Ask user what bookmark to use

2. **Handle bookmark mismatch before doing anything else:**
   ```
   ⚠️ Bookmark mismatch detected:
   - Handoff was on: `feature-branch`
   - Currently on: `main`
   
   Options:
   1. Switch to `feature-branch` to continue where we left off
   2. Stay on `main` and start fresh
   3. Create a new bookmark for this work
   
   Which would you like?
   ```

3. **Once bookmark is confirmed:**
   - Read and understand the document
   - Verify current state matches (check jj status, key files exist)
   - Summarize back to user: "Picking up where we left off: {brief summary}"
   - Confirm before continuing: "Ready to continue with {next step}?"
   - Start from the "Next steps" section

**IMPORTANT:** Never proceed with work until bookmark situation is resolved. The user must explicitly confirm which bookmark to use.

List available handoffs:

```bash
{baseDir}/scripts/pickup.sh --list
{baseDir}/scripts/pickup.sh --list mega
```

## Storage Location

```
~/.local/share/pi/handoffs/
├── mega/
│   ├── 2026-02-19T14-30-00.md
│   └── 2026-02-19T16-45-00.md
├── rx/
│   └── 2026-02-18T09-00-00.md
└── canonize/
    └── 2026-02-17T11-20-00.md
```

## Handoff Document Format

```markdown
# Handoff: {brief title}

**Session:** mega
**Time:** 2026-02-19 14:30:00 EST
**Working Directory:** /Users/seth/projects/myapp
**Bookmark:** feature-auth-refactor

## What I was working on

{Clear description of the task/goal}

## Current state

{Where things stand - what's done, what's in progress}

## Key files

- `src/auth/login.ts` - Modified authentication flow
- `tests/auth.test.ts` - Added new test cases
- `docs/api.md` - Updated API documentation

## Recent changes

{Summary of uncommitted changes or recent commits}

## Decisions made

- Decided to use JWT instead of sessions because...
- Chose to split the module into two files for...

## Next steps

1. [ ] Finish implementing the refresh token logic
2. [ ] Add error handling for expired tokens
3. [ ] Update the client SDK

## Blockers / Concerns

- Need to verify the token expiry edge case
- Performance concern with the database query in `getUser()`

## Context for pickup

{Any additional context that would help the next session understand the situation}
```

## Best Practices

### When to handoff

- Context window feeling "full" (model starts hallucinating or forgetting)
- Before taking a break from a complex task
- Before switching to a different project
- When you want a "checkpoint" of the current state

### Writing a good handoff

- **Be specific** - Include file paths, not just descriptions
- **Document decisions** - Note non-obvious choices and reasoning
- **Concrete next steps** - List actionable items, not vague goals
- **Note surprises** - Mention anything tricky or unexpected
- **Include blockers** - What might stop progress?

### Picking up

1. Run `/pickup` to retrieve the handoff
2. Verify state: `jj status`, check key files exist
3. Summarize back to user before continuing
4. Ask for confirmation before starting work
5. Begin with "Next steps" section
