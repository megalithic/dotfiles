# Pi Coding Agent Instructions

## Tools

- Always use `trash` instead of `rm` for file deletion
- Always use `jj` instead of `git` for version control (this repo uses Jujutsu)
- Always use `fd` instead of `find` for file discovery
- Always use `rg` instead of `grep` for content search
- Always use `web-search` skill first (ddg), fall back to `brave-search` if
  needed
- Always read `AGENTS.md` file in project roots

## Writing

- Use sentence case: "Next steps" not "Next Steps"
- Prefer bullet points over paragraphs
- Be concise - sacrifice grammar if needed for brevity
- No corporate buzzwords: comprehensive, robust, utilize, leverage, streamline,
  enhance
- No AI phrases: "dive into", "diving into"

## Version Control (Jujutsu)

- **Never use git commands** - always use `jj` equivalents
- **Never push to main** directly - use feature bookmarks
- **Never push without explicit user permission** - no `jj git push` unless user
  explicitly requests (e.g., "push it", "push to remote")
- **When requesting push permission:** show the exact command, e.g.:
  ```
  Ready to push. Run this?
  jj git push -b my-feature
  ```
- Common mappings:
  - `git status` → `jj status`
  - `git diff` → `jj diff`
  - `git commit` → `jj describe` (changes auto-tracked)
  - `git log` → `jj log`
  - `git push` → `jj git push` (requires user permission)

## Multi-Phase Work (IMPORTANT)

When working on a feature with multiple phases on the same bookmark:

**Always create a new commit BEFORE starting each new phase:**

```bash
# Phase 1: Make changes, then commit
jj desc -m "feat(x): phase 1 - core functionality"

# Phase 2: Create new commit FIRST, then make changes
jj new                                              # <- CRITICAL!
# ... make phase 2 changes ...
jj desc -m "feat(x): phase 2 - reliability"

# Phase 3: Create new commit FIRST, then make changes
jj new                                              # <- CRITICAL!
# ... make phase 3 changes ...
jj desc -m "feat(x): phase 3 - polish"
```

**Result:** Multiple commits on one bookmark, clean history:
```
@  c3  feat(x): phase 3 - polish           my-feature
·  c2  feat(x): phase 2 - reliability
·  c1  feat(x): phase 1 - core functionality
*  m   main
```

