vim.loader.enable()
vim.g.colorscheme = "megaforest"

require("vim._extui").enable({ enable = true })

--- @diagnostic disable-next-line: duplicate-set-field
vim.deprecate = function() end -- no-op deprecation messages
local ok, mod_or_err = pcall(require, "config.globals")
if ok then
  require("config.options")
  require("config.commands")
  require("config.autocmds")
  require("config.keymaps")
  require("config.lazy")
else
  vim.notify("Error loading `globals.lua`; unable to continue...\n" .. mod_or_err)
end
