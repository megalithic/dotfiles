vim.loader.enable()
vim.g.colorscheme = "megaforest"

require("vim._extui").enable({
  enable = true,
  -- msg = {
  --   -- msg: similar rendering to the notifier.nvim plugin
  --   -- cmd: normal cmd mode looking stuff
  --   target = "cmd",
  --   -- timeout = vim.g.extui_msg_timeout or 5000,
  -- },
})

-- vim.api.nvim_create_autocmd("FileType", {
--   pattern = { "cmd", "msg", "pager", "dialog" },
--   callback = function(_evt)
--     vim.api.nvim_set_option_value("winhl", "Normal:PanelBackground,FloatBorder:PanelBorder", {})
--   end,
-- })

--- @diagnostic disable-next-line: duplicate-set-field
vim.deprecate = function() end -- no-op deprecation messages
local ok, mod_or_err = pcall(require, "config.globals")
if ok then
  -- if not vim.g.started_by_firenvim then
  --   mod_or_err.version()
  -- end
  require("config.options")
  require("config.commands")
  require("config.autocmds")
  require("config.keymaps")
  require("config.lazy")
else
  vim.notify("Error loading `globals.lua`; unable to continue...\n" .. mod_or_err)
end
