local log = hs.logger.new('bindings.tabjump', 'debug')
local module = {}

-- TODO: extend to support defined browsers, not just Brave

module.go = function(url)
  local app = 'Brave'

  hs.osascript.javascript([[
  (function() {
    var brave = Application(']] .. app .. [[');
    brave.activate();

    for (win of brave.windows()) {
      var tabIndex =
        win.tabs().findIndex(tab => tab.url().match(/]] .. url .. [[/));

      if (tabIndex != -1) {
        win.activeTabIndex = (tabIndex + 1);
        win.index = 1;
      }
    }
  })();
  ]])

  log.df('Opened %s in %s', app, url)
end

module.start = function()
  -- bind tabjumps
  for bundleID, app in pairs(config.apps) do
    if app.superKey ~= nil and app.shortcut ~= nil then

      if (app.tabjump ~= nil) then
        hs.hotkey.bind(app.superKey, app.shortcut, function()
          module.go(app.tabjump)
        end)
      end

    end
  end
end

module.stop = function()
  -- nil
end

return module
