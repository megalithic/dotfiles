local obj = {}

obj.__index = obj
obj.name = "utils"
obj.debug = false

obj.dndCmd = os.getenv("HOME") .. "/.dotfiles/bin/dnd"
obj.slckCmd = os.getenv("HOME") .. "/.dotfiles/bin/slck"

function obj.template(template, vars) return string.gsub(template, "{(.-)}", vars) end

--- utils.scriptPath([n]) -> string
--- Function
--- Return path of the current spoon.
---
--- Parameters:
---  * n - (optional) stack level for which to get the path. Defaults to 2, which will return the path of the spoon which called `scriptPath()`
---
--- Returns:
---  * String with the path from where the calling code was loaded.
function obj.scriptPath(n)
  if n == nil then n = 2 end
  local str = debug.getinfo(n, "S").source:sub(2)
  return str:match("(.*/)")
end

--- utils.resourcePath(partial) -> string
--- Function
--- Return full path of an object within a spoon directory, given its partial path.
---
--- Parameters:
---  * partial - path of a file relative to the Spoon directory. For example `images/img1.png` will refer to a file within the `images` directory of the Spoon.
---
--- Returns:
---  * Absolute path of the file. Note: no existence or other checks are done on the path.
function obj.resourcePath(partial) return (obj.scriptPath(3) .. partial) end

function obj.eventString(e)
  local a = hs.application.watcher

  if type(e) == "string" then return e end

  local enum_tbl = {
    [0] = { "launching", a.launching },
    [1] = { "launched", a.launched },
    [2] = { "terminated", a.terminated },
    [3] = { "hidden", a.hidden },
    [4] = { "unhidden", a.unhidden },
    [5] = { "activated", a.activated },
    [6] = { "deactivated", a.deactivated },
  }

  return table.unpack(enum_tbl[e])
end

function obj.tlen(t)
  local len = 0
  for _ in pairs(t) do
    len = len + 1
  end
  return len
end

---@param dndStatus boolean|string dnd status on or off as a boolean to pass to the dnd binary
---@param slackStatus string|nil slack status to pass to the slck binary
function obj.dnd(dndStatus, slackStatus)
  if type(dndStatus) == "boolean" then dndStatus = dndStatus and "on" or "off" end

  if dndStatus ~= nil then
    hs.task
      .new(obj.dndCmd, function(_stdTask, _stdOut, _stdErr) info("[DND]: " .. dndStatus) end, { dndStatus })
      :start()
  end

  -- if slackStatus ~= nil and slackStatus ~= "" then obj.slack(slackStatus) end
end

-- TODO:
-- https://github.com/kiooss/dotmagic/blob/master/hammerspoon/slack.lua
function obj.slack(slackStatus)
  if slackStatus ~= nil and slackStatus ~= "" then
    local slck = hs.task.new("/opt/homebrew/bin/zsh", function(stdTask, stdOut, stdErr)
      dbg({ stdTask, stdOut, stdErr }, true)
      info("[SLCK]: " .. slackStatus)
    end, { "-lc", obj.slckCmd, slackStatus })
    -- local slck = hs.task.new(obj.slckCmd, function(stdTask, stdOut, stdErr)
    --   dbg({ stdTask, stdOut, stdErr }, true)
    --   info("[SLCK]: " .. slackStatus)
    -- end, { slackStatus })
    slck:setEnvironment({
      TERM = "xterm-256color",
      -- HOMEBREW_PREFIX = "/opt/homebrew",
      -- HOME = os.getenv("HOME"),
      -- PATH = os.getenv("PATH") .. ":/opt/homebrew/bin",
    })

    slck:start()

    dbg({ slck }, true)
  end
end

