local M = {}

function M.require(mod)
  local ok, ret = M.try(require, mod)
  return ok and ret
end

function M.try(fn, ...)
  local args = { ... }

  return xpcall(function() return fn(unpack(args)) end, function(err)
    local lines = {}
    table.insert(lines, err)
    table.insert(lines, debug.traceback("", 3))

    M.error(table.concat(lines, "\n"))
    return err
  end)
end
-- bootstrap from github
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "--single-branch",
    "git@github.com:folke/lazy.nvim.git",
    lazypath,
  })
end

vim.opt.runtimepath:prepend(lazypath)

local plugins = {}

-- load lazy
-- REF:
-- https://github.com/M3dry/Dotfiles/blob/master/.config/nvim/lua/m3dry/plugins.lua
require("lazy").setup(plugins, {
  defaults = { lazy = true },
  dev = { patterns = { "megalithic" } },
  install = { colorscheme = { "megaforest", "tokyonight-storm" } },
  checker = { enabled = true },
  performance = {
    rtp = {
      disabled_plugins = {
        "gzip",
        "matchit",
        "matchparen",
        "netrwPlugin",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
  debug = true,
})

vim.keymap.set("n", "<leader>pp", "<cmd>:Lazy<cr>")

return M
