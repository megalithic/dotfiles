-- [[ Install `lazy.nvim` plugin manager ]]
--    See `:help lazy.nvim.txt` or https://github.com/folke/lazy.nvim for more info
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
end ---@diagnostic disable-next-line: undefined-field

vim.opt.rtp:prepend(lazypath)
-- settings and autocmds must load before plugins,
-- but we can manually enable caching before both
-- of these for optimal performance
local lcc_ok, lazy_cache = pcall(require, "lazy.core.cache")
if lcc_ok then lazy_cache.enable() end

local le_ok, event = pcall(require, "lazy.core.handler.event")
if le_ok then
  event.mappings.LazyFile = { id = "LazyFile", event = { "BufReadPre", "BufReadPost", "BufNewFile", "BufWritePre" } }
  event.mappings["User LazyFile"] = event.mappings.LazyFile
end

local plugin_spec = {
  { import = "plugins.core" },
  { import = "plugins.extended" },
}

require("lazy").setup(plugin_spec, {
  ui = {
    -- If you are using a Nerd Font: set icons to an empty table which will use the
    -- default lazy.nvim defined Nerd Font icons, otherwise define a unicode icons table
    icons = vim.g.have_nerd_font and {} or {
      cmd = "⌘",
      config = "🛠",
      event = "📅",
      ft = "📂",
      init = "⚙",
      keys = "🗝",
      plugin = "🔌",
      runtime = "💻",
      require = "🌙",
      source = "📄",
      start = "🚀",
      task = "📌",
      lazy = "💤 ",
    },
  },
})