function obj.showAvailableHotkeys()
  local white = hs.drawing.color.white
  local black = hs.drawing.color.black
  local blue = hs.drawing.color.blue
  local osx_red = hs.drawing.color.osx_red
  local osx_green = hs.drawing.color.osx_green
  local osx_yellow = hs.drawing.color.osx_yellow
  local tomato = hs.drawing.color.x11.tomato
  local dodgerblue = hs.drawing.color.x11.dodgerblue
  local firebrick = hs.drawing.color.x11.firebrick
  local lawngreen = hs.drawing.color.x11.lawngreen
  local lightseagreen = hs.drawing.color.x11.lightseagreen
  local purple = hs.drawing.color.x11.purple
  local royalblue = hs.drawing.color.x11.royalblue
  local sandybrown = hs.drawing.color.x11.sandybrown
  local black50 = { red = 0, blue = 0, green = 0, alpha = 0.5 }
  local darkblue = { red = 24 / 255, blue = 195 / 255, green = 145 / 255, alpha = 1 }
  local gray = { red = 246 / 255, blue = 246 / 255, green = 246 / 255, alpha = 0.3 }
  -- scrape and list setup hotkeys
  if not hotkeytext then
    local hotkey_list = hs.hotkey.getHotkeys()
    local mainScreen = hs.screen.mainScreen()
    local mainRes = mainScreen:fullFrame()
    local localMainRes = mainScreen:absoluteToLocal(mainRes)
    local hkbgrect = hs.geometry.rect(
      mainScreen:localToAbsolute(localMainRes.w / 5, localMainRes.h / 5, localMainRes.w / 5 * 3, localMainRes.h / 5 * 3)
    )
    hotkeybg = hs.drawing.rectangle(hkbgrect)
    -- hotkeybg:setStroke(false)
    if not hotkey_tips_bg then hotkey_tips_bg = "light" end
    if hotkey_tips_bg == "light" then
      hotkeybg:setFillColor({ red = 238 / 255, blue = 238 / 255, green = 238 / 255, alpha = 0.95 })
    elseif hotkey_tips_bg == "dark" then
      hotkeybg:setFillColor({ red = 0, blue = 0, green = 0, alpha = 0.95 })
    end
    hotkeybg:setRoundedRectRadii(10, 10)
    hotkeybg:setLevel(hs.drawing.windowLevels.modalPanel)
    hotkeybg:behavior(hs.drawing.windowBehaviors.stationary)
    local hktextrect = hs.geometry.rect(hkbgrect.x + 40, hkbgrect.y + 30, hkbgrect.w - 80, hkbgrect.h - 60)
    hotkeytext = hs.drawing.text(hktextrect, "")
    hotkeytext:setLevel(hs.drawing.windowLevels.modalPanel)
    hotkeytext:behavior(hs.drawing.windowBehaviors.stationary)
    hotkeytext:setClickCallback(nil, function()
      hotkeytext:delete()
      hotkeytext = nil
      hotkeybg:delete()
      hotkeybg = nil
    end)
    hotkey_filtered = {}
    for i = 1, #hotkey_list do
      if hotkey_list[i].idx ~= hotkey_list[i].msg then table.insert(hotkey_filtered, hotkey_list[i]) end
    end
    local availablelen = 70
    local hkstr = ""
    for i = 2, #hotkey_filtered, 2 do
      local tmpstr = hotkey_filtered[i - 1].msg .. hotkey_filtered[i].msg
      if string.len(tmpstr) <= availablelen then
        local tofilllen = availablelen - string.len(hotkey_filtered[i - 1].msg)
        hkstr = hkstr
          .. hotkey_filtered[i - 1].msg
          .. string.format("%" .. tofilllen .. "s", hotkey_filtered[i].msg)
          .. "\n"
      else
        hkstr = hkstr .. hotkey_filtered[i - 1].msg .. "\n" .. hotkey_filtered[i].msg .. "\n"
      end
    end
    if math.fmod(#hotkey_filtered, 2) == 1 then hkstr = hkstr .. hotkey_filtered[#hotkey_filtered].msg end
    local hkstr_styled = hs.styledtext.new(hkstr, {
      font = { name = "Courier-Bold", size = 16 },
      color = dodgerblue,
      paragraphStyle = { lineSpacing = 12.0, lineBreak = "truncateMiddle" },
      shadow = { offset = { h = 0, w = 0 }, blurRadius = 0.5, color = darkblue },
    })
    hotkeytext:setStyledText(hkstr_styled)
    hotkeybg:show()
    hotkeytext:show()
  else
    hotkeytext:delete()
    hotkeytext = nil
    hotkeybg:delete()
    hotkeybg = nil
  end
end

return obj
