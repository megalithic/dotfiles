local obj = {
  table = {},
  string = {},
  tmux = {},
  file = {},
}

obj.__index = obj
obj.name = "utils"
obj.debug = true

obj.dndCmd = os.getenv("HOME") .. "/.dotfiles/bin/dnd"
obj.slckCmd = os.getenv("HOME") .. "/.dotfiles/bin/slck"

function obj.template(template, vars) return string.gsub(template, "{(.-)}", vars) end

--- utils.scriptPath([n]) -> string
--- Function
--- Return path of the current spoon.
---
--- Parameters:
---  * n - (optional) stack level for which to get the path. Defaults to 2, which will return the path of the spoon which called `scriptPath()`
---
--- Returns:
---  * String with the path from where the calling code was loaded.
function obj.scriptPath(n)
  if n == nil then n = 2 end
  local str = debug.getinfo(n, "S").source:sub(2)
  return str:match("(.*/)")
end

--- utils.resourcePath(partial) -> string
--- Function
--- Return full path of an object within a spoon directory, given its partial path.
---
--- Parameters:
---  * partial - path of a file relative to the Spoon directory. For example `images/img1.png` will refer to a file within the `images` directory of the Spoon.
---
--- Returns:
---  * Absolute path of the file. Note: no existence or other checks are done on the path.
function obj.resourcePath(partial) return (obj.scriptPath(3) .. partial) end

function obj.eventString(e)
  local a = hs.application.watcher

  if type(e) == "string" then return e end

  local enum_tbl = {
    [0] = { "launching", a.launching },
    [1] = { "launched", a.launched },
    [2] = { "terminated", a.terminated },
    [3] = { "hidden", a.hidden },
    [4] = { "unhidden", a.unhidden },
    [5] = { "activated", a.activated },
    [6] = { "deactivated", a.deactivated },
  }

  return table.unpack(enum_tbl[e])
end

function obj.tlen(t)
  local len = 0
  for _ in pairs(t) do
    len = len + 1
  end
  return len
end
obj.table.length = obj.tlen

function obj.truncate(str, width, at_tail)
  local ellipsis = "…"
  local n_ellipsis = #ellipsis

  -- HT: https://github.com/lunarmodules/Penlight/blob/master/lua/pl/stringx.lua#L771-L796
  --- Return a shortened version of a string.
  -- Fits string within w characters. Removed characters are marked with ellipsis.
  -- @string s the string
  -- @int w the maxinum size allowed
  -- @bool tail true if we want to show the end of the string (head otherwise)
  -- @usage ('1234567890'):shorten(8) == '12345...'
  -- @usage ('1234567890'):shorten(8, true) == '...67890'
  -- @usage ('1234567890'):shorten(20) == '1234567890'
  local function shorten(s, w, tail)
    if s == nil then return "" end
    if #s > w then
      if w < n_ellipsis then return ellipsis:sub(1, w) end
      if tail then
        local i = #s - w + 1 + n_ellipsis
        return ellipsis .. s:sub(i)
      else
        return s:sub(1, w - n_ellipsis) .. ellipsis
      end
    end
    return s
  end

  return shorten(str, width, at_tail)
end

---@param status boolean|string|nil dnd status on or off as a boolean to pass to the dnd binary
function obj.dnd(status)
  if type(status) == "boolean" then status = status and "on" or "off" end

  if status ~= nil then
    hs.task.new(obj.dndCmd, function(_exitCode, _stdOut, _stdErr) info("[RUN] dnd/" .. status) end, { status }):start()
  else
    hs.task.new(obj.dndCmd, function(_exitCode, _stdOut, _stdErr) info("[RUN] dnd/toggle") end, { "toggle" }):start()
  end
end

-- TODO:
-- https://github.com/kiooss/dotmagic/blob/master/hammerspoon/slack.lua
---@param status string|nil slack status to pass to the slck binary
function obj.slack(status)
  dbg(status, true)
  if status ~= nil and status ~= "" then
    -- local slck = hs.task.new("/opt/homebrew/bin/zsh", function(exitCode, stdOut, stdErr)
    --   dbg({ exitCode, stdOut, stdErr }, true)
    --   info("[RUN] slack/" .. slackStatus)
    -- end, { "-lc", obj.slckCmd, slackStatus })
    local slck = hs.task.new(obj.slckCmd, function(_exitCode, _stdOut, _stdErr) end, function(stdTask, stdOut, stdErr)
      dbg({ stdTask, stdOut, stdErr }, true)
      local continue = true
      -- info("[SLCK]: " .. slackStatus)
      return continue
    end, { status })

    -- local slck = hs.task.new(
    --   "/opt/homebrew/bin/zsh",
    --   function(_exitCode, _stdOut, _stdErr) end,
    --   function(stdTask, stdOut, stdErr)
    --     dbg({ stdOut, stdErr }, true)
    --     stdOut = string.gsub(stdOut, "^%s*(.-)%s*$", "%1")
    --
    --     local continue = true
    --     -- local continue = stdOut == fmt([[input audio device set to "%s"]], device)
    --     --
    --     -- if continue then success(fmt("[%s] audio input set to %s", obj.name, device)) end
    --
    --     return continue
    --   end,
    --   { "-lc", obj.slckCmd, "-r", slackStatus }
    -- )
    slck:setEnvironment({
      TERM = "xterm-256color",
      HOMEBREW_PREFIX = "/opt/homebrew",
      --   -- HOME = os.getenv("HOME"),
      PATH = os.getenv("PATH") .. ":/opt/homebrew/bin",
    })
    slck:start()
  end
