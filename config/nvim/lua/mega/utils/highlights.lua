local fmt = string.format
local fn = vim.fn
local api = vim.api
local C = mega.colors
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

local function alter(attr, percent) return math.floor(attr * (100 + percent) / 100) end

---@source https://stackoverflow.com/q/5560248
---@see: https://stackoverflow.com/a/37797380
---Darken a specified hex color
---@param color string
---@param percent number
---@return string
function M.alter_color(color, percent)
  local r, g, b = hex_to_rgb(color)
  if not r or not g or not b then return "NONE" end
  r, g, b = alter(r, percent), alter(g, percent), alter(b, percent)
  r, g, b = math.min(r, 255), math.min(g, 255), math.min(b, 255)
  return fmt("#%02x%02x%02x", r, g, b)
end

--- Check if the current window has a winhighlight
--- which includes the specific target highlight
--- @param win_id integer
--- @vararg string
--- @return boolean, string
function M.winhighlight_exists(win_id, ...)
  local win_hl = vim.wo[win_id].winhighlight
  for _, target in ipairs({ ... }) do
    if win_hl:match(target) ~= nil then return true, win_hl end
  end
  return false, win_hl
end

---@param group_name string A highlight group name
local function get_hl(group_name)
  local ok, hl = pcall(api.nvim_get_hl_by_name, group_name, true)
  if ok then
    hl.foreground = hl.foreground and "#" .. bit.tohex(hl.foreground, 6)
    hl.background = hl.background and "#" .. bit.tohex(hl.background, 6)
    hl[true] = nil -- BUG: API returns a true key which errors during the merge
    return hl
  end
  return {}
end

---A mechanism to allow inheritance of the winhighlight of a specific
---group in a window
---@param win_id number
---@param target string
---@param name string
---@param fallback string
function M.adopt_winhighlight(win_id, target, name, fallback)
  local win_hl_name = name .. win_id
  local _, win_hl = M.winhighlight_exists(win_id, target)
  local hl_exists = fn.hlexists(win_hl_name) > 0
  if hl_exists then return win_hl_name end
  local parts = vim.split(win_hl, ",")
  local found = mega.find(parts, function(part) return part:match(target) end)
  if not found then return fallback end
  local hl_group = vim.split(found, ":")[2]
  local bg = M.get_hl(hl_group, "bg")
  M.set_hl(win_hl_name, { background = bg, inherit = fallback })
  return win_hl_name
end

---This helper takes a table of highlights and converts any highlights
---specified as `highlight_prop = { from = 'group'}` into the underlying colour
---by querying the highlight property of the from group so it can be used when specifying highlights
---as a shorthand to derive the right color.
---For example:
---```lua
---  M.set_hl({ MatchParen = {foreground = {from = 'ErrorMsg'}}})
---```
---This will take the foreground colour from ErrorMsg and set it to the foreground of MatchParen.
---@param opts table<string, string|boolean|table<string,string>>
local function convert_hl_to_val(opts)
  for name, value in pairs(opts) do
    if type(value) == "table" and value.from then opts[name] = M.get_hl(value.from, vim.F.if_nil(value.attr, name)) end
  end
end

---@param name string
---@param opts table
function M.set_hl(name, opts)
  assert(name and opts, "Both 'name' and 'opts' must be specified")
  local hl = get_hl(opts.inherit or name)
  convert_hl_to_val(opts)
  opts.inherit = nil
  local ok, msg = pcall(api.nvim_set_hl, 0, name, vim.tbl_deep_extend("force", hl, opts))
  if not ok then vim.notify(fmt("Failed to set %s because: %s", name, msg)) end
end

---Get the value a highlight group whilst handling errors, fallbacks as well as returning a gui value
---in the right format
---@param group string
---@param attribute string
---@param fallback string?
---@return string
function M.get_hl(group, attribute, fallback)
  if not group then
    vim.notify("Cannot get a highlight without specifying a group", levels.ERROR)
    return "NONE"
  end
  local hl = get_hl(group)
  attribute = ({ fg = "foreground", bg = "background" })[attribute] or attribute
  local color = hl[attribute] or fallback
  if not color then
    vim.schedule(function() vim.notify(fmt("%s %s does not exist", group, attribute), levels.INFO) end)
    return "NONE"
  end
  -- convert the decimal RGBA value from the hl by name to a 6 character hex + padding if needed
  return color
end

function M.clear_hl(name)
  assert(name, "name is required to clear a highlight")
  api.nvim_set_hl(0, name, {})
end

---Apply a list of highlights
---@param hls table<string, table<string, boolean|string>>
function M.all(hls)
  for name, hl in pairs(hls) do
    M.set_hl(name, hl)
  end
end

---------------------------------------------------------------------------------
-- Plugin highlights
---------------------------------------------------------------------------------
---Apply highlights for a plugin and refresh on colorscheme change
---@param name string plugin name
---@vararg table<string, table> map of highlights
function M.plugin(name, hls)
  name = name:gsub("^%l", string.upper) -- capitalise the name for autocommand convention sake
  M.all(hls)
  mega.augroup(fmt("%sHighlightOverrides", name), {
    {
      event = { "ColorScheme" },
      command = function() M.all(hls) end,
    },
  })
end

return M
