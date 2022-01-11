local log = hs.logger.new("[screenshots]", "debug")

local cache = {}
local M = { cache = cache }

local s3_task_runner = function(file)
  local task = hs.task.new(
    "~/.dotfiles/bin/share_to_s3",
    function() end, -- Fake callback
    function(task, stdOut, stdErr)
      local success = string.find(stdOut, "Completed") ~= nil
      log.df("#-> task execution results: \n%s \n%s \n%s]", hs.inspect(task), hs.inspect(stdOut), hs.inspect(stdErr))

      if success then
        hs.alert.show("screenshot captured and placed on clipboard")

        -- copy our screenshot to iCloud for longer-term storage
        hs.execute('cp "' .. file .. '" "$HOME/Library/Mobile Documents/com~apple~CloudDocs/screenshots/"', true)
      end
    end,
    { string.format([[%s]], file) }
  )
  task:start()
  print(task)

  return task
end

local screenshot_watcher = function(files, flagTables)
  -- usually the second file after screenshotting is the one we want
  local file = files[2]
  local flags = flagTables[2]

  if file == nil then
    -- skip if file is nothing
    return
  end

  log.df("#-> file changed: %s, flags: %s", hs.inspect(file), hs.inspect(flags))

  -- send it to s3 and copy the resulting public URI to clipboard
  local task = s3_task_runner(file)
  log.df("#-> resulting task: \n%s", hs.inspect(task))
end

M.start = function()
  -- cache.watcher = hs.watchable.watch("status.isDocked", screenshot_watcher)
  cache.watcher = hs.pathwatcher.new(Config.preferred.screenshots, screenshot_watcher):start()
end

M.stop = function()
  cache.watcher:stop()
end

return M

-- obj.showPostUI = true

-- local static_choices = {
--         {
--             text = "Capture menu",
--             subText = "Show macOS screen capture menu",
--             plugin = obj.__name,
--             type = "screenUI"
--         },
--         {
--             text = "Capture Screen",
--             subText = "Capture the current screen",
--             plugin = obj.__name,
--             type = "screen"
--         },
--         {
--             text = "Capture Screen to Clipboard",
--             subText = "Capture the current screen to the clipboard",
--             plugin = obj.__name,
--             type = "screen_clipboard"
--         },
--         {
--             text = "Capture Interactive",
--             subText = "Draw a rectangle to capture",
--             plugin = obj.__name,
--             type = "interactive"
--         },
--         {
--             text = "Capture Interactive to Clipboard",
--             subText = "Draw a rectangle to capture to the clipboard",
--             plugin = obj.__name,
--             type = "interactive_clipboard"
--         }
-- }

-- function obj:commands()
--     return {sc = {
--         cmd = "sc",
--         fn = obj.choicesScreenCaptureCommand,
--         name = "Screencapture",
--         description = "Capture the screen",
--         plugin = obj.__name
--         }
--     }
-- end

-- function obj:bare()
--     return nil
-- end

-- function obj.choicesScreenCaptureCommand(query)
--     local choices = {}

--     for k,choice in pairs(static_choices) do
--         if string.match(choice["text"]:lower(), query:lower()) then
--             table.insert(choices, choice)
--         end
--     end

--     return choices
-- end

-- function obj.completionCallback(rowInfo)
--     local filename = hs.fs.pathToAbsolute("~").."/Desktop/Screen Capture at "..os.date("!%Y-%m-%d-%T")..".png"
--     local args = ""
--     local scType = rowInfo["type"]

--     if scType == "screen" then
--         -- Nothing required here
--     elseif scType == "screen_clipboard" then
--         args = "-c"
--     elseif scType == "interactive" then
--         args = "-i"
--     elseif scType == "screenUI" then
--         args = "-iU"
--     elseif scType == "interactive_clipboard" then
--         args = "-ci"
--     end

--     if obj.showPostUI then
--         args = args .. "u"
--     end

--     print(hs.inspect(args))
--     hs.task.new("/usr/sbin/screencapture", nil, {args, filename}):start()
-- end

-- return obj
