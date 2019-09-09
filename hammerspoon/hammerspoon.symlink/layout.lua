-- local config = require('config')
-- local hyper = require("hyper")
-- local num_of_screens = 0
-- local log = hs.logger.new('[layout]', 'debug')

-- targetDisplay = function(display_int)
--   -- detect the current number of monitors
--   displays = hs.screen.allScreens()
--   if displays[display_int] ~= nil then
--     return displays[display_int]
--   else
--     return hs.screen.primaryScreen()
--   end
-- end

-- autoLayout = function()
--   for _, app_config in pairs(config.applications) do
--     -- if we have a preferred display
--     if app_config.preferred_display ~= nil then
--       application = hs.application.find(app_config.hint)

--       if application ~= nil and application:mainWindow() ~= nil then
--         application
--         :mainWindow()
--         :moveToScreen(targetDisplay(app_config.preferred_display), false, true, 0)
--         :moveToUnit(hs.layout.maximized)
--       end
--     end
--   end
-- end

-- watcher = hs.screen.watcher.new(function()
--   if num_of_screens ~= #hs.screen.allScreens() then
--     print("I'm autolayouting!")
--     autoLayout()
--     num_of_screens = #hs.screen.allScreens()
--   end
-- end):start()

-- hyper:bind({}, 'return', nil, autoLayout)
