-- Selection Capture Module
-- Wrapper for bin/get-selection Swift script (Accessibility API-based)
-- Does NOT touch the clipboard - queries kAXSelectedTextAttribute directly
--
local M = {}
local fmt = string.format

-- Path to the Swift script
M.scriptPath = os.getenv("HOME") .. "/.dotfiles/bin/get-selection"

--------------------------------------------------------------------------------
-- ASYNC SELECTION CAPTURE
--------------------------------------------------------------------------------

---@class SelectionResult
---@field hasSelection boolean Whether there was selected text
---@field selectedText string|nil The selected text (if any)
---@field app { bundleID: string|nil, name: string|nil }|nil Source app info
---@field window { title: string|nil }|nil Window info
---@field url string|nil URL if source was a browser
---@field timestamp string ISO8601 timestamp
---@field appType "browser"|"terminal"|"editor"|"communication"|"other" Detected app category

--- Categorize app by bundle ID (matches Swift script logic)
---@param bundleID string|nil
---@return "browser"|"terminal"|"editor"|"communication"|"other"
local function categorizeApp(bundleID)
  if not bundleID then return "other" end
  local id = bundleID:lower()

  -- Browsers
  local browsers = { "safari", "chrome", "brave", "firefox", "edge", "opera", "thebrowser", "vivaldi" }
  for _, b in ipairs(browsers) do
    if id:find(b) then return "browser" end
  end

  -- Terminals
  local terminals = { "terminal", "iterm", "kitty", "ghostty", "wezterm", "alacritty", "hyper" }
  for _, t in ipairs(terminals) do
    if id:find(t) then return "terminal" end
  end

  -- Editors/IDEs
  local editors = { "nvim", "vim", "neovim", "vscode", "xcode", "sublime", "textedit", "bbedit", "nova", "zed" }
  for _, e in ipairs(editors) do
    if id:find(e) then return "editor" end
  end

  -- Communication
  local comms = { "slack", "teams", "discord", "messages", "mail", "telegram", "signal" }
  for _, c in ipairs(comms) do
    if id:find(c) then return "communication" end
  end

  return "other"
end

--- Get selected text and context asynchronously via Swift script
--- Uses hs.task.new() for non-blocking execution
---@param callback fun(result: SelectionResult|nil, error: string|nil)
function M.get(callback)
  if not callback then error("selection.get() requires a callback function") end

  -- Check script exists
  local f = io.open(M.scriptPath, "r")
  if not f then
    callback(nil, "get-selection script not found at: " .. M.scriptPath)
    return
  end
  f:close()

  -- Run async
  local task = hs.task.new(M.scriptPath, function(exitCode, stdOut, stdErr)
    if exitCode ~= 0 then
      local errMsg = stdErr and stdErr ~= "" and stdErr or fmt("exit code %d", exitCode)
      callback(nil, "get-selection failed: " .. errMsg)
      return
    end

    -- Parse JSON response
    local ok, result = pcall(hs.json.decode, stdOut)
    if not ok or not result then
      callback(nil, "Failed to parse JSON from get-selection: " .. (stdOut or "(empty)"))
      return
    end

    -- Add appType categorization
    local bundleID = result.app and result.app.bundleID
    result.appType = categorizeApp(bundleID)

    callback(result, nil)
  end, { "--json" })

  if not task then
    callback(nil, "Failed to create task for get-selection")
    return
  end

  task:start()
end

--------------------------------------------------------------------------------
-- SYNCHRONOUS WRAPPER (for simple use cases)
--------------------------------------------------------------------------------

--- Get selected text and context synchronously
--- Uses hs.execute() which is already synchronous (no event loop required)
---@param timeout number|nil Timeout in seconds (unused, kept for API compat)
---@return SelectionResult|nil result
---@return string|nil error
function M.getSync(timeout)
  -- Note: timeout parameter kept for API compatibility but hs.execute has its own timeout

  -- Check script exists
  local f = io.open(M.scriptPath, "r")
  if not f then return nil, "get-selection script not found at: " .. M.scriptPath end
  f:close()

  -- Run synchronously via hs.execute (blocks but doesn't need event loop)
  local output, success, _, _ = hs.execute(M.scriptPath .. " --json", true)

  if not success then return nil, "get-selection failed: " .. (output or "unknown error") end

  -- Strip ANSI escape codes that may leak from terminal apps when queried via AX API
  -- Pattern matches ESC[ followed by any parameters and a final letter (CSI sequences)
  output = output:gsub("\27%[[%d;]*%??[%d;]*[a-zA-Z]", "")

  -- Parse JSON response
  local ok, result = pcall(hs.json.decode, output)
  if not ok or not result then return nil, "Failed to parse JSON from get-selection: " .. (output or "(empty)") end

  -- Add appType categorization
  local bundleID = result.app and result.app.bundleID
  result.appType = categorizeApp(bundleID)

  return result, nil
end

--------------------------------------------------------------------------------
-- CONVENIENCE METHODS
--------------------------------------------------------------------------------

--- Check if there's currently selected text (async)
---@param callback fun(hasSelection: boolean)
function M.hasSelection(callback)
  M.get(function(result, _) callback(result and result.hasSelection or false) end)
end

--- Get just the selected text (async)
---@param callback fun(text: string|nil)
function M.getText(callback)
  M.get(function(result, _)
    if result and result.hasSelection then
      callback(result.selectedText)
    else
      callback(nil)
    end
  end)
end

--------------------------------------------------------------------------------
-- DEBUG
--------------------------------------------------------------------------------

--- Debug helper: print selection info to console
function M.debug()
  M.get(function(result, err)
    if err then
      print("[selection] Error: " .. err)
      return
    end

    print("\n[selection] Current selection:")
    print(string.rep("─", 60))
    print(fmt("  hasSelection: %s", tostring(result.hasSelection)))
    if result.app then
      print(fmt("  app.bundleID: %s", result.app.bundleID or "(nil)"))
      print(fmt("  app.name: %s", result.app.name or "(nil)"))
    end
    if result.window then print(fmt("  window.title: %s", result.window.title or "(nil)")) end
    print(fmt("  url: %s", result.url or "(nil)"))
    print(fmt("  appType: %s", result.appType))
    print(fmt("  timestamp: %s", result.timestamp))
    if result.hasSelection then
      local preview = result.selectedText:sub(1, 100)
      if #result.selectedText > 100 then preview = preview .. "..." end
      print(fmt("  selectedText: %s", preview))
    end
    print(string.rep("─", 60) .. "\n")
  end)
end

return M
