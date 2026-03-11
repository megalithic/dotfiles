-- lifted from https://github.com/folke/tokyonight.nvim/blob/2e1daa1d164ad8cc3e99b44ca68e990888a66038/lua/tokyonight/util.lua

local M = {}

---@alias RGB [number, number, number]

---@param c  string|number
---@return RGB
function M.rgb(c)
  if type(c) == "number" then
    return { c / (256 ^ 2), (c % (256 ^ 2)) / 256, c % 256 }
  else
    c = string.lower(c)
    return {
      tonumber(c:sub(2, 3), 16),
      tonumber(c:sub(4, 5), 16),
      tonumber(c:sub(6, 7), 16),
    }
  end
end

---@param color RGB|number
---@return string
function M.hex(color)
  if type(color) == "number" then color = M.rgb(color) end
  return string.format("#%02x%02x%02x", color[1], color[2], color[3])
end

---@param color1 string|number
---@param color2 string|number
---@param alpha number number between 0 and 1. 0 results in color1, 1 results in color2
function M.blend(color1, alpha, color2)
  local bg = M.rgb(color2)
  local fg = M.rgb(color1)

  local blend_channel = function(i)
    local ret = (alpha * fg[i] + ((1 - alpha) * bg[i]))
    return math.floor(math.min(math.max(0, ret), 255) + 0.5)
  end

  return string.format("#%02x%02x%02x", blend_channel(1), blend_channel(2), blend_channel(3))
end

function M.blend_bg(color, amount)
  local normal = vim.api.nvim_get_hl(0, { name = "Normal" })
  local bg = normal.bg and normal.bg or "#000000"
  return M.blend(color, amount, bg)
end
M.darken = M.blend_bg

function M.blend_fg(color, amount)
  local normal = vim.api.nvim_get_hl(0, { name = "Normal" })
  local fg = normal.fg and normal.fg or "#ffffff"
  return M.blend(color, amount, fg)
end
M.lighten = M.blend_fg

---@type fun()[]
local colorscheme_callbacks = {}

---@param cb fun() callback to run on color scheme change and VeryLazy
function M.register_color_update(cb)
  table.insert(colorscheme_callbacks, cb)
  cb()
end

vim.api.nvim_create_autocmd("ColorScheme", {
  desc = "update colors",
  callback = function()
    for _, cb in ipairs(colorscheme_callbacks) do
      cb()
    end
  end,
})

return M
