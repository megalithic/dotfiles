-- if true then return end
if not mega then return end
if not vim.g.enabled_plugin["treesitter"] then return end

vim.defer_fn(require("mega.plugins.treesitter"), 0)
