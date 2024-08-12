G = {} -- persist from garbage collector

---Try to require the module, and do not error when one of them cannot be
---loaded, but go ahead and tell me if something is amiss.
---@param mod string module to load
--- @diagnostic disable-next-line: lowercase-global
function req(mod)
  local ok, M = pcall(require, mod)
  G[mod:sub(5)] = M

  if not ok then
    hs.alert.show(M, 5)
    print(M)
  else
    -- always return the module.. we end up immediately invoking it, usually.
    return M
  end
end

req("preflight")
req("config")
req("bindings")
-- listing of *.watcher based modules; the core of the automation that takes place.
-- NOTE: `app` contains the app layout and app context logic.
req("watchers"):start({ "bluetooth", "usb", "dock", "app", "url" })
req("ptt")
req("quitter")

-- experimental/wip modules and stuff..
req("wip")

hs.timer.doAfter(0.2, function()
  hs.notify.withdrawAll()
  hs.notify.new({ title = "hammerspork", subTitle = "config is loaded." }):send()
end)
