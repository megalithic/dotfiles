---
name: jj
description: Jujutsu (jj) version control workflow, commands, and best practices. Use when working with version control in jj-enabled repos. Covers commits, bookmarks, workspaces, and safe push patterns.
tools: Bash
---

# Jujutsu (jj) Version Control

## Overview

**CRITICAL**: Always use `jj` commands instead of `git` for ALL version control operations in jj-enabled repos. Never use raw git commands directly.

Jujutsu is a Git-compatible VCS with automatic snapshots, mutable history, and conflict-free parallel work. This dotfiles repo is jj-initialized with full git coexistence.

## Quick Reference Card

```
STATUS:         jj status (jj s)
DIFF:           jj diff (jj d)
LOG:            jj log (jj l)
NEW COMMIT:     jj new -m "message"
DESCRIBE:       jj describe -m "msg" (jj dm "msg")
SQUASH:         jj squash -m "message"
FETCH:          jj git fetch (jj g fetch)
PUSH:           jj git push (jj push)
REBASE:         jj rebase -d main (jj rb -d main)
BOOKMARK:       jj bookmark set main -r @ (jj main)
```

---

## Decision Trees

### "I need to start new work"

```
Need to start new work?
│
├─▶ Standard workflow (RECOMMENDED):
│   └─▶ jj new -m "feat: description"
│       └─▶ Work in default workspace
│
├─▶ Need isolation? (⚠️ WIP - workspace scripts not stable)
│   └─▶ For now: just use jj new in default workspace
│       └─▶ Workspace scripts under development
│
└─▶ Multiple parallel features?
    └─▶ jj new main -m "Feature A"
        └─▶ jj new main -m "Feature B"
            └─▶ Use jj edit <change-id> to switch
```

### "I need to save/commit my work"

```
Need to save work?
│
├─▶ Just want to record progress (local)?
│   └─▶ jj describe -m "work in progress"
│       (or just keep working - jj auto-snapshots)
│
├─▶ Ready to finalize commit message?
│   └─▶ jj describe -m "feat(scope): detailed message
│
│        - What changed
│        - Why it changed"
│
├─▶ Want to squash into parent?
│   └─▶ jj squash -m "combined message"
│
└─▶ Want to split into multiple commits?
    └─▶ jj split
        (interactive - opens editor)
```

### "I need to push to remote"

```
Ready to push?
│
├─▶ Check what will be pushed:
│   └─▶ jj log -r 'main@origin::main'
│
├─▶ Nothing to push (main == main@origin)?
│   └─▶ First move main to current: jj bookmark set main -r @
│
├─▶ Remote is ahead (commits on origin we don't have)?
│   └─▶ jj git fetch
│       └─▶ jj rebase -d main@origin
│           └─▶ Then try push again
│
└─▶ Ready to push?
    └─▶ ASK USER FIRST - Never push without consent!
        └─▶ jj git push --bookmark main
```

### "I have conflicts"

```
Conflicts detected?
│
├─▶ See conflict markers:
│   └─▶ jj status (shows conflicted files)
│       └─▶ Look for <<<<<<< markers in files
│
├─▶ Resolve conflicts:
│   └─▶ Edit files to resolve
│       └─▶ Remove conflict markers
│           └─▶ jj status (verify resolved)
│
├─▶ Want to use a merge tool?
│   └─▶ jj resolve <file>
│
└─▶ Want to abort and try different approach?
    └─▶ jj op log (find pre-conflict state)
        └─▶ jj op restore <op-id>
```

### "Something went wrong"

```
Need to recover?
│
├─▶ Undo last operation:
│   └─▶ jj undo
│
├─▶ See operation history:
│   └─▶ jj op log
│       └─▶ jj op restore <op-id>
│
├─▶ Abandon current change:
│   └─▶ jj abandon
│
├─▶ Discard uncommitted edits:
│   └─▶ jj restore
│
└─▶ Find lost commit:
    └─▶ jj evolog (shows change evolution)
        └─▶ jj op log (shows all operations)
```

---

## Configuration

### User's Custom Aliases

These aliases are configured and available:

