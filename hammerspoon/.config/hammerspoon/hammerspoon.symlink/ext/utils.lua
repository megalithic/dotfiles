local module = {}

-- run function without window animation
module.noAnim = function(callback)
  local lastAnimDuration      = hs.window.animationDuration
  hs.window.animationDuration = 0

  callback()

  hs.window.animationDuration = lastAnimDuration
end

-- run cmd and return it's output
module.capture = function(cmd)
  local handle = io.popen(cmd)
  local result = handle:read('*a')

  handle:close()

  return result
end

-- capitalize string
module.capitalize = function(str)
  return str:gsub("^%l", string.upper)
end

return module
