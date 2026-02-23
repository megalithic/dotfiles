---
name: preview
description: Display code, diffs, images, and other content in a tmux pane next to the agent. Wraps the preview-ai script for safe pane management.
tools: Bash
---

# Preview Skill

Display content in a tmux pane next to the pi agent. Supports code files, JSON, markdown, diffs, images, logs, and more.

## Requirements

- Must be running inside tmux
- `preview-ai` script must be in PATH (installed via dotfiles)

## Commands

### /preview

Display content in a preview pane.

```
/preview [options] [type] <content>
```

**Options:**
- `--auto-close-after <seconds>` - Auto-close pane after N seconds
- `--delta` - Use delta for diff viewing (non-interactive, default is codediff.nvim)
- `-h, --help` - Show help

**Content Types:**
- `json` - JSON content (inline or file path)
- `markdown` - Markdown content (inline or file path)
- `diff` - jj diff arguments (e.g., "-r @") - uses interactive codediff by default
- `codediff` - Explicit codediff.nvim mode (e.g., "HEAD~1 HEAD")
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
/preview diff -r @                    # Interactive codediff (default)
/preview --delta diff -r @            # Non-interactive delta view
/preview codediff HEAD~2 HEAD         # Compare specific revisions

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
```

## Keyboard Shortcuts

- `Ctrl+Shift+P` - Quick preview of current diff (equivalent to `/preview diff`)

## How It Works

The preview extension wraps the existing `preview-ai` bash script which:

1. **Safe pane management:**
   - Never renders in the caller's pane
   - Only searches current session/window for existing previews
   - Reuses existing preview pane (kills and recreates)

2. **Content rendering:**
   - JSON: Uses `jq` for formatting
   - Markdown: Uses `glow` for rendering
   - Diffs: Uses `codediff.nvim` (interactive) or `delta` (non-interactive)
   - Images: Uses `chafa` for terminal display or kitty protocol
   - Files: Uses `bat` with syntax highlighting
   - Logs: Uses `jj log` with paging disabled

3. **Interactive vs. non-interactive:**
   - Interactive modes (codediff.nvim): Waits for you to close the editor
   - Non-interactive modes: Shows "Press q to close" prompt

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
