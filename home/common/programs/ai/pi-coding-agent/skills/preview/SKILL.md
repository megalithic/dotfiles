---
name: preview
description: Display code, diffs, images, and other content in a tmux pane or popup. Auto-detects nvim/megaterm for floating popups.
tools: Bash
---

# Preview Skill

Display content in a tmux pane or popup next to the pi agent. Supports code files, JSON, markdown, diffs, images, logs, and more.

## Requirements

- Must be running inside tmux
- `preview-ai` script must be in PATH (installed via dotfiles)

## Commands

### /preview

Display content in a preview pane or popup.

```
/preview [options] [type] <content>
```

**Options:**
- `-m, --mode <mode>` - Preview mode: `tmux-split`, `tmux-float`, `auto` (default)
- `--auto-close-after <seconds>` - Auto-close pane after N seconds
- `--delta` - Explicit delta flag (delta is now the default)
- `-h, --help` - Show help

**Modes:**
- `tmux-split` - Side pane (default outside nvim)
- `tmux-float` - Large popup window (default inside nvim/megaterm)
- `auto` - Auto-detect: popup if inside nvim, split otherwise

**Content Types:**
- `json` - JSON content (inline or file path)
- `markdown` - Markdown content (inline or file path)
- `diff` - jj diff arguments (e.g., "-r @") - uses delta
- `log` - jj log arguments (e.g., "-n 5")
- `bead` - Bead task ID - renders with glow
- `file` - File path to preview with bat
- `image` - Image file path (uses chafa or kitty protocol)
- `cmd` - Shell command to execute (prefix with "cmd:")
- `auto` - Auto-detect type (default)

**Examples:**

```
# Preview JSON
/preview json '{"foo": "bar"}'
/preview json /path/to/data.json

# Preview diffs
/preview diff -r @                    # Uses delta for diff viewing
/preview diff                         # Current working copy changes

# Preview files
/preview file ~/.config/nvim/init.lua
/preview /tmp/output.log              # Auto-detects type

# Preview markdown
/preview markdown "# Hello World"
/preview /path/to/README.md

# Preview images
/preview image /path/to/screenshot.png

# Preview with auto-close
/preview --auto-close-after 5 diff    # Auto-close after 5 seconds

# Preview jj log
/preview log -n 10
/preview log -r 'main..'

# Explicit mode selection
/preview --mode tmux-float diff       # Force popup mode
/preview -m tmux-split file foo.lua   # Force split pane mode
```

## Keyboard Shortcuts

- `Ctrl+Shift+P` - Quick preview of current diff (equivalent to `/preview diff`)

## How It Works

The preview extension wraps the existing `preview-ai` bash script which:

1. **Auto-detection:**
   - Inside nvim/megaterm (`$NVIM` set): Uses `tmux display-popup` (large floating window)
   - Regular tmux: Uses `tmux split-window` (side pane)

2. **Safe pane management:**
   - Never renders in the caller's pane
   - Only searches current session/window for existing previews
   - Reuses existing preview pane (kills and recreates)

2. **Content rendering:**
   - JSON: Uses `jq` for formatting
   - Markdown: Uses `glow` for rendering
   - Diffs: Uses `delta` for syntax-highlighted diff viewing
   - Images: Uses `chafa` for terminal display or kitty protocol
   - Files: Uses `bat` with syntax highlighting
   - Logs: Uses `jj log` with paging disabled

3. **Closing the preview:**
   - Press `q` or `Escape` to close the preview pane/popup

## Limitations

- Requires tmux (will not work in plain terminal)
- Preview pane is created in current window only
- Large files may take time to render
- Image quality depends on terminal capabilities

## Troubleshooting

**Error: "Preview requires tmux"**
- Solution: Run pi inside a tmux session

**Error: "preview-ai failed"**
- Check if `preview-ai` is in PATH: `which preview-ai`
- Check if required tools are installed: `bat`, `glow`, `jq`, `delta`, `chafa`

**Preview pane not appearing:**
- Check if you're in the correct tmux window
- Try manually: `preview-ai diff` in a terminal

**Image preview not working:**
- Check if `chafa` is installed: `which chafa`
- Check terminal capabilities for image display
- Try `preview file /path/to/image.png` to see actual output

## Related

- **tmux skill** - For advanced tmux pane control
- **files extension** - Browse and manage files in the session
- `~/.dotfiles/bin/preview-ai` - The underlying bash script
