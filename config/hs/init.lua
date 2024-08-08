G = {} -- persist from garbage collector

---Try to require the module, and do not error when one of them cannot be
---loaded, but do notify if there was an error.
---@param mod string module to load
function req(mod)
  local ok, M = pcall(require, mod)
  G[mod:sub(5)] = M
  if not ok then
    hs.alert.show(M, 5)
    print(M)
  else
    return M
  end
end

req("preflight")
req("config")
req("bindings")
req("watchers"):start({ "bluetooth", "usb", "dock", "app", "url" })
req("ptt")
req("quitter")
req("wip")

hs.notify.withdrawAll()
hs.notify.new({ title = "hammerspork", subTitle = "config is loaded." }):send()
