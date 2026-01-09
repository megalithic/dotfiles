---
name: tmux
description: tmux terminal multiplexer configuration, key bindings, session management, and custom scripts. Use when interacting with tmux sessions, panes, windows, or debugging tmux issues.
tools: Bash, Read, Grep, Glob
---

# tmux Configuration and Usage

## Overview

**Current version**: tmux 3.6a

tmux is a terminal multiplexer that lets you:
- Run multiple terminal sessions in a single window
- Detach and reattach sessions (persist across disconnects)
- Split terminals into panes and windows
- Share sessions between users

This dotfiles repo has a heavily customized tmux setup with:
- **Prefix key**: `C-space` (Ctrl+Space)
- **Session manager**: `ftm` (fzf-based session switcher/creator)
- **Theme**: Megaforest (custom everforest-inspired colors)
- **Plugins**: TPM-managed with mode indicator, battery, CPU, pomodoro, etc.
- **Custom scripts**: 20+ helper scripts in `~/bin/tmux-*`

## tmux Fundamentals

### Core Concepts

```
┌─────────────────────────────────────────────────────────────────┐
│                         tmux Server                              │
│  (background process managing all sessions)                      │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │                      Session: "main"                         ││
│  │  ┌─────────────────────┐  ┌─────────────────────┐           ││
│  │  │   Window 1: "code"  │  │  Window 2: "logs"   │           ││
│  │  │  ┌───────┬────────┐ │  │  ┌────────────────┐ │           ││
│  │  │  │ Pane  │ Pane   │ │  │  │     Pane       │ │           ││
│  │  │  │  1    │  2     │ │  │  │      1         │ │           ││
│  │  │  │       │        │ │  │  │                │ │           ││
│  │  │  │ nvim  │ shell  │ │  │  │ tail -f logs   │ │           ││
│  │  │  └───────┴────────┘ │  │  └────────────────┘ │           ││
│  │  └─────────────────────┘  └─────────────────────┘           ││
│  └─────────────────────────────────────────────────────────────┘│
│                                                                  │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │                    Session: "work"                           ││
│  │  ...                                                         ││
│  └─────────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────────┘
```

| Concept | Description |
|---------|-------------|
| **Server** | Background process managing all tmux state |
| **Session** | Collection of windows, can attach/detach |
| **Window** | Full screen container, like a tab |
| **Pane** | Split within a window, runs a shell/process |
| **Client** | Terminal attached to a session |

### Target Syntax

tmux uses a hierarchical target syntax:

```
session:window.pane
  │       │     │
  │       │     └── Pane index (0-based) or unique ID (%N)
  │       └──────── Window index (1-based*) or name or unique ID (@N)
  └──────────────── Session name or unique ID ($N)

* This config uses base-index 1, so windows start at 1
```

**Examples:**
```bash
# Target session "main"
tmux switch-client -t main

# Target window 2 in session "main"
tmux select-window -t main:2

# Target pane 1 in window 2 of session "main"
tmux select-pane -t main:2.1

# Target by unique ID
tmux send-keys -t %5 "command"  # Pane ID %5
```

### Command Syntax

```bash
tmux [command] [flags] [arguments]
```

**Common patterns:**
```bash
# Most commands have short aliases
tmux new-session    # Full command
tmux new            # Short alias
tmux new -s name    # With flag

# -t = target (session, window, or pane)
tmux kill-session -t session-name
tmux select-window -t 2
tmux send-keys -t session:window.pane "text"

# -F = format string (for output formatting)
tmux list-sessions -F '#{session_name}: #{session_windows} windows'

# -p = print (for display-message)
tmux display-message -p '#{pane_current_path}'
```

### Format Strings (Variables)

tmux provides extensive format variables for scripting:

