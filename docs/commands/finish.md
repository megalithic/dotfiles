---
description: Finish work session - review changes, update tasks, prepare for push (asks before pushing)
allowed-tools: Bash(jj:*), Bash(bd:*), Bash(git:*), Read
---

Finishing work session. Execute these steps but **DO NOT PUSH without explicit user approval**:

1. **Check current state**:
   - Run `jj status` to see uncommitted changes
   - Run `jj log -r 'main..@'` to see commits not yet on main
   - Run `jj diff` if there are uncommitted changes (summarize, don't dump entire diff)

2. **If code was changed, consider quality gates**:
   - Check if there's a justfile: `test -f justfile && just --list`
   - Ask user if they want to run tests/lints before finishing

3. **Document the work** (if needed):
   - If current change has poor/no description, suggest running `jj describe`
   - Propose a comprehensive message: what changed, why, key details

4. **Review task tracking**:
   - Run `bd show` to see current task status
   - List any in-progress tasks that should be closed
   - Ask if any tasks should be closed or updated

5. **Sync check** (read-only):
   - Run `jj git fetch` to check for remote changes
   - Run `jj log -r 'main' -r 'main@origin'` to compare

6. **Present summary**:

   ## jj Commands Used This Session
   | Command | Purpose |
   |---------|---------|
   | `jj status` | Show working copy state |
   | `jj log -r 'main..@'` | Commits ahead of main |
   | `jj diff` | View uncommitted changes |
   | `jj git fetch` | Pull latest from origin |
   | `jj log -r 'main' -r 'main@origin'` | Compare local/remote |

   ## Beads Task Status
   - Show output from `bd show`
   - List tasks to close

   ## Ready to Push?
   - Commits ready: (list them)
   - Remote status: (ahead/behind/synced)

7. **ASK FOR PERMISSION**:
   
   "Ready to push to origin/main. Commands that will run:"
   ```
   jj bookmark set main -r @
   bd sync
   jj git push --bookmark main
   ```
   
   **Do you want me to push? (yes/no)**

**CRITICAL**: Do NOT run push commands until user explicitly says yes.

After push (if approved):
- Run `jj new` to start fresh for next session
- Verify with `jj log -r main` that it shows as synced
- Provide handoff summary: what was done, what's next
