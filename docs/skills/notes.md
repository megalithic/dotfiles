---
name: notes
description: Expert help with the meganote system - cross-tool note capture, daily notes, and obsidian.nvim integration. Covers Hammerspoon, Shade, nvim, and the full capture → daily note linking pipeline.
tools: Bash, Read, Grep, Glob, Edit, Write
---

# meganote system expert

## Prerequisites

**Load the `shade` skill first** for Shade-specific details:
- Shade app internals (Swift, ContextGatherer, MLX inference)
- IPC notification protocol and debugging
- nvim RPC from Shade side (ShadeNvim.swift)
- Sidebar mode window management

This skill focuses on the **nvim side** of meganote: obsidian.nvim config, daily note linking, template substitutions, and task management.

## Overview

The meganote system is a **multi-tool note capture and organization system** built across Hammerspoon, Shade, nvim (obsidian.nvim), and Obsidian. It enables quick capture of text and images with rich context, automatic linking to daily notes, and seamless integration with an Obsidian vault.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                      User Hotkey Trigger                         │
│           Hyper+Shift+N (text) / Hyper+Shift+O (daily)          │
└──────────────────────────┬──────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────────┐
│                        Hammerspoon                               │
│  Posts DistributedNotification: io.shade.note.capture           │
└──────────────────────────┬──────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────────┐
│                          Shade.app                               │
│  1. ContextGatherer: app type, URL, selection, language         │
│  2. Writes: ~/.local/state/shade/context.json                   │
│  3. ShadeNvim RPC: :Obsidian new_from_template capture-text     │
└──────────────────────────┬──────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────────┐
│                    nvim (obsidian.nvim)                         │
│  1. Reads context.json for template substitution                │
│  2. Creates: captures/YYYYMMDDHHMM-descriptor.md                │
│  3. User adds notes, saves file                                 │
└──────────────────────────┬──────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────────┐
│                   nvim (autocmds.lua)                           │
│  BufWritePost autocmd "NotesCaptureLink":                       │
│  1. Parse frontmatter, extract first content                    │
│  2. Ensure daily note exists (create via :ObsidianToday)        │
│  3. Check same-day: only link if capture date == today          │
│  4. Append: - HH:MM [[filename|description]] to daily note      │
└─────────────────────────────────────────────────────────────────┘
```

## Key Directories & Files

| Path | Purpose |
|------|---------|
| `~/.dotfiles/config/nvim/after/plugin/notes.lua` | Main nvim notes plugin |
| `~/.dotfiles/config/nvim/lua/plugins/obsidian.lua` | obsidian.nvim config + template substitutions |
| `~/.dotfiles/config/nvim/lua/config/autocmds.lua` | Capture → daily note linking autocmd |
| `~/.dotfiles/config/hammerspoon/lib/interop/shade.lua` | Hammerspoon → Shade IPC |
| `~/.dotfiles/config/hammerspoon/lib/notes.lua` | Path utilities for notes |
| `~/.dotfiles/config/hammerspoon/clipper.lua` | Image capture workflow |
| `~/.local/state/shade/context.json` | Runtime capture context |
| `$NOTES_HOME/` | Obsidian vault root (default: `~/iclouddrive/Documents/_notes`) |
| `$NOTES_HOME/daily/YYYY/YYYYMMDD.md` | Daily notes (year folders) |
| `$NOTES_HOME/captures/` | Capture notes |
| `$NOTES_HOME/assets/` | Image attachments |
| `$NOTES_HOME/templates/` | Obsidian templates (daily.md, capture-text.md, etc.) |

## Capture Filename Format

```
YYYYMMDDHHMM-descriptor.md
│         │
│         └─ Derived from context (window title, domain, app type)
└─ Zettelkasten timestamp (creation time)
```

Examples:
- `202601141430-github-pr.md`
- `202601141432-stackoverflow-python.md`
- `202601141435-capture.md` (fallback)

## Daily Note Linking

### When Linking Occurs

The `NotesCaptureLink` autocmd triggers on `BufWritePost` for `*/captures/*.md` files.

### Same-Day Check (CRITICAL)

Captures are **only auto-linked** if created on the same day as the daily note:

```lua
-- In autocmds.lua append_to_daily_note()
local capture_date = extract_capture_date(filename) -- "20260114" from "202601141430-..."
local today = os.date("%Y%m%d")

if capture_date ~= today then
  -- Capture from a different day - don't link to today's daily
  return false, "not_same_day"
end
```

### Daily Note Auto-Creation

If the daily note doesn't exist when saving a capture, it's created automatically:

```lua
-- ensure_daily_note_exists() in autocmds.lua
-- Uses obsidian.nvim's client:today() which applies the daily.md template
local obsidian = require("obsidian")
local client = obsidian.get_client()
client:today()  -- Creates with template substitutions
```

### Link Format

Appended to `## Captures` section in daily note:
```markdown
## Captures

- 14:30 [[202601141430-github-pr|Code review for auth changes]]
- 14:45 [[202601141445-stackoverflow|Python async patterns]]
```

## Template Substitutions

### obsidian.nvim Template Variables

Defined in `lua/plugins/obsidian.lua`:

| Variable | Value | Used In |
|----------|-------|---------|
| `{{date_id}}` | `YYYYMMDD` | Daily note ID |
| `{{timestamp}}` | `YYYY-MM-DDTHH:MM:SS` | Frontmatter |
| `{{migrated_tasks}}` | Incomplete tasks from previous day | Daily template |
| `{{yesterday_link}}` | Link to previous daily note | Daily template |
| `{{capture_context}}` | Collapsible callout with app/URL/window | Capture template |
| `{{capture_selection}}` | Selected text as code block | Capture template |
| `{{image_filename}}` | Image filename in assets/ | Image capture |

### Context JSON Schema

Written to `~/.local/state/shade/context.json` by Shade:

```json
{
  "appType": "browser",
  "appName": "Brave Browser Nightly",
  "windowTitle": "GitHub - Pull Request #123",
  "url": "https://github.com/owner/repo/pull/123",
  "selection": "const foo = 'bar';",
  "detectedLanguage": "javascript",
  "filePath": "/path/to/file.js",
  "filetype": "javascript",
  "timestamp": "2026-01-14T14:30:00"
}
```

## Key Functions Reference

### autocmds.lua

| Function | Purpose |
|----------|---------|
| `get_daily_note_path(date_str)` | Returns `$NOTES_HOME/daily/YYYY/YYYYMMDD.md` |
| `extract_capture_date(filename)` | Parses YYYYMMDD from capture filename |
| `ensure_daily_note_exists(date_str)` | Creates daily note via :ObsidianToday if missing |
| `append_to_daily_note(filename, desc, date)` | Links capture to daily note |
| `parse_frontmatter(lines)` | Extracts YAML frontmatter as table |
| `extract_first_content(lines, fm_end)` | Gets first non-header content line |
| `build_description(fm, content, lang)` | Creates link description |

### notes.lua

| Function | Purpose |
|----------|---------|
| `M.toggle_task(status)` | Cycle task checkbox status |
| `M.get_previous_daily_note()` | Find most recent daily note before today |
| `M.is_capture_note_empty(bufnr)` | Check if capture has user content |
| `M.cleanup_empty_capture(path)` | Prompt to delete empty capture |
| `M.run_vision_ocr(image_path)` | Execute OCR on image |
| `M.sort_tasks(bufnr, lines)` | Sort task list by status |

### obsidian.lua

| Function | Purpose |
|----------|---------|
| `find_previous_daily_note()` | Find previous daily for task migration |
| `extract_incomplete_tasks(path)` | Get unchecked tasks from daily note |
| `read_shade_context()` | Parse context.json |
| `generate_capture_note_id(title)` | Create YYYYMMDDHHMM-descriptor ID |
| `sanitize_for_filename(str)` | Clean string for filename use |

## Hotkeys

| Hotkey | Action | Flow |
|--------|--------|------|
| Hyper+Shift+N | Text capture | HS → Shade → context.json → obsidian.nvim capture |
| Hyper+Ctrl+N | Capture in sidebar | Same, but enters sidebar-left mode first |
| Hyper+Shift+O | Open daily note | HS → Shade → :ObsidianToday |
| Hyper+N | Toggle Shade | HS → Shade toggle visibility |

## Decision Trees

### "Capture not linking to daily note"

```
Capture not linking?
│
├─▶ Check capture filename format
│   └─▶ Must be: YYYYMMDDHHMM-*.md (12 digits then dash)
│       ├─▶ Missing digits → obsidian.nvim note_id_func issue
│       └─▶ Correct → Continue
│
├─▶ Check same-day
│   └─▶ Compare capture date (first 8 digits) to today
│       ├─▶ Different day → Expected behavior (no cross-day linking)
│       └─▶ Same day → Continue
│
├─▶ Check daily note exists
│   └─▶ ls $NOTES_HOME/daily/YYYY/YYYYMMDD.md
│       ├─▶ Missing → Should auto-create on save
│       │   └─▶ Check ensure_daily_note_exists() logs
│       └─▶ Exists → Continue
│
├─▶ Check frontmatter
│   └─▶ Capture must have valid YAML frontmatter
│       └─▶ No frontmatter → Not a proper capture, skip linking
│
└─▶ Check vim.b[buf].capture_linked
    └─▶ If true, already linked (or marked as processed)
```

### "Daily note not created on capture save"

```
Daily not created?
│
├─▶ Check obsidian.nvim loaded
│   └─▶ :Obsidian (should show commands)
│       └─▶ Not loaded → Check lazy.nvim config
│
├─▶ Check client available
│   └─▶ :lua print(require('obsidian').get_client())
│       └─▶ nil → Workspace not found
│
├─▶ Check directory exists
│   └─▶ ls $NOTES_HOME/daily/YYYY/
│       └─▶ Missing → vim.fn.mkdir should create it
│
└─▶ Check template
    └─▶ ls $NOTES_HOME/templates/daily.md
        └─▶ Missing → obsidian.nvim fails silently
```

### "Context not captured in note"

```
No context in capture?
│
├─▶ Check context.json written
│   └─▶ cat ~/.local/state/shade/context.json
│       ├─▶ Empty/missing → Shade ContextGatherer issue
│       └─▶ Has data → Continue
│
├─▶ Check read_shade_context()
│   └─▶ :lua print(vim.inspect(require('plugins.obsidian').read_shade_context()))
│       └─▶ nil → JSON parse error or file missing
│
├─▶ Check template uses variables
│   └─▶ cat $NOTES_HOME/templates/capture-text.md
│       └─▶ Should have {{capture_context}}, {{capture_selection}}
│
└─▶ Check app has focus when capturing
    └─▶ Context gathered from frontmost app at capture time
```

## Common Patterns

### Adding a new template substitution

```lua
-- In lua/plugins/obsidian.lua, under templates.substitutions:
my_variable = function()
  local ctx = read_shade_context()
  if ctx and ctx.someField then
    return ctx.someField
  end
  return ""
end,
```

### Modifying link description format

```lua
-- In lua/config/autocmds.lua, build_description():
-- Priority 1: First content line
-- Priority 2: Source context (domain · language)
-- Priority 3: "Text capture" fallback
```

### Adding a new capture type

1. Create template in `$NOTES_HOME/templates/capture-newtype.md`
2. Add to obsidian.lua `templates.template_customizations`:
   ```lua
   ["capture-newtype"] = {
     notes_subdir = "captures",
     note_id_func = generate_capture_note_id,
   },
   ```
3. Add Shade notification handler if needed

## Task Management

### Task Status Cycle

```
[ ]  →  [.]  →  [x]  →  [ ]
 │       │       │
 │       │       └─ Done (completed)
 │       └─ In progress (started)
 └─ Todo (not started)
```

### Task Sorting Order

In daily notes, `sort_tasks()` orders by:
1. `[.]` In progress (highest)
2. `[-]` Partially done
3. `[ ]` Not started
4. `[/]` Partially complete
5. Other statuses
6. `[x]` Completed (lowest)

### Task Migration

On new daily note creation:
- Extracts `- [ ]` tasks from previous day
- Replaces "tomorrow" with "today"
- Inserts into `{{migrated_tasks}}`

## Debugging

### Check capture linking logs

```vim
:messages
" Look for "Linked to daily:" or warning messages
```

### Verify daily note path

```lua
:lua print(require('config.autocmds').get_daily_note_path())
```

### Test context reading

```lua
:lua print(vim.inspect(require('plugins.obsidian').read_shade_context()))
```

### Check capture date extraction

```lua
:lua print(require('config.autocmds').extract_capture_date("202601141430-test"))
-- Should print: "20260114"
```

### Manual daily note creation

```vim
:ObsidianToday
```

### Force re-link capture

```lua
:lua vim.b.capture_linked = nil
:w
```

## Related Skills

- **shade**: Shade app IPC, context gathering, nvim RPC
- **nvim**: Neovim configuration, LSP, plugins
- **hs**: Hammerspoon configuration, hotkeys

## Key Implementation Details

### Why same-day linking?

Prevents accidental linking of old captures to today's daily note when re-saving files. Each capture should only link to the daily note for its creation date.

### Why auto-create daily note?

Users often capture notes before opening their daily note. Auto-creation ensures the capture link isn't lost due to missing daily note.

### Why context.json instead of direct RPC?

1. Decouples Shade from obsidian.nvim internals
2. Templates can use consistent substitution syntax
3. Easier debugging (context is visible as file)
4. obsidian.nvim reads context at template expansion time

### Frontmatter preservation

obsidian.nvim's `frontmatter.func()` preserves custom fields (source, source_url, etc.) from captures. Without this, obsidian.nvim would strip non-standard fields.