| Variable | Description |
|----------|-------------|
| `#{session_name}` | Current session name |
| `#{session_id}` | Unique session ID ($N) |
| `#{window_index}` | Window number |
| `#{window_name}` | Window name |
| `#{window_id}` | Unique window ID (@N) |
| `#{pane_index}` | Pane number |
| `#{pane_id}` | Unique pane ID (%N) |
| `#{pane_current_path}` | Pane's working directory |
| `#{pane_current_command}` | Running command |
| `#{pane_tty}` | Pane's TTY device |
| `#{pane_pid}` | Shell PID in pane |
| `#{cursor_x}`, `#{cursor_y}` | Cursor position |
| `#{pane_width}`, `#{pane_height}` | Pane dimensions |

**Conditionals in formats:**
```bash
# #{?condition,true-value,false-value}
tmux display-message -p '#{?window_zoomed_flag,ZOOMED,normal}'

# Comparisons
tmux display-message -p '#{?#{>:#{window_panes},1},multiple,single}'
```

### tmux 3.x Features

**tmux 3.6+ features used in this config:**

| Feature | Description | Example |
|---------|-------------|---------|
| Popup windows | Floating overlays | `display-popup -E "command"` |
| Extended keys | Meta/Ctrl modifiers | `set extended-keys on` |
| Passthrough | Pass escape sequences to terminal | `set allow-passthrough on` |
| Styled borders | Pane border customization | `pane-border-indicators both` |
| Copy pipe | Pipe selection to command | `send-keys -X copy-pipe "pbcopy"` |
| Hooks | React to tmux events | `set-hook -g pane-focus-in 'run ...'` |
| If-shell | Conditional config | `if-shell 'test ...' 'command'` |
| Run-shell | Execute shell commands | `run-shell "script.sh"` |

## Decision Trees

### "How do I manage tmux sessions?"

```
Session management?
│
├─▶ Create/switch to session?
│   ├─▶ Interactive (fuzzy): ftm
│   │   └─▶ Shows existing sessions + predefined layouts
│   │   └─▶ Ctrl-x: kill session, Ctrl-r: rename session
│   ├─▶ Direct by name: ftm <session-name>
│   │   └─▶ Switches if exists, creates if not
│   └─▶ From popup: <prefix> C-space
│       └─▶ Opens ftm in tmux popup
│
├─▶ List sessions?
│   ├─▶ Simple list: tmux ls
│   ├─▶ Tree view: tmux-tree
│   │   └─▶ Shows sessions → windows hierarchy
│   └─▶ Current session: tmux display-message -p '#S'
│
├─▶ Kill session?
│   ├─▶ Current session: <prefix> C-k
│   │   └─▶ Prompts for confirmation
│   ├─▶ Specific session: tmux kill-session -t <name>
│   └─▶ Via ftm: Ctrl-x on selected session
│
└─▶ Rename session?
    ├─▶ Current: tmux rename-session <new-name>
    └─▶ Via ftm: Ctrl-r on selected session
```

### "How do I work with panes and windows?"

```
Panes and windows?
│
├─▶ Split panes?
│   ├─▶ Vertical split (side by side): <prefix> v
│   └─▶ Horizontal split (top/bottom): <prefix> s
│
├─▶ Navigate panes?
│   ├─▶ C-h/j/k/l: Move left/down/up/right
│   │   └─▶ Works seamlessly with vim/nvim (smart-splits)
│   └─▶ Last pane: <prefix> C-l
│
├─▶ Resize panes?
│   ├─▶ M-h/j/k/l (Alt+hjkl): Resize by 3 units
│   └─▶ <prefix> H/J/K/L: Resize by 10 units
│
├─▶ Kill pane/window?
│   ├─▶ Kill pane: <prefix> x (with confirmation)
│   ├─▶ Kill window: <prefix> C-x (with confirmation)
│   └─▶ Force kill process: <prefix> * (tmux-cowboy)
│
├─▶ Create window?
│   ├─▶ New window: <prefix> t or <prefix> C-t
│   └─▶ Inherits current pane's working directory
│
├─▶ Move windows?
│   ├─▶ Swap left: <prefix> C-H or C-S-Left
│   ├─▶ Swap right: <prefix> C-L or C-S-Right
│   └─▶ Make first: <prefix> T
│
└─▶ Switch windows?
    ├─▶ By number: <prefix> 1-9
    ├─▶ Last window: <prefix> Tab
    └─▶ Fuzzy find: <prefix> C-w
```

