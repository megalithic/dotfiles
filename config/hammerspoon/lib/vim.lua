-- DISABLING FOR NOW
-- local VimMode = hs.loadSpoon("VimMode")
local vim = VimMode:new()

hs.chooser.globalCallback = function(chooser, eventName)
  hs.chooser._defaultGlobalCallback(chooser, eventName)

  if eventName == "willOpen" then
    vim:disable()
  else
    vim:enable()
  end
end

-- Configure apps you do *not* want Vim mode enabled in
-- For example, you don't want this plugin overriding your control of Terminal
-- vim
vim
  :disableForApp("kitty")
  :disableForApp("Alacritty")
  :disableForApp("Obsidian")
  :disableForApp("Code")
  :disableForApp("Terminal")
  :disableForApp("Tuple")
  :disableForApp("Visual Studio Code")
  :disableForApp("iTerm")
  :disableForApp("iTerm2")
  :disableForApp("zoom.us")

vim:enableBetaFeature("block_cursor_overlay")

vim:enableBetaFeature("fallback_only_urls")
vim:setFallbackOnlyUrlPatterns({
  "docs.google.com",
})

-- If you want the screen to dim (a la Flux) when you enter normal mode
-- flip this to true.
vim:shouldDimScreenInNormalMode(false)

-- If you want to show an on-screen alert when you enter normal mode, set
-- this to true
vim:shouldShowAlertInNormalMode(true)

vim:setAlertFont("JetBrainsMono Nerd Font")

-- Enter normal mode by typing a key sequence
vim:enterWithSequence("jk", 100)
-- if you want to bind a single key to entering vim, remove the
-- :enterWithSequence('jk') line above and uncomment the bindHotKeys line
-- below:
--
-- To customize the hot key you want, see the mods and key parameters at:
--   https://www.hammerspoon.org/docs/hs.hotkey.html#bind
--
-- vim:bindHotKeys({ enter = { {'ctrl'}, ';' } })
--------------------------------
-- END VIM CONFIG
--------------------------------
--