end

function obj.vidconvert(path, opts)
  opts = opts or {
    srcFormat = "mkv",
    destFormat = "mov",
  }

  local srcFormat = opts["srcFormat"]
  local destFormat = opts["destFormat"]

  if
    path
    and type(path) == "string"
    and string.match(path, fmt(".%s", srcFormat))
    -- and hs.fs.displayName(path) ~= nil
  then
    info(fmt("[%s] vidconvert started for %s at %s", obj.name, path, os.date("%H:%M:%S")))
    hs.notify
      .new({ title = "vidconvert", subTitle = fmt("STARTED converting %s at %s", path, os.date("%H:%M:%S")) })
      :send()

    local task = hs.task.new(os.getenv("HOME") .. "/.dotfiles/bin/vidconvert", function(exitCode, stdOut, stdErr)
      -- dbg(fmt("sync func: \r\n %s \r\n %s \r\n %s", stdOut, stdErr, exitCode))

      local foundStreamEnd = exitCode == 0
      -- dbg(fmt("sync foundStreamEnd: %s", foundStreamEnd), true)

      if foundStreamEnd then
        success(fmt("[%s] vidconvert compeleted for %s at %s", obj.name, path, os.date("%H:%M:%S")))
        hs.notify.new({ title = "vidconvert", subTitle = fmt("FINISHED converting at %s", os.date("%H:%M:%S")) }):send()
      end

      -- end, function(_task, stdOut, stdErr)
      --   -- TODO: figure out why ffmpeg outputs stdOut to stdErr (or is it a hs.task issue?)

      --   stdErr = string.gsub(stdErr, "^%s*(.-)%s*$", "%1")
      --   local foundStreamEnd = string.match(stdErr, "Qavg:")
      --   -- dbg(fmt("stream foundStreamEnd: %s", foundStreamEnd), true)

      --   if foundStreamEnd then
      --     success(fmt("[%s] vidconvert completed for %s", obj.name, path))

      --     hs.notify.new({ title = "vidconvert", subTitle = fmt("FINISHED converting at %s", os.date("%H:%M:%S")) }):send()

      --     return foundStreamEnd
      --   end

      --   return not foundStreamEnd
    end, { "-t", destFormat, path })

    task:setEnvironment({
      TERM = "xterm-256color",
      HOMEBREW_PREFIX = "/opt/homebrew",
      HOME = os.getenv("HOME"),
      PATH = os.getenv("PATH") .. ":/opt/homebrew/bin",
    })

    task:start()
  end
end

function obj.tmux.update()
  hs.task.new("/opt/homebrew/bin/tmux", function() end, { "refresh-client" }):start()
end

function obj.tmux.focusDailyNote(splitFocusedWindow)
  local frontmostApp = hs.application.frontmostApplication()
  local frontmostAppWindow = frontmostApp:focusedWindow()
  local term = hs.application.get(TERMINAL)
  local termWindow

  if term then
    termWindow = term:mainWindow()

    if splitFocusedWindow and frontmostApp ~= term then
      hs.layout.apply({
        { nil, termWindow, frontmostAppWindow:screen(), hs.layout.left30, 0, 0 },
        { nil, frontmostAppWindow, frontmostAppWindow:screen(), hs.layout.right70, 0, 0 },
      })
    end

    term:activate()

    hs.timer.waitUntil(function() return term:isFrontmost() end, function()
      -- mimics pressing the tmux prefix `ctrl-space`,
      hs.eventtap.keyStroke({ "ctrl" }, "space", 10000, term)
      -- then the daily note binding, `ctrl-o`,
      hs.eventtap.keyStroke({ "ctrl" }, "o", 10000, term)

      -- FIXME: unreliable
      -- then tell nvim to open my daily note.
      -- hs.eventtap.keyStrokes(",nd", term)
      -- hs.eventtap.keyStroke({}, "n", 100000, term)
      -- hs.eventtap.keyStroke({}, "d", 100000, term)
    end)
  end
end

-- Takes a list of path parts, returns a string with the parts delimited by '/'
function obj.file.toPath(...) return table.concat({ ... }, "/") end

