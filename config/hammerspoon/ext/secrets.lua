module = {}

module.start = function()
  local file = io.open('.secrets')
  io.input(file)

  for line in io.lines() do
    local data = hs.fnutils.split(line, " ")
    hs.settings.set(data[1], data[2])
  end
end

return module
