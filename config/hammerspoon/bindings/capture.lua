local log = hs.logger.new("[capture]", "debug")

-- REFS:
-- https://github.com/ecerulm/dotfiles/blob/master/.hammerspoon/init.lua#L296-L317
-- https://github.com/sarangak/dotfiles/blob/master/dot_hammerspoon/windows.lua#L131-L150 (more detailed impl)
-- https://github.com/kylejohnston/dotfiles/blob/main/hammerspoon/utils.lua#L34-L57
-- https://github.com/charlietanksley/dotemacs/blob/main/hammerspoon/.hammerspoon/init.lua#L45-L49
-- https://github.com/CommandPost/CommandPost/blob/develop/src/plugins/finder/screencapture/screencapture.lua
-- https://github.com/staticaland/dotfiles/blob/master/hammerspoon/.hammerspoon/init.lua#L57-L80
-- https://github.com/lowne/hammerspoon-extensions/blob/master/hs/expose/init.lua#L22-L35 (neat checks for ok)

local M = {}
local fmt = string.format

local s3_task_runner = function(file)
  local task = hs.task.new(
    fmt("/usr/local/bin/zsh -l -c %s/.dotfiles/bin/share_to_s3", os.getenv("HOME")),
    function() end, -- Fake callback
    function(task, stdOut, stdErr)
      local success = string.find(stdOut, "Completed") ~= nil
      log.df("#-> s3_task execution: \n%s \n%s]", hs.inspect(task), hs.inspect(stdOut))

      if success then
        hs.alert.show("screenshot captured and placed on clipboard")

        -- copy our screenshot to iCloud for longer-term storage
        -- hs.execute('cp "' .. file .. '" "$HOME/Library/Mobile Documents/com~apple~CloudDocs/screenshots/"', true)
      else
        log.df("#-> s3_task execution error: \n%s]", hs.inspect(stdErr))
      end
    end,
    { fmt([[%s]], file) }
  )
  task:start()
  print(task)

  return task
end

M.capture = function(type, showPostUI)
  showPostUI = showPostUI or true
  local args = M.parseArgs(type, showPostUI)
  local filename = fmt("%s/screenshooots_%s.png", Config.dirs.screenshots, os.date("!%Y-%m-%d-%T"))
  print(hs.inspect(args), hs.inspect(filename))
  return hs.execute(fmt('/usr/sbin/screencapture %s "%s"', args, filename))

  -- hs.task.new("/usr/sbin/screencapture", function(exitCode, stdOut, stdErr)
  --   log.df(
  --     "#-> capture_task callback execution results: \n%s \n%s \n%s]",
  --     hs.inspect(exitCode),
  --     hs.inspect(stdOut),
  --     hs.inspect(stdErr)
  --   )

  --   -- local s3_task = s3_task_runner(filename)
  --   -- log.df("#-> resulting s3_task: \n%s", hs.inspect(s3_task))
  -- end, function(task, stdOut, stdErr)
  --   log.df(
  --     "#-> capture_task streamCallback execution results: \n%s \n%s \n%s]",
  --     hs.inspect(task),
  --     hs.inspect(stdOut),
  --     hs.inspect(stdErr)
  --   )

  --   local s3_task = s3_task_runner(filename)
  --   log.df("#-> resulting s3_task: \n%s", hs.inspect(s3_task))
  -- end, {
  --   args,
  --   filename,
  -- }):start()
end

M.parseArgs = function(scType, showPostUI)
  local args = ""

  if scType == "screen" then
    -- Nothing required here
  elseif scType == "screen_clipboard" then
    args = "-c"
  elseif scType == "interactive" then
    args = "-i"
  elseif scType == "screenUI" then
    args = "-iU"
  elseif scType == "interactive_clipboard" then
    args = "-ci"
  end

  if showPostUI then
    args = args .. "u"
  end

  return args .. "d"
end

M.start = function()
  log.df("starting..")

  hs.hotkey.bind(Config.modifiers.cmdShift, "4", function()
    log.df("should be capturing interactive")
    print(M.capture("interactive", true))
  end)
  hs.hotkey.bind(Config.modifiers.mashShift, "4", function()
    log.df("should be capturing interactive clipboard")
    print(M.capture("interactive_clipboard", true))
  end)
end

M.stop = function()
  log.df("stopping..")
end

return M
