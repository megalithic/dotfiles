---
description: Start a new work session - sync with remote, check for available tasks
allowed-tools: Bash(jj:*), Bash(bd:*), Bash(git:*)
---

Starting new work session. Execute these steps:

1. **Sync with remote** (read-only, safe):
   - Run `jj git fetch` - pulls latest commits from origin without modifying working copy
   - Run `jj log -r 'main@origin' -r 'main'` - compare local vs remote main

2. **Check version control state**:
   - Run `jj status` - shows uncommitted working copy changes
   - Run `jj log -r ::@ -n 5` - shows recent history leading to current change

3. **Check task tracking**:
   - Run `bd ready` - shows available tasks to work on
   - If there's a task argument ($ARGUMENTS), show details with `bd show $ARGUMENTS`

4. **Present session summary**:
   
   ## jj Commands Used
   | Command | Purpose |
   |---------|---------|
   | `jj git fetch` | Pull latest from origin (read-only) |
   | `jj log -r 'main@origin' -r 'main'` | Compare local/remote main |
   | `jj status` | Show working copy changes |
   | `jj log -r ::@ -n 5` | Recent commit history |

   ## Session State
   - Sync status: Is local main up to date with origin/main?
   - Working copy: Any uncommitted changes?
   - Available tasks: List from `bd ready`

Ask: "What are we working on today?"

If starting new work, remind to run: `jj new -m "Brief description of task"`
