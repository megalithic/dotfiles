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

### Element selection (agent-driven)

The agent can identify and act on elements without human help:

```
mcp chrome-devtools take_snapshot {}       # accessibility tree with uids
mcp chrome-devtools click {"uid": "2_3"}   # click by uid from snapshot
```

Combine with `take_screenshot` for visual context when the snapshot alone
is ambiguous.

### Interactive element picking (human-driven)

When the agent needs the user to point at something, inject the picker
overlay via `evaluate_script`. The function returns a Promise that resolves
when the user clicks (or null on Escape):

```
mcp chrome-devtools evaluate_script {"function": "<picker function below>"}
```

Picker function (copy verbatim):

```javascript
async () => {
  return await new Promise((resolve) => {
    const overlay = document.createElement("div");
    overlay.style.cssText =
      "position:fixed;top:0;left:0;width:100%;height:100%;z-index:2147483647;pointer-events:none";
    const highlight = document.createElement("div");
    highlight.style.cssText =
      "position:absolute;border:2px solid #3b82f6;background:rgba(59,130,246,0.1);transition:all 0.1s;pointer-events:none";
    overlay.appendChild(highlight);
    const banner = document.createElement("div");
    banner.style.cssText =
      "position:fixed;bottom:20px;left:50%;transform:translateX(-50%);background:#1f2937;color:white;padding:12px 24px;border-radius:8px;font:14px sans-serif;box-shadow:0 4px 12px rgba(0,0,0,0.3);pointer-events:auto;z-index:2147483647";
    const selections = [];
    const selectedElements = new Set();
    const updateBanner = () => {
      banner.textContent =
        "Click to select (" +
        selections.length +
        " selected). Cmd/Ctrl+Click = multi. Enter = done. ESC = cancel.";
    };
    updateBanner();
    document.body.append(banner, overlay);
    const cleanup = () => {
      document.removeEventListener("mousemove", onMove, true);
      document.removeEventListener("click", onClick, true);
      document.removeEventListener("keydown", onKey, true);
      overlay.remove();
      banner.remove();
      selectedElements.forEach((el) => (el.style.outline = ""));
    };
    const info = (el) => ({
      tag: el.tagName.toLowerCase(),
      id: el.id || null,
      class: el.className || null,
      text: (el.textContent || "").trim().slice(0, 200) || null,
      html: el.outerHTML.slice(0, 500),
    });
    const onMove = (e) => {
      const el = document.elementFromPoint(e.clientX, e.clientY);
      if (!el || overlay.contains(el) || banner.contains(el)) return;
      const r = el.getBoundingClientRect();
      Object.assign(highlight.style, {
        top: r.top + "px",
        left: r.left + "px",
        width: r.width + "px",
        height: r.height + "px",
      });
    };
    const onClick = (e) => {
      if (banner.contains(e.target)) return;
      e.preventDefault();
      e.stopPropagation();
      const el = document.elementFromPoint(e.clientX, e.clientY);
      if (!el || overlay.contains(el) || banner.contains(el)) return;
      if (e.metaKey || e.ctrlKey) {
        if (!selectedElements.has(el)) {
          selectedElements.add(el);
          el.style.outline = "3px solid #10b981";
          selections.push(info(el));
          updateBanner();
        }
      } else {
        cleanup();
        resolve(selections.length > 0 ? selections : info(el));
      }
    };
    const onKey = (e) => {
      if (e.key === "Escape") {
        cleanup();
        resolve(null);
      } else if (e.key === "Enter" && selections.length > 0) {
        cleanup();
        resolve(selections);
      }
    };
    document.addEventListener("mousemove", onMove, true);
    document.addEventListener("click", onClick, true);
    document.addEventListener("keydown", onKey, true);
  });
};
```

Returns one of:

- Single click: `{tag, id, class, text, html}` for the clicked element
- Multi-select (Cmd+Click then Enter): array of element objects
- Escape: `null`

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
