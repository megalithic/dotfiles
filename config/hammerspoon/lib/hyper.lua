local obj = {}

obj.__index = obj

function obj:init(opts)
  opts = opts or {}
  print(string.format("hyper:init(opts: %s) loaded.", hs.inspect(opts)))
end
function obj:start() print(string.format("hyper:start() executed.")) end
function obj:stop() print(string.format("hyper:stop() executed.")) end

return obj
