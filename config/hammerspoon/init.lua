G = {} -- persist from garbage collector

require("preflight")

--- @diagnostic disable-next-line: lowercase-global
function req(mod, ...)
  local ok, reqmod = pcall(require, mod)
  if not ok then
    -- hs.alert.show(M, 5)
    error(reqmod)
  else
    -- if there is an init function; invoke it first.
    if type(reqmod) == "table" and reqmod.init ~= nil and type(reqmod.init) == "function" then reqmod:init(...) end

    -- always return the module.. we typically end up immediately invoking it.
    return reqmod
  end
end

-- Our listing of *.watcher based modules; the core of the automation that takes place.
-- NOTE: `app` contains the app layout and app context logic.
local watchers = { "bluetooth", "usb", "dock", "app", "url", "files" }

req("config")
req("bindings")
req("watchers"):start(watchers)
req("ptt"):start({ mode = "push-to-talk" })
req("quitter"):start({ mode = "double" })

-- experimental/wip modules and stuff..
req("wip")

hs.shutdownCallback = function() req("watchers"):stop(watchers) end

hs.timer.doAfter(0.2, function()
  hs.notify.withdrawAll()
  hs.notify.new({ title = "hammerspork", subTitle = "config is loaded." }):send()
end)
