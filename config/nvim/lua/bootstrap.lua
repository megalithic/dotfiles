mega.p.lazy = {}

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

-- settings and autocmds must load before plugins,
-- but we can manually enable caching before both
-- of these for optimal performance
local lc_ok, lazy_cache = pcall(require, "lazy.core.cache")
if lc_ok then lazy_cache.enable() end
--
local le_ok, lazy_event = pcall(require, "lazy.core.handler.event")
if le_ok then
  lazy_event.mappings.LazyFile =
    { id = "LazyFile", event = { "BufReadPre", "BufReadPost", "BufNewFile", "BufWritePre" } }
  lazy_event.mappings["User LazyFile"] = lazy_event.mappings.LazyFile
end

require("lazy").setup({
  spec = {
    { import = "plugins" },
    { import = "plugins.ai" },
    { import = "plugins.lsp" },
    { import = "plugins.snacks" },
    { import = "plugins.mini" },
    -- Lang-specific plugins from lua/langs/*.lua
    { require("langs").lazy_specs() },
  },
  dev = {
    -- directory where you store your local plugin projects
    path = "~/code/oss",
    ---@type string[] plugins that match these patterns will use your local versions instead of being fetched from GitHub
    patterns = { "megalithic" },
    fallback = true, -- Fallback to git when local plugin doesn't exist
  },
  defaults = { lazy = false, version = false },
  install = { missing = true, colorscheme = { vim.g.theme, "habamax" } },
  ui = { backdrop = 100 },
  checker = { enabled = true, notify = false },
  change_detection = { enabled = true, notify = false },
  rocks = { hererocks = true },
  performance = {
    rtp = {
      disabled_plugins = {
        "gzip",
        "matchit",
        "matchparam",
        "netrwPlugin",
        "rplugin",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
})

vim.cmd.cabbrev("L", "Lazy")

---@return boolean
function mega.p.lazy.ensure_hidden()
  if vim.bo.filetype == "lazy" then
    vim.cmd.close()
    return true
  end
  return false
end

---@return boolean
function mega.p.lazy.anything_missing()
  local status = require("lazy.status")
  return status.has_updates()
end

function mega.p.lazy.install() require("lazy").install() end

function mega.p.lazy.sync() require("lazy").sync() end

-- Keymaps for Lazy plugin manager
vim.keymap.set("n", "<leader>pm", "<cmd>Lazy<cr>", { desc = "Lazy menu" })
vim.keymap.set("n", "<leader>ps", function() require("lazy").sync() end, { desc = "Lazy sync" })
