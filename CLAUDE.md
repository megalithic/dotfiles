## Your response and general tone

- Never compliment me.
- Criticize my ideas, ask clarifying questions, and include both funny and
  humorously insulting comments when you find mistakes in the codebase or
  overall bad ideas or code.
- Be skeptical of my ideas and ask questions to ensure you understand the
  requirements and goals.
- Rate confidence (1-100) before and after saving and before task completion.

## Your required tasks for every conversation

- You are to always utilize the `~/bin/ntfy` script to send notifications,
  taking special note of your ability to utilize tools on this system to
  determine which notification method(s) to use at any given moment.

### ntfy Usage

```bash
# Basic usage
ntfy send -t "Title" -m "Message"

# With urgency levels: normal|high|critical
ntfy send -t "Title" -m "Message" -u high

# Send via Pushover (for remote notifications when away from desk)
ntfy send -t "Title" -m "Message" -P

# Send to phone via iMessage
ntfy send -t "Title" -m "Message" -p

# Track as question (will retry with reminders if unanswered)
ntfy send -t "Question" -m "Should I continue?" -q

# Mark a question as answered
ntfy answer -t "Question" -m "Should I continue?"

# List pending questions
ntfy pending
```

**Source detection**: ntfy auto-detects the calling program and prefixes the title (e.g., `[claude] Task Done`). Use `-S` to disable or `-s myapp` to override.

**Routing behavior**: ntfy automatically detects attention state:
- `paying_attention` → subtle macOS notification only
- `terminal_not_focused` → canvas overlay
- `display_asleep`/`screen_locked` → phone (if critical/requested)

**Phone notifications**: Uses iMessage with `🤖 [from hammerspork]` prefix. Phone number is auto-fetched from macOS Contacts.

## General Workflow

- When working in this repo (dotfiles-nix), always check the `justfile` to see available commands
- To rebuild darwin, use `sudo darwin-rebuild switch --flake ./` - this produces clean, verifiable output
- Avoid `just mac` and `nh darwin switch` as they produce excessive animated output that's hard to verify success/failure

## Hammerspoon

- **Configuration file**: Always check `config/hammerspoon/config.lua` first for settings, constants, and configuration including:
  - Display names (`C.displays.internal`, `C.displays.external`)
  - App bundle IDs and layouts (`C.launchers`, `C.layouts`)
  - Paths to resources (`C.paths`)
  - Notification settings
  - Any hardcoded values - prefer using config over hardcoding
- **Reloading Hammerspoon**: Use `timeout` to prevent hanging, then verify via notification database:
  ```bash
  RELOAD_TIME=$(date +%s)
  timeout 2 hs -c "hs.reload()" 2>&1 || true
  sqlite3 ~/.local/share/hammerspoon/hammerspoon.db "SELECT timestamp FROM notifications WHERE sender = 'hammerspork' AND message = 'config is loaded.' AND timestamp >= $RELOAD_TIME LIMIT 1" && echo "✓ Reloaded"
  ```
  - `timeout` is required because hs.reload() destroys the Lua interpreter, causing the CLI command to hang
  - The timeout is expected and normal - reload succeeds even though the command times out
  - Notification database path: `~/.local/share/hammerspoon/hammerspoon.db`
  - Do NOT use sleep - check the database immediately after the timeout
