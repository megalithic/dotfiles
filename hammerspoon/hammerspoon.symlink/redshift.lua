-- simulate flux
local utils = require 'utils'

utils.log.df('[redshift] initializing')

hs.location.start()
local loc = hs.location.get()
utils.log.df('[redshift] getting location', loc)
hs.location.stop()

local times = {sunrise = "07:00", sunset = "20:00"}

if loc then
  local tzOffset = tonumber(string.sub(os.date("%z"), 1, -1))
  utils.log.df('[redshift] location %s; timezone offset %s', loc, tzOffset)
  for i,v in pairs({"sunrise", "sunset"}) do
    times[v] = os.date("%H:%M", hs.location[v](loc.latitude, loc.longitude, tzOffset))
  end
end

hs.redshift.start(3400, times.sunset, times.sunrise)

-- FIXME: doesn't seem to work when wrapped in the timer callback
-- hs.timer.doAfter(1, function()
--   loc = hs.location.get()
--   utils.log.df('[redshift] getting location', loc)
--   hs.location.stop()

--   local times = {sunrise = "07:00", sunset = "20:00"}

--   if loc then
--     local tzOffset = tonumber(string.sub(os.date("%z"), 1, -1))
--     utils.log.df('[redshift] location %s; timezone offset %s', loc, tzOffset)
--     for i,v in pairs({"sunrise", "sunset"}) do
--       times[v] = os.date("%H:%M", hs.location[v](loc.latitude, loc.longitude, tzOffset))
--     end
--   end

--   hs.redshift.start(3600, times.sunset, times.sunrise)
-- end)
