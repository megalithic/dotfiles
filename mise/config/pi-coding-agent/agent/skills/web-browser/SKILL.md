---
name: web-browser
description: "Browse the web, take screenshots, fill forms, and interact with pages via the chrome-devtools MCP server. Auto-triggers when user mentions visual bugs, wants to check a page, needs to fill a form, or discusses anything that benefits from seeing a live website."
---

# Web browser skill

Browser automation via the `chrome-devtools` MCP server. Uses Helium (Chromium).

## When to use this skill

Activate when the user:

- Says "check this page", "look at", "open", "browse to", "go to [url]"
- Reports a visual bug, layout issue, or styling problem
- Asks "what does X look like", "can you see", "screenshot"
- Needs to fill a form, log in, or interact with a web UI
- Wants to test responsive/mobile layout
- Mentions a URL and seems to want you to inspect it
- Says "pick", "show me", "which element", "point at"

Do NOT ask for permission to use the browser — just use it. Navigate, snapshot,
screenshot as needed to answer the user's question.

## Quick reference

### See a page

```
navigate_page  → go to URL
take_screenshot → capture what it looks like
take_snapshot   → get accessibility tree with element uids
```

### Interact with elements

```
click {uid: "..."}     → click element from snapshot
fill {uid, value}      → fill input field
fill_form {fields}     → fill multiple fields
type_text {text}       → type keystrokes
press_key {key}        → Enter, Tab, Escape, etc.
```

### Let the user pick

Read `scripts/pick.js` and pass its contents as the `function` parameter to
`evaluate_script`. The picker shows a blue highlight overlay — user clicks to
select, Cmd+Click for multi-select, Enter to finish, Escape to cancel.

```bash
# Agent workflow:
# 1. Read the picker script
read scripts/pick.js
# 2. Pass the function text to evaluate_script
mcp chrome-devtools evaluate_script {"function": "<contents of pick.js>"}
# 3. User clicks in the browser → result returned as JSON
```

### Other tools

| Tool                    | Purpose                         |
| ----------------------- | ------------------------------- |
| `new_page`              | Open new tab                    |
| `list_pages`            | List open tabs                  |
| `select_page`           | Switch tab                      |
| `close_page`            | Close tab                       |
| `hover`                 | Hover over element              |
| `drag`                  | Drag element                    |
| `upload_file`           | Upload to file input            |
| `handle_dialog`         | Accept/dismiss alerts           |
| `wait_for`              | Wait for selector, URL, or time |
| `emulate`               | Mobile device emulation         |
| `resize_page`           | Change viewport size            |
| `list_network_requests` | See network activity            |
| `list_console_messages` | See console output              |
| `lighthouse_audit`      | Run Lighthouse                  |
| `evaluate_script`       | Run arbitrary JS in page        |

## Browsing modes

### Isolated (default)

Every `chrome-devtools` tool call uses a fresh temp profile. No cookies, no
logins. Works for public pages, testing, screenshots.

### Copied profile (logged-in sessions)

When the user needs their logged-in session (e.g., "check my dashboard",
"look at my account page"):

1. Run the copy script:
   ```bash
   ./scripts/copy-profile.sh           # copy daily Helium profile
   ./scripts/copy-profile.sh brave     # copy daily Brave Nightly profile
   ```
2. Tell the user: "I've copied your profile. To use it, enable
   `chrome-devtools-profile` in `~/.pi/agent/mcp.json` (set `disabled: false`
   and set `chrome-devtools` to `disabled: true`), then reload the session."

### Attach to running Helium

When the user's daily Helium is running with a debug port:

```bash
helium --remote-debugging-port=9223   # user launches from fish
```

Use the `chrome-devtools-attach` MCP server (enable in mcp.json, disable
the default `chrome-devtools`). This shares the live session — all cookies,
tabs, and extensions.

## Tips

- Prefer `take_snapshot` over `take_screenshot` for understanding page
  structure — it's text, cheaper, and gives you uids to click.
- Use `take_screenshot` when the user asks about visual appearance or layout.
- Combine both: snapshot to find the uid, screenshot to verify visually.
- The `chrome-cdp` skill is separate — it connects to existing browser tabs
  via `chrome://inspect`. Use it for inspecting the user's actual open tabs.
