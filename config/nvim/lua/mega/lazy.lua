local M = {}

function M.setup()
  -- add event aliases
  local lche_ok, event = pcall(require, "lazy.core.handler.event")
  if lche_ok then
    event.mappings.LazyFile = { id = "LazyFile", event = { "BufReadPre", "BufReadPost", "BufNewFile", "BufWritePre" } }
    event.mappings["User LazyFile"] = event.mappings.LazyFile
  end

  local spec = {
    { import = "plugins.core" },
    { import = "plugins.extended" },
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
      colorscheme = { vim.g.colorscheme, "default", "habamax" },
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
