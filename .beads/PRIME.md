# Beads Workflow Context

> **Context Recovery**: Run `bd prime` after compaction, clear, or new session
> Hooks auto-call this in Claude Code when .beads/ detected

# SESSION CLOSE PROTOCOL

**CRITICAL**: Before saying "done" or "complete", you MUST run this checklist:

```
[ ] 1. git status              (check what changed)
[ ] 2. git add <files>         (stage code changes)
[ ] 3. bd sync --from-main     (pull beads updates from main)
[ ] 4. git commit -m "..."     (commit code changes)
```

**Note:** This is an ephemeral branch (no upstream). Code is merged to main locally, not pushed.

## Core Rules
- Track strategic work in beads (multi-session, dependencies, discovered work)
- Use `bd create` for issues, TodoWrite for simple single-session execution
- When in doubt, prefer bd—persistence you don't need beats lost context
- Git workflow: hooks auto-sync, run `bd sync` at session end
- Session management: check `bd ready` for available work

## Essential Commands

### Finding Work
- `bd ready` - Show issues ready to work (no blockers)
- `bd list --status=open` - All open issues
- `bd list --status=in_progress` - Your active work
- `bd show <id>` - Detailed issue view with dependencies

### Creating & Updating
- `bd create --title="..." --type=task|bug|feature --priority=2` - New issue
  - Priority: 0-4 or P0-P4 (0=critical, 2=medium, 4=backlog). NOT "high"/"medium"/"low"
- `bd update <id> --status=in_progress` - Claim work
- `bd update <id> --assignee=username` - Assign to someone
- `bd close <id>` - Mark complete
- `bd close <id1> <id2> ...` - Close multiple issues at once (more efficient)
- `bd close <id> --reason="explanation"` - Close with reason
- **Tip**: When creating multiple issues/tasks/epics, use parallel subagents for efficiency

### Dependencies & Blocking
- `bd dep add <issue> <depends-on>` - Add dependency (issue depends on depends-on)
- `bd blocked` - Show all blocked issues
- `bd show <id>` - See what's blocking/blocked by this issue

### Sync & Collaboration
- `bd sync --from-main` - Pull beads updates from main (for ephemeral branches)
- `bd sync --status` - Check sync status without syncing

### Project Health
- `bd stats` - Project statistics (open/closed/blocked counts)
- `bd doctor` - Check for issues (sync problems, missing hooks)

## Cross-Repo Workflow (IMPORTANT)

This repo is configured for **bidirectional cross-repo beads** with Shade (`~/code/shade`).

### Architecture
```
DOTFILES (.dotfiles)              SHADE (~/code/shade)
├── .dotfiles-* (native)    ←→    ├── shade-* (native)
└── shade-* (hydrated, r/o)       └── .dotfiles-* (hydrated, r/o)
```

### Rules
1. **Issues live in their native repo** based on prefix:
   - `shade-*` issues → created/edited in Shade repo
   - `.dotfiles-*` issues → created/edited in dotfiles repo

2. **Cross-repo visibility**: Both repos hydrate each other's issues (read-only)
   - You can SEE and DEPEND ON foreign issues
   - Edits happen in the source repo only

3. **Creating cross-repo work**:
   ```bash
   # From dotfiles, create a Shade task:
   bd create --title "Fix Swift thing" --type task --repo ~/code/shade
   # Creates shade-xyz in Shade's .beads/issues.jsonl

   # From Shade, create a dotfiles task:
   bd create --title "Install libvips via Nix" --type task --repo ~/.dotfiles
   # Creates .dotfiles-abc in dotfiles' .beads/issues.jsonl
   ```

4. **Cross-repo dependencies work**:
   ```bash
   bd dep add shade-xyz .dotfiles-abc  # Shade task blocked by dotfiles task
   ```

5. **Sync propagates changes**: Run `bd repo sync` to update hydrated copies

### Anti-Patterns (DO NOT)
- **DON'T** create duplicate issues (e.g., both `shade-cgn` AND `.dotfiles-cgn` for same work)
- **DON'T** edit hydrated (foreign-prefix) issues locally—edit in source repo
- **DON'T** create `shade-*` issues directly in dotfiles—use `--repo ~/code/shade`

## Common Workflows

**Starting work:**
```bash
bd ready           # Find available work
bd show <id>       # Review issue details
bd update <id> --status=in_progress  # Claim it
```

**Completing work:**
```bash
bd close <id1> <id2> ...    # Close all completed issues at once
bd sync --from-main         # Pull latest beads from main
git add . && git commit -m "..."  # Commit your changes
# Merge to main when ready (local merge, not push)
```

**Creating dependent work:**
```bash
# Run bd create commands in parallel (use subagents for many items)
bd create --title="Implement feature X" --type=feature
bd create --title="Write tests for X" --type=task
bd dep add beads-yyy beads-xxx  # Tests depend on Feature (Feature blocks tests)
```

**Cross-repo task assignment:**
```bash
# From dotfiles: "Shade needs to implement OCR"
bd create --title="Implement VisionKit OCR" --type=task --repo ~/code/shade

# From Shade: "Dotfiles needs to install a library"
bd create --title="Add libvips to brew.nix" --type=task --repo ~/.dotfiles
```
