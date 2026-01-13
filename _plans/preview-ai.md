# Preview-AI Implementation Plan

## Problem Statement

The current `/preview` command pattern uses `tmux split-window -t "{current}"` which SHOULD create a new pane by splitting. However, there are issues:
1. Output could accidentally render in the AI session pane
2. No consistent pane reuse mechanism exists
3. Content type routing is manual in the command prompt
4. **BUG**: Searching all panes with `-a` flag could find/kill preview panes in OTHER tmux sessions

User requirement: "you CANNOT and MUST NOT render the preview in the current tmux pane that has claude code, opencode, or any other ai agent in it."

## Solution: `bin/preview-ai` Shell Script

Create a dedicated `bin/preview-ai` bash script that:
1. **NEVER** runs commands in the caller's pane (`$TMUX_PANE`)
2. **ALWAYS** creates/reuses a dedicated "ai-preview" titled pane
3. **SESSION-SCOPED**: Only searches current session+window for existing preview panes
4. Handles multiple content types with auto-detection
5. Is invoked by the `/preview` command

## Insights from [claude-canvas](https://github.com/dvdsgl/claude-canvas)

Key patterns borrowed:
- **tmux split-pane spawning** as core mechanism (same approach)
- **Command-driven interface** - verb-noun pattern: `preview-ai json '...'`
- **IPC consideration** - future enhancement could add socket-based updates

## Implementation Details

### Script: `bin/preview-ai`

```bash
#!/usr/bin/env bash
# preview-ai - Safe preview pane manager for AI agents
# CRITICAL: Never renders in caller's pane
# CRITICAL: Only searches CURRENT session/window for existing preview panes

set -euo pipefail

CALLER_PANE="$TMUX_PANE"  # Pane to NEVER touch
PREVIEW_TITLE="ai-preview"
SPLIT_PERCENT=45

# Get current session and window (for scoped pane search)
get_current_session() {
    tmux display-message -p '#{session_name}'
}

get_current_window() {
    tmux display-message -p '#{window_index}'
}

# Find existing preview pane by title - SCOPED TO CURRENT SESSION/WINDOW ONLY
# This prevents killing preview panes in other projects/sessions
find_preview_pane() {
    local session=$(get_current_session)
    local window=$(get_current_window)

    # List panes ONLY in current window (no -a flag!)
    tmux list-panes -t "${session}:${window}" -F "#{pane_id} #{pane_title}" 2>/dev/null \
        | grep "$PREVIEW_TITLE" | head -1 | cut -d' ' -f1
}

# Kill existing preview pane if found (session-scoped)
cleanup_preview() {
    local existing=$(find_preview_pane)
    if [[ -n "$existing" ]]; then
        tmux kill-pane -t "$existing" 2>/dev/null || true
    fi
}

# Create new preview pane (split from caller, lands on RIGHT)
create_preview_pane() {
    local cmd="$1"
    cleanup_preview

    # Split horizontally, new pane on right
    # The command runs IN the new pane, not in CALLER_PANE
    tmux split-window -h -p "$SPLIT_PERCENT" -t "$CALLER_PANE" \
        "printf '\\033]2;${PREVIEW_TITLE}\\033\\\\'; $cmd; echo; read -n1 -rsp '[press any key to close]'"
}

# Auto-detect content type from first arg
detect_type() {
    local arg="$1"
    case "$arg" in
        *.json|*.jsonc)          echo "json" ;;
        *.md)                    echo "markdown" ;;
        .dotfiles-*|shade-*)     echo "bead" ;;
        diff)                    echo "diff" ;;
        log)                     echo "log" ;;
        cmd:*)                   echo "cmd" ;;
        *)
            # Check if it's a file
            if [[ -f "$arg" ]]; then
                local mime=$(file --mime-type -b "$arg" 2>/dev/null)
                case "$mime" in
                    image/*) echo "image" ;;
                    *)       echo "file" ;;
                esac
                return
            fi
            # Check if JSON-like
            [[ "$arg" == "{"* || "$arg" == "["* ]] && echo "json" && return
            # Check if markdown-like
            [[ "$arg" == "#"* ]] && echo "markdown" && return
            echo "text"
            ;;
    esac
}

# Build preview command for given type and content
build_preview_cmd() {
    local type="$1"
    shift
    local content="$*"

    case "$type" in
        json)
            # Handle both inline JSON and file paths
            if [[ -f "$content" ]]; then
                echo "jq -C . '$content' 2>/dev/null || bat -l json '$content'"
            else
                echo "echo '$content' | jq -C . 2>/dev/null || echo '$content' | bat -l json"
            fi
            ;;
        markdown)
            if [[ -f "$content" ]]; then
                echo "glow -p -s dark -w 120 '$content'"
            else
                echo "echo '$content' | glow -p -s dark -w 120"
            fi
            ;;
        diff)
            # Exclude noisy beads jsonl from diff output using jj fileset negation
            # Syntax: 'all() & ~glob:".beads/**"' excludes .beads directory
            if [[ -z "$content" || "$content" == "-r"* ]]; then
                # If no path args or just revision args, add the exclusion fileset
                echo "jj diff $content 'all() & ~glob:\".beads/**\"' | delta"
            else
                # User specified paths, use as-is
                echo "jj diff $content | delta"
            fi
            ;;
        log)      echo "jj log $content --no-pager" ;;
        bead)     echo "bd show '$content'" ;;
        file)     echo "bat --style=numbers --color=always '$content'" ;;
        image)    echo "preview '$content'" ;;  # Delegate to existing preview script
        cmd)      echo "${content#cmd:}" ;;
        text|*)
            if [[ -f "$content" ]]; then
                echo "bat --style=numbers --color=always '$content'"
            else
                echo "echo '$content' | bat -l txt"
            fi
            ;;
    esac
}

# Show usage
usage() {
    cat <<EOF
preview-ai - Safe preview pane manager for AI agents

Usage: preview-ai [type] [content/args...]

Types:
  json      JSON content (inline or file path)
  markdown  Markdown content (inline or file path)
  diff      jj diff arguments (e.g., "-r @")
  log       jj log arguments (e.g., "-n 5")
  bead      Bead task ID (e.g., ".dotfiles-t7f")
  file      File path to preview with bat
  image     Image file path
  cmd       Shell command to execute (prefix with "cmd:")
  auto      Auto-detect type (default)

Examples:
  preview-ai json '{"foo": "bar"}'
  preview-ai diff -r @
  preview-ai bead .dotfiles-t7f
  preview-ai file /path/to/file.lua
  preview-ai cmd:jj status
  preview-ai markdown "# Hello World"
  preview-ai auto .dotfiles-t7f

Safety:
  - NEVER renders in caller's pane (\$TMUX_PANE)
  - Only searches CURRENT session/window for existing previews
  - Reuses existing preview pane (kills and recreates)
EOF
}

# Main
main() {
    # Check if we're in tmux
    if [[ -z "${TMUX:-}" ]]; then
        echo "ERROR: preview-ai must be run inside tmux" >&2
        exit 1
    fi

    # Handle help
    if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
        usage
        exit 0
    fi

    # Handle no args
    if [[ $# -eq 0 ]]; then
        usage
        exit 1
    fi

    local type="${1:-auto}"
    shift || true

    # Auto-detect if type is "auto" or looks like content
    if [[ "$type" == "auto" ]]; then
        type=$(detect_type "${1:-}")
    elif [[ ! "$type" =~ ^(json|markdown|diff|log|bead|file|image|cmd|text)$ ]]; then
        # First arg wasn't a type, treat it as content
        set -- "$type" "$@"
        type=$(detect_type "$type")
    fi

    local preview_cmd=$(build_preview_cmd "$type" "$@")
    create_preview_pane "$preview_cmd"
}

main "$@"
```