| Alias | Expands To | Purpose |
|-------|-----------|---------|
| `jj b` | `jj bookmark` | Bookmark management |
| `jj d` | `jj diff` | Show diff |
| `jj dm "msg"` | `jj desc -m "msg"` | Describe with message |
| `jj dv` | `jj desc` | Describe (opens editor) |
| `jj g` | `jj git` | Git subcommand |
| `jj l` | `jj log` | Show log |
| `jj ll` | `jj log -T builtin_log_compact_full_description` | Log with full descriptions |
| `jj main` | `jj bookmark move main --to @` | Move main to current |
| `jj push` | `jj git push` | Push to remote |
| `jj rb` | `jj rebase` | Rebase |
| `jj s` | `jj status` | Status |
| `jj tug` | (moves closest bookmark to parent) | Pull bookmark down |

### User's Custom Revsets

| Revset | Meaning |
|--------|---------|
| `trunk()` | `main@origin` |
| `current_work` | Work between trunk and @, used as default log |
| `stack()` | Ancestors of reachable mutable commits |
| `stack(x)` | Stack at specific revision |
| `stack(x, n)` | Stack with depth limit |
| `closest_bookmark(to)` | Find nearest bookmark ancestor |

### UI Settings

- **Pager**: delta (with syntax highlighting)
- **Graph style**: curved
- **Editor**: neovim
- **Signing**: SSH with 1Password integration
- **Default command**: `jj log` (runs when just typing `jj`)

---

## Revset Syntax Reference

Revsets are jj's query language for selecting commits.

### Basic Selectors

| Revset | Meaning |
|--------|---------|
| `@` | Current working copy commit |
| `@-` | Parent of @ |
| `@--` | Grandparent of @ |
| `root()` | Repository root commit |
| `heads()` | All head commits |
| `main` | Bookmark named "main" |
| `main@origin` | Remote tracking bookmark |
| `abc123` | Commit/change ID (prefix match) |

### Operators

| Operator | Meaning | Example |
|----------|---------|---------|
| `::x` | Ancestors of x (inclusive) | `::main` |
| `x::` | Descendants of x (inclusive) | `@::` |
| `x::y` | Range from x to y | `main::@` |
| `x-` | Parent of x | `main-` |
| `x+` | Children of x | `main+` |
| `x \| y` | Union (x or y) | `main \| @` |
| `x & y` | Intersection (x and y) | `heads() & main::` |
| `x ~ y` | Difference (x but not y) | `all() ~ immutable()` |
| `!x` | Negation (not x) | `!immutable()` |

### Functions

| Function | Returns |
|----------|---------|
| `all()` | All commits |
| `none()` | Empty set |
| `heads(x)` | Commits in x with no descendants in x |
| `roots(x)` | Commits in x with no ancestors in x |
| `ancestors(x)` | All ancestors of x |
| `descendants(x)` | All descendants of x |
| `reachable(x, y)` | Commits reachable from x through y |
| `connected(x)` | Ancestors and descendants connecting x |
| `parents(x)` | Direct parents of x |
| `children(x)` | Direct children of x |
| `mutable()` | Non-immutable commits |
| `immutable()` | Immutable commits (usually pushed) |
| `bookmarks()` | Commits with bookmarks |
| `bookmarks(pattern)` | Commits matching bookmark pattern |
| `remote_bookmarks()` | Commits with remote bookmarks |
| `tags()` | Commits with tags |
| `git_head()` | Git HEAD |
| `empty()` | Empty commits |
| `conflict()` | Commits with conflicts |
| `author(pattern)` | Commits by author |
| `description(pattern)` | Commits with matching description |
| `file(pattern)` | Commits touching file |

### Common Revset Patterns

```bash
# What will I push?
jj log -r 'main@origin::main'

# My recent work
jj log -r '@::'

# Unpushed work on any bookmark
jj log -r 'bookmarks() ~ remote_bookmarks()'

# Find commits with "fix" in message
jj log -r 'description("fix")'

# Commits I authored
jj log -r 'author("seth")'

# Commits touching specific file
jj log -r 'file("home/programs/ai")'

# All workspace bookmarks
jj log -r 'bookmarks(glob:"ws/*")'
```

---

## Template Language

Templates control output formatting with `-T` flag.

### Common Template Variables

