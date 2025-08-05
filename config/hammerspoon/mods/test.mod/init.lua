local M = {}

M.name = "Test"
M.version = "1.0"
M.author = "seth"
M.license = "MIT - https://opensource.org/licenses/MIT"
M.logger = hs.logger.new("Test")
M.spoonPath = hs.spoons.scriptPath()

function M:init()
  -- hs.fs.mkdir(options.annotations)

  -- M.readTimestamps()

  -- -- Load hammerspoon docs
  -- M.createWhenChanged(hs.docstrings_json_file)

  -- -- Load Spoons
  -- for _, spoon in ipairs(hs.spoons.list()) do
  --   local doc = hs.configdir .. "/Spoons/" .. spoon.name .. ".spoon/docs.json"
  --   if hs.fs.attributes(doc, "modification") then M.createWhenChanged(doc, "spoon.") end
  -- end

  -- M.writeTimestamps()
  print("mod Test:init()")
end

function M:start() end

return M
