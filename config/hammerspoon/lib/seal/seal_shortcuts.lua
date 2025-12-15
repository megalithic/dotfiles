-- luacheck: no self
local obj = {}
obj.__index = obj
obj.__name = "seal_shortcuts"
obj.__icon = hs.image.imageFromAppBundle("com.apple.shortcuts")
obj.__logger = hs.logger.new(obj.__name)

obj.shortcuts = hs.shortcuts.list()

function obj:commands()
  return {
    short = {
      cmd = "short",
      fn = obj.choicesShortcuts,
      name = "Shortcuts",
      description = "Run a Shortcut",
      plugin = obj.__name,
      icon = obj.__icon,
    },
  }
end

function obj:bare() return nil end

function obj.choicesShortcuts(query)
  query = query:lower()
  local choices = {}

  for _, shortcut in pairs(obj.shortcuts) do
    if string.match(shortcut.name:lower(), query) then
      local choice = {}
      choice["text"] = shortcut.name
      choice["subText"] = shortcut.actionCount .. " actions"
      choice["id"] = shortcut.id
      choice["plugin"] = obj.__name
      choice["image"] = obj.__icon
      table.insert(choices, choice)
    end
  end
  table.sort(choices, function(a, b) return a["text"] < b["text"] end)

  return choices
end

function obj.completionCallback(row_info)
  if not row_info then return end
  U.spawn(function() hs.shortcuts.run(row_info.text) end)
end

return obj