| Variable | Type | Description |
|----------|------|-------------|
| `commit_id` | CommitId | Full commit hash |
| `change_id` | ChangeId | jj change ID |
| `description` | String | Commit message |
| `author` | Signature | Author info |
| `committer` | Signature | Committer info |
| `working_copies` | String | Working copy info |
| `bookmarks` | List | Bookmarks pointing here |
| `tags` | List | Tags pointing here |
| `git_head` | Bool | Is this git HEAD? |
| `empty` | Bool | Is commit empty? |
| `conflict` | Bool | Has conflicts? |
| `root` | Bool | Is root commit? |

### Template Methods

```
commit_id.short()           # Short hash
commit_id.short(8)          # 8-char hash
change_id.shortest()        # Shortest unique prefix
description.first_line()    # First line only
author.name()               # Author name
author.email()              # Author email
author.timestamp()          # Commit time
```

### Template Syntax

```bash
# Simple template
jj log -T 'change_id.short() ++ " " ++ description.first_line() ++ "\n"'

# Conditional
jj log -T 'if(empty, "(empty) ") ++ description.first_line()'

# With labels (for colors)
jj log -T 'label("commit_id", commit_id.short())'

# Check boolean
jj log -r @ --no-graph -T 'if(empty, "true", "false")'
```

---

## Workspace Scripts (⚠️ WORK IN PROGRESS)

> **WARNING**: These workspace scripts are under active development and not fully
> functional yet. Do NOT rely on them for production work. Use standard jj commands
> (`jj new`, `jj describe`, etc.) in the default workspace until these are stable.

Four custom scripts for AI agent workspace management:

### jj-ws-claim

Claim or create a workspace for isolated work.

```bash
# Basic usage
jj-ws-claim <task-id>

# With options
jj-ws-claim <task-id> --base <revision> --json

# Example
jj-ws-claim hs-memory-leaks
# Creates: .workspaces/hs-memory-leaks/
# Creates bead task if doesn't exist
```

**What it does:**
1. Creates `.workspaces/<task-id>/` directory
2. Creates jj workspace pointing to main repo
3. Creates bead task for tracking (if `bd` available)
4. Uses mkdir-based locking for concurrent safety

**Exit codes:**
- 0: Success
- 1: Invalid arguments
- 2: Not in jj repository
- 3: Workspace creation failed
- 4: Already in non-default workspace

### jj-ws-complete

Complete work in a workspace and clean up.

```bash
# Complete current workspace
jj-ws-complete

# Complete specific workspace
jj-ws-complete <workspace-name>

# Options
jj-ws-complete -r              # Rebase if parallel branch
jj-ws-complete --no-merge      # Don't merge to main
jj-ws-complete --no-cleanup    # Keep workspace directory
jj-ws-complete --reason "text" # Close reason for bead
```

**What it does:**
1. Creates `ws/<workspace-name>` bookmark for tracking
2. Merges work to main (moves main bookmark)
3. Closes associated bead task
4. Cleans up workspace directory

**Exit codes:**
- 0: Success
- 1: Invalid arguments
- 2: Not in jj repository
- 3: In default workspace (nothing to complete)
- 4: Workspace not found

### jj-ws-push

Review and push completed workspace work.

```bash
# List all completed workspace work
jj-ws-push --list

# Push specific bookmark
jj-ws-push ws/<name>

# Push all workspace bookmarks
jj-ws-push --all

# Force (skip confirmation)
jj-ws-push -f ws/<name>
```

