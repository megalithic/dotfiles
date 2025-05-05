local obj = {}
obj.__index = obj
obj.name = "ptt"
obj.debug = false

obj.momentaryKey = { "cmd", "alt" }
obj.toggleKey = { { "cmd", "alt" }, "p" }
obj.mode = "push-to-talk"
obj.tmuxMode = ""

obj.mic = hs.audiodevice.defaultInputDevice()
obj.inputs = hs.audiodevice.allInputDevices()

obj.defaultInputVolume = 55
obj.pushed = false

obj.icons = {
  ["mic-on"] = req("hs.styledtext").new("◉", {
    color = { hex = "#c43e1f" },
    font = { name = DefaultFont.name, size = 15 },
  }),
  ["push-to-mute"] = req("hs.styledtext").new("", {
    color = { hex = "#c43e1f" },
    font = { name = DefaultFont.name, size = 13 },
  }),
  ["push-to-talk"] = req("hs.styledtext").new("", {
    color = { hex = "#aaaaaa" },
    font = { name = DefaultFont.name, size = 13 },
  }),
}

local function dbg(...)
  if obj.debug then
    return _G.dbg(fmt(...), false)
  else
    return ""
  end
end

local log = {
  df = function(...) dbg(..., false) end,
}

function obj.menuKeyFormatter(tbl)
  local modLookup = {
    cmd = "⌘",
    ctrl = "⌃",
    alt = "⌥",
    opt = "⌥",
    shift = "⇧",
  }

  local s = ""

  for _, p in ipairs(tbl) do
    s = s .. " " .. modLookup[p]
  end

  -- removes first separator (+,space, etc)
  local v = string.sub(s, 2)

  return v
end

function obj.getModes(currentMode)
  currentMode = currentMode or obj.mode

  return {
    { title = "push-to-talk", mode = "push-to-talk", checked = (currentMode == "push-to-talk") },
    { title = "push-to-mute", mode = "push-to-mute", checked = (currentMode == "push-to-mute") },
  }
end

function obj.setAllInputsMuted(muted)
  local inputVolume = muted and 0 or obj.defaultInputVolume

  for _i, input in ipairs(obj.inputs) do
    input:setInputMuted(muted)
    input:setInputVolume(inputVolume)
  end

  obj.mic:setInputMuted(muted)
  obj.mic:setInputVolume(inputVolume)
end

function obj.updateMenubar()
  if obj.pushed then log.df("device to handle: %s", obj.mic) end

  local muted = false

  if obj.mode == "push-to-talk" then
    if obj.pushed then
      obj.menubar:setTitle(obj.icons["push-to-mute"] .. " " .. obj.icons["mic-on"])
      obj.tmuxMode = "◉ unmuted"
      muted = false
    else
      obj.menubar:setTitle(obj.icons["push-to-talk"])
      obj.tmuxMode = "󰍭 muted"
      muted = true
    end
  elseif obj.mode == "push-to-mute" then
    if obj.pushed then
      obj.menubar:setTitle(obj.icons["push-to-talk"])
      obj.tmuxMode = "󰍭 muted"
      muted = true
    else
      obj.menubar:setTitle(obj.icons["push-to-mute"] .. " " .. obj.icons["mic-on"])
      obj.tmuxMode = "◉ unmuted"
      muted = false
    end
  end

  obj.setAllInputsMuted(muted)
end

function obj.buildMenubar()
  local menutable = hs.fnutils.map(obj.getModes(), function(item)
    local title = ""
    if item.checked then
      title = req("utils").template(
        "{menu_title}\t\t {menu_keys}",
        { menu_title = tostring(item.title), menu_keys = obj.menuKeyFormatter(obj.momentaryKey) }
      )
    else
      title = item.title
    end

    return {
      title = title,
      fn = function() obj.setMode(item.mode) end,
      checked = item.checked,
    }
  end)

  return menutable
end

function obj.setMode(s)
  obj.mode = s
  log.df("Setting PTT mode to %s", s)

  -- local muted = obj.mode == "push-to-talk"
  -- hs.audiodevice.defaultInputDevice():setInputMuted(muted)

  if obj.menubar ~= nil then
    obj.menubar:setMenu(obj.buildMenubar())
    obj.menubar:setTitle(obj.icons[obj.mode])

    obj.updateMenubar()
  end
end
obj.setState = obj.setMode

function obj.toggleMode()
  local currentMode = obj.mode
  local toggle_to = hs.fnutils.find(obj.getModes(currentMode), function(item)
    if not item.checked then return item end
  end) or obj.mode

  obj.setMode(toggle_to.mode)

  log.df("Toggling PTT mode to %s", toggle_to.mode, currentMode)

  return toggle_to.mode
end

function obj.currentMode() return obj.tmuxMode end

function obj:start(opts)
  if opts["mode"] ~= nil then self.mode = opts["mode"] end

  self:stop()

  self.momentaryKeyWatcher = hs.eventtap.new({ hs.eventtap.event.types.flagsChanged }, function(evt)
    local modifiersMatch = function(modifiers)
      local modifiersMatch = true

      for _, key in ipairs(obj.momentaryKey) do
        if modifiers[key] ~= true then modifiersMatch = false end
      end

      return modifiersMatch
    end

    if modifiersMatch(evt:getFlags()) then
      self.pushed = true
    else
      self.pushed = false
    end

    require("utils").tmux.update()
    self.updateMenubar()
  end)
  self.momentaryKeyWatcher:start()

  if self.menubar == nil then self.menubar = hs.menubar.new() end

  self.setMode(self.mode)

  local toggleMod, toggleKey = table.unpack(self.toggleKey)
  hs.hotkey.bind(toggleMod, toggleKey, function()
    local newMode = self.toggleMode()
    hs.alert.closeAll()
    hs.alert.show("Toggled to -> " .. newMode)
  end)

  info(fmt("[START] %s (%s)", self.name, self.mode))

  return self
end

function obj:stop()
  if self.momentaryKeyWatcher then self.momentaryKeyWatcher:stop() end
  return self
end

return obj
