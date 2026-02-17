# Ghostty Terminal Configuration

## Structure

```
ghostty/
├── config       # Main configuration file
├── shaders/     # Custom GLSL shaders (cursor effects, etc.)
└── AGENTS.md    # This file
```

## Key settings

| Setting | Value | Purpose |
|---------|-------|---------|
| `shell-integration` | `fish` | Fish shell integration |
| `macos-option-as-alt` | `true` | Option key sends Alt |
| `macos-titlebar-style` | `hidden` | No native titlebar |
| `window-save-state` | `always` | Persist window state |
| `cursor-style` | `block` | Block cursor with blink |
| `copy-on-select` | `clipboard` | Auto-copy selection |
| `quit-after-last-window-closed` | `true` | Exit when last window closes |

## Terminal features

Ghostty provides advanced terminal capabilities used by tmux and nvim:

- **True color (24-bit RGB)** - Full color support
- **Undercurl** - Wavy underlines for diagnostics
- **Colored underlines** - LSP error/warning colors
- **Strikethrough** - Text decoration
- **Extended keys (CSI u)** - Shift+Enter, Ctrl+Shift+X, etc.
- **Clipboard integration** - Read/write system clipboard
- **Hyperlinks** - Clickable URLs

## Tmux integration

Ghostty is configured to work seamlessly with tmux:

```
default-terminal = "xterm-ghostty"
extended-keys-format = csi-u
```

The terminal type and extended keys settings must match between Ghostty and tmux for proper key handling.

## Window behavior

- Starts maximized (`window-height/width = 9999`)
- Non-native fullscreen with visible menu
- No window decoration (tmux provides status)
- Working directory inheritance enabled

## Shaders

Custom GLSL shaders in `shaders/` for visual effects:
- Cursor trails/smear effects
- Custom cursor glow
- Enable via `custom-shader = shaders/name.glsl`

Currently disabled (commented out in config).

## Shell integration

Fish shell integration enabled with all features:
```
shell-integration = fish
shell-integration-features = true
```

This provides:
- Working directory tracking
- Command duration
- Semantic prompts
- Title setting

## Quick terminal

Supports a quick-access terminal (like Quake-style dropdown):
```
quick-terminal-position = left
```

Accessible via global hotkey (configured in Ghostty preferences).

## Editing conventions

- Settings are `key = value` format
- Comments start with `#`
- No sections/headers needed
- After editing: restart Ghostty or use Cmd+Shift+, to reload

## Cross-references

- **Tmux config:** `config/tmux/AGENTS.md`
- **Fish shell:** `home/common/programs/fish/AGENTS.md`