**What it does:**
1. Lists ws/* bookmarks (completed workspace work)
2. Shows diff/log for review
3. Requires explicit confirmation before push
4. Moves main and pushes to origin

### jj-ws-status

Get current workspace status (useful for agents).

```bash
# Human readable
jj-ws-status

# Machine readable
jj-ws-status --json
```

**Returns:**
- Workspace name and path
- Commit info (empty, conflicts, description)
- Associated bead task
- All available workspaces

### Workspace Lifecycle (⚠️ WIP)

```
⚠️ NOT YET STABLE - Use standard jj workflow for now

┌─────────────────┐
│ jj-ws-claim     │  Create isolated workspace
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Work in         │  Make changes, jj describe
│ workspace       │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ jj-ws-complete  │  Creates ws/* bookmark, merges to main
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ jj-ws-push      │  User reviews and pushes (requires consent!)
└─────────────────┘
```

**Current Recommended Workflow (Stable):**
```
jj new -m "description"  →  work  →  jj describe  →  jj bookmark set main -r @  →  ask user to push
```

---

## Command Reference

### Core Commands

| Command | Purpose | Example |
|---------|---------|---------|
| `jj status` | Show working copy changes | `jj s` |
| `jj diff` | Show current change diff | `jj d` |
| `jj log` | Show revision history | `jj l` |
| `jj show` | Show commit details | `jj show @-` |
| `jj new` | Create new change | `jj new -m "feat: add X"` |
| `jj describe` | Update commit message | `jj dm "message"` |
| `jj edit` | Switch to editing a change | `jj edit abc123` |
| `jj abandon` | Discard a change | `jj abandon @` |

### History Manipulation

| Command | Purpose | Example |
|---------|---------|---------|
| `jj squash` | Merge current into parent | `jj squash -m "msg"` |
| `jj split` | Split change into multiple | `jj split` |
| `jj rebase` | Move change to new parent | `jj rb -d main` |
| `jj absorb` | Auto-distribute fixes | `jj absorb` |
| `jj duplicate` | Copy changes | `jj duplicate @` |
| `jj parallelize` | Make revisions siblings | `jj parallelize x y` |

### Bookmarks (like git branches)

| Command | Purpose | Example |
|---------|---------|---------|
| `jj bookmark list` | List bookmarks | `jj b list` |
| `jj bookmark set` | Move bookmark | `jj b set main -r @` |
| `jj bookmark create` | Create bookmark | `jj b create feat -r @` |
| `jj bookmark delete` | Delete bookmark | `jj b delete feat` |
| `jj bookmark move` | Move bookmark | `jj main` (alias) |

### Git Integration

| Command | Purpose | Example |
|---------|---------|---------|
| `jj git fetch` | Fetch from remote | `jj g fetch` |
| `jj git push` | Push to remote | `jj push` |
| `jj git clone` | Clone git repo | `jj git clone <url>` |
| `jj git init` | Init in git repo | `jj git init --colocate` |
| `jj git export` | Export to .git | `jj git export` |
| `jj git import` | Import from .git | `jj git import` |

### Recovery

| Command | Purpose | Example |
|---------|---------|---------|
| `jj undo` | Undo last operation | `jj undo` |
| `jj redo` | Redo undone operation | `jj redo` |
| `jj op log` | Show operation history | `jj op log` |
| `jj op restore` | Restore to past state | `jj op restore <id>` |
| `jj evolog` | Show change evolution | `jj evolog` |
| `jj restore` | Restore file content | `jj restore <file>` |

### Workspaces

| Command | Purpose | Example |
|---------|---------|---------|
| `jj workspace list` | List workspaces | `jj workspace list` |
| `jj workspace add` | Create workspace | See scripts above |
| `jj workspace forget` | Remove workspace | `jj workspace forget ws` |
| `jj workspace root` | Show workspace root | `jj workspace root` |
| `jj workspace update-stale` | Update stale ws | Auto with config |

### File Operations

| Command | Purpose | Example |
|---------|---------|---------|
| `jj file list` | List tracked files | `jj file list` |
| `jj file show` | Show file at rev | `jj file show @- file.txt` |
| `jj file chmod` | Change permissions | `jj file chmod x script.sh` |
| `jj sparse` | Sparse checkout | `jj sparse set --add dir/` |

---

## Common Workflows

### Daily Work Pattern

```bash
# 1. Start day - fetch latest
jj git fetch

# 2. Check if behind
jj log -r 'main@origin::main'

# 3. Rebase if needed
jj rebase -d main@origin

# 4. Start new work
jj new -m "feat: today's work"

# 5. Work... (changes auto-tracked)

# 6. Describe when ready
jj describe -m "feat(scope): what I did

Detailed description here."

# 7. Move main bookmark
jj bookmark set main -r @

# 8. Push (with user consent)
jj git push
```

### Parallel Features

```bash
# Create feature branches off main
jj new main -m "Feature A"  # Now at feature-a change
jj new main -m "Feature B"  # Creates new change off main

# Switch between them
jj edit <change-id-a>  # Work on A
jj edit <change-id-b>  # Work on B

# Merge both to main when done
jj rebase -r <change-id-a> -d main
jj bookmark set main -r <change-id-a>
jj rebase -r <change-id-b> -d main
jj bookmark set main -r <change-id-b>
```

### Sync with Remote (Before Push)

```bash
# Fetch latest
jj git fetch

# Check divergence
jj log -r 'main@origin..main'  # Local-only commits
jj log -r 'main..main@origin'  # Remote-only commits

# If remote is ahead, rebase
jj rebase -d main@origin

# Then push
jj git push --bookmark main
```

### Clean Up History

```bash
# Squash multiple small commits into one
jj squash --from <start> --into <target>

# Split a big commit
jj split  # Interactive, choose files

# Reword any commit
jj describe -r <rev> -m "new message"
```

---

## Safety Rules

### NEVER Do

1. **NEVER push without explicit user consent**
2. **NEVER use git commands directly** (use jj equivalents)
3. **NEVER assume push will succeed** (always fetch first)
4. **NEVER force push** without extreme caution

### ALWAYS Do

1. **ALWAYS start work with `jj new`** - creates clean change
2. **ALWAYS check `jj log -r 'main@origin::main'`** before pushing
3. **ALWAYS ask user** before any push operation
4. **ALWAYS use headless/non-interactive flags** (see below)

---

## Interactive vs Headless Commands (CRITICAL)

**CRITICAL**: Many jj commands open an editor by default. AI agents MUST use headless flags to avoid hanging.

### Commands That Open Editor (AVOID)

| Command | Opens Editor | Headless Alternative |
|---------|-------------|---------------------|
| `jj describe` | YES - opens $EDITOR | `jj describe -m "message"` |
| `jj squash` | YES - opens $EDITOR | `jj squash -m "message"` |
| `jj split` | YES - interactive | **NO HEADLESS** - ask user |
| `jj commit` | YES - opens $EDITOR | `jj commit -m "message"` |
| `jj resolve` | YES - opens merge tool | **NO HEADLESS** - ask user |

### Always Use These Patterns

```bash
# WRONG - will hang waiting for editor
jj describe
jj squash
jj commit

# RIGHT - provide message inline
jj describe -m "feat: add feature X"
jj squash -m "combine: cleanup commits"
jj commit -m "feat: complete feature"
```

### Commands That Are Safe (Non-Interactive)

These commands never open an editor:

```bash
jj status          # Safe
jj diff            # Safe
jj log             # Safe
jj new -m "msg"    # Safe (with -m)
jj abandon         # Safe
jj git fetch       # Safe
jj git push        # Safe
jj bookmark set    # Safe
jj rebase          # Safe
jj edit            # Safe
jj undo            # Safe
jj op log          # Safe
jj op restore      # Safe
```

### When Interactive is Required

Some commands have no headless mode. For these, **ask the user**:

```bash
# jj split - no headless mode
# Ask user: "I need to split this commit. Can you run `jj split` interactively?"

# jj resolve - needs merge tool
# Ask user: "There are conflicts. Can you resolve them with `jj resolve <file>`?"
```

### Editor Timeout Prevention

If you accidentally run an interactive command:
- The command will hang waiting for editor
- Use Ctrl+C to abort
- Re-run with `-m` flag

---

## Transparency Protocol

When using jj in sessions, provide:

### Inline Explanations

For each jj command, explain:
- What the command does
- Why you're running it
- Expected outcome

```
Running `jj git fetch` - This pulls the latest commits from origin
without modifying the working copy. Needed to check if main is ahead
before attempting to push.
```

### End-of-Session Summary

```markdown
## jj Commands Used This Session

| Command | Purpose |
|---------|---------|
| `jj new -m "feat: ..."` | Started new unit of work |
| `jj git fetch` | Pulled latest from remote |
| `jj describe -m "..."` | Updated commit message |
| `jj bookmark set main -r @` | Moved main to current |
| `jj git push --bookmark main` | Pushed to origin (with consent) |
```

---

## Beads Integration

### ID Correlation Patterns

Beads tasks and jj work should be correlated through consistent naming:

| Bead Task ID | jj Bookmark | jj Workspace | Commit Reference |
|--------------|-------------|--------------|------------------|
| `.dotfiles-abc` | `ws/abc` | `.workspaces/abc/` | `Task: .dotfiles-abc` |
| `.dotfiles-fix-lsp` | `ws/fix-lsp` | `.workspaces/fix-lsp/` | `Task: .dotfiles-fix-lsp` |

### Finding Correlated Work

```bash
# From bead task → find jj work
bd show .dotfiles-abc  # Get task details
jj log -r 'description(".dotfiles-abc")'  # Find commits referencing it
jj bookmark list | grep -i abc  # Find related bookmarks

# From jj bookmark → find bead task
jj log -r 'ws/abc' --no-graph -T 'description'  # Get commit description
bd show .dotfiles-abc  # Look up task by ID extracted from commit

# From workspace → find both
jj-ws-status --json  # Shows associated task ID
bd show $(jj-ws-status --json | jq -r '.task.id')  # Get task details
```

### Workspace Scripts Auto-Correlation (⚠️ WIP)

> **Note**: Workspace scripts are under development. For now, manually correlate
> tasks with commits using the patterns below.

The `jj-ws-*` scripts (when stable) will automatically correlate:

```bash
# jj-ws-claim creates both (WIP)
jj-ws-claim fix-lsp
# Creates: .workspaces/fix-lsp/
# Creates: .dotfiles-fix-lsp (bead task)

# jj-ws-complete references task in close (WIP)
jj-ws-complete
# Closes bead task with: "Completed in workspace fix-lsp [bookmark: ws/fix-lsp]"

# jj-ws-status shows correlation (WIP)
jj-ws-status --json | jq '.task'
# {"id": ".dotfiles-fix-lsp", "status": "in_progress", "title": "..."}
```

**Current Manual Workflow:**
```bash
# 1. Create bead task
bd create fix-lsp -t task -p P2

# 2. Start jj work with reference
jj new -m "fix(lsp): address issue

Task: .dotfiles-fix-lsp"

# 3. Complete and close manually
jj describe -m "fix(lsp): resolved issue

Closes: .dotfiles-fix-lsp"
bd close .dotfiles-fix-lsp
```

### Standard Commit References

Always include task reference in commit messages:

```bash
# Short reference (in commit subject)
jj describe -m "feat(lsp): add diagnostic filtering (.dotfiles-abc)"

# Full reference (in commit body)
jj describe -m "feat(lsp): add diagnostic filtering

Implemented severity-based filtering for LSP diagnostics.
Added configuration for per-language rules.

Task: .dotfiles-abc
Closes: .dotfiles-abc"
```

### Finding Orphaned Work

```bash
# Commits without task references
jj log -r 'all() ~ description("dotfiles-")'

# Workspace bookmarks without closed tasks
for bm in $(jj bookmark list | grep '^ws/' | awk '{print $1}'); do
  task_id=".dotfiles-${bm#ws/}"
  if bd show "$task_id" 2>/dev/null | grep -q "open"; then
    echo "Open task for $bm: $task_id"
  fi
done

# Bead tasks without jj work
bd list --status=open | while read task; do
  if ! jj log -r "description(\"$task\")" --no-graph 2>/dev/null | head -1 | grep -q .; then
    echo "No commits for: $task"
  fi
done
```

### Link in Both Directions

**Starting work (current stable workflow):**
```bash
# 1. Create bead task
bd create fix-lsp -t task -p P2 -d "Fix LSP diagnostic flooding"
# Creates: .dotfiles-fix-lsp

# 2. Start jj work with task reference
jj new -m "fix(lsp): address diagnostic flooding

Task: .dotfiles-fix-lsp"

# 3. Update task status
bd update .dotfiles-fix-lsp --status in_progress
```

**Completing work (current stable workflow):**
```bash
# 1. Describe final commit
jj describe -m "fix(lsp): implement diagnostic filtering

Added severity-based filtering for LSP diagnostics.

Closes: .dotfiles-fix-lsp"

# 2. Move main bookmark
jj bookmark set main -r @

# 3. Close bead task
bd close .dotfiles-fix-lsp --reason "Implemented in $(jj log -r @ --no-graph -T 'change_id.short(8)')"

# 4. ASK USER before pushing
# "Ready to push. Run: jj git push --bookmark main"
```

---

## Known Issues and Limitations

### jj Limitations

1. **No interactive rebase** - use `jj squash`, `jj split` instead
2. **No staging area** - all changes auto-tracked (feature, not bug)
3. **Conflicts stored in tree** - unlike git stash conflicts
4. **Immutable after push** - can't rewrite pushed commits easily

### Common Gotchas

| Issue | Cause | Solution |
|-------|-------|----------|
| "change is immutable" | Commit was pushed | Create new commit instead |
| Bookmark disappeared | Moved unexpectedly | `jj op log` + `jj op restore` |
| Working copy conflict | Auto-merge failed | Edit files, remove markers |
| "no description" warning | Empty commit message | Use `jj describe` |
| Workspace stale | Another workspace changed repo | `jj workspace update-stale` |

### GitHub Actions Interaction

The dotfiles repo has a GitHub Action that updates flake.lock on Sundays. Always:

```bash
jj git fetch  # Get flake.lock updates
jj rebase -d main@origin  # Rebase onto updated main
```

---

## Self-Discovery Patterns

### Finding Commands

```bash
# List all commands
jj help

# Help for specific command
jj help <command>
jj describe --help

# Search command help
jj help | grep -i <keyword>
```

### Exploring Configuration

```bash
# List all config
jj config list

# Show specific config
jj config get <key>

# Config file location
jj config path --user
jj config path --repo
```

### Inspecting Repository State

```bash
# All changes
jj log -r 'all()'

# All bookmarks
jj bookmark list

# Operation history
jj op log

# Change evolution
jj evolog

# Workspace state
jj-ws-status --json
```

### Revset Debugging

```bash
# Test revset (dry run)
jj log -r '<revset>' --no-graph

# Count matches
jj log -r '<revset>' --no-graph | wc -l

# Show IDs only
jj log -r '<revset>' --no-graph -T 'change_id.short()'
```

### Official Resources

- **jj book**: https://martinvonz.github.io/jj/latest/
- **GitHub**: https://github.com/martinvonz/jj
- **Discord**: https://discord.gg/dkmfj3aGQN

---

## Directory Structure

```
~/.dotfiles/                          # Main workspace (default)
├── .jj/                              # jj data directory
│   ├── repo/                         # Repository data
│   │   ├── store/                    # Object store
│   │   └── op_store/                 # Operation store
│   ├── working_copy/                 # Working copy state
│   └── workspace-ops.lock/           # Concurrent op lock (created by scripts)
│
├── .workspaces/                      # Secondary workspaces (gitignored)
│   └── <workspace-name>/             # Created by jj-ws-claim
│       ├── .jj/                      # Points to main repo
│       └── (files)                   # Working copy
│
├── bin/                              # Custom scripts
│   ├── jj-ws-claim                   # Create workspace
│   ├── jj-ws-complete                # Complete workspace
│   ├── jj-ws-push                    # Push workspace work
│   └── jj-ws-status                  # Get workspace status
│
└── _docs/                            # Research/documentation
    ├── jj-workspace-conventions.md   # Naming conventions
    └── jj-workspaces-research.md     # Implementation research
```

---

## Quick Troubleshooting

### "Change is immutable"

```bash
# Can't modify pushed commits
# Solution: create new change instead
jj new -m "fix: corrected version"
```

### "Bookmark moved unexpectedly"

```bash
jj op log  # Find when it moved
jj op restore <op-id>  # Restore previous state
```

### "Working copy is stale"

```bash
# Usually auto-resolves with auto-update-stale=true
jj workspace update-stale
```

### "Conflicts in working copy"

```bash
jj status  # See conflicted files
# Edit files to resolve <<<<<<< markers
jj status  # Verify resolved
```

### "Can't push - remote ahead"

```bash
jj git fetch
jj log -r 'main..main@origin'  # See what's new
jj rebase -d main@origin  # Rebase onto remote
jj git push  # Now push
```

### Lost Work

```bash
jj op log  # Find operation before loss
jj op restore <op-id>  # Restore

# Or find via evolution log
jj evolog  # Shows all versions of current change
```