**Common mistake (DON'T DO THIS):**
```bash
jj desc -m "phase 1"
# make phase 2 changes WITHOUT jj new
jj desc -m "phase 2"  # WRONG: overwrites phase 1, all changes in one commit
```

## Shared Codebase Etiquette

Best practices for collaborative work:

- **Small, focused commits** - One logical change per commit
- **Descriptive messages** - Future you (and teammates) will thank you
- **Don't rewrite shared history** - Only rebase/amend unpushed commits
- **Review before push** - `jj diff` and `jj log` before pushing
- **Keep bookmarks short-lived** - Merge and delete, don't let them drift
- **Sync often** - `jj git fetch` regularly to stay current with main
- **Rebase onto main** - Before pushing, ensure your work is on latest main
- **Atomic PRs** - Each PR should be reviewable and mergeable independently

## Uncommitted Changes (CRITICAL - NEVER DISCARD)

**User's uncommitted changes are SACRED. Never assume they can be discarded.**

### Before ANY VCS operation, ALWAYS:
1. Run `jj status` to see working copy state
2. Run `jj diff` to see actual changes
3. If changes exist, ask user what to do - do NOT assume

### NEVER assume:
- "(no description set)" means empty - it likely has uncommitted work
- You can rebase/abandon/restore without checking first
- The working copy is clean

### Blocked commands (guardrails - immutable, non-overrideable):
| Command | Why blocked | What to do instead |
|---------|-------------|-------------------|
| `jj rebase` | Can orphan uncommitted changes | Check `jj status` first, commit WIP, ask user |
| `jj abandon` | Permanently discards changes | Check `jj diff -r <rev>`, ask user |
| `jj restore` | Overwrites working copy | Check `jj status`, ask user |
| `jj undo` | Can affect uncommitted work | Explain what it does, ask user |

### Example safe workflow:
```bash
# ALWAYS check state first
jj status
jj diff

# If uncommitted changes exist, commit them first
jj describe -m "wip: user's changes before rebase"

# Now safe to do VCS operations
# But STILL ask user: "I see uncommitted changes in @. Should I commit them
# first as WIP, or is it safe to proceed?"
```

**This is not overrideable.** Losing user's work is unacceptable.

## Interactive commands (AVOID)

**These commands open an editor/prompt and will hang forever. Never use without
flags:**

| Command                        | Problem                                | Non-interactive alternative                                |
| ------------------------------ | -------------------------------------- | ---------------------------------------------------------- |
| `jj squash`                    | Opens editor for message               | `jj squash -m "message"` or `-u` (use destination message) |
| `jj squash --from X --into Y`  | Opens editor if both have descriptions | Add `-u` or `-m "message"`                                 |
| `jj describe`                  | Opens editor                           | `jj describe -m "message"`                                 |
| `jj commit`                    | Opens editor                           | `jj commit -m "message"`                                   |
| `jj split`                     | Inherently interactive                 | Avoid entirely - use separate commits instead              |
| `jj split -i` / `jj squash -i` | Interactive selection                  | Avoid - use file paths instead                             |
| `git commit`                   | Opens editor                           | Don't use git, use `jj describe -m`                        |
| `vim`, `nano`, `emacs`         | Editor                                 | Use `Write` tool or `cat <<EOF`                            |

**When moving changes between commits:**

```bash
# WRONG - will hang if both commits have descriptions
jj squash --from @- --into @

# CORRECT - use -u to keep destination message
jj squash --from @- --into @ -u

# CORRECT - use -m to specify message
jj squash --from @- --into @ -m "combined message"

# CORRECT - specify files to avoid emptying source (no editor needed)
jj squash --from @- --into @ -u path/to/file.ex
```

**Don't guess flags** - run `<cmd> --help` to find the right option.

## Remote Server Access

- **Never SSH to remote servers without explicit user permission**
- Treat `ssh` the same as `jj git push` - requires explicit consent
- Includes any remote execution: `ssh user@host`, `scp`, `rsync` to remote, etc.
- **When requesting SSH permission:** show the exact command, e.g.:
  ```
  Need to check server logs. Run this?
  ssh user@host "tail -100 /var/log/app.log"
  ```
- Always ask first and wait for approval
- Exception: user explicitly requests (e.g., "ssh in and check logs", "check the
  server")

## Deployments

- **Never deploy without explicit user permission**
- Includes: `just deploy`, `deploy`, `fly deploy`, `vercel`, `netlify deploy`,
  `kubectl apply`, `terraform apply`, `pulumi up`, `dokploy`, etc.
- **When requesting deploy permission:** show the exact command, e.g.:
  ```
  Ready to deploy. Run this?
  just deploy
  ```
  ```
  Ready to deploy. Run this?
  dokploy app deploy --app-id abc123
  ```
- Always ask first and wait for approval
- Exception: user explicitly requests (e.g., "deploy it", "ship it", "push to
  prod")

## Guardrail Override Protocol

When a command is blocked by sentinel (the guardrails extension), the user can
grant single-use bypass permission.

### Keywords

- `override`, `bypass`, `force` — show confirmation prompt, then grant
- `!override`, `!bypass`, `!force` — grant immediately (no prompt)

### Flow (handled by sentinel extension)

1. Agent tries command → sentinel blocks it
2. User says `override` (or `!override`)
3. Sentinel intercepts input, grants override, sends message: "✓ Override
   granted for **rule**. Retry the command now."
4. **Agent MUST immediately retry the exact blocked command**
5. Sentinel allows it (override consumed), command executes

### Agent behavior on override

**When you see "Override granted... Retry the command now":**

- **Immediately retry** the blocked command — don't ask again, don't explain,
  just execute it
- The override is single-use and time-limited (2 minutes)
- If you don't retry promptly, the override expires

### Rules

- **Single-use**: permission applies ONLY to the most recently blocked command
- **Time-limited**: override expires after 2 minutes if not used
- **No persistence**: after execution, guardrails return to normal

### Example flow

```
Agent: <tries jj git push -b feature>
Sentinel: 🔒 **push** — Push to remote. Say `override` to allow.
User: override
Sentinel: ✓ Override granted for **push**. Retry the command now.
Agent: <immediately retries jj git push -b feature>
<command executes successfully>
```

## Coding Guidelines

- KISS, YAGNI - prefer duplication over wrong abstraction
- Prefer unix tools for single task scripts
- Use project scripts (just, package.json, Makefile) for linting/formatting
- Node: prefer package.json scripts over npx/bunx
- Always use lockfiles
- Only fix what's asked - no bonus improvements unless requested

## Multi-step Task Workflow

1. For complex tasks: write plan in markdown file first
2. Always clarify user's intention unless request is completely clear
3. If uncertain, say so immediately - don't guess
4. Work incrementally:
   - Complete step
   - Run verification commands (build, lint, test)
   - If verification passes, commit. If not, fix first.
5. Don't create plans for simple single-step tasks

## Research & Plans

When asked to research or create a plan:

- **Location:** `~/.local/share/pi/plans/{session}/`
- **Session:** Use `$PI_SESSION` env var, or repo name if not set
- **Format:** Markdown files with descriptive names (e.g., `telegram-rpc-architecture.md`)
- **Not version controlled** - persists locally, backed up via system backups

Example paths:
```
~/.local/share/pi/plans/mega/telegram-rpc-architecture.md
~/.local/share/pi/plans/rx/api-refactor-plan.md
~/.local/share/pi/plans/dotfiles/nix-module-migration.md
```

Create the directory if it doesn't exist:
```bash
mkdir -p ~/.local/share/pi/plans/${PI_SESSION:-$(basename $PWD)}
```

## Notifications

- Use `~/bin/ntfy` for sending notifications
- It handles attention detection and multi-channel routing automatically

## Local Development Scripts

- Use `/tmp/` for temporary verification scripts that shouldn't be committed
- Examples: version update checks, one-off validation scripts, personal dev
  utilities
- Scripts are automatically cleaned up by the system; however, you should
  explicitly remove them after successful validation and verification is
  completed. Don't rely on the system, we don't want bloat, either.


