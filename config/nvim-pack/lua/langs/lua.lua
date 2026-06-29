-- lua/langs/lua.lua
-- Lua language support (primarily for Neovim config)

return {
  filetypes = { "lua" },

  servers = {
    lua_ls = {
      cmd = { "lua-language-server" },
      root_markers = { ".luarc.json", ".luarc.jsonc", ".git" },
      settings = {
        Lua = {
          workspace = {
            checkThirdParty = false,
          },
          codeLens = {
            enable = true,
          },
          completion = {
            callSnippet = "Replace",
          },
          diagnostics = {
            globals = { "vim", "Snacks", "MiniPick", "MiniExtra", "mega" },
          },
          doc = {
            privateName = { "^_" },
          },
          hint = {
            enable = true,
            setType = false,
            paramType = true,
            paramName = "Disable",
            semicolon = "Disable",
            arrayIndex = "Disable",
          },
        },
      },
    },
  },

  formatters = {
    lua = { "stylua" },
  },

  repl = {
    cmd = "lua",
    position = "right",
  },

  ftplugin = {
    lua = {
      opt = {
        shiftwidth = 2,
        expandtab = true,
        comments = ":---,:--",  -- Support for LuaCATS doc comments
      },
      abbr = {
        locla = "local",
        vll = "vim.log.levels",
      },
      keys = {
        { "n", "gh", "<CMD>exec 'help ' . expand('<cword>')<CR>", desc = "Help for word under cursor" },
      },
      callback = function(bufnr)
        -- != is not valid Lua, auto-correct to ~=
        vim.keymap.set("ia", "!=", "~=", { buffer = bufnr })
      end,
    },
  },

  plugins = {
    -- Lazydev for neovim lua development
    {
      "folke/lazydev.nvim",
      ft = "lua",
      opts = {
        library = {
          { path = "${3rd}/luv/library", words = { "vim%.uv" } },
          { path = "snacks.nvim", words = { "Snacks" } },
        },
      },
    },
  },
}
