-- Puts Wi-Fi ahead of Ethernet in the network service order while Wi-Fi is on
-- the phone hotspot, and puts Ethernet back ahead when Wi-Fi leaves it.
-- Event-driven: configd pushes IPv4 changes for the Wi-Fi interface; nothing polls.
-- No sudo needed: Apple entitles networksetup for the network-settings right.

local M = {}

M._stopped = true
M._store = nil
M._task = nil
M._dirty = false

local NETWORKSETUP = "/usr/sbin/networksetup"

local function ipv4Key() return string.format("State:/Network/Interface/%s/IPv4", C.hotspot.interface) end

local function notify(message)
  U.log.w(message)
  hs.notify.new({ title = "Hammerspoon hotspot", subTitle = message }):send()
end

-- Service names from `networksetup -listnetworkserviceorder`, in order.
-- Lines look like "(1) Wi-Fi"; disabled services show "(*)" instead of a number.
function M.parseOrder(output)
  local names = {}
  for line in output:gmatch("[^\n]+") do
    local name = line:match("^%([%d%*]+%) (.+)$")
    if name then table.insert(names, name) end
  end
  return names
end

-- Returns a new order with `first` directly ahead of `second`, or nil when it
-- already is ahead or either service is missing. Other services keep their place.
function M.moveAhead(names, first, second)
  local firstIdx, secondIdx
  for i, name in ipairs(names) do
    if name == first then
      firstIdx = i
    elseif name == second then
      secondIdx = i
    end
  end
  if not firstIdx or not secondIdx or firstIdx < secondIdx then return nil end

  local order = {}
  for i, name in ipairs(names) do
    if i == secondIdx then table.insert(order, first) end
    if i ~= firstIdx then table.insert(order, name) end
  end
  return order
end

function M.isOnHotspot()
  local key = ipv4Key()
  local ipv4 = (M._store and M._store:contents(key) or {})[key]
  local prefix = C.hotspot.subnetPrefix
  for _, address in ipairs(ipv4 and ipv4.Addresses or {}) do
    if address:sub(1, #prefix) == prefix then return true end
  end
  return false
end

local reconcile

-- One task at a time. Changes that arrive mid-run set _dirty and rerun after.
local function run(launchPath, args, callback)
  local task
  task = hs.task.new(launchPath, function(exitCode, stdOut, stdErr)
    if M._task ~= task then return end
    M._task = nil
    callback(exitCode, stdOut or "", stdErr or "")
    if M._dirty and not M._task then
      M._dirty = false
      reconcile()
    end
  end, args)

  M._task = task
  if not task or task:start() == false then
    M._task = nil
    U.log.wf("hotspot: could not start %s", launchPath)
  end
end

reconcile = function()
  if M._stopped then return end
  if M._task then
    M._dirty = true
    return
  end

  local first, second = C.hotspot.ethernetService, C.hotspot.wifiService
  if M.isOnHotspot() then
    first, second = second, first
  end

  run(NETWORKSETUP, { "-listnetworkserviceorder" }, function(exitCode, stdOut, stdErr)
    if exitCode ~= 0 then
      U.log.wf("hotspot: cannot read service order: %s", stdErr)
      return
    end

    local order = M.moveAhead(M.parseOrder(stdOut), first, second)
    if not order then return end

    local args = { "-ordernetworkservices" }
    for _, name in ipairs(order) do
      table.insert(args, name)
    end
    run(NETWORKSETUP, args, function(code, out, err)
      if code == 0 then
        U.log.of("hotspot: %s now ahead of %s", first, second)
      else
        notify(string.format("Cannot put %s ahead of %s", first, second))
        U.log.wf("hotspot: reorder failed (%d): %s%s", code, out, err)
      end
    end)
  end)
end

function M:start()
  self:stop()
  M._stopped = false

  local store = hs.network.configuration.open()
  if not store then
    U.log.w("hotspot: cannot open network configuration store")
    return
  end
  store:setCallback(function()
    if M._store == store then reconcile() end
  end)
  store:monitorKeys({ ipv4Key() })
  store:start()
  M._store = store

  reconcile()
end

function M:stop()
  M._stopped = true
  if M._store then
    M._store:stop()
    M._store = nil
  end
  -- Let a running networksetup finish; dropping the reference ignores its result.
  M._task = nil
  M._dirty = false
end

return M
