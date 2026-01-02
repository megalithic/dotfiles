-- Kitty Terminal Integration Library
-- Utilities for launching and controlling Kitty terminal instances
--
-- Used for:
--   - Daily notes scratchpad windows
--   - Persistent nvim sessions via --listen/--server
--
local M = {}
local fmt = string.format
local nvimLib = require("lib.interop.nvim")

--------------------------------------------------------------------------------
-- CONFIGURATION
--------------------------------------------------------------------------------

M.config = {
  -- Default window wait time (seconds) for window to appear after launch
  windowWaitTime = 0.8,
}

--------------------------------------------------------------------------------
-- KITTY LAUNCHING
--------------------------------------------------------------------------------

--- Build Kitty CLI arguments for a scratchpad-style window
--- Includes overrides for consistent behavior across invocations
---@param opts table Options
---@field opts.title string Window title
---@field opts.frame? hs.geometry Target frame (for initial dimensions)
---@field opts.opacity? number Background opacity (0.0-1.0, default 1.0)
---@field opts.decorations? string Window decorations: "no"|"titlebar-only"|"titlebar-and-corners"
---@return table args CLI arguments (without the 'kitty' command itself)
function M.buildArgs(opts)
  opts = opts or {}
  local args = {}

  -- CRITICAL: Disable single-instance so our overrides actually work!
  -- With single-instance=yes (from config), the existing Kitty process
  -- creates the window and IGNORES all --override flags.
  table.insert(args, "--single-instance=no")

  -- Window title
  if opts.title then
    table.insert(args, "--title=" .. opts.title)
  end

  -- Background opacity (default to fully opaque for scratchpads)
  local opacity = opts.opacity or 1.0
  table.insert(args, "--override")
  table.insert(args, fmt("background_opacity=%.2f", opacity))

  -- Disable remembered window size (use our explicit dimensions)
  table.insert(args, "--override")
  table.insert(args, "remember_window_size=no")

  -- Center placement
  table.insert(args, "--override")
  table.insert(args, "placement_strategy=center")

  -- Window decorations (default to minimal)
  local decorations = opts.decorations or "titlebar-and-corners"
  table.insert(args, "--override")
  table.insert(args, "hide_window_decorations=" .. decorations)

  -- Explicit dimensions if frame provided (prevents resize flash)
  if opts.frame then
    table.insert(args, "--override")
    table.insert(args, fmt("initial_window_width=%d", opts.frame.w))
    table.insert(args, "--override")
    table.insert(args, fmt("initial_window_height=%d", opts.frame.h))
  end

  return args
end

--- Create a launcher function for Kitty with nvim server
--- Returns a function that launches Kitty with nvim listening on a socket
---@param title string Window title
---@param socketPath string Nvim socket path
---@param filePath string Initial file to open
---@param frame? hs.geometry Target frame for sizing
---@return function launcher Function that launches the terminal
function M.createNvimLauncher(title, socketPath, filePath, frame)
  return function()
    local nvimArgs = nvimLib.getServerArgs(socketPath, filePath)

    -- Build Kitty args
    local kittyArgs = M.buildArgs({
      title = title,
      frame = frame,
    })

    -- Combine into full command args (for hs.task with /usr/bin/env)
    local termArgs = { "MEGANOTE=1", "kitty" }
    for _, arg in ipairs(kittyArgs) do
      table.insert(termArgs, arg)
    end

    -- Add -e flag and nvim args
    table.insert(termArgs, "-e")
    for _, arg in ipairs(nvimArgs) do
      table.insert(termArgs, arg)
    end

    local task = hs.task.new("/usr/bin/env", nil, termArgs)
    if task then task:start() end
  end
end

--- Launch Kitty with a simple command (no nvim server)
---@param title string Window title
---@param command table Command and arguments to run
---@param frame? hs.geometry Target frame for sizing
---@return hs.task|nil task The launched task or nil on failure
function M.launch(title, command, frame)
  local kittyArgs = M.buildArgs({
    title = title,
    frame = frame,
  })

  local termArgs = { "kitty" }
  for _, arg in ipairs(kittyArgs) do
    table.insert(termArgs, arg)
  end

  if command and #command > 0 then
    table.insert(termArgs, "-e")
    for _, arg in ipairs(command) do
      table.insert(termArgs, arg)
    end
  end

  local task = hs.task.new("/usr/bin/env", nil, termArgs)
  if task then
    task:start()
    return task
  end
  return nil
end

return M
