local mega = require("mega.globals")

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

-- ---A thin wrapper around vim.notify to add packer details to the message
-- ---@param msg string
function M.notify(msg, level) vim.notify(msg, level, { title = "lazy" }) end

function M.conf(name) 
  return function() 
    -- P(name)
  end
end

function M.setup()
  -- REF: nvim --headless "+Lazy! sync" +qa
  --   mega.augroup("LazySetupInit", {
  --     {
  --       event = { "BufWritePost" },
  --       pattern = { "*/mega/plugins/*.lua", "*/mega/plugs/*.lua", "*/mega/lsp/servers.lua" },
  --       desc = "setup and reloaded",
  --       command = mega.reload,
  --     },
  --     {
  --       event = { "User" },
  --       pattern = { "VimrcReloaded" },
  --       desc = "setup and reloaded",
  --       command = mega.reload,
  --     },
  --     -- {
  --     --   event = { "User" },
  --     --   pattern = { "PackerCompileDone" },
  --     --   command = function()
  --     --     if not vim.g.packer_compiled_loaded and vim.loop.fs_stat(vim.g.packer_compiled_path) then
  --     --       vim.cmd.source(vim.g.packer_compiled_path)
  --     --       vim.g.packer_compiled_loaded = true
  --     --     end
  --     --     M.notify("compilation finished")
  --     --   end,
  --     -- },
  --     -- {
  --     --   event = { "User" },
  --     --   pattern = { "LazyDone" },
  --     --   command = function()
  --     --     M.notify("updates finished")
  --     --     vim.defer_fn(function()
  --     --       if vim.env.PACKER_NON_INTERACTIVE then vim.cmd("quitall!") end
  --     --     end, 100)
  --     --   end,
  --     -- },
  --   })

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

  -- load lazy
  -- REF:
  -- https://github.com/M3dry/Dotfiles/blob/master/.config/nvim/lua/m3dry/plugins.lua
  require("lazy").setup("mega.plugins", {
    -- debug = true,
    defaults = { lazy = true },
    checker = { enabled = true },
    install = {
      missing = true,
      colorscheme = { vim.g.colorscheme },
    },
    -- dev = { patterns = { "megalithic" } },
    performance = {
      rtp = {
        disabled_plugins = {
          "gzip",
          "zip",
          "zipPlugin",
          "tar",
          "tarPlugin",
          "getscript",
          "getscriptPlugin",
          "vimball",
          "vimballPlugin",
          "2html_plugin",
          "logipat",
          "rrhelper",
          "spellfile_plugin",
          "matchit",
          "tutor_mode_plugin",
          "remote_plugins",
          "shada_plugin",
          "filetype",
          "spellfile",
          "tohtml",
        },
      },
    },
  })

  vim.keymap.set("n", "<leader>pp", "<cmd>:Lazy<cr>")
end

return M