### Interface

```bash
preview-ai [type] [content/args...]

# Explicit type:
preview-ai json '{"foo": "bar"}'
preview-ai diff -r @
preview-ai bead .dotfiles-t7f
preview-ai file /path/to/file.lua
preview-ai cmd:jj status
preview-ai markdown "# Hello"
preview-ai image /path/to/img.png
preview-ai log -n 5

# Auto-detect (type can be omitted):
preview-ai '{"foo": "bar"}'          # → json
preview-ai .dotfiles-t7f             # → bead
preview-ai /path/to/file.lua         # → file
preview-ai /path/to/image.png        # → image
```

### Pane Management - SESSION SCOPED

**CRITICAL FIX**: Pane search is scoped to current session+window only:

```bash
# BAD (old pattern) - searches ALL sessions/windows
tmux list-panes -a -F "#{pane_id} #{pane_title}"

# GOOD (new pattern) - searches ONLY current window
session=$(tmux display-message -p '#{session_name}')
window=$(tmux display-message -p '#{window_index}')
tmux list-panes -t "${session}:${window}" -F "#{pane_id} #{pane_title}"
```

This prevents killing preview panes in other tmux sessions (e.g., another project).

### Safety Guarantees

1. `$TMUX_PANE` captured at script start = pane that MUST NOT be touched
2. `split-window -t "$CALLER_PANE"` creates NEW pane, runs command THERE
3. All output goes to the NEW pane via the command passed to split-window
4. Caller pane remains untouched
5. **Session-scoped**: Only affects preview panes in current window

## Files to Create/Modify

1. **CREATE**: `bin/preview-ai` - Main bash script (~150 lines)
2. **UPDATE**: `docs/commands/preview.md` - Update to reference preview-ai

## Verification Steps

1. Start Claude Code in tmux, note pane ID (`echo $TMUX_PANE`)
2. Run: `preview-ai json '{"test": true}'` - should split right, show JSON
3. Verify caller pane unchanged, preview pane has title "ai-preview"
4. Run another preview - should reuse/replace same preview pane
5. **Session isolation test**:
   - Open second tmux session with another preview-ai
   - Run preview in first session - should NOT affect second session's preview
6. Test all content types: markdown, diff, bead, file, log, image

## Future Enhancements

Inspired by claude-canvas:
- IPC socket for live updates (ready/update/close messages)
- Multiple canvas types (document, data table, diagram)
- Mouse interaction support

Sources:
- [dvdsgl/claude-canvas](https://github.com/dvdsgl/claude-canvas) - TUI toolkit inspiration
- [BEARLY-HODLING/claude-canvas](https://github.com/BEARLY-HODLING/claude-canvas) - Fork with iTerm2 support
