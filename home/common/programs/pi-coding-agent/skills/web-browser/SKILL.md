---
name: web-browser
description: "Browse the web, take screenshots, fill forms, and interact with pages via the chrome-devtools MCP server. Supports isolated (fresh) or profile-copy (logged-in) modes."
---

# Web browser skill

Browser automation via the `chrome-devtools` MCP server. Uses Helium (Chromium)
at `/Applications/Helium.app`.

## Modes

### Isolated (default)

The `chrome-devtools` MCP server in `mcp.json` uses `--isolated` — spawns a
fresh temp profile. No cookies, no logins. Good for scraping public pages.

### Profile copy (logged-in sessions)

To browse as the logged-in user, copy the daily profile to a temp dir first:

```bash
./scripts/copy-profile.sh           # copies daily Helium profile (default)
./scripts/copy-profile.sh brave     # copies daily Brave Nightly profile
```

Then use the `chrome-devtools-profile` MCP server instead of `chrome-devtools`.
It launches Helium with the copied profile. The copy is read-only to the
original — no risk of corruption.

### Attach to running browser

If daily Helium is running with `--remote-debugging-port=9223`:

```bash
# Launch from fish with debug port:
helium --remote-debugging-port=9223
```

Then use the `chrome-devtools-attach` MCP server. It connects to `localhost:9223`
and shares the live session (cookies, logins, extensions, tabs).

## MCP tools reference

All tools are prefixed `chrome_devtools_`. Use via the `mcp` gateway.

### Navigation

| Tool            | Purpose                             |
| --------------- | ----------------------------------- |
| `navigate_page` | Go to URL, back, forward, or reload |
| `new_page`      | Open new tab                        |
| `list_pages`    | List open tabs                      |
| `select_page`   | Switch to a tab                     |
| `close_page`    | Close a tab                         |

```
mcp chrome-devtools navigate_page {"type": "url", "url": "https://example.com"}
mcp chrome-devtools new_page {"url": "https://example.com"}
```

### Interaction

| Tool            | Purpose                                |
| --------------- | -------------------------------------- |
| `click`         | Click element by CSS selector or text  |
| `fill`          | Fill a single input field              |
| `fill_form`     | Fill multiple form fields at once      |
| `type_text`     | Type text (keystroke simulation)       |
| `press_key`     | Press a key (Enter, Tab, Escape, etc.) |
| `hover`         | Hover over element                     |
| `drag`          | Drag from one element to another       |
| `upload_file`   | Upload file to input                   |
| `handle_dialog` | Accept/dismiss alert/confirm/prompt    |

### Inspection

| Tool                | Purpose                             |
| ------------------- | ----------------------------------- |
| `evaluate_script`   | Run JavaScript in the page          |
| `take_screenshot`   | Capture viewport image              |
| `take_snapshot`     | Get page DOM/accessibility snapshot |
| `take_heapsnapshot` | Capture V8 heap snapshot            |

### Network and console

| Tool                    | Purpose                           |
| ----------------------- | --------------------------------- |
| `list_network_requests` | List captured network requests    |
| `get_network_request`   | Get details of a specific request |
| `list_console_messages` | List console output               |
| `get_console_message`   | Get a specific console message    |

### Emulation and performance

| Tool                          | Purpose                                    |
| ----------------------------- | ------------------------------------------ |
| `emulate`                     | Set device emulation (viewport, UA, touch) |
| `resize_page`                 | Resize viewport                            |
| `lighthouse_audit`            | Run Lighthouse audit                       |
| `performance_start_trace`     | Start performance trace                    |
| `performance_stop_trace`      | Stop trace and get results                 |
| `performance_analyze_insight` | Analyze a performance insight              |
| `wait_for`                    | Wait for selector, URL, or timeout         |

## Common workflows

### Screenshot a page

```
mcp chrome-devtools navigate_page {"type": "url", "url": "https://example.com"}
mcp chrome-devtools take_screenshot {}
```

### Fill and submit a form

```
mcp chrome-devtools navigate_page {"type": "url", "url": "https://example.com/login"}
mcp chrome-devtools fill_form {"fields": [{"selector": "#email", "value": "user@example.com"}, {"selector": "#password", "value": "secret"}]}
mcp chrome-devtools click {"selector": "button[type=submit]"}
```

### Interactive element picking

Use `evaluate_script` to inject an interactive picker overlay (the agent
prompts the user to click an element, then reads back the selection):

```
mcp chrome-devtools evaluate_script {"expression": "<picker JS>"}
```

The picker JS creates a full-screen overlay with mousemove highlight, captures
click targets with their tag/id/class/text/html, and supports Cmd+Click for
multi-select and Enter to finish. See the `pick()` pattern below.

### Mobile testing

```
mcp chrome-devtools emulate {"deviceName": "iPhone 14"}
mcp chrome-devtools navigate_page {"type": "url", "url": "https://example.com"}
mcp chrome-devtools take_screenshot {}
```

## Notes

- The `chrome-cdp` skill is a separate tool for connecting to an existing
  browser session via `chrome://inspect` — use it when you need to inspect
  the user's actual open tabs without spawning a new instance.
- All MCP-spawned instances are independent of the daily Helium browser.
- Profile copies are stored in `~/.cache/agent-web/profile-copy/` and cleaned
  on each fresh copy.
