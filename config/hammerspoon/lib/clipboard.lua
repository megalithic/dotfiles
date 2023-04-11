-- REF:
-- clipboard handling: https://github.com/victorandree/dotfiles/blob/master/hammerspoon/.hammerspoon/common.lua
-- image uploading via imgur: https://github.com/evanpurkhiser/image-paste.nvim/blob/main/lua/image-paste.lua

local obj = {}

obj.__index = obj
obj.name = "clipboard"
obj.debug = true
obj.imgur_client_id = "2974b259fd073e2"
obj.paste_script = [[osascript -e "get the clipboard as «class PNGf»" | sed "s/«data PNGf//; s/»//" | xxd -r -p]]

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
      dbg(stdOut)
      dbg(stdErr)
      -- url = fn.join(stdOut):gsub("^%s*(.-)%s*$", "%1")
      info(fmt("screenshot created and uploaded to imgur: ", url))
    end,
    {}
  )
  task:start()
  print(task)

  return task
end

local function insert(contents)
  local pasteboardContents = hs.pasteboard.getContents()
  hs.pasteboard.setContents(contents)
  hs.eventtap.keyStroke({ "cmd" }, "v")
  hs.pasteboard.setContents(pasteboardContents)
end

local function bindings()
  hs.hotkey.bind({}, "", function()
    local pasteboardContents = hs.pasteboard.getContents() or ""
    pasteboardContents = string.gsub(pasteboardContents, "\n", "\\n")
    pasteboardContents = string.gsub(pasteboardContents, "\"", "\\\"")
    insert(pasteboardContents)
  end)
end

function obj:init(opts)
  opts = opts or {}
  hs.pasteboard.watcher
    .new(function(pb) dbg(fmt("[pasteboard] contents: %s / textArgs: %s", I(pb), I({ pb }))) end)
    :start()

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
