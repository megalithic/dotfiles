_G.mega = {}

vim.loader.enable()

require("vim._extui").enable({
  enable = true,
  msg = {
    target = "cmd", -- for now I'm happy with 'cmd'; 'box' seems buggy
    timeout = vim.g.extui_msg_timeout or 5000, -- Time a message is visible in the message window.
  },
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "cmd", "msg", "pager", "dialog" },
  callback = function() vim.api.nvim_set_option_value("winhl", "Normal:PanelBackground,FloatBorder:PanelBorder", {}) end,
})

--- @diagnostic disable-next-line: duplicate-set-field
vim.deprecate = function() end -- no-op deprecation messages

vim.g.mapleader = ","
vim.g.maplocalleader = " "

local ok, err = pcall(require, "config.globals")
if ok then
  require("config.options").apply()
  require("config.lazy")
  require("config.commands")
  require("config.autocmds").apply()
  require("config.keymaps")
else
  function _G.Plugin_enabled(_plugin) return false end
  vim.notify("Error loading `config/globals.lua`; unable to continue...\n" .. err)
  vim.cmd.runtime("minvimrc.vim")
end