- for any and all changes to hammerspoon, you must verify that there are NO workspace or document diagnostic errors before attempting to reload hammerspoon; that you always check online documentation and references (never assume); and that cpu and memory efficiency are of absolute importance (we can't have the operating system crash or become laggy because of hammerspoon scripts).

## Version Control with Jujutsu (jj)

**CRITICAL**: ALWAYS use `jj` commands instead of `git` for ALL version control operations in this repo. NEVER use raw git commands directly.

### Command Mappings (use jj, not git)

| Instead of...              | Use...                                      |
|----------------------------|---------------------------------------------|
| `git status`               | `jj status`                                 |
| `git diff`                 | `jj diff`                                   |
| `git add` + `git commit`   | `jj describe` (changes are auto-tracked)   |
| `git log`                  | `jj log`                                    |
| `git stash`                | Not needed (jj auto-snapshots)             |
| `git pull --rebase`        | `jj git fetch` + `jj rebase -d main`       |
| `git push`                 | `jj git push`                              |
| `git fetch`                | `jj git fetch`                             |
| `git checkout -b`          | `jj new -m "description"`                  |
| `git branch`               | `jj branch list` or `jj log`               |

### Core Workflow (CRITICAL - Must Follow)

**BEFORE starting ANY new unit of work or task:**
1. **ALWAYS run `jj new -m "Brief description of task"`** - This is non-negotiable
2. **When switching tasks**: Claude MUST confirm with the user: "We're changing tasks - should I run `jj new -m '...'` before we start?"
3. **Accountability**: Claude helps keep the user accountable too - if they ask to start something new without a `jj new`, remind them

**During work:**
1. **Work iteratively**: Make changes, test, iterate
2. **Document when complete**: Run `jj describe` and write a comprehensive description including:
   - What was changed and why
   - Key implementation details
   - Any breaking changes or important notes
   - Related context (e.g., "Fixes notification system regression on macOS Sequoia")

**After completing a unit of work (when user says to push/commit):**
1. **Move main to current commit**: `jj bookmark set main -r @`
2. **Push main to GitHub**: `jj git push --bookmark main`
3. **Start fresh for next task**: `jj new`
4. **If work accumulated without proper commits**: Use `jj split` with filesets to organize retroactively

**Bookmark workflow:**
- Feature bookmarks (e.g., `feat/cool-thing`) are for tracking work-in-progress
- `main` bookmark should always reflect what's on GitHub origin/main
- After pushing to main, the feature bookmark becomes historical (can delete or leave)
- Statusline shows: `jj:bookmark-name* (change_id)` where `*` = unpushed changes

### Key Commands

- `jj status` - Show working copy changes
- `jj log` - View change history
- `jj new -m "message"` - Create new change (starts fresh unit of work)
- `jj describe` - Document current change with detailed message
- `jj squash` - Merge current change into parent (for cleaning up)
- `jj split` - Split current change into multiple changes (for organizing)
- `jj abandon` - Discard current change if work is unwanted
- `jj op log` - View operation history (undo/recovery)
- `jj op restore <id>` - Restore to previous state

### Benefits for AI-Assisted Development

- **Automatic snapshots**: Jj automatically captures working copy state
- **Safe experimentation**: Easy to abandon or squash messy changes
- **Clean history**: Use describe/squash/split to curate clean commits afterward
- **Never lose work**: Operation log (`jj op log`) tracks everything
- **Mutable changes**: Can edit any change, automatic rebasing of descendants

### Parallel Work (Advanced)

For working on multiple features simultaneously:
```bash
# Create separate changes off main
jj new main -m "Feature A"  # Creates change abc123
jj new main -m "Feature B"  # Creates change def456

# Switch between them
jj edit abc123  # Work on Feature A
jj edit def456  # Work on Feature B
```

### Current State

This repo is already jj-initialized with git coexistence. Always check `jj status` before starting work to see current state.

## CLI Tool Preferences

**CRITICAL**: Use modern CLI tools instead of legacy UNIX commands:

| Instead of... | Use...   | Notes                                      |
|---------------|----------|--------------------------------------------|
| `find`        | `fd`     | Faster, respects .gitignore by default     |
| `grep`        | `rg`     | Faster, respects .gitignore, better output |

### fd (find replacement)

```bash
# Find files by name pattern
fd "\.lua$"                      # Find all .lua files
fd -e lua                        # Same, using extension flag
fd config                        # Find files/dirs containing "config"
fd -t f config                   # Files only (-t d for directories)

# Find in specific directory
fd -e nix modules/               # Find .nix files in modules/

# Include hidden/ignored files
fd -H "\.env"                    # Include hidden files
fd -I node_modules               # Include gitignored files
fd -HI "secret"                  # Include both

# Execute command on results
fd -e lua -x wc -l               # Count lines in each lua file
fd -e test.ts -X prettier -w     # Format all test files (all at once)
```

### rg (grep replacement)

```bash
# Basic search
rg "TODO"                        # Search for TODO in current dir
rg -i "error"                    # Case-insensitive search
rg -w "app"                      # Whole word only (not "application")

# File filtering
rg "import" -t lua               # Search only in Lua files
rg "config" -g "*.nix"           # Search with glob pattern
rg "test" -g "!*.md"             # Exclude markdown files

# Context
rg "function" -A 3               # Show 3 lines after match
rg "function" -B 2               # Show 2 lines before match
rg "function" -C 2               # Show 2 lines before and after

# File listing (like find)
rg --files                       # List all files (respects .gitignore)
rg --files -g "*.lua"            # List only .lua files
rg --files | rg config           # Pipe to filter filenames

# Advanced
rg -l "TODO"                     # List files with matches only
rg -c "TODO"                     # Count matches per file
rg --json "pattern"              # JSON output for parsing
rg -U "multi\nline"              # Multiline matching
```

### Combined Examples

```bash
# Find large Lua files
fd -e lua -x wc -l | sort -n

# Search for pattern in specific file types
rg "hs\." -t lua

# Find and search in one go
fd -e lua -x rg "require"

# Find files modified recently (fd doesn't do this, use find or ls)
fd -e lua --changed-within 1d
```

## Git Hooks

**Pre-commit hook** (`.githooks/pre-commit`): Blocks commits containing symlinks to `/nix/store/`. These are ephemeral build artifacts that should never be version controlled.

To install hooks after cloning:
```bash
git config core.hooksPath .githooks
```

**CRITICAL**: Never commit symlinks pointing to `/nix/store/` - they are machine-specific and will break on other systems or after garbage collection.

## Configuration Validation

**CRITICAL**: Never assume existing configuration values are complete or accurate.

- When config lists specific values (focus modes, app bundles, patterns, etc.), **ask if there are others not listed**
- Comments in config may be outdated or wrong — verify them independently
- Before writing "all" or "complete" in comments, **verify that's actually true**
- When in doubt, ask the user or research programmatically (e.g., query system APIs)
- This prevents bugs and breaking changes caused by false assumptions

**Example failure**: Config had 3 focus modes listed, assumed that was "all" when user actually had 9 configured. Wrote "Override ALL focus modes" comment that was completely wrong.

## General Conventions

- When creating shell scripts that take arguments, always assume we want long and short form arguments supported.
- When working through nix-related code, remember, I am on macOS, so I use nix-darwin. I am also on aarch64-darwin architecture.
- Any markdown documents you create, without my explicit request, should always go into a _docs folder in the root of the CWD you were called from. So, for this CWD, `.dotfiles-nix` which is the dotfiles-nix repo for my github user @megalithic, any docs that you auto-generate (again, ones that i didn't explicitly ask you to create), should go into .dotfiles-nix/_docs (and that directory should be added to .gitignore)
- Always check that the remote origin/main isn't ahead of us before trying to push to main on github. Remember that we have a github workflow that gets the latest flake updates, so we need to pull the latest lock file from remote origin/main.