### "How do I copy/search in tmux?"

```
Copy mode and search?
│
├─▶ Enter copy mode?
│   └─▶ <prefix> C-b
│       └─▶ Uses vi keybindings
│
├─▶ Search in pane?
│   ├─▶ Forward: / (in copy mode)
│   ├─▶ Backward: ? (in copy mode)
│   └─▶ Fuzzy search history: <prefix> f (tmux-fuzzback)
│
├─▶ Select and copy?
│   ├─▶ Start selection: v
│   ├─▶ Line selection: V
│   ├─▶ Rectangle selection: C-v
│   ├─▶ Copy to clipboard: y
│   └─▶ Cancel: Escape
│
├─▶ Quick copy (thumbs)?
│   └─▶ <prefix> C-f (tmux-thumbs)
│       └─▶ Highlights copyable items (URLs, paths, etc.)
│       └─▶ Press hint key to copy
│
└─▶ Jump to text (like easymotion)?
    └─▶ <prefix> / (tmux-jump)
        └─▶ Type target chars, press hint key
```

### "What plugins are available?"

```
Plugin functionality?
│
├─▶ Mode indicator (top-left)?
│   └─▶ Shows: WAIT (prefix), COPY, SYNC, or session name
│
├─▶ Pomodoro timer?
│   ├─▶ Start/pause: <prefix> p
│   ├─▶ Cancel: <prefix> P
│   └─▶ Skip: <prefix> -
│
├─▶ Suspend tmux (nested sessions)?
│   └─▶ F6 (tmux-suspend)
│       └─▶ Disables outer tmux for SSH nested sessions
│
├─▶ Battery/CPU in status bar?
│   └─▶ Right side shows battery %, charging status, CPU %
│
├─▶ Plugin management?
│   ├─▶ Install plugins: <prefix> I
│   ├─▶ Update plugins: <prefix> U
│   └─▶ Uninstall: <prefix> M-u
│
└─▶ Mouse mode?
    └─▶ Enabled by default
        └─▶ Click to select pane
        └─▶ Scroll to enter copy mode
        └─▶ Drag to select text
```

## Key Bindings Reference

### Prefix: `C-space` (Ctrl+Space)

| Binding | Action |
|---------|--------|
| `C-r` | Reload config |
| `v` | Split vertical (side by side) |
| `s` | Split horizontal (top/bottom) |
| `t` / `C-t` | New window |
| `x` | Kill pane (confirm) |
| `C-x` | Kill window (confirm) |
| `C-k` | Kill session (confirm) |
| `C-b` | Enter copy mode |
| `C-space` | Session popup (ftm) |
| `C-l` | Switch to last session |
| `C-w` | Fuzzy find window |
| `f` | Fuzzback (search history) |
| `C-f` | Thumbs (quick copy) |
| `/` | Jump (easymotion-like) |
| `*` | Kill process (cowboy) |
| `p` | Pomodoro start/pause |
| `P` | Pomodoro cancel |
| `-` | Pomodoro skip |
| `I` | Install plugins |
| `U` | Update plugins |
| `M-u` | Uninstall plugins |

### No-Prefix Bindings

| Binding | Action |
|---------|--------|
| `C-h/j/k/l` | Navigate panes (vim-aware) |
| `M-h/j/k/l` | Resize panes (small) |
| `C-S-Left/Right` | Move window left/right |
| `M-C` | Claude monitor popup |
| `F6` | Suspend tmux (for nested) |

### Copy Mode (vi)

| Binding | Action |
|---------|--------|
| `v` | Begin selection |
| `V` | Line selection |
| `C-v` | Rectangle selection |
| `y` | Copy and exit |
| `Enter` | Copy and exit |
| `/` | Search forward |
| `?` | Search backward |
| `Escape` | Cancel |

