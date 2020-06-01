local log = hs.logger.new('[bindings.brave]', 'warning')

local cache  = {}
local module = { cache = cache, targetAppName = 'Brave Browser Dev' }

-- module.jump = function(url)
--   hs.osascript.javascript([[
--   (function() {
--     var brave = Application('Brave');
--     brave.activate();
--     for (win of brave.windows()) {
--       var tabIndex =
--         win.tabs().findIndex(tab => tab.url().match(/]] .. url .. [[/));
--       if (tabIndex != -1) {
--         win.activeTabIndex = (tabIndex + 1);
--         win.index = 1;
--       }
--     }
--   })();
--   ]])
-- end

-- module.killTabsByTag = function(tag)
--   local toKill = fn.filter(config.websites, function(w)
--     return w.tags and fn.contains(w.tags, tag)
--   end)

--   fn.map(toKill, function(site) module.killTabsByDomain(site.url) end)
-- end

-- module.killTabsByDomain = function(domain)
--   hs.osascript.javascript([[
--   (function() {
--     var brave = Application('Brave');
--     for (win of brave.windows()) {
--       for (tab of win.tabs()) {
--         if (tab.url().match(/]] .. domain .. [[/)) {
--           tab.close()
--         }
--       }
--     }
--   })();
--   ]])
-- end

module.start = function()
  log.df("Starting [bindings.slack]..")

  cache.slack  = hs.hotkey.modal.new({}, nil)
  cache.filter = hs.window.filter.new({module.targetAppName})

  cache.filter
  :subscribe(hs.window.filter.windowFocused, function(win, appName, event)
    if appName == module.targetAppName then
      cache.slack:enter()

      cache.slack:bind({ 'ctrl' }, 'j', function()
        hs.eventtap.keyStroke({ 'alt' }, 'down')
      end)
      cache.slack:bind({ 'ctrl' }, 'k', function()
        hs.eventtap.keyStroke({ 'alt' }, 'up')
      end)
      cache.slack:bind({ 'ctrl', 'shift' }, 'j', function()
        hs.eventtap.keyStroke({ 'alt', 'shift' }, 'down')
      end)
      cache.slack:bind({ 'ctrl', 'shift' }, 'k', function()
        hs.eventtap.keyStroke({ 'alt', 'shift' }, 'up')
      end)
      cache.slack:bind({ 'cmd' }, 'w', function()
        hs.eventtap.keyStroke({}, 'escape')
      end)
      cache.slack:bind({ 'cmd' }, 'r', function()
        hs.eventtap.keyStroke({}, 'escape')
      end)
      cache.slack:bind({ 'ctrl' }, 'g', function()
        hs.eventtap.keyStroke({ 'cmd' }, 'k')
      end)
    end
  end)
  :subscribe(hs.window.filter.windowUnfocused , function(_, appName, event)
    cache.slack:exit()
  end)
end

module.stop = function()
  log.df("Stopping [bindings.slack]..")

  cache.slack:exit()
end

return module
