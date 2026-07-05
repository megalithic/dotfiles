-- Pasteboard Watcher Module
-- Generic pasteboard monitoring with hook API
--
-- Usage:
--   local pb = require("watchers.pasteboard")
--   pb.addHook("image", function(image) ... end)
--   pb.addHook("text", function(text) ... end)
--   pb:start()
--

--------------------------------------------------------------------------------
-- TYPE DEFINITIONS
--------------------------------------------------------------------------------

---@alias PasteboardContentType "image"|"text"|"url"|"file"|"any"

---@class PasteboardHook
---@field id string Unique hook identifier
---@field type PasteboardContentType Content type to watch for
---@field callback fun(content: any, metadata: PasteboardMetadata) Hook callback
---@field priority? number Higher priority hooks run first (default: 0)

---@class PasteboardMetadata
---@field contentType PasteboardContentType Detected content type
---@field changeCount number Pasteboard change count
---@field timestamp number Unix timestamp of change
---@field utis string[] Available UTI types

---@class PasteboardWatcherModule
---@field hooks table<string, PasteboardHook> Registered hooks by ID
---@field watcher hs.pasteboard.watcher|nil Active watcher
---@field lastChangeCount number Last seen change count
---@field running boolean Whether watcher is active

local fmt = string.format

---@type PasteboardWatcherModule
local M = {}

--------------------------------------------------------------------------------
-- STATE
--------------------------------------------------------------------------------

M.hooks = {}
M.watcher = nil
M.lastChangeCount = 0
M.running = false

--------------------------------------------------------------------------------
-- CONTENT DETECTION
--------------------------------------------------------------------------------

---Detect the primary content type on the pasteboard
---@return PasteboardContentType type
---@return any content The content value
---@return string[] utis Available UTI types
local function detectContent()
  local utis = hs.pasteboard.contentTypes() or {}
  
  -- Check for image first (highest priority for clipper use case)
  local image = hs.pasteboard.readImage()
  if image then
    return "image", image, utis
  end
  
  -- Check for file URLs
  local fileURLs = hs.pasteboard.readDataForUTI("public.file-url")
  if fileURLs then
    return "file", fileURLs, utis
  end
  
  -- Check for URLs
  local url = hs.pasteboard.readString()
  if url and url:match("^https?://") then
    return "url", url, utis
  end
  
  -- Default to text
  local text = hs.pasteboard.readString()
  if text then
    return "text", text, utis
  end
  
  return "any", nil, utis
end

--------------------------------------------------------------------------------
-- HOOK MANAGEMENT
--------------------------------------------------------------------------------

---Add a hook for pasteboard changes
---@param contentType PasteboardContentType Type to watch ("image", "text", "url", "file", "any")
---@param callback fun(content: any, metadata: PasteboardMetadata) Callback function
---@param opts? { id?: string, priority?: number } Options
---@return string hookId The hook identifier (for removal)
function M.addHook(contentType, callback, opts)
  opts = opts or {}
  local id = opts.id or (contentType .. "_" .. tostring(os.time()) .. math.random(1000))
  
  M.hooks[id] = {
    id = id,
    type = contentType,
    callback = callback,
    priority = opts.priority or 0,
  }
  
  return id
end

---Remove a hook by ID
---@param hookId string Hook identifier
---@return boolean success Whether hook was found and removed
function M.removeHook(hookId)
  if M.hooks[hookId] then
    M.hooks[hookId] = nil
    return true
  end
  return false
end

---Clear all hooks
function M.clearHooks()
  M.hooks = {}
end

---Get all hooks, sorted by priority (highest first)
---@return PasteboardHook[]
local function getSortedHooks()
  local sorted = {}
  for _, hook in pairs(M.hooks) do
    table.insert(sorted, hook)
  end
  table.sort(sorted, function(a, b)
    return (a.priority or 0) > (b.priority or 0)
  end)
  return sorted
end

--------------------------------------------------------------------------------
-- WATCHER CALLBACKS
--------------------------------------------------------------------------------

---Handle pasteboard change
---@param pbContents string|nil Text contents (nil if not text)
local function onPasteboardChange(pbContents)
  local changeCount = hs.pasteboard.changeCount()
  
  -- Avoid duplicate processing
  if changeCount == M.lastChangeCount then
    return
  end
  M.lastChangeCount = changeCount
  
  -- Detect content type
  local contentType, content, utis = detectContent()
  
  -- Skip if no content
  if content == nil and contentType ~= "any" then
    return
  end
  
  -- Build metadata
  local metadata = {
    contentType = contentType,
    changeCount = changeCount,
    timestamp = os.time(),
    utis = utis,
  }
  
  -- Call matching hooks
  local hooks = getSortedHooks()
  for _, hook in ipairs(hooks) do
    if hook.type == "any" or hook.type == contentType then
      -- Protected call to prevent one hook from breaking others
      local ok, err = pcall(hook.callback, content, metadata)
      if not ok then
        U.log.e(fmt("hook '%s' error: %s", hook.id, err))
      end
    end
  end
end

--------------------------------------------------------------------------------
-- LIFECYCLE
--------------------------------------------------------------------------------

---Start the pasteboard watcher
---@return PasteboardWatcherModule self
function M:start()
  -- Defensive: stop existing watcher to avoid duplicates on reload
  if M.watcher then
    M.watcher:stop()
    M.watcher = nil
  end
  
  M.lastChangeCount = hs.pasteboard.changeCount()
  
  M.watcher = hs.pasteboard.watcher.new(onPasteboardChange)
  M.watcher:start()
  
  M.running = true
  U.log.d("watcher started")
  
  return self
end

---Stop the pasteboard watcher
---@return PasteboardWatcherModule self
function M:stop()
  if not M.running then
    return self
  end
  
  if M.watcher then
    M.watcher:stop()
    M.watcher = nil
  end
  
  M.running = false
  U.log.d("watcher stopped")
  
  return self
end

---Check if watcher is running
---@return boolean
function M:isRunning()
  return M.running
end

---Get count of registered hooks
---@return number
function M:hookCount()
  local count = 0
  for _ in pairs(M.hooks) do
    count = count + 1
  end
  return count
end

return M
