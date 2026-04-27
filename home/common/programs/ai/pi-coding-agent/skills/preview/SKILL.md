---
name: preview
description: Display code, diffs, images, and other content in a tmux pane or popup, OR render markdown as a single-page interactive HTML and open in the default chromium-family browser. Auto-detects nvim/megaterm for floating popups.
tools: Bash
---

# Preview Skill

Display content in a tmux pane or popup next to the pi agent (default), OR render a markdown plan/proposal as an interactive single-page HTML in the default browser's main window (`--html` mode). Supports code files, JSON, markdown, diffs, images, logs, and more.

## CRITICAL: Pane Safety Rules

**Never kill or disrupt the pane running pi.** Before killing, closing, or replacing ANY pane:

1. **Identify your own pane first:** `tmux display-message -p '#{pane_id}'` — this is pi's pane. Never kill it.
2. **Before `kill-pane -t X`:** Verify X is not pi's pane ID.
3. **Before sending keys to any pane:** Verify the expected app is actually running there:
   ```bash
   # What's running in that pane?
   tmux display-message -t "$TARGET" -p '#{pane_current_command}'
   # Confirm visually
   tmux capture-pane -p -t "$TARGET" -S -3
   ```
4. **Never send keys blindly.** If target pane doesn't have the expected process, STOP. Re-discover the correct pane.
5. **Never assume pane identity persists.** User may close, rearrange, or swap panes between your commands. Always re-verify.

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
- **HTML in browser** - via `--html` flag (see HTML mode below)

**HTML mode flags (skip tmux entirely):**
- `--html` - Render markdown as interactive HTML, open in browser. Persistent output at `~/.local/share/pi/preview/<ts>-<slug>.html`.
- `--html-ephemeral` - Same, but output to `/tmp/preview-<slug>-<ts>.html` (gc'd in 1 day)
- `--html-no-open` - Render only; print path, skip browser open
- `--html-browser <bundle-id>` - Force a specific chromium-family browser by bundle id (e.g. `com.brave.Browser.nightly`)

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
# Render plan/proposal as interactive HTML in browser (chromium, max-tab window)
/preview --html ~/.local/share/pi/plans/foo/proposal.md
/preview --html-ephemeral /tmp/quick-notes.md
/preview --html --html-no-open doc.md          # render only

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

## HTML mode (`--html`)

Render a markdown document as a single-page interactive HTML and open it in the user's default chromium-family browser, in the window with the most tabs (the user's "main" window).

**When to use:** plans, proposals, research docs, decision documents, anything you want the user to scroll, collapse, tick checkboxes on, or answer Q&A in.

**Underlying script:** `~/.dotfiles/bin/preview-html` (Python; pandoc + osascript)

**Output paths:**
- Default: `~/.local/share/pi/preview/<YYYYMMDD-HHMMSS>-<slug>.html` (gc'd >30d)
- `--html-ephemeral`: `/tmp/preview-<slug>-<ts>.html` (gc'd >1d)
- Override dir: `PI_PREVIEW_DIR` env var

**Browser detection (chromium family only):**
1. `PI_PREVIEW_BROWSER` env var (bundle id), if set
2. macOS LaunchServices default `http` handler — used if it's chromium-family
3. Priority chain (running first): Brave Nightly → Brave → Chrome → Arc → Edge → Vivaldi
4. Any installed chromium app

Safari, Firefox: NOT supported. Use a chromium browser, or override with `--html-browser <bundle-id>`.

**Window targeting:** picks the running window with the **most tabs** (heuristic for the user's primary window). Adds new tab at the end, switches focus to it, brings the window to front.

**Interactive features in the rendered HTML:**
- Sticky TOC sidebar (auto-built from h2/h3) with active-section highlighting
- Smooth-scroll on TOC click
- h2 sections become collapsible (`<details>`); state persisted in localStorage
- GFM task lists (`- [ ] item`) become interactive checkboxes; state persisted
- Headings matching `Q1:`, `Q:`, `??`, `Decision:`, OR any h3/h4 nested under `## Open questions`, become **decision cards** with Yes/No/Maybe/Skip radios + free-text notes; state persisted
- Floating "Export answers" button: builds markdown summary of all decisions + checkbox state, copies to clipboard, downloads `<slug>-answers.md`
- Dark/light mode via `prefers-color-scheme`
- Print-friendly (`@media print` collapses TOC and FAB)
- "Reset answers" link in TOC sidebar clears localStorage

**Garbage collection:** `~/.dotfiles/bin/preview-html-gc` runs automatically on every `preview-html` invocation (`--quiet`). Prunes:
- `~/.local/share/pi/preview/*.{html,json,*-answers.md}` older than 30 days
- `/tmp/preview-*.html` older than 1 day

Override: `PI_PREVIEW_PERSIST_DAYS` and `PI_PREVIEW_TMP_DAYS` env vars, or `--persist-days` / `--tmp-days` flags.

**Direct invocation (bypass tmux extension):**
```bash
preview-html doc.md                          # render + open
preview-html --no-open doc.md                # render only
preview-html --ephemeral notes.md            # /tmp output
preview-html --browser com.google.Chrome doc.md
preview-html-gc --dry-run                    # show what would be gc'd
preview-html-gc --quiet                      # silent prune
```

**When user makes choices in the HTML and clicks "Export answers":**
- Markdown summary copied to clipboard AND downloaded as `<slug>-answers.md`
- Pi can then paste / read the file from `~/Downloads/`
- Future enhancement: File System Access API write-back to `~/.local/share/pi/preview/<slug>-answers.md` (currently relies on clipboard + Downloads)

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

**HTML mode: "no chromium-family browser found"**
- Install Brave/Chrome/Arc/Edge/Vivaldi, OR set `PI_PREVIEW_BROWSER` to a chromium bundle id
- Verify with: `preview-html --browser com.brave.Browser.nightly --no-open doc.md`

**HTML mode: tab opens in wrong window**
- The script picks the window with the **most tabs**. If you want a different window, close other windows or temporarily move tabs around.
- Future: support `--window-id <id>` flag for explicit targeting.

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
- `~/.dotfiles/bin/preview-ai` - The underlying bash dispatcher
- `~/.dotfiles/bin/preview-html` - HTML render + browser-open script (Python)
- `~/.dotfiles/bin/preview-html-gc` - Garbage collection script
