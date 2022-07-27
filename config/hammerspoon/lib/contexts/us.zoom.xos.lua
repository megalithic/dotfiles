local Settings = require("hs.settings")
local obj = {}
local _appObj = nil
local preferred_browsers = Settings.get(CONFIG_KEY).preferred.browsers

obj.__index = obj
obj.name = "context.zoom"
obj.debug = true

obj.modal = nil
obj.actions = {}

local function info(...)
  if obj.debug then
    return _G.info(...)
  else
    return print("")
  end
end
local function dbg(...)
  if obj.debug then
    return _G.dbg(...)
  else
    return print("")
  end
end
local function note(...)
  if obj.debug then
    return _G.note(...)
  else
    return print("")
  end
end
local function success(...)
  if obj.debug then
    return _G.success(...)
  else
    return print("")
  end
end

function obj:start(opts)
  opts = opts or {}
  _appObj = opts["appObj"]
  local event = opts["event"]

  note(fmt("[START] %s: %s", obj.name, opts))

  if event == hs.application.watcher.activated then -- and _appObj:isRunning() then
    if obj.modal then obj.modal:enter() end
  end

  if event == hs.application.watcher.launched then -- and _appObj:isRunning() then
    ----------------------------------------------------------------------
    -- handle DND toggling
    -- wh.dndHandler(app, { enabled = true, mode = "zoom" }, event)

    ----------------------------------------------------------------------
    -- pause spotify
    hs.spotify.pause()

    ----------------------------------------------------------------------
    -- mute (PTT) by default
    L.req("lib.menubar.ptt").setState("push-to-talk")

    ----------------------------------------------------------------------
    -- close web browser "zoom launching" tabs
    L.req("lib.browser").killTabsByDomain("us02web.zoom.us")

    local zoom = hs.application.get("zoom.us")
    local kitty = hs.application.get("kitty")
    local browser = hs.application.get(preferred_browsers[1])

    hs.timer.waitUntil(function() return zoom:getWindow("Zoom Meeting") end, function()
      local target_close_window = zoom:getWindow("Zoom")
      if target_close_window ~= nil then target_close_window:close() end

      local layouts = {
        { "zoom.us", "Zoom Meeting", hs.screen.primaryScreen():name(), hs.layout.left50, nil, nil },
        { browser:name(), nil, hs.screen.primaryScreen():name(), hs.layout.right50, nil, nil },
        { "kitty", nil, hs.screen.primaryScreen():name(), hs.layout.right50, nil, nil },
      }
      hs.layout.apply(layouts)
      kitty:setFrontmost(true)

      -- TODO: disabling zetty notes for now
      -- hs.timer.doAfter(0.5, function()
      -- 	hs.execute(os.getenv("HOME") .. "/.dotfiles/bin/zetty meeting", true)
      -- end)
    end)
  end

  return self
end

function obj:stop(opts)
  opts = opts or {}
  local event = opts["event"]

  note(fmt("[STOP] %s: %s", obj.name, self))

  if event == hs.application.watcher.deactivated then
    if obj.modal then obj.modal:exit() end
  end

  if event == hs.application.watcher.terminated then
    ---@diagnostic disable-next-line: unused-local
    local kitty = hs.application.get("kitty")
    local browser = hs.application.get(preferred_browsers[1])

    -- FIXME: do i really need all the error checking here?
    if browser ~= nil then
      local browser_win = browser:mainWindow()
      if browser_win ~= nil then browser_win:moveToUnit(hs.layout.maximized) end
    end

    if kitty ~= nil then
      local kitty_win = kitty:mainWindow()
      if kitty_win ~= nil then kitty_win:moveToUnit(hs.layout.maximized) end
    end

    L.req("lib.menubar.ptt").setState("push-to-talk")
  end

  return self
end

return obj
