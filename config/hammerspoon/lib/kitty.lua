local socket = require("hs.socket")

local module = {}

module.sockFile = string.format("/tmp/kitty", os.getenv("USER"))
module.sockTimeout = 5

module.send = function(fn, ...)
  assert(
    type(fn) == "function" or (getmetatable(fn) or {}).__call,
    "callback must be a function or object with __call metamethod"
  )

  local args = table.pack(...)
  local message = ""
  for i = 1, args.n, 1 do
    message = message .. tostring(args[i]) .. string.char(0)
  end
  message = message .. string.char(0)

  local mySocket = socket.new()
  local results = ""
  mySocket:setTimeout(module.sockTimeout or -1):connect(module.sockFile, function()
    mySocket:write(message, function(_)
      mySocket:setCallback(function(data, _)
        results = results .. data
        -- having to do this is annoying; investigate module to see if we can
        -- add a method to get bytes of data waiting to be read
        if mySocket:connected() then
          mySocket:read("\n")
        else
          fn(results)
        end
      end)
      mySocket:read("\n")
    end)
  end)
end

return module
