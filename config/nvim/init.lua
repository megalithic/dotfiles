_G.mega = {}

local ok, err = pcall(require, "core")
if not ok then
  vim.notify("Error loading `core.lua`; loading fallback...\n" .. err)
  vim.cmd.runtime("minvimrc.vim")
end
