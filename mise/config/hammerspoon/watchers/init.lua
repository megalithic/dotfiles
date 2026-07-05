local enum = require("hs.fnutils")

local M = {}

function M:init(opts)
  M.watchers = opts.watchers
  U.log.f("initializing %s", table.concat(opts.watchers, ", "))

  enum.each(opts.watchers or {}, function(watcher)
    local ok, mod = pcall(require, string.format("watchers.%s", watcher))
    if ok then
      mod:start()
    else
      U.log.e(string.format("%s failed to start", watcher))
      U.log.e(string.format("%s %s", watcher, mod))
    end
  end)

  return self
end

function M:stop(opts)
  local watchers = opts.watchers and opts.watchers or M.watchers
  U.log.f("stopping", watchers)

  enum.each(watchers or {}, function(watcher)
    local ok, mod = pcall(require, string.format("watchers.%s", watcher))
    if ok then
      mod:stop()
    else
      U.log.e(string.format("%s failed to stop", watcher))
      U.log.e(string.format("%s %s", watcher, mod))
    end
  end)

  return self
end

return M
