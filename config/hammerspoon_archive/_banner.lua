-- [ BANNER ] ------------------------------------------------------------------

P()
info("----------------------------------------------------")
info("░  Application Path: " .. hs.processInfo.bundlePath)
info("░  Accessibility: " .. tostring(hs.accessibilityState()))
if hs.processInfo.debugBuild then
  local gitbranchfile = hs.processInfo.resourcePath .. "/gitbranch"
  local gfile = io.open(gitbranchfile, "r")
  if gfile then
    GITBRANCH = gfile:read("l")
    gfile:close()
  else
    GITBRANCH = "<" .. gitbranchfile .. " missing>"
  end
  success("░  Debug Version: " .. hs.processInfo.version .. ", " .. hs.processInfo.buildTime)
  success("░  Build: " .. GITBRANCH)
else
  info("░  Release Version: " .. hs.processInfo.version)
end
info("░  Hostname: " .. hostname())
info("----------------------------------------------------")
P()
