-- local hyper = require("hyper")

tabjump = function(url)
  hs.osascript.javascript([[
  (function() {
    var brave = Application('Brave');
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
end

return tabjump
