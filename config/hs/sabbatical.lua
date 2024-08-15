-- simple reminder to look away from the screen periodically
local obj = {}
obj.__index = obj
obj.name = "sabbatical"
obj.debug = false
obj.timer = nil

local drawing = require("hs.drawing")
local timer = require("hs.timer")
local uuid = require("hs.host").uuid
local restDuration = 1 -- in minutes

obj._screenShades = {}
obj._start_sound_name = "Morse"
obj._stop_sound_name = "Blow"

local start_sound = require("hs.sound").getByName(obj._start_sound_name)
local stop_sound = require("hs.sound").getByName(obj._stop_sound_name)

local purgeShade = function(UUID)
  local indexToRemove
  for i, v in ipairs(obj._screenShades) do
    if v.UUID == UUID then
      if v.timer then v.timer:stop() end
      v.drawing:hide()
      indexToRemove = i
      break
    end
  end
  if indexToRemove then table.remove(obj._screenShades, indexToRemove) end
  stop_sound:play()
end

function obj:shade()
  hs.alert.closeAll()
  local str = "Look 20 feet away for 20 seconds."
  hs.fnutils.imap(hs.screen.allScreens(), function(screen)
    local UUID = uuid()
    local shade = {
      drawing = drawing.rectangle(screen:fullFrame()),
      screen = screen,
      UUID = UUID,
    }

    --shade characteristics
    --white - the ratio of white to black from 0.0 (completely black) to 1.0 (completely white); default = 0.
    --alpha - the color transparency from 0.0 (completely transparent) to 1.0 (completely opaque)
    shade.drawing:setFillColor({ ["white"] = 0, ["alpha"] = 0.8 })

    --set to cover the whole screen, all spaces and expose
    shade.drawing:bringToFront(true):setBehavior(17)

    shade.drawing:show()
    table.insert(obj._screenShades, shade)
    shade.timer = timer.doAfter(restDuration, function() purgeShade(UUID) end)
    -- start_sound:play()
    return hs.alert.show(str, hs.alert.defaultStyle, screen, restDuration)
  end)
end

function obj:start()
  self.timer = hs.timer.new(restDuration * 60, self.shade)
  self.timer:start()

  info(fmt("[START] %s", self.name))
end
