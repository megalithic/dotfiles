local obj = {}
local appObj = nil

obj.__index = obj
obj.name = "context.apple.preview"
obj.debug = true

obj.modal = true
obj.actions = {
  selectRectangularSelection = {
    action = function() appObj:selectMenuItem({ "Tools", "Rectangular Selection" }) end,
    hotkey = { "ctrl", "r" },
  },
  cropSelectionK = {
    action = function() appObj:selectMenuItem({ "Tools", "Crop" }) end,
    hotkey = { "ctrl", "k" },
  },
  cropSelectionT = {
    action = function() appObj:selectMenuItem({ "Tools", "Crop" }) end,
    hotkey = { "ctrl", "t" },
  },
}

function obj:start(opts)
  opts = opts or {}
  appObj = opts["appObj"]
  local event = opts["event"]
  local bundleID = opts["bundleID"]

  -- if
  --   event == hs.application.watcher.launched
  --   and appObj:bundleID() == bundleID
  --   and appObj:bundleID() == "com.apple.Preview"
  -- then
  --   appObj:selectMenuItem({ "Tools", "Rectangular Selection" })
  -- end

  if event == hs.application.watcher.activated then
    -- function obj.modal:entered() info("entered com.apple.Preview modal") end

    if obj.modal then obj.modal:enter() end
  end

  return self
end

function obj:stop(opts)
  opts = opts or {}
  if obj.modal then obj.modal:exit() end
  return self
end

return obj
