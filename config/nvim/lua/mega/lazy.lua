local M = {}
--
-- function M.require(mod)
--   local ok, ret = M.try(require, mod)
--   return ok and ret
-- end
--
-- function M.try(fn, ...)
--   local args = { ... }
--
--   return xpcall(function() return fn(unpack(args)) end, function(err)
--     local lines = {}
--     table.insert(lines, err)
--     table.insert(lines, debug.traceback("", 3))
--
--     M.error(table.concat(lines, "\n"))
--     return err
--   end)
-- end
--
-- -- ---A thin wrapper around vim.notify to add packer details to the message
-- -- ---@param msg string
-- function M.notify(msg, level) vim.notify(msg, level, { title = "lazy" }) end

function M.setup()
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
  require("lazy.core.cache").enable()
  local spec = {
    { import = "mega.plugins" },
    -- { import = "mega.plugins_new" }, -- WIP plugins
  }

  require("lazy").setup({
    spec = spec,
    debug = false,
    defaults = { lazy = true },
    checker = { enabled = false },
    diff = {
      cmd = "terminal_git",
    },
    install = {
      missing = true,
      colorscheme = { vim.g.colorscheme, "habamax" },
    },
    dev = {
      -- directory where you store your local plugin projects
      path = "~/code",
      ---@type string[] plugins that match these patterns will use your local versions instead of being fetched from GitHub
      patterns = { "megalithic" },
      fallback = true, -- Fallback to git when local plugin doesn't exist
    },
    performance = {
      cache = {
        enabled = true,
        -- disable_events = {},
      },
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
    ui = {
      custom_keys = {
        ["<localleader>d"] = function(plugin) print(vim.inspect(plugin)) end,
      },
    },
  })

  nnoremap("<leader>pp", "<cmd>Lazy home<cr>", { desc = "lazy: home" })
  nnoremap("<leader>ps", "<cmd>Lazy sync<cr>", { desc = "lazy: sync" })
  nnoremap("<leader>pu", "<cmd>Lazy update<cr>", { desc = "lazy: update all" })
  nnoremap("<leader>pb", "<cmd>Lazy build<cr>", { desc = "lazy: build all" })
  nnoremap("<leader>px", "<cmd>Lazy clean<cr>", { desc = "lazy: clean all" })
end

return M
