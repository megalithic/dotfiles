-- Ghostty Integration Library
-- Spawn floating Ghostty windows for note editing
--
local M = {}
local fmt = string.format

--------------------------------------------------------------------------------
-- CONFIGURATION
--------------------------------------------------------------------------------

M.config = {
  -- Default floating window size (percentage of screen)
  floatWidth = 0.6,
  floatHeight = 0.5,
  -- Window class for identification
  floatClass = "floating-note",
  -- Time to wait for window to appear (seconds)
  windowWaitTime = 0.5,
  -- Ghostty app path
  appPath = "/Applications/Ghostty.app",
  -- Full path to nvim (needed since hs.task doesn't inherit shell PATH)
  nvimPath = "/etc/profiles/per-user/seth/bin/nvim",
}

--------------------------------------------------------------------------------
-- FLOATING WINDOW
--------------------------------------------------------------------------------

--- Calculate centered frame for floating window
---@param screen hs.screen|nil Screen to use (defaults to main screen)
---@return table frame {x, y, w, h}
function M.getFloatFrame(screen)
  screen = screen or hs.screen.mainScreen()
  local frame = screen:frame()

  local width = math.floor(frame.w * M.config.floatWidth)
  local height = math.floor(frame.h * M.config.floatHeight)
  local x = math.floor(frame.x + (frame.w - width) / 2)
  local y = math.floor(frame.y + (frame.h - height) / 2)

  return { x = x, y = y, w = width, h = height }
end

--- Open a floating Ghostty window with nvim editing a file
---@param filePath string Path to file to edit
---@param opts? table Options: { title?: string, onClose?: function, screen?: hs.screen }
---@return boolean success
function M.openFloatingEditor(filePath, opts)
  opts = opts or {}

  local frame = M.getFloatFrame(opts.screen)
  local title = opts.title or "Capture Note"

  -- Build Ghostty command with config overrides
  -- Using -e to run nvim with the file
  local args = {
    fmt("--class=%s", M.config.floatClass),
    fmt("--title=%s", title),
    fmt("--window-width=%d", frame.w),
    fmt("--window-height=%d", frame.h),
    "-e",
    M.config.nvimPath,
    filePath,
  }

  -- Launch Ghostty
  local task = hs.task.new(M.config.appPath .. "/Contents/MacOS/ghostty", function(exitCode, _stdOut, _stdErr)
    -- Called when Ghostty exits
    if opts.onClose then
      opts.onClose(exitCode)
    end
  end, args)

  if not task then
    hs.alert.show("Failed to create Ghostty task", 2)
    return false
  end

  task:start()

  -- Position window after it appears
  -- Ghostty doesn't support position via CLI, so we use Hammerspoon
  hs.timer.doAfter(M.config.windowWaitTime, function()
    -- Find the window by class or title
    local win = hs.window.find(M.config.floatClass) or hs.window.find(title)
    if win then
      win:setFrame(frame)
      win:focus()
    else
      -- Fallback: find most recent Ghostty window
      local app = hs.application.find("Ghostty")
      if app then
        local wins = app:allWindows()
        if #wins > 0 then
          -- Sort by creation time (newest first) and pick the first
          local newest = wins[1]
          for _, w in ipairs(wins) do
            if w:id() > newest:id() then
              newest = w
            end
          end
          newest:setFrame(frame)
          newest:focus()
        end
      end
    end
  end)

  return true
end

--- Open a floating Ghostty window with nvim at cursor position (for existing file)
---@param filePath string Path to file to edit
---@param line? number Line number to jump to
---@param opts? table Options (same as openFloatingEditor)
---@return boolean success
function M.openFloatingEditorAtLine(filePath, line, opts)
  opts = opts or {}

  local frame = M.getFloatFrame(opts.screen)
  local title = opts.title or "Capture Note"

  -- Build nvim command with line number
  local nvimArgs = { filePath }
  if line then
    table.insert(nvimArgs, 1, fmt("+%d", line))
  end

  local args = {
    fmt("--class=%s", M.config.floatClass),
    fmt("--title=%s", title),
    fmt("--window-width=%d", frame.w),
    fmt("--window-height=%d", frame.h),
    "-e",
    M.config.nvimPath,
  }
  for _, arg in ipairs(nvimArgs) do
    table.insert(args, arg)
  end

  local task = hs.task.new(M.config.appPath .. "/Contents/MacOS/ghostty", function(exitCode, _stdOut, _stdErr)
    if opts.onClose then
      opts.onClose(exitCode)
    end
  end, args)

  if not task then
    hs.alert.show("Failed to create Ghostty task", 2)
    return false
  end

  task:start()

  hs.timer.doAfter(M.config.windowWaitTime, function()
    local win = hs.window.find(M.config.floatClass) or hs.window.find(title)
    if win then
      win:setFrame(frame)
      win:focus()
    else
      local app = hs.application.find("Ghostty")
      if app then
        local wins = app:allWindows()
        if #wins > 0 then
          local newest = wins[1]
          for _, w in ipairs(wins) do
            if w:id() > newest:id() then
              newest = w
            end
          end
          newest:setFrame(frame)
          newest:focus()
        end
      end
    end
  end)

  return true
end

return M
