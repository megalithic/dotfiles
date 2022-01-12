-- REFS:
-- https://github.com/ecerulm/dotfiles/blob/master/.hammerspoon/init.lua#L296-L317
-- https://github.com/sarangak/dotfiles/blob/master/dot_hammerspoon/windows.lua#L131-L150 (more detailed impl)
-- https://github.com/kylejohnston/dotfiles/blob/main/hammerspoon/utils.lua#L34-L57
-- https://github.com/charlietanksley/dotemacs/blob/main/hammerspoon/.hammerspoon/init.lua#L45-L49
-- https://github.com/CommandPost/CommandPost/blob/develop/src/plugins/finder/screencapture/screencapture.lua
-- https://github.com/staticaland/dotfiles/blob/master/hammerspoon/.hammerspoon/init.lua#L57-L80
-- https://github.com/lowne/hammerspoon-extensions/blob/master/hs/expose/init.lua#L22-L35 (neat checks for ok)

local log = hs.logger.new("[capture]", "debug")
local cache = {
  image = nil,
  image_contents = nil,
  image_url = nil,
  original_clipboard = nil,
}
local M = { cache = cache }
local fmt = string.format

M.capture = function(type, store_s3)
  M.cache.original_clipboard = hs.pasteboard.getContents()

  store_s3 = store_s3 or false
  local args = M.parseArgs(type)
  local timestamp = string.gsub(os.date("%Y%m%d_%T"), ":", "") -- os.date("!%Y-%m-%d-%T")
  local filename = fmt("%s/ss_%s.png", Config.dirs.screenshots, timestamp)

  hs.task.new("/usr/sbin/screencapture", function()
    -- get interactive screen capture content that's now in the system clipboard
    M.cache.image_contents = hs.pasteboard.readAllData()

    -- get an hs.image object from that content
    M.cache.image = hs.pasteboard.readImage()
    hs.pasteboard.setContents(M.cache.image, "image")

    if M.cache.image and store_s3 then
      local save_ok = M.cache.image:saveToFile(filename)
      if save_ok then
        log.df("saved image (%s) successfully!", filename)
        local output, s3_ok, t, rc = hs.execute(
          fmt([[%s/.dotfiles/bin/share_to_s3 %s]], os.getenv("HOME"), filename),
          true
        )
        if s3_ok then
          hs.notify.new({
            title = "Capture",
            subTitle = "S3 Upload completed",
            informativeText = filename,
          }):setIdImage(M.cache.image):send()

          -- get stored s3 image url that's now in the system clipboard
          M.cache.image_url = hs.pasteboard.getContents()

          hs.pasteboard.setContents(M.cache.image, "image")
          hs.pasteboard.setContents(M.cache.image_url, "image_url")
          hs.pasteboard.setContents(M.cache.image_contents, "image_contents")
        else
          log.ef("#-> errored s3 upload: \n[%s]", hs.inspect({ output, s3_ok, t, rc }))
        end
      end
    end
  end, {
    args,
    filename,
  }):start()
end

M.parseArgs = function(scType)
  local args = ""

  if scType == "screen" then
    -- no-op
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

  return args .. "du"
end

M.start = function()
  log.df("starting.. %s", hs.inspect(hs.pasteboard.allContentTypes()))

  hs.hotkey.bind(Config.modifiers.cmdShift, "4", function()
    M.capture("interactive_clipboard", true)
  end)

  hs.hotkey.bind(Config.modifiers.mashShift, "4", function()
    M.capture("interactive_clipboard", false)
  end)

  hs.hotkey.bind(Config.modifiers.cmdShift, "s", function()
    M.capture("window", true)
  end)

  -- TODO:  http://www.hammerspoon.org/docs/hs.pasteboard.html#writeDataForUTI

  -- hs.hotkey.bind(Config.modifiers.cmd, "v", function()
  --   -- hs.pasteboard.setContents(image_url)
  --   log.df("cmd+v -------------- ")
  --   log.df("cache -------------- %s", hs.inspect(M.cache))
  --   log.df("image_contents -------------- %s", hs.inspect(hs.pasteboard.getContents("image_contents")))
  --   log.df("image_url -------------- %s", hs.inspect(hs.pasteboard.getContents("image_url")))
  --   log.df("image -------------- %s", hs.inspect(hs.pasteboard.getContents("image")))

  --   hs.pasteboard.setContents(M.cache.image_url)
  --   hs.eventtap.keyStroke({ "cmd" }, "v")
  -- end)

  hs.hotkey.bind(Config.modifiers.cmdShift, "v", function()
    local original_clipboard = hs.pasteboard.getContents()

    -- NOTE: this is the binary image text here:
    -- log.df("cache (image_contents) -------------- %s", hs.inspect(M.cache.image_contents["public.png"]))
    log.df("allContentTypes: %s", hs.inspect(hs.pasteboard.allContentTypes()))

    -- which of this are supposed to do the thing?
    -- hs.pasteboard.setContents(M.cache.image_contents["public.png"])
    --
    -- or
    --public.utf8-plain-text
    local written = hs.pasteboard.writeDataForUTI("public.png", M.cache.image_contents["public.png"], true)

    log.df("allContentTypes after set: %s", hs.inspect(hs.pasteboard.allContentTypes()))
    -- log.df("written result: %s", written)

    -- if written then
    --   -- hs.pasteboard.setContents(M.cache.image_contents["public.png"])
    --   -- log.df("readString: %s", hs.inspect(hs.pasteboard.readString("image_contents")))
    --   -- log.df("readAllData: %s", hs.inspect(hs.pasteboard.readAllData("image_contents")))
    --   -- log.df("readImage: %s", hs.inspect(hs.pasteboard.readImage("image_contents")))
    --   -- log.df("getContents: %s", hs.inspect(hs.pasteboard.getContents("image_contents")))
    --   hs.eventtap.keyStroke({ "cmd" }, "v")
    -- end
    hs.eventtap.keyStroke({ "cmd" }, "v")

    -- Allow some time for the command+v keystroke to fire asynchronously before
    -- we restore the original clipboard
    hs.timer.doAfter(0.2, function()
      hs.pasteboard.setContents(original_clipboard)
    end)
  end)
end

M.stop = function()
  log.df("stopping..")
end

return M
