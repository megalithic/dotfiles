local enum = req("hs.fnutils")
local browser = req("browser")
local obj = {}

obj.__index = obj
obj.name = "context.brave.browser.nightly"
obj.debug = true

obj.modal = false
obj.actions = {}

function obj.browserTabWatcher(_event, metadata)
  if metadata ~= nil and metadata.url ~= nil then
    if browser.hasTab(metadata.url) then
      -- if browser.tabCount() == metadata.tabCount + 1 and browser.hasTab(metadata.url) then
      hs.spotify.pause()
      req("utils").dnd(true)
      req("ptt").setMode("push-to-talk")
      req("watchers.dock").refreshInput("docked")

      -- hacky way of detecting when the tab is closed
      hs.timer.waitUntil(
        function() return not browser.hasTab(metadata.url) end,
        -- function() return browser.tabCount() == metadata.tabCount and not browser.hasTab(metadata.url) end,
        function()
          req("utils").dnd(false)
          req("ptt").setMode("push-to-talk")
        end
      )
    end
  end
end

function obj:start(opts)
  opts = opts or {}
  local event = opts["event"]
  local metadata = opts["metadata"]

  --
  -- TODO:
  -- - add ability to track the opening of specific tabs, as well as closing.
  --
  if enum.contains({ hs.application.watcher.activated, hs.application.watcher.launched }, event) then
    if obj.modal then obj.modal:enter() end

    obj.browserTabWatcher(event, metadata)
  end

  return self
end

function obj:stop(opts)
  opts = opts or {}

  if obj.modal then obj.modal:exit() end

  return self
end

return obj