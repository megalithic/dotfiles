local log = hs.logger.new("[screenshots]", "debug")

local cache = {}
local M = { cache = cache }

local s3_task_runner = function(file)
  local task = hs.task.new(
    "~/.dotfiles/bin/share_to_s3",
    function() end, -- Fake callback
    function(task, stdOut, stdErr)
      local success = string.find(stdOut, "Completed") ~= nil
      log.df("share_to_s3 task: %s [%s, %s]", hs.inspect(task), hs.inspect(stdOut), hs.inspect(stdErr))

      if success then
        hs.alert.show("screenshot captured and placed on clipboard")
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

  log.df("file changed: %s, flags: %s", hs.inspect(file), hs.inspect(flags))

  -- send it to s3 and copy the resulting public URI to clipboard
  local task = s3_task_runner(file)
  log.df("s3_task_runner task: %s", hs.inspect(task))

  -- cp our screenshot to iCloud for longer-term storage
  hs.execute('cp "' .. file .. '" "$HOME/Library/Mobile Documents/com~apple~CloudDocs/screenshots/"', true)
end

M.start = function()
  -- cache.watcher = hs.watchable.watch("status.isDocked", screenshot_watcher)
  cache.watcher = hs.pathwatcher.new(Config.preferred.screenshots, screenshot_watcher):start()
end

M.stop = function()
  cache.watcher:stop()
end

return M
