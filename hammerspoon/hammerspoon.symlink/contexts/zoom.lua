local log = hs.logger.new('[contexts.zoom]', 'debug')

-- TODO:
-- 1. DND toggling
-- 2. Window layout and closing
-- 3. Spotify pause
-- 4. Check output/input and set correctly
-- 5. Set PTT is on (e.g., mute by default)

local cache  = {}
local module = { cache = cache, }

module.localBindings = function()
  return {
  }
end

module.apply = function(event)
end

return module
