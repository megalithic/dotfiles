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

M.capture = function(type, showPostUI)
  showPostUI = showPostUI or true
  local args = M.parseArgs(type, showPostUI)
  local timestamp = string.gsub(os.date("%Y%m%d_%T"), ":", "") -- os.date("!%Y-%m-%d-%T")
  local filename = fmt("%s/ss_%s.png", Config.dirs.screenshots, timestamp)

  hs.task.new("/usr/sbin/screencapture", function(exitCode, stdOut, stdErr)
    log.df(
      "#-> capture_task callback execution results: \n%s \n%s \n%s]",
      hs.inspect(exitCode),
      hs.inspect(stdOut),
      hs.inspect(stdErr)
    )

    local image = hs.pasteboard.readImage()
    print(hs.inspect(image))
    local save_ok = image:saveToFile(filename)
    if save_ok then
      log.df("saved image (%s) successfully! %s", filename, hs.inspect(image))
      local output, s3_ok, t, rc = hs.execute(
        fmt([[%s/.dotfiles/bin/share_to_s3 %s]], os.getenv("HOME"), filename),
        true
      )
      if s3_ok then
        hs.alert.show("screenshot captured and placed on clipboard")
      else
        log.df("#-> resulting s3 upload: \n[%s]", hs.inspect({ output, s3_ok, t, rc }))
      end
    end
  end, {
    args,
    filename,
  }):start()
end

M.parseArgs = function(scType, showPostUI)
  local args = ""

  if scType == "screen" then
    -- Nothing required here
  elseif scType == "window" then
    local windowId = hs.window.frontmostWindow():id()
    args = "-l" .. windowId
  elseif scType == "screen_clipboard" then
    args = "-c"
  elseif scType == "interactive" then
    args = "-s"
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
    log.df("should be capturing interactive clipboard")
    print(M.capture("interactive_clipboard", true))
  end)
  hs.hotkey.bind(Config.modifiers.mashShift, "4", function()
    log.df("should be capturing interactive clipboard")
    print(M.capture("interactive_clipboard", true))
  end)
  hs.hotkey.bind(Config.modifiers.cmdShift, "s", function()
    log.df("should be capturing window")
    print(M.capture("window", true))
  end)
end

M.stop = function()
  log.df("stopping..")
end

return M
