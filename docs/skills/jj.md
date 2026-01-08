---
name: jj
description: Jujutsu (jj) version control workflow, commands, and best practices. Use when working with version control in jj-enabled repos. Covers commits, bookmarks, workspaces, and safe push patterns.
tools: Bash
---

# Jujutsu (jj) Version Control

## Overview

**CRITICAL**: Always use `jj` commands instead of `git` for ALL version control operations in jj-enabled repos. Never use raw git commands directly.

Jujutsu is a Git-compatible VCS with automatic snapshots, mutable history, and conflict-free parallel work.

## Command Mappings (jj vs git)

| Instead of... | Use... |
|---------------|--------|
| `git status` | `jj status` |
| `git diff` | `jj diff` |
| `git add` + `git commit` | `jj describe` (changes auto-tracked) |
| `git log` | `jj log` |
| `git stash` | Not needed (auto-snapshots) |
| `git pull --rebase` | `jj git fetch` + `jj rebase -d main` |
| `git push` | `jj git push` |
| `git checkout -b` | `jj new -m "description"` |
| `git branch` | `jj bookmark list` or `jj log` |

## Core Workflow

### Starting Work (MANDATORY)

**ALWAYS run `jj new -m "description"` before starting any new task:**

```bash
# Start new unit of work
jj new -m "feat: add user authentication"

# This creates a fresh change, preserving the parent
```

### During Work

```bash
# Check status
jj status

# See diff of current changes
jj diff

# See full log
jj log

# Describe/update commit message
jj describe -m "better description of what was done"
```

### Completing Work

```bash
# 1. Describe the change thoroughly
jj describe -m "feat(auth): implement JWT token validation

- Add token parsing middleware
- Validate expiry and signature
- Return 401 on invalid tokens

Related: .dotfiles-abc (bead task)"

# 2. Move bookmark to current commit
jj bookmark set main -r @

# 3. Start fresh for next task
jj new
```

### Pushing to Remote

**NEVER push without explicit user consent:**

```bash
# Check what would be pushed
jj log -r 'main@origin::main'

# Push (only after user approval)
jj git push --bookmark main
```

## Key Commands Reference

### Status and Inspection

```bash
jj status              # Working copy changes
jj log                 # Change history (graph)
jj log --no-graph      # Linear log
jj log -r 'all()'      # All changes
jj diff                # Current change diff
jj diff -r @-          # Parent change diff
jj show                # Show current change details
```

### Creating and Modifying Changes

```bash
jj new -m "message"    # New change with message
jj new main            # New change based on main
jj describe            # Edit current change message (opens editor)
jj describe -m "msg"   # Set message directly
jj edit <change_id>    # Switch to editing a different change
jj abandon             # Discard current change
```

### Organizing History

```bash
jj squash              # Merge current into parent
jj squash --into <id>  # Merge current into specific change
jj split               # Split current change into multiple
jj rebase -d main      # Rebase current onto main
jj rebase -r @ -d <id> # Rebase current onto specific change
```

### Bookmarks (like git branches)

```bash
jj bookmark list              # List all bookmarks
jj bookmark set main -r @     # Move main to current change
jj bookmark create feat -r @  # Create new bookmark
jj bookmark delete feat       # Delete bookmark
```

### Git Integration

```bash
jj git fetch           # Fetch from remote
jj git push            # Push current bookmark
jj git push --bookmark main  # Push specific bookmark
jj git push --all      # Push all bookmarks
```

### Recovery

```bash
jj op log              # Operation history (undo/recovery)
jj op restore <id>     # Restore to previous state
jj undo                # Undo last operation
```

## Workspace Workflow (Advanced)

For parallel work across multiple features:

```bash
# Create separate changes off main
jj new main -m "Feature A"  # Creates change abc123
jj new main -m "Feature B"  # Creates change def456

# Switch between them
jj edit abc123  # Work on Feature A
jj edit def456  # Work on Feature B
```

## Safety Rules

1. **NEVER push without user consent** - Always ask first
2. **NEVER use git commands directly** - Use jj equivalents
3. **ALWAYS start with `jj new`** - Before any new task
4. **Commits are cheap, pushes are permanent** - Commit freely

## Transparency Requirements

When using jj, provide:

### 1. Inline Explanations

For each jj command, explain:
- What the command does
- Why you're running it
- Expected outcome

Example:
```
Running `jj git fetch` - This pulls the latest commits from origin 
without modifying the working copy. Needed to check if main is ahead.
```

### 2. End-of-Session Summary

Before ending a session, provide:

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

## Beads Integration

Link jj work to bead tasks:

```bash
# Start work on a bead task
bd update .dotfiles-abc --status in_progress
jj new -m "feat: implement feature (abc)"

# Complete work
jj describe -m "feat: implement feature

Detailed description here.

Closes: .dotfiles-abc"
bd close .dotfiles-abc --reason "Implemented in commit xyz"
```

## Common Patterns

### Sync with Remote

```bash
jj git fetch
jj rebase -d main@origin  # Rebase onto remote main
```

### Prepare for Push

```bash
# Check divergence
jj log -r 'main@origin::main'

# If behind, rebase first
jj rebase -d main@origin
```

### Fix Last Change

```bash
# Edit the message
jj describe -m "corrected message"

# Squash small fix into parent
jj squash
```

### Abandon Experimental Work

```bash
jj abandon  # Current change
jj abandon <id>  # Specific change
```

## Troubleshooting

### "Change is immutable"
The change has been pushed. Create a new change instead of modifying.

### "Bookmark moved unexpectedly"
Run `jj op log` to see what happened, `jj op restore` to recover.

### "Conflicts detected"
Jujutsu tracks conflicts in the tree. Edit files to resolve, then `jj status` to verify.
