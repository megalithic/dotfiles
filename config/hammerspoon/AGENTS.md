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

### Force reload

```lua
hs.reload()  -- or Cmd+Ctrl+R if bound
```

## Key files to understand

| File | Why it matters |
|------|---------------|
| `init.lua` | Load order, global setup |
| `lib/state.lua` | All state namespaces |
| `overrides.lua` | hs.task env injection, reload cleanup |
| `preflight.lua` | PATH setup, early initialization |
| `bindings.lua` | All global hotkeys |
