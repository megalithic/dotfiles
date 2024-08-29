local enum = req("hs.fnutils")
local pw = hs.pathwatcher.new
local home = os.getenv("HOME")

local obj = {}

obj.__index = obj
obj.name = "watcher.files"
obj.watchedPaths = {}
obj.debug = false

local function path(dir) return fmt("%s/%s", home, dir) end

function obj:start()
  -- obj.watchedPaths.hs = pw(hs.configdir, function() hs.timer.doAfter(0.25, hs.reload) end)
  obj.watchedPaths.obs = pw(path("Movies/obs"), function(paths, _attrs)
    -- auto-convert obs videos to .mov format once
    hs.timer.waitUntil(function() return hs.application.get("com.obsproject.obs-studio") == nil end, function()
      enum.each(paths, function(p)
        local name = p:match(".*/(.+)")
        local ext = p:match("%.(.+)$")
        if ext == "mkv" then
          note(fmt("[%s] %s", obj.name, p))

          hs.task
            .new(
              "/opt/homebrew/bin/ffmpeg",
              function(stdTask, stdOut, stdErr) dbg({ stdTask, stdOut, stdErr }, obj.debug) end,
              {
                "-i",
                p,
                "-vcodec",
                "libx264",
                "-crf",
                "28",
                "-preset",
                "faster",
                "-tune",
                "film",
                fmt("%s/%s.mov", path("Movies/obs"), name:gsub("." .. ext, "")),
              }
            )
            :start()
        end
      end)
    end)
  end)

  enum.each(self.watchedPaths, function(w) w:start() end)

  return self
end

function obj:stop()
  enum.each(self.watchedPaths, function(w) w:stop() end)
  obj.watchedPaths = nil

  return self
end

return obj
