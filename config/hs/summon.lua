--------------------------------------------------------------------------------
-- Summon App / Toggle App Visibility
--
-- Courtesy of: https://github.com/jesseleite/dotfiles/blob/master/hammerspoon/summon.lua
--------------------------------------------------------------------------------

local lastFocusedWindow

hs.window.filter.default:subscribe(hs.window.filter.windowUnfocused, function(window) lastFocusedWindow = window end)

return function(appName)
  local id
  if APPS and APPS[appName] then
    id = APPS[appName].id
  elseif hs.application.find(appName) then
    id = hs.application.find(appName):bundleID()
  else
    id = appName
  end
  local app = hs.application.find(id)
  local currentId = hs.application.frontmostApplication():bundleID()
  if currentId == id and not next(app:allWindows()) then
    hs.application.open(id)
  elseif currentId ~= id then
    hs.application.open(id)
  elseif lastFocusedWindow then
    lastFocusedWindow:focus()
  end
end
