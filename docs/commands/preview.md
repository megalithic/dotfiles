---
description: Smart preview - opens content in appropriate viewer in a tmux pane (context-aware)
allowed-tools: Bash(tmux:*), Bash(bd:*), Bash(jj:*), Bash(nvim:*), Bash(preview:*), Bash(preview-ai:*), Read, Write
---

# Smart Preview Command

Opens content in an appropriate viewer in a managed tmux pane. Handles pane lifecycle (reuse/cleanup) automatically.

**CRITICAL SAFETY**: Use `preview-ai` script for all previews to ensure the AI agent's pane is NEVER replaced.

## Primary Tool: `preview-ai`

The `bin/preview-ai` script is the safe way to preview content from AI agent sessions:

```bash
# Explicit type
preview-ai json '{"foo": "bar"}'
preview-ai diff -r @
preview-ai bead .dotfiles-t7f
preview-ai file /path/to/file.lua
preview-ai log -n 5
preview-ai markdown "# Hello"

# Auto-detect (type can be omitted)
preview-ai .dotfiles-t7f             # → bead
preview-ai /path/to/file.lua         # → file
preview-ai '{"foo": "bar"}'          # → json
```

**Safety guarantees:**
- NEVER renders in caller's pane (`$TMUX_PANE`)
- Only searches CURRENT session/window for existing previews (no cross-session interference)
- Automatically reuses/replaces existing preview pane
- Returns focus to caller pane after creating preview

## Context Awareness (CRITICAL)

When user runs `/preview` with no arguments or partial arguments, **infer from recent conversation**:

1. **Look at what was just discussed**:
   - Did I just mention a bead task ID? → Preview that bead
   - Did I just suggest running a command? → Preview that command's output
   - Did I just reference a file path? → Preview that file
   - Did I just show a diff? → Preview the full diff
   - Did I just mention a screenshot/image? → Preview that image

2. **Arguments provided** (`$ARGUMENTS`):
   - If explicit args given, use those
   - Examples: `/preview .dotfiles-t7f`, `/preview diff -r @`

3. **Ask if ambiguous**:
   - If multiple candidates exist and it's unclear, ask which one to preview
   - "Did you want me to preview the bead task or the diff I mentioned?"

## Pre-flight (MANDATORY)

Before ANY preview operation:

1. **Check for existing preview pane**:
   ```fish
   tmux list-panes -F "#{pane_index} #{pane_title}" | grep -q "preview"
   ```

2. **Kill existing preview pane if found** (to avoid orphans):
   ```fish
   tmux kill-pane -t preview 2>/dev/null || true
   ```

3. **Create new pane with title** for tracking:
   ```fish
   tmux split-window -h -p 40 -t "{current}" "fish -c 'printf \"\\033]2;preview\\033\\\\\\"; <command>; read'"
   ```

## Content Type Routing

Determine the content type from context or explicit request, then route appropriately:

### Beads Task/Epic (`bead <id>`)

Show bead details in a pane:

```fish
tmux split-window -h -p 45 "fish -c 'bd show <id>; read'"
```

**When to use**: User asks to "see" or "show" a bead task/epic

**Future**: Convert to proper markdown and open in nvim (tracked in .dotfiles-alq epic)

### Diff Output (`diff [args]`)

Show jj diff directly in pane with syntax highlighting:

```fish
tmux split-window -h -p 50 "jj diff $args | delta; read"
```

Or for specific revisions:
```fish
tmux split-window -h -p 50 "jj diff -r <rev> | delta; read"
```

**When to use**: User asks to see diff, changes, or compare revisions

### Image/Screenshot (`image <path>`)

Use the preview binary to display:

```fish
tmux split-window -h -p 50 "preview $path; read"
```

**When to use**: User asks to see a screenshot, image, or visual output

### Log Output (`log [args]`)

Show jj log with graph:

```fish
tmux split-window -h -p 45 "jj log $args --no-pager; read"
```

**When to use**: User asks to see history, commits, or log

### File Preview (`file <path>`)

Open file in nvim (read-only for previewing):

```fish
tmux split-window -h -p 50 "nvim -R $path; read"
```

For non-text files, use appropriate viewer:
- PDF: `open $path` (macOS Preview)
- Image: `preview $path`

**When to use**: User asks to see a file's contents

### Command Output (`cmd <command>`)

Run arbitrary command in pane:

```fish
tmux split-window -h -p 45 "fish -c '$command'; read"
```

**When to use**: User wants to see output of any command

### JSON/Structured Data (`json <content>`)

Pretty-print and show in pane:

```fish
echo '$content' | jq . | bat -l json
```

Or write to temp file and open in nvim for navigation.

## Pane Management Rules

1. **Always check for orphan panes first** - list and clean up
2. **Use consistent pane title** (`preview`) for tracking
3. **Default split**: horizontal, 40-50% width on right
4. **Always end with `read`** to keep pane open until user dismisses
5. **Clean up temp files** after viewer closes

## Inference Rules

When user says... | Content Type | Action
------------------|--------------|--------
"show me task X" | bead | `bd show X` → nvim markdown
"what's the diff" | diff | `jj diff` → pane with delta
"see the changes" | diff | `jj diff` → pane with delta
"show that image" | image | `preview <path>` → pane
"see the log" | log | `jj log` → pane
"look at file X" | file | `nvim -R X` → pane
"show me X.png" | image | `preview X.png` → pane
"run X and show me" | cmd | `fish -c 'X'` → pane

## Example Invocations

User: "show me .dotfiles-t7f"
→ Create temp markdown from `bd show .dotfiles-t7f`, open in nvim

User: "what changed in the last commit"
→ `jj diff -r @-` in pane with delta

User: "preview that screenshot"
→ `preview /path/to/screenshot.png` in pane

User: "/preview bead shade-cgn"
→ Explicit bead preview

User: "/preview diff -r @"
→ Explicit diff preview