## Custom Scripts Reference

### Session Management

| Script | Purpose | Usage |
|--------|---------|-------|
| `ftm` | Fuzzy session manager | `ftm [session-name]` |
| `tmux-launch` | Launch command in session | `tmux-launch <session> <command>` |
| `tmux-kill-session` | Kill session, switch to fallback | `tmux-kill-session <session> [fallback]` |
| `tmux-tree` | Tree view of sessions/windows | `tmux-tree [highlight-session]` |

### Status Bar Scripts

| Script | Purpose | Location |
|--------|---------|----------|
| `tmux-var` | Get tmux environment variables | Used for dynamic session styling |
| `tmux-process-name` | Smart process name for window title | Auto-runs via automatic-rename |
| `tmux-fancy-numbers` | Pane number icons | Used in status format |
| `tmux-vpn` | VPN status indicator | Status bar right |
| `tmux-dnd` | Do Not Disturb status | Status bar right |
| `tmux-ptt` | Push-to-talk status | Status bar right |
| `tmux-spotify-hs` | Spotify now playing | Status bar right (disabled) |
| `tmux-cal` | Calendar indicator | Status bar right |
| `tmux-weather` | Weather info | Available but unused |

### Pane/Window Helpers

| Script | Purpose | Usage |
|--------|---------|-------|
| `tmux-pane-focus` | Flash pane on focus, track history | Auto-runs via hook |
| `tmux-ssh` | SSH with tmux window rename | `tmux-ssh <host>` |
| `tmux-ssh-split` | SSH in split pane | `tmux-ssh-split <host>` |
| `tmux-icons` | Get icon for process | `tmux-icons <process>` |

## Predefined Layouts

Layouts live in `~/.config/tmux/layouts/`:

| Layout | Purpose |
|--------|---------|
| `default.zsh` | Generic layout for any project |
| `mega.zsh` | Main dotfiles session |
| `launchdeck.zsh` | LaunchDeck project layout |
| `canonize.zsh` | Canonize project layout |
| `megalithic-io.zsh` | Blog/website layout |

Create session with layout: `ftm <layout-name>`

## Configuration Files

| Path | Purpose |
|------|---------|
| `~/.config/tmux/tmux.conf` | Main config (settings, bindings) |
| `~/.config/tmux/plugins.tmux.conf` | Plugin configuration |
| `~/.config/tmux/megaforest.tmux.conf` | Theme/colors |
| `~/.config/tmux/layouts/*.zsh` | Predefined session layouts |
| `~/.local/share/tmux/plugins/` | TPM plugin directory |

## AI Agent tmux Orchestration

### Critical: Detecting tmux Context

**ALWAYS check if running inside tmux before attempting operations:**

```bash
# Check if inside tmux
if [[ -n "$TMUX" ]]; then
  echo "Running inside tmux"
else
  echo "NOT in tmux - tmux commands may fail or create new sessions"
fi

# Get full context
tmux display-message -p 'Session: #S | Window: #I:#W | Pane: #P'
```

### Creating Panes for AI Workflows

**Split current pane and run command:**

```bash
# Horizontal split (pane below) - run jj diff
tmux split-window -v -l 30% "jj diff; read -p 'Press enter to close'"

# Vertical split (pane to right) - run jj diff
tmux split-window -h -l 40% "jj diff; read -p 'Press enter to close'"

# Split without blocking (command runs, pane stays open)
tmux split-window -v -l 30%
tmux send-keys "jj diff" C-m

# Split at specific percentage
tmux split-window -h -p 40  # 40% width on right
tmux split-window -v -p 30  # 30% height below
```

**Common AI workflow splits:**

```bash
# jj diff in split pane
tmux split-window -v -l 40% "jj diff --color=always | less -R"

# jj log in split pane
tmux split-window -h -l 50% "jj log --color=always | less -R"

# Watch file changes
tmux split-window -v -l 20% "watch -n 1 'jj status'"

# Run tests in split
tmux split-window -v -l 40% "just test; echo 'Tests complete'; read"

# Interactive shell in split (stays open)
tmux split-window -v -l 30%
```

