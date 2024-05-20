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
local lc_ok, lazy_cache = pcall(require, "lazy.core.cache")
if lc_ok then lazy_cache.enable() end

local le_ok, lazy_event = pcall(require, "lazy.core.handler.event")
if le_ok then
  lazy_event.mappings.LazyFile = { id = "LazyFile", event = { "BufReadPre", "BufReadPost", "BufNewFile", "BufWritePre" } }
  lazy_event.mappings["User LazyFile"] = lazy_event.mappings.LazyFile
end

local plugin_spec = {
  { import = "plugins.core" },
  { import = "plugins.extended" },
}

require("lazy").setup(plugin_spec, {
  -- debug = false,
  -- defaults = { lazy = true },
  -- checker = { enabled = false },
  -- diff = {
  --   cmd = "terminal_git",
  -- },
  -- install = {
  --   missing = true,
  --   colorscheme = { vim.g.colorscheme, "default", "habamax" },
  -- },
  dev = {
    -- directory where you store your local plugin projects
    path = "~/code",
    ---@type string[] plugins that match these patterns will use your local versions instead of being fetched from GitHub
    patterns = { "megalithic" },
    fallback = true, -- Fallback to git when local plugin doesn't exist
  },
  -- performance = {
  --   cache = {
  --     enabled = true,
  --     -- disable_events = {},
  --   },
  --   rtp = {
  --     disabled_plugins = {
  --       "gzip",
  --       "zip",
  --       "zipPlugin",
  --       "tar",
  --       "tarPlugin",
  --       "getscript",
  --       "getscriptPlugin",
  --       "vimball",
  --       "vimballPlugin",
  --       "2html_plugin",
  --       "logipat",
  --       "rrhelper",
  --       "spellfile_plugin",
  --       "matchit",
  --       "tutor_mode_plugin",
  --       "remote_plugins",
  --       "shada_plugin",
  --       "filetype",
  --       "spellfile",
  --       "tohtml",
  --     },
  --   },
  -- },
  -- dev = {
  --   -- directory where you store your local plugin projects
  --   path = "~/code",
  --   ---@type string[] plugins that match these patterns will use your local versions instead of being fetched from GitHub
  --   patterns = { "megalithic" },
  --   fallback = true, -- Fallback to git when local plugin doesn't exist
  -- },
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
