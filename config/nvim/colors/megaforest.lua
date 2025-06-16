vim.opt.background = "dark"

local colorscheme = "megaforest"
local theme = string.format("lush_theme.%s", colorscheme)
local ok, lush_theme = pcall(require, theme)

if ok then
  vim.g.colors_name = colorscheme
  package.loaded[theme] = nil

  require("lush")(lush_theme)
end

pcall(vim.cmd.colorscheme, vim.g.colorscheme)
if pcall(require, "lush_theme.colors") then
mega.colors = require("lush_theme.colors")
end