### Running Commands in Existing Panes

```bash
# Send to current pane (from a script)
tmux send-keys "jj diff" C-m

# Send to specific pane by ID
PANE_ID=$(tmux display-message -p '#{pane_id}')
tmux send-keys -t "$PANE_ID" "jj status" C-m

# Send to pane in different window
tmux send-keys -t "session:window.pane" "command" C-m

# Send keys without executing (no C-m)
tmux send-keys "echo hello"  # Types but doesn't run

# Send special keys
tmux send-keys C-c     # Ctrl-C (interrupt)
tmux send-keys C-l     # Ctrl-L (clear)
tmux send-keys Escape  # Escape key
tmux send-keys Up      # Up arrow
```

### Reading Pane Output

**Capture pane content:**

```bash
# Capture visible content only
tmux capture-pane -p

# Capture full scrollback history
tmux capture-pane -pS -

# Capture last N lines
tmux capture-pane -pS -50  # Last 50 lines

# Capture to file
tmux capture-pane -pS - > /tmp/pane-output.txt

# Capture from specific pane
tmux capture-pane -p -t %5  # Pane ID %5

# Capture and strip trailing whitespace
tmux capture-pane -p | sed 's/[[:space:]]*$//'
```

**Wait for command to complete:**

```bash
# Create pane, run command, capture output
tmux split-window -v -P -F '#{pane_id}' "jj status" > /tmp/pane_id
PANE_ID=$(cat /tmp/pane_id)

# Wait a moment for command
sleep 0.5

# Capture output
OUTPUT=$(tmux capture-pane -p -t "$PANE_ID")
echo "$OUTPUT"
```

### AI Agent Workflow Patterns

**Pattern 1: Show diff in adjacent pane**

```bash
# Split right, show jj diff with syntax highlighting
tmux split-window -h -l 50% "jj diff --color=always | less -R"
```

**Pattern 2: Create reference pane**

```bash
# Create pane, keep it for multiple commands
NEW_PANE=$(tmux split-window -h -l 40% -P -F '#{pane_id}')

# Later, send commands to it
tmux send-keys -t "$NEW_PANE" "jj status" C-m
sleep 0.5
tmux send-keys -t "$NEW_PANE" "jj log -l 5" C-m
```

**Pattern 3: Run and capture output**

```bash
# Run command, capture result, close pane
OUTPUT=$(tmux split-window -v -l 30% -P "jj diff --stat; sleep 1" && sleep 1.5 && tmux capture-pane -p -t "$(tmux display-message -p '#{pane_id}')")
# Note: This is tricky; better to use the method below
```

**Pattern 4: Run in background pane (for AI)**

```bash
# Create named pane for AI reference
tmux split-window -h -l 40%
tmux select-pane -T "ai-reference"  # Name the pane

# Run commands in it by title (tmux 3.6+)
# Or track pane ID for later use
```

**Pattern 5: Interactive watch**

```bash
# Watch jj status in split
tmux split-window -v -l 15% "watch -n 2 'jj status --color=always'"
```

### Environment Variables Available

When running inside tmux, these are available:

```bash
$TMUX            # tmux socket path (non-empty if inside tmux)
$TMUX_PANE       # Current pane ID (%N)
$TERM            # Usually "tmux-256color" or terminal-specific
```

### Detecting Current Pane's Process

```bash
# What's running in current pane?
tmux display-message -p '#{pane_current_command}'

# What's the PID?
tmux display-message -p '#{pane_pid}'

# What's the working directory?
tmux display-message -p '#{pane_current_path}'

# Full process info
ps -t "$(tmux display-message -p '#{pane_tty}')" -o args=
```

### Managing Pane Layout