function obj.file.splitPath(file)
  -- Splits a string by '/', returning the parent dir, filename (with extension),
  -- and the extension alone.
  local parent = file:match("(.+)/[^/]+$")
  if parent == nil then parent = "." end
  local filename = file:match("/([^/]+)$")
  if filename == nil then filename = file end
  local ext = filename:match("%.([^.]+)$")
  return parent, filename, ext
end

function obj.file.exists(file)
  -- Return true if the file exists, else false
  local f = io.open(file, "r")
  if f ~= nil then
    io.close(f)
    return true
  else
    return false
  end
end

-- If any files are found in the given path, make a list of them and call the
-- given callback function with that list.
function obj.file.runOnFiles(path, callback)
  local iter, data = hs.fs.dir(path)
  local files = {}
  repeat
    local item = iter(data)
    if item ~= nil then table.insert(files, obj.file.toPath(path, item)) end
  until item == nil
  if #files > 0 then callback(files) end
end

-- Make a parent dir for a file. Does not error if it exists already.
function obj.file.makeParentDir(path)
  local parent, _, _ = obj.file.splitPath(path)
  local ok, err = hs.fs.mkdir(parent)
  if ok == nil then
    if err == "File exists" then ok = true end
  end
  return ok, err
end

-- Create a file (making parent directories if necessary).
function obj.file.create(path)
  if obj.file.makeParentDir(path) then io.open(path, "w"):close() end
end

-- Append a line of text to a file.
function obj.file.append(file, text)
  if text == "" then return end

  local f = io.open(file, "a")
  f:write(tostring(text) .. "\n")
  f:close()
end

-- Move a file. This calls task (so runs asynchronously), so calls onSuccess
-- and onFailure callback functions depending on the result. Set force to true
-- to overwrite.
function obj.file.move(from, to, force, onSuccess, onFailure)
  force = force and "-f" or "-n"

  local function callback(exitCode, stdOut, stdErr)
    if exitCode == 0 then
      onSuccess(stdOut)
    else
      onFailure(stdErr)
    end
  end

  if obj.file.exists(from) then hs.task.new("/bin/mv", callback, { force, from, to }):start() end
end

-- If the given file is older than the given time (in epoch seconds), return
-- true. This checks the inode change time, not the original file creation
-- time.
function obj.file.isOlderThan(file, seconds)
  local age = os.time() - hs.fs.attributes(file, "change")
  if age > seconds then return true end
  return false
end

-- Return the last modified time of a file in epoch seconds.
function obj.file.lastModified(file)
  local when = os.time()
  if obj.file.exists(file) then when = hs.fs.attributes(file, "modification") end
  return when
end

function obj.file.moveFileToPath(file, toPath)
  -- move a given file to toPath, overwriting the destination, with logging
  local function onFileMoveSuccess(_) info("Moved " .. file .. " to " .. toPath) end

  local function onFileMoveFailure(stdErr) error("Error moving " .. file .. " to " .. toPath .. ": " .. stdErr) end

  obj.file.makeParentDir(toPath)
  obj.file.move(file, toPath, true, onFileMoveSuccess, onFileMoveFailure)
end

-- Unhide the extension on the given file, if it matches the extension given,
-- and that extension does not exist in the given hiddenExtensions table.
function obj.file.unhideExtension(file, ext, hiddenExtensions)
  if ext == nil or hiddenExtensions == nil or hiddenExtensions[ext] == nil then
    local function unhide(exitCode, stdOut, stdErr)
      if exitCode == 0 and tonumber(stdOut) == 1 then
        hs.task.new("/usr/bin/SetFile", nil, { "-a", "e", file }):start()
      end
    end
    hs.task.new("/usr/bin/GetFileInfo", unhide, { "-aE", file }):start()
  end
end

-- download external libraries
function obj.download_lib(rel_file_path, url)
  local paths = {
    libs = hs.configdir .. "/libs",
    icons = hs.configdir .. "/assets",
  }

  local rel_file_dir, filename = rel_file_path:match("(.+)/(.+)")

  if rel_file_dir == nil or filename == nil then
    rel_file_dir = ""
    filename = rel_file_path
  end

  local lib_path = paths.libs
  local dir_path = lib_path .. "/" .. rel_file_dir
  local file_path = dir_path .. "/" .. filename

  hs.notify
    .new({
      title = "Downloading library",
      informativeText = "Downloading to " .. file_path,
    })
    :send()

  local _, success = hs.execute(string.format("mkdir -p %s && curl -o %s %s", dir_path, file_path, url))

  -- If fail then notify user
  if not success then
    hs.notify
      .new({
        title = "Library download failed",
        informativeText = string.format("Failed to download \"%s\"", filename),
        autoWithdraw = false,
      })
      :send()

    return
  end
end

return obj
