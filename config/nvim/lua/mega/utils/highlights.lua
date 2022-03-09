local fmt = string.format
local api = vim.api
local levels = vim.log.levels

local M = {}

---Convert a hex color to RGB
---@param color string
---@return number
---@return number
---@return number
local function hex_to_rgb(color)
  local hex = color:gsub("#", "")
  return tonumber(hex:sub(1, 2), 16), tonumber(hex:sub(3, 4), 16), tonumber(hex:sub(5), 16)
end

local function alter(attr, percent)
  return math.floor(attr * (100 + percent) / 100)
end

---@source https://stackoverflow.com/q/5560248
---@see: https://stackoverflow.com/a/37797380
---Darken a specified hex color
---@param color string
---@param percent number
---@return string
function M.alter_color(color, percent)
  local r, g, b = hex_to_rgb(color)
  if not r or not g or not b then
    return "NONE"
  end
  r, g, b = alter(r, percent), alter(g, percent), alter(b, percent)
  r, g, b = math.min(r, 255), math.min(g, 255), math.min(b, 255)
  return fmt("#%02x%02x%02x", r, g, b)
end

--- Check if the current window has a winhighlight
--- which includes the specific target highlight
--- @param win_id integer
--- @vararg string
function M.has_win_highlight(win_id, ...)
  local win_hl = vim.wo[win_id].winhighlight
  for _, target in ipairs({ ... }) do
    if win_hl:match(target) ~= nil then
      return true, win_hl
    end
  end
  return false, win_hl
end

---A mechanism to allow inheritance of the winhighlight of a specific
---group in a window
---@param win_id number
---@param target string
---@param name string
---@param default string
function M.adopt_winhighlight(win_id, target, name, default)
  name = name .. win_id
  local _, win_hl = M.has_win_highlight(win_id, target)
  local hl_exists = vim.fn.hlexists(name) > 0
  if not hl_exists then
    local parts = vim.split(win_hl, ",")
    local found = mega.find(parts, function(part)
      return part:match(target)
    end)
    if found then
      local hl_group = vim.split(found, ":")[2]
      local bg = M.get_hl(hl_group, "bg")
      local fg = M.get_hl(default, "fg")
      local gui = M.get_hl(default, "gui")
      M.set_hl(name, { guibg = bg, guifg = fg, gui = gui })
    end
  end
  return name
end

---get a highlight groups details from the nvim API and format the result
---to match the attributes seen when using `:highlight GroupName`
--- `nvim_get_hl_by_name` e.g.
---```json
---{
--- foreground: 123456
--- background: 123456
--- italic: true
--- bold: true
--}
---```
--- is converted to
---```json
---{
--- gui: {"italic", "bold"}
--- guifg: #FFXXXX
--- guibg: #FFXXXX
--}
---```
---@param group_name string A highlight group name
local function get_hl(group_name)
  local attrs = { foreground = "guifg", background = "guibg" }
  local hl = api.nvim_get_hl_by_name(group_name, true)
  local result = {}
  if hl then
    local gui = {}
    for key, value in pairs(hl) do
      local t = type(value)
      if t == "number" and attrs[key] then
        result[attrs[key]] = "#" .. bit.tohex(value, 6)
      elseif t == "boolean" then -- NOTE: we presume that a boolean value is a GUI attribute
        table.insert(gui, key)
      end
    end
    result.gui = #gui > 0 and gui or nil
  end
  return result
end

--- NOTE: vim.highlight's link and create are private, so eventually move to using `nvim_set_hl`
---@param name string
---@param opts table
function M.set_hl(name, opts)
  assert(name and opts, "Both 'name' and 'opts' must be specified")
  if not vim.tbl_isempty(opts) then
    if opts.link then
      vim.highlight.link(name, opts.link, opts.force)
    else
      if opts.inherit then
        local attrs = get_hl(opts.inherit)
        --- FIXME: deep extending does not merge { a = {'one'}} with {b = {'two'}}
        --- correctly in nvim 0.5.1, but should do in 0.6
        if opts.gui and not opts.gui:match("NONE") and attrs.gui then
          opts.gui = opts.gui .. "," .. table.concat(attrs.gui, ",")
        end
        opts = vim.tbl_deep_extend("force", attrs, opts)
        opts.inherit = nil
      end
      opts.gui = type(opts.gui) == "table" and table.concat(opts.gui, ", ") or opts.gui
      local ok, msg = pcall(vim.highlight.create, name, opts)
      if not ok then
        vim.notify(fmt("Failed to set %s because: %s", name, msg))
      end
    end
  end
end

---Get the value a highlight group whilst handling errors, fallbacks as well as returning a gui value
---in the right format
---@param grp string
---@param attr string
---@param fallback string
---@return string
function M.get_hl(grp, attr, fallback)
  if not grp then
    vim.notify("Cannot get a highlight without specifying a group", levels.ERROR)
    return "NONE"
  end
  local hl = get_hl(grp)
  local color = hl[attr:match("gui") and attr or fmt("gui%s", attr)] or fallback
  if not color then
    vim.notify(fmt("%s %s does not exist", grp, attr), levels.INFO)
    return "NONE"
  end
  -- convert the decimal RGBA value from the hl by name to a 6 character hex + padding if needed
  return color
end

function M.clear_hl(name)
  if not name then
    return
  end
  vim.cmd(fmt("highlight clear %s", name))
end

---Apply a list of highlights
---@param hls table[]
function M.all(hls)
  for _, hl in ipairs(hls) do
    M.set_hl(unpack(hl))
  end
end

---------------------------------------------------------------------------------
-- Plugin highlights
---------------------------------------------------------------------------------
---Apply highlights for a plugin and refresh on colorscheme change
---@param name string plugin name
---@vararg table list of highlights
function M.plugin(name, ...)
  name = name:gsub("^%l", string.upper) -- capitalise the name for autocommand convention sake
  local hls = { ... }
  M.all(hls)
  mega.augroup(fmt("%sHighlightOverrides", name), {
    {
      events = { "ColorScheme" },
      targets = { "*" },
      command = function()
        M.all(hls)
      end,
    },
  })
end

return M