```bash
# Zoom current pane (toggle fullscreen)
tmux resize-pane -Z

# Even horizontal layout (all panes same width)
tmux select-layout even-horizontal

# Even vertical layout (all panes same height)
tmux select-layout even-vertical

# Main-horizontal (one big, rest below)
tmux select-layout main-horizontal

# Main-vertical (one big, rest on right)
tmux select-layout main-vertical

# Tiled (grid)
tmux select-layout tiled

# Resize specific pane
tmux resize-pane -D 10  # Down 10 lines
tmux resize-pane -U 10  # Up 10 lines
tmux resize-pane -L 10  # Left 10 cols
tmux resize-pane -R 10  # Right 10 cols
```

### Closing/Killing Panes

```bash
# Kill current pane
tmux kill-pane

# Kill specific pane
tmux kill-pane -t %5

# Kill all panes except current
tmux kill-pane -a

# Kill pane running specific command (by finding it)
PANE=$(tmux list-panes -F '#{pane_id}:#{pane_current_command}' | grep 'watch' | cut -d: -f1)
tmux kill-pane -t "$PANE"
```

## AI Agent Interaction Patterns

### Getting Current tmux Context

```bash
# Get current session name
tmux display-message -p '#S'

# Get current window index and name
tmux display-message -p '#I:#W'

# Get current pane index
tmux display-message -p '#P'

# Get full context (session:window.pane)
tmux display-message -p '#S:#I.#P'

# Get pane's working directory
tmux display-message -p '#{pane_current_path}'

# Get pane's current command
tmux display-message -p '#{pane_current_command}'
```

### Sending Commands to tmux

```bash
# Send keys to current pane
tmux send-keys "echo hello" C-m

# Send keys to specific pane
tmux send-keys -t session:window.pane "command" C-m

# Run command in new window
tmux new-window -n "window-name" "command"

# Run command in split pane
tmux split-window -h "command"
```

### Capturing Pane Content

```bash
# Capture visible pane content
tmux capture-pane -p

# Capture full history
tmux capture-pane -pS -

# Capture to file
tmux capture-pane -pS - > /tmp/pane-content.txt

# Capture last N lines
tmux capture-pane -pS -50
```

### Checking tmux State

```bash
# Check if inside tmux
[[ -n "$TMUX" ]] && echo "In tmux" || echo "Not in tmux"

# Check if session exists
tmux has-session -t "session-name" 2>/dev/null && echo "exists"

# List all sessions
tmux list-sessions -F '#S'

# List windows in session
tmux list-windows -t "session" -F '#I:#W'

# List panes in window
tmux list-panes -t "session:window" -F '#P:#{pane_current_command}'
```

### Creating Sessions Programmatically

```bash
# Create session (detached)
tmux new-session -d -s "session-name" -c "/path/to/directory"

# Create session with initial command
tmux new-session -d -s "session-name" "nvim"

# Create window in session
tmux new-window -t "session-name" -n "window-name"

# Create pane in window
tmux split-window -t "session-name:window-name" -h
```

## Self-Discovery Patterns

### Exploring Key Bindings

```bash
# List all bindings
tmux list-keys

# Search for specific binding
tmux list-keys | grep -i "split"

# List bindings in copy mode
tmux list-keys -T copy-mode-vi

# Show current prefix
tmux show-options -g prefix
```

### Exploring Options

```bash
# List all options
tmux show-options -g

# Search for option
tmux show-options -g | grep -i "status"

# Get specific option value
tmux show-option -gv status-position

# List window options
tmux show-window-options -g
```

### Exploring Plugins

```bash
# List installed plugins
ls ~/.local/share/tmux/plugins/

# Check TPM status
~/.local/share/tmux/plugins/tpm/bin/install_plugins

# View plugin source
cat ~/.local/share/tmux/plugins/<plugin>/README.md
```

### Exploring Custom Scripts

```bash
# List tmux-* scripts
ls ~/bin/tmux-*

# Get script help (most support -h)
tmux-launch -h
ftm -h

# View script source
cat ~/bin/tmux-<script>
```

