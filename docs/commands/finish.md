---
description: Finish work session - review changes, update tasks, prepare for push (asks before pushing)
allowed-tools: Bash(jj:*), Bash(bd:*), Bash(git:*), Bash(preview-ai:*), Read
---

Finishing work session. Execute these steps but **DO NOT PUSH without explicit user approval**.

**REQUIRED**: Load the `task-completion` skill for summary format guidelines.

1. **Check current state**:
   - Run `jj status` to see uncommitted changes
   - Run `jj log -r 'main..@'` to see commits not yet on main
   - Run `jj diff` if there are uncommitted changes (summarize, don't dump entire diff)

2. **Run quality gates** (MANDATORY if tests exist):
   - Check for test infrastructure in order of preference:
     1. `justfile` with test/check target: `just test` or `just check`
     2. `package.json` with test script: `npm test` or `bun test`
     3. `Makefile` with test target: `make test`
     4. Language-specific: `cargo test`, `go test ./...`, `pytest`, etc.
   - **If tests exist, run them BEFORE proceeding**
   - **If tests FAIL**: Stop here. Do NOT proceed to push consent.
     - Show the test output clearly
     - Ask: "Tests failed. Options: (1) Fix issues and re-run, (2) Skip tests and proceed anyway (not recommended)"
   - **If tests PASS**: Continue to step 3
   - If no tests found, note this in summary and proceed

3. **Document the work** (if needed):
   - If current change has poor/no description, suggest running `jj describe`
   - Propose a comprehensive message: what changed, why, key details

4. **Review task tracking**:
   - Run `bd show` to see current task status
   - List any in-progress tasks that should be closed
   - Ask if any tasks should be closed or updated

5. **Sync beads** (if .beads/ exists):
   - Run `bd sync --from-main` - pulls latest bead task state from main branch
   - Run `bd repo sync` - hydrates issues from linked repos (cross-repo visibility)
   - This ensures task tracking reflects any work merged to main by other sessions

6. **Sync check** (read-only):
   - Run `jj git fetch` to check for remote changes
   - Run `jj log -r 'main' -r 'main@origin'` to compare

7. **Preview changes** (REQUIRED):
   - Run `preview-ai diff` to open a split pane showing all changes
   - This shows the diff excluding `.beads/**` noise
   - Preview opens RIGHT next to the AI agent pane
   - User can visually review before proceeding

8. **Present summary** (follow task-completion skill format):

   ```
   `★ Insight ─────────────────────────────────────`
   [2-3 codebase-specific insights about the work done]
   `─────────────────────────────────────────────────`
   ```

   ## Summary

   **Created/Modified:**
   - List files with brief descriptions

   **Features/Fixes:**
   - ✅ Key accomplishments

   ## Quality Gates
   - **Tests**: ✅ Passed / ❌ Failed / ⚠️ No tests found
   - Command run: `just test` (or whatever was used)
   - Output summary if relevant

   ## Commands Used This Session
   | Command | Purpose |
   |---------|---------|
   | `jj status` | Show working copy state |
   | `jj log -r 'main..@'` | Commits ahead of main |
   | `just test` | Run project tests (if applicable) |
   | `preview-ai diff` | Visual diff review (excludes beads) |
   | `bd sync --from-main` | Pull latest bead state from main |
   | `bd repo sync` | Hydrate cross-repo issues |
   | `jj git fetch` | Pull latest from origin |

   ## Beads Task Status
   - Show output from `bd show`
   - List tasks to close

   ## Ready to Push?
   - Commits ready: (list them)
   - Remote status: (ahead/behind/synced)

9. **ASK FOR PERMISSION**:
   
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
- **Cleanup preview pane** (REQUIRED):
  ```bash
  # Close the ai-preview pane in current session/window
  tmux list-panes -F "#{pane_id} #{pane_title}" 2>/dev/null | grep "ai-preview" | head -1 | cut -d' ' -f1 | xargs -I{} tmux kill-pane -t {} 2>/dev/null || true
  ```
  This cleans up the preview-ai pane that was opened for diff review, keeping the workspace tidy.
- Provide handoff summary: what was done, what's next
