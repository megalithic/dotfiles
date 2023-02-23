local obj = {}

obj.__index = obj
obj.name = "scrot"
obj.debug = true
obj.paste_script = [[osascript -e "get the clipboard as «class PNGf»" | sed "s/«data PNGf//; s/»//" | xxd -r -p]]
obj.imgur_client_id = "2974b259fd073e2"

-- local log = hs.logger.new("[screenshots]", "debug")
--
-- local cache = {}
-- local M = { cache = cache }
--
-- local s3_task_runner = function(file)
--   local task = hs.task.new(
--     "~/.dotfiles/bin/share_to_s3",
--     function() end, -- Fake callback
--     function(task, stdOut, stdErr)
--       local success = string.find(stdOut, "Completed") ~= nil
--       log.df("#-> task execution results: \n%s \n%s \n%s]", hs.inspect(task), hs.inspect(stdOut), hs.inspect(stdErr))
--
--       if success then
--         hs.alert.show("screenshot captured and placed on clipboard")
--
--         -- copy our screenshot to iCloud for longer-term storage
--         hs.execute('cp "' .. file .. '" "$HOME/Library/Mobile Documents/com~apple~CloudDocs/screenshots/"', true)
--       end
--     end,
--     { string.format([[%s]], file) }
--   )
--   task:start()
--   print(task)
--
--   return task
-- end
--
-- local screenshot_watcher = function(files, flagTables)
--   -- usually the second file after screenshotting is the one we want
--   local file = files[2]
--   local flags = flagTables[2]
--
--   if file == nil then
--     -- skip if file is nothing
--     return
--   end
--
--   log.df("#-> file changed: %s, flags: %s", hs.inspect(file), hs.inspect(flags))
--
--   -- send it to s3 and copy the resulting public URI to clipboard
--   local task = s3_task_runner(file)
--   log.df("#-> resulting task: \n%s", hs.inspect(task))
-- end
--
-- M.start = function()
--   -- cache.watcher = hs.watchable.watch("status.isDocked", screenshot_watcher)
--   cache.watcher = hs.pathwatcher.new(Config.preferred.screenshots, screenshot_watcher):start()
-- end
--
-- M.stop = function()
--   cache.watcher:stop()
-- end
--
-- return M

local dbg = function(...)
  if obj.debug then return _G.dbg(fmt(...), false) end
end

function obj.capture()
  local url = ""
  local upload_cmd = fmt(
    [[%s \
      | curl --silent \
        --fail \
        --request POST \
        --form "image=@-" \
        --header "Authorization: Client-ID %s" \
        "https://api.imgur.com/3/upload" \
      | jq --raw-output .data.link
  ]],
    obj.paste_script,
    obj.imgur_client_id
  )

  local task = hs.task.new(
    upload_cmd,
    function() end, -- Fake callback
    function(task, stdOut, stdErr)
      url = fn.join(stdOut):gsub("^%s*(.-)%s*$", "%1")
      success(fmt("screenshot created and uploaded to imgur: ", url))
    end,
    {}
  )
  task:start()
  print(task)

  return task
end

function obj:init(opts)
  opts = opts or {}

  return self
end

function obj:start(opts)
  opts = opts or {}

  return self
end

function obj:stop(opts)
  opts = opts or {}
  return self
end
return obj