## Troubleshooting

### "Colors look wrong"

```bash
# Check TERM value
echo $TERM
# Should be: xterm-ghostty or similar

# Check tmux terminal setting
tmux show-options -g default-terminal

# Verify true color support
tmux show-options -g terminal-overrides | grep -i rgb

# Test colors
printf "\x1b[38;2;255;100;0mTrueColor\x1b[0m\n"
```

### "Key bindings not working"

```bash
# Check if binding exists
tmux list-keys | grep "<key>"

# Check for conflicts
tmux list-keys | grep "C-space"

# Reload config
tmux source-file ~/.config/tmux/tmux.conf

# Or use the binding: <prefix> C-r
```

### "Vim/nvim navigation not working with C-hjkl"

```bash
# Check is_vim detection
ps -o state= -o comm= -t "$(tmux display-message -p '#{pane_tty}')" | grep -iqE 'nvim|vim'

# The tmux.conf uses not_tmux pattern for vim-aware navigation
# Check: C-h/j/k/l should work in both tmux and vim

# If not working, ensure vim has matching keymaps
# (usually via vim-tmux-navigator or smart-splits.nvim)
```

### "Plugins not loading"

```bash
# Check TPM installation
ls ~/.local/share/tmux/plugins/tpm

# If missing, install TPM
git clone https://github.com/tmux-plugins/tpm ~/.local/share/tmux/plugins/tpm

# Install plugins
~/.local/share/tmux/plugins/tpm/bin/install_plugins

# Or: <prefix> I inside tmux
```

### "Status bar not updating"

```bash
# Check status interval
tmux show-option -gv status-interval
# Should be: 3 (seconds)

# Force refresh
tmux refresh-client

# Check for script errors
~/bin/tmux-vpn  # Run directly to see errors
~/bin/tmux-dnd
```

### "Copy to clipboard not working"

```bash
# Check pbcopy availability
which pbcopy

# Test copy manually
echo "test" | pbcopy
pbpaste  # Should show "test"

# Check yank settings
tmux show-options -g | grep yank

# In copy mode, use 'y' to copy (not Enter for some configs)
```

### "Session layout not loading"

```bash
# Check layout exists
ls ~/.config/tmux/layouts/

# Run layout directly to see errors
sh ~/.config/tmux/layouts/<layout>.zsh

# Check ftm can find layouts
ftm -h  # Shows TMUX_LAYOUTS path
echo $TMUX_LAYOUTS  # Default: ~/.config/tmux/layouts
```

### "Pane focus flash not working"

```bash
# Check hook is set
tmux show-hooks -g | grep pane-focus-in

# Check script exists
ls ~/bin/tmux-pane-focus

# Run manually
~/bin/tmux-pane-focus --onfocus

# Check temp file
cat /tmp/tmuxpanehist
```

## Known Limitations

1. **Nested tmux sessions** - Use F6 (tmux-suspend) to disable outer tmux
2. **Pane focus history** - `/tmp/tmuxpanehist` grows unbounded (clears on reboot)
3. **Automatic rename** - May be slow for processes with many children
4. **Popup sessions** - `C-space C-space` popup uses fzf, requires terminal support
5. **True color** - Requires terminal with true color support (Ghostty, iTerm2, etc.)
6. **Mouse mode** - Can interfere with terminal app mouse handling

## Integration with Other Tools

### Hammerspoon

The ntfy notification system detects tmux context for attention routing:

```lua
-- Hammerspoon can query tmux state
local session = os.capture("tmux display-message -p '#S'")
local window = os.capture("tmux display-message -p '#W'")
```

### Neovim (smart-splits)

C-h/j/k/l navigation is shared between tmux and nvim via:
- tmux: `is_vim` detection pattern in tmux.conf
- nvim: smart-splits.nvim plugin with matching keymaps

### Fish Shell

The `mux` function in zsh/fish provides convenient tmux attachment:

```bash
mux           # Attach to existing session or show help
mux <session> # Attach to specific session
```
