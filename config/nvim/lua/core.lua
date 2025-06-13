vim.loader.enable()

if vim.fn.has("nvim-0.12") == 1 then
  -- extui
  require("vim._extui").enable({
    enable = true,
    msg = {
      pos = "cmd",
      box = {
        timeout = 4000,
      },
    },
  })

  vim.api.nvim_create_autocmd("FileType", {
    pattern = { "msgbox", "msgmore", "msgprompt", "cmdline" },
    callback = function() vim.api.nvim_set_option_value("winhl", "Normal:Normal,FloatBorder:FloatBorder", {}) end,
  })
end

--- @diagnostic disable-next-line: duplicate-set-field
vim.deprecate = function() end -- no-op deprecation messages

vim.g.mapleader = ","
vim.g.maplocalleader = " "

local ok, err = pcall(require, "config.globals")
if ok then
  require("config.settings").apply()
  require("config.lazy")
  require("config.commands")
  require("config.autocmds").apply()
  require("config.keymaps")
else
  vim.notify("Error loading `config/globals.lua`; unable to continue...\n" .. err)
end
