# config/hammerspoon/ — Hammerspoon configuration

## Overview

Lua-based macOS automation. This config is **out-of-store** (symlinked via `linkConfig`), so changes take effect immediately on `hs.reload()` without nix rebuild.

## Architecture

```
init.lua              # Entry point: preflight → config → state → modules
preflight.lua         # Early setup: path injection, hs.ipc, console styling
config.lua            # Settings table (_G.C) - colors, apps, paths
overrides.lua         # Patches to hs.* functions (reload cleanup, task env)

lib/
  state.lua           # Centralized state (_G.S) - replaces scattered globals
  canvas.lua          # Canvas drawing utilities
  db.lua              # SQLite database helpers
  notifications/      # Notification system components
  interop/            # External tool integration (nvim, tmux)

watchers/
  init.lua            # Loads all watchers
  app.lua             # App launch/quit events
  audio.lua           # Audio device changes
  camera.lua          # Camera on/off detection
  notification.lua    # macOS notification interception
  url.lua             # URL scheme handling

contexts/
  init.lua            # Context loader
  <bundleID>.lua      # Per-app key bindings and behaviors
```

## Global State

| Global | Purpose | Set in |
|--------|---------|--------|
| `_G.C` | Config table (colors, paths, settings) | config.lua |
| `_G.S` | State namespaces (replaces scattered globals) | lib/state.lua |
| `_G.U` | Utility functions | utils.lua |
| `_G.req()` | Safe require with error handling | init.lua |

### State namespaces (`_G.S.*`)

```lua
S.notification.canvas      -- Active notification canvas
S.notification.timers.*    -- Display, animation, overlay timers
S.hypers                   -- Hyper modal state
S.ptt                      -- Push-to-talk state
S.ptd                      -- Push-to-dictate state
S.micchecka                -- Unified voice module state (planned)
```

### Reset functions

```lua
S.reset("notification")    -- Clear a namespace
S.resetAll()               -- Clear all state (called on reload)
```

## Module lifecycle

Modules should support clean reload:

```lua
local M = {}

function M.init()
  -- Called once on load
  -- Set up watchers, register hotkeys
end

function M.start()
  -- Called to activate
end

function M.stop()
  -- Called before reload or to deactivate
  -- MUST clean up: timers, watchers, canvases, callbacks
end

return M
```

## Context files

Per-app configurations in `contexts/<bundleID>.lua`:

```lua
-- contexts/com.example.app.lua
return {
  bindings = {
    { mods = {"cmd"}, key = "k", action = function() ... end },
  },
  callbacks = {
    onActivate = function() ... end,
    onDeactivate = function() ... end,
  },
}
```

Context loader (`contexts/init.lua`) watches app activation and loads appropriate context.

## Watchers

Event-driven modules in `watchers/`:

```lua
-- watchers/example.lua
local M = {}

M.watcher = nil

function M.start()
  M.watcher = hs.somewatcher.new(function(event)
    -- Handle event
  end)
  M.watcher:start()
end

function M.stop()
  if M.watcher then
    M.watcher:stop()
    M.watcher = nil
  end
end

return M
```

## Nix integration

Nix generates `~/.local/share/hammerspoon/nix_path.lua`:

```lua
NIX_PATH = "/nix/store/.../bin:/run/current-system/sw/bin"
NIX_ENV = {
  NOTES_HOME = "...",
  DOTS = "...",
  -- etc.
}
```

Loaded in `preflight.lua` and injected into `hs.task` via `overrides.lua`.

## Logging

Use `U.log.*` for all logging. **Never prefix with module name** — it's auto-captured:

```lua
-- WRONG
U.log.i("clipper: initialized")
U.log.e(fmt("clipper: upload failed: %s", err))

-- CORRECT
U.log.i("initialized")
U.log.e(fmt("upload failed: %s", err))
```

Log levels:
- `U.log.d()` — Debug (verbose, development)
- `U.log.i()` — Info (normal operations)
- `U.log.w()` — Warning (recoverable issues)
- `U.log.e()` — Error (failures)
- `U.log.n()` — Notify (user-facing, shows alert)

## Common tasks

### Add a new hotkey

1. For global: add to `bindings.lua`
2. For app-specific: add to `contexts/<bundleID>.lua`

### Add a new watcher

1. Create `watchers/mywatch.lua` with `start()`/`stop()` functions
2. Add `require("watchers.mywatch")` to `watchers/init.lua`
3. Ensure cleanup in `stop()` for reload safety

### Debug state

```lua
-- In Hammerspoon console
hs.inspect(_G.S)           -- View all state
hs.inspect(_G.S.notification)  -- View specific namespace
```

### Force reload (CRITICAL — DO NOT CRASH)

**Never use `hs -c "hs.reload()"` directly** — it destroys the Lua interpreter
and crashes the IPC connection. Also avoid calling `hs.reload()` from timers
inside `hs -c` commands.

```bash
# CORRECT — use the hs-reload script (clicks menu, waits for "hammerspork loaded")
hs-reload

# WRONG — crashes IPC connection
hs -c "hs.reload()"
```

The `hs-reload` script uses AppleScript to click "Reload Config" in the menu bar,
then watches the console for "hammerspork loaded" to confirm completion.

From Lua (inside Hammerspoon console or a module):
```lua
hs.reload()  -- OK here, only dangerous via hs -c
```

### If Hammerspoon is crashed/not running

```bash
open -a Hammerspoon
sleep 3  # Wait for init
hs -c 'print("ok")' && echo "✓ Started"
```

### Quick hs -c commands

```bash
# Test if alive
hs -c 'print("ok")'

# Get last 20 console lines
hs -c 'local c = hs.console.getConsole(); local lines = {}; for line in c:gmatch("[^\n]+") do lines[#lines+1] = line end; for i = math.max(1, #lines-20), #lines do print(lines[i]) end'

# Check specific module loaded
hs -c 'print(HUD ~= nil and "HUD loaded" or "HUD missing")'
```

### Check for errors after reload

After reloading Hammerspoon, check the console for errors:

```bash
# View recent console output (last 50 lines)
hs -c "hs.console.getConsole()" | tail -50

# Search for errors specifically
hs -c "hs.console.getConsole()" | rg -i "ERROR:|attempt to|not found|stack traceback"

# Check if a specific module loaded
hs -c "hs.console.getConsole()" | rg "\[clipper\]"

# Open the console GUI
hs -c "hs.openConsole()"
```

**Error patterns to look for:**
- `ERROR:` — Lua errors, module load failures, LuaSkin errors
- `attempt to` — Nil access, type errors (e.g., "attempt to index a nil value")
- `module .* not found` — Missing require
- `stack traceback` — Full error with line numbers

**Success patterns to verify:**
- `[modulename] initialized` — Module loaded successfully
- `[watchers] initializing ...` — Lists active watchers
- `hammerspork config is loaded` — Full config loaded

**Enable debug logging:**
```lua
-- In Hammerspoon console, or add to config temporarily
_G.DEBUG = true
```
This enables `U.log.d()` and `U.log.df()` output. By default, debug logs are suppressed.

**From the Hammerspoon console GUI:**
- Cmd+Ctrl+H opens console (if bound)
- Errors appear in red
- Filter with the search box

## Key files to understand

| File | Why it matters |
|------|---------------|
| `init.lua` | Load order, global setup |
| `lib/state.lua` | All state namespaces |
| `overrides.lua` | hs.task env injection, reload cleanup |
| `preflight.lua` | PATH setup, early initialization |
| `bindings.lua` | All global hotkeys |
