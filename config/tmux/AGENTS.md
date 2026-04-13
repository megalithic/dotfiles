# Tmux Configuration

## Structure

```
tmux/
├── tmux.conf           # Main config (settings, keybindings, appearance)
├── plugins.tmux.conf   # TPM plugins configuration
├── megaforest.tmux.conf # Everforest theme colors
├── tmate.conf          # tmate-specific overrides
├── layouts/            # Session layout scripts
│   ├── mega.zsh        # Personal dev layout
│   ├── rx.zsh          # Work layout
│   └── ...
└── AGENTS.md           # This file
```

## Key settings

| Setting | Value | Purpose |
|---------|-------|---------|
| `prefix` | `C-a` | Tmux prefix key |
| `base-index` | `1` | Windows start at 1 |
| `pane-base-index` | `1` | Panes start at 1 |
| `mouse` | `on` | Mouse support enabled |
| `mode-keys` | `vi` | Vi-style copy mode |
| `default-shell` | `fish` | Default shell |
| `status-position` | `top` | Status bar at top |

## Terminal compatibility

Configured for Ghostty with full feature support:
- True color (24-bit RGB)
- Undercurl and colored underlines
- Strikethrough
- CSI u extended keys (shift+enter, etc.)
- Clipboard integration
- Cursor shape changes

## Pi agent interaction

Pi can interact with tmux via the tmux skill. Key commands:

```bash
# Send keys to a pane
tmux send-keys -t session:window.pane "command" Enter

# Capture pane output (last 200 lines)
tmux capture-pane -p -J -t session:window.pane -S -200

# Create a new split
tmux split-window -h -t session:window

# List sessions
tmux list-sessions
```

**Target format:** `session:window.pane` (e.g., `mega:0.0`)

**For pi sessions:** Use `$PI_SESSION` env var for current session name.

## Title format

Window titles follow a parseable format for Hammerspoon attention detection:

```
#S:#I:#P:#{pane_pid} process_name
```

Example: `mega:1:0:12345 nvim`

## Layouts

Layout scripts in `layouts/` create predefined window arrangements:

```bash
# Run a layout
~/.config/tmux/layouts/mega.zsh
```

## Keybindings (common)

| Key | Action |
|-----|--------|
| `prefix + c` | New window |
| `prefix + ,` | Rename window |
| `prefix + n/p` | Next/prev window |
| `prefix + \|` | Split horizontal |
| `prefix + -` | Split vertical |
| `prefix + h/j/k/l` | Navigate panes (vim-style) |
| `prefix + z` | Zoom pane |
| `prefix + [` | Enter copy mode |
| `prefix + d` | Detach |

## Plugins (via TPM)

Managed in `plugins.tmux.conf`:
- tmux-sensible
- tmux-yank
- tmux-resurrect
- tmux-continuum

## Editing conventions

- Main settings go in `tmux.conf`
- Theme colors go in `megaforest.tmux.conf`
- Plugins go in `plugins.tmux.conf`
- After editing, reload with: `tmux source-file ~/.config/tmux/tmux.conf`

## Cross-references

- **Pi tmux skill:** `~/.dotfiles/home/common/programs/ai/pi-coding-agent/skills/tmux/SKILL.md`
- **Ghostty config:** `config/ghostty/AGENTS.md`
- **Hammerspoon attention detection:** `config/hammerspoon/lib/attention.lua`
