local enum = req("hs.fnutils")
local ufile = require("utils").file

local new = hs.pathwatcher.new

local obj = {}

obj.__index = obj
obj.name = "watcher.files"
obj.watchedPaths = {}
obj.debug = false

TIMERS = {
  pathWatcherDelay = 10, -- seconds
}

local function ignored(file)
  if file == nil then return true end

  local _, filename, _ = ufile.splitPath(file)

  -- ignore dotfiles
  if filename:match("^%.") then return true end

  return false
end

local function homePath(path) return fmt("%s/%s", os.getenv("HOME"), path) end

local function watchPath(path, files, process_cb)
  -- wait a little while before doing anything, to give files a chance to
  -- settle down.
  --
  hs.timer
    .doAfter(TIMERS.pathWatcherDelay, function()
      -- loop through the files and call the process_cb function on any that are
      -- not ignored, still exist, and are found in the given path.
      for _, file in ipairs(files) do
        if not ignored(file) and ufile.exists(file) then
          local parent, filename, ext = ufile.splitPath(file)
          local data = { file = file, parent = parent, filename = filename, ext = ext }

          if parent == path then process_cb(data) end
        end
      end
    end)
    :start()
end

-- REFS:
-- screenshot renaming: https://github.com/focusaurus/dotfiles-public/blob/main/.hammerspoon/screenshots.lua
-- somewhat related, but lots of interactions to take over a mac without a mouse: https://github.com/avegetablechicken/MacWithoutMouse/tree/master
-- hazel-like behaviour: https://github.com/scottcs/dot_hammerspoon/blob/master/.hammerspoon/modules/hazel.lua
-- related to to the above, the file utilities: https://github.com/scottcs/dot_hammerspoon/blob/master/.hammerspoon/utils/file.lua
-- again, slightly related: launching https://github.com/knu/Knu.spoon/blob/main/application.lua
-- commandpost's impl: https://github.com/CommandPost/CommandPost/blob/develop/src/extensions/cp/sourcewatcher/init.lua#L48-L110

local function watchDownloads(files)
  -- m.log.d('watchDownloads ----')
  watchPath(homePath("Downloads"), files, function(data)
    -- m.log.d('watchDownloads processing', hs.inspect(data))

    -- unhide extensions for files written here
    ufile.unhideExtension(data.file, data.ext, { app = true })

    -- send nzb and torrent files to the transfer directory
    if data.ext == "text" then
      note("doing something with file %s", data.file)
      -- ufile.moveFileToPath(data.file, m.cfg.path.transfer)
    else
      -- ignore files with color tags
      -- if not ufile.isColorTagged(data.file) then
      --   -- move files older than a week into the dump directory
      --   if ufile.isOlderThan(data.file, TIME.WEEK) then ufile.moveFileToPath(data.file, m.cfg.path.dump) end
      -- end
    end
  end)
end

function obj:start()
  obj.watchedPaths.downloads = new(homePath("Downloads"), watchDownloads)
  -- obj.watchedPaths.hsConfig = new(hs.configdir, function() hs.timer.doAfter(0.25, hs.reload) end)
  -- obj.watchedPaths.obs = new(homePath("Movies/obs"), function(paths, _attrs)
  --   -- auto-convert obs videos to .mov format once
  --   hs.timer.waitUntil(function() return hs.application.get("com.obsproject.obs-studio") == nil end, function()
  --     enum.each(paths, function(p)
  --       local name = p:match(".*/(.+)")
  --       local ext = p:match("%.(.+)$")
  --       if ext == "mkv" then
  --         note(fmt("[%s] %s", obj.name, p))
  --
  --         hs.task
  --           .new(
  --             "/opt/homebrew/bin/ffmpeg",
  --             function(stdTask, stdOut, stdErr) dbg({ stdTask, stdOut, stdErr }, obj.debug) end,
  --             {
  --               "-i",
  --               p,
  --               "-vcodec",
  --               "libx264",
  --               "-crf",
  --               "28",
  --               "-preset",
  --               "faster",
  --               "-tune",
  --               "film",
  --               fmt("%s/%s.mov", path("Movies/obs"), name:gsub("." .. ext, "")),
  --             }
  --           )
  --           :start()
  --       end
  --     end)
  --   end)
  -- end)

  enum.each(self.watchedPaths, function(w)
    w:start()
    local watchedPath = tostring(w):gsub("hs.pathwatcher: ", ""):match("(.*/* )")
    note(fmt("[RUN] %s watching %s", obj.name, watchedPath))
  end)

  info(fmt("[START] %s", obj.name))
  return self
end

function obj:stop()
  enum.each(self.watchedPaths, function(w) w:stop() end)
  obj.watchedPaths = nil

  return self
end

return obj
