G = {} -- persist from garbage collector

require("preflight")

--- @diagnostic disable-next-line: lowercase-global
function req(mod)
  local ok, M = pcall(require, mod)
  if not ok then
    -- hs.alert.show(M, 5)
    error(M)
  else
    -- always return the module.. we typically end up immediately invoking it.
    return M
  end
end

req("config")
req("bindings")
-- listing of *.watcher based modules; the core of the automation that takes place.
-- NOTE: `app` contains the app layout and app context logic.
req("watchers"):start({ "bluetooth", "usb", "dock", "app", "url" })
req("ptt"):start({ mode = "push-to-talk" })
req("quitter"):start({ mode = "double" })

-- experimental/wip modules and stuff..
req("wip")

hs.timer.doAfter(0.2, function()
  hs.notify.withdrawAll()
  hs.notify.new({ title = "hammerspork", subTitle = "config is loaded." }):send()
end)
