-- Minimal v1 config for the Atlas end-to-end test: F19 as a bare Carbon
-- hotkey entering a hyper modal, as config/hammerspoon/hyper.lua does, with
-- hyper+n (the binding v2's layer also claims) and hyper+j bound.
local logPath = os.getenv("HOME") .. "/hs1-e2e.log"

local function log(line)
  local f = io.open(logPath, "a")
  f:write(line .. "\n")
  f:close()
end

local hyper = hs.hotkey.modal.new()
Hyper = hs.hotkey.bind({}, "F19", function()
  hyper:enter()
  log("v1 hyper down")
end, function()
  hyper:exit()
  log("v1 hyper up")
end)
hyper:bind({}, "n", function() log("v1 hyper+n") end)
hyper:bind({}, "j", function() log("v1 hyper+j") end)

log("v1 e2e loaded")
