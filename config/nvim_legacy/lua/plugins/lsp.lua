return {
  {
    -- NOTE: using this until it's fixed in blink
    -- BUG https://github.com/Saghen/blink.cmp/issues/1670
    "ray-x/lsp_signature.nvim",
    event = "InsertEnter",
    opts = {
      hint_prefix = "󰏪 ",
      hint_scheme = "Todo",
      floating_window = false,
      always_trigger = true,
    },
  },
  { "b0o/schemastore.nvim" },
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    dependencies = {
      {
        "mason-org/mason-lspconfig.nvim",
        opts = {
          automatic_enable = false,
          automatic_installation = false,
          ensure_installed = {},
        },
        dependencies = {
          { "mason-org/mason.nvim", opts = { install_root_dir = vim.fs.joinpath(vim.env.XDG_DATA_HOME, "lsp/mason") } },
          { "neovim/nvim-lspconfig" },
        },
      },
    },
    config = function()
      local ensure_installed = {
        "lua_ls",
        "bash-language-server",
        "beautysh",
        "biome",
        "black",
        -- "chrome-debug-adapter",
        "css-lsp",
        "docker-compose-language-service",
        "dockerfile-language-server",
        "emmet-language-server",
        "eslint_d",
        -- "firefox-debug-adapter",
        "fixjson",
        "html-lsp",
        "isort",
        "js-debug-adapter",
        "just-lsp",
        "json-lsp",
        "lua-language-server",
        "markdown-toc",
        "markdownlint-cli2",
        "marksman",
        "markdown-oxide",
        -- "nil",
        -- "nixfmt",
        "nixpkgs-fmt",
        "prettier",
        "prettierd",
        "ruff",
        "shellcheck",
        "shfmt",
        "sql-formatter",
        "sqlfmt",
        "stylua",
        "terraform",
        "terraform-ls",
        -- "tailwindcss-language-server@0.0.27",
        -- "tailwindcss-language-server@0.12.18",
        -- "tailwindcss-language-server",
        "vtsls",

        -- LSP servers (matching your vim.lsp.enable() config)
        "lua-language-server", -- Lua LSP
        -- "lua_ls", -- Lua (LSP, lua-language-server)
        -- "gopls", -- Go LSP
        "zls", -- Zig LSP
        "typescript-language-server", -- TypeScript LSP
        "vtsls",
        "rust-analyzer", -- Rust LSP
        "html-lsp", -- HTML LSP
        -- "html", -- HTML (LSP, html-lsp)
        "css-lsp", -- CSS LSP
        -- "cssls", -- CSS, SCSS, LESS (LSP, css-lsp)
        "vue-language-server", -- Vue LSP
        "just-lsp",
        "json-lsp",
        "terraform-ls",
        -- "bashls", -- Bash (LSP, bash-language-server)
        "bash-language-server",
        "docker-compose-language-service",
        "dockerfile-language-server",
        "emmet-language-server",
        "marksman", -- Markdown (LSP)
        "postgrestools",
        "postgres_lsp",
        "basedpyright", -- Python (LSP, better fork of pyright) -- Replaces `pyright`

        -- "biome", -- JavaScript, TypeScript (LSP, Linter, Formatter) -- TODO: Needs testing to replace eslint.
        "clangd", -- C, C++ (LSP)
        -- "eslint_lsp", -- JavaScript, TypeScript (LSP, eslint_lsp) -- Replaces `eslint_d`
        -- 'pyright', -- Python (LSP) -- Replaced by `basedpyright`
        "ruff", -- Python (LSP, Linter, Formatter)
        -- 'ts_ls', -- JavaScript, TypeScript (LSP, typescript-language-server) -- Replaced by `vtsls`
        "typos-lsp", -- * (LSP, typos-lsp, Code Spell Checker)
        -- "vimls", -- VimScript (LSP, vim-language-server)
        "vim-language-server",
        "vtsls", -- JavaScript, TypeScript, Vue via vue_ls -- Replaces `ts_ls`
        -- "vue_ls", -- Vue (LSP, vue-language-server)
        "yaml-language-server", -- YAML (LSP, yaml-language-server)
        -- "nil",
        -- "nixfmt",

        -- "tailwindcss-language-server@0.0.27",
        -- "tailwindcss-language-server@0.12.18",
        -- "tailwindcss-language-server",

        -- Formatters (for conform.nvim and general use)
        "stylua",
        -- "goimports",
        -- Note: gofmt comes with Go installation, not managed by Mason
        "prettier",
        "prettierd",
        "isort",
        "beautysh",
        -- "biome",
        "black",
        "fixjson",
        "sqlfmt",
        "sql-formatter",
        "shfmt",
        -- "nixpkgs-fmt",

        -- Linters and diagnostics
        -- "golangci-lint",
        "eslint_d",
        "luacheck", -- Lua linting
        "shellcheck",
        -- "markdownlint", -- Markdown linting
        -- "markdown-toc",
        -- "markdownlint-cli2",
        "yamllint", -- YAML linting
        "jsonlint", -- JSON linting

        -- Additional useful tools
        -- "delve", -- Go debugger

        -- Optional but useful additions
        --
        --
        -- mine...
        -- "chrome-debug-adapter",
        -- "firefox-debug-adapter",
        "js-debug-adapter",
        "terraform",
      }

      local defined_lsp_servers_to_install
      local ok_server_list, server_list = pcall(dofile, vim.fn.stdpath("config") .. "/plugin/lsp/servers.lua")

      if ok_server_list then
        defined_lsp_servers_to_install = vim.iter(server_list):filter(function(key, s)
          if type(s) == "table" then
            return not s.manual_install
          elseif type(s) == "function" then
            s = s()
            return (s and not s.manual_install)
          else
            return s
          end
        end)
      end

      ensure_installed = vim.tbl_deep_extend("force", ensure_installed, defined_lsp_servers_to_install or {})

      require("mason-lspconfig").setup({
        automatic_enable = false,
        automatic_installation = false,
        ensure_installed = {},
      })

      -- require("mason-tool-installer").setup({
      --   ensure_installed = ensure_installed,
      --   auto_update = false,
      --   run_on_start = true,
      --   integrations = {
      --     ["mason-lspconfig"] = true,
      --     ["mason-null-ls"] = true,
      --     ["mason-nvim-dap"] = true,
      --   },
      -- })
    end,
  },
  -- {
  --   "williamboman/mason.nvim",
  --   lazy = false, -- Load immediately to ensure PATH is set
  --   cmd = "Mason",
  --   keys = { { "<leader>lim", "<cmd>Mason<cr>", desc = "Mason" } },
  --   build = ":MasonUpdate",
  --   opts = {
  --     ensure_installed = {
  --       -- LSP servers (matching your vim.lsp.enable() config)
  --       "lua-language-server", -- Lua LSP
  --       -- "lua_ls", -- Lua (LSP, lua-language-server)
  --       -- "gopls", -- Go LSP
  --       "zls", -- Zig LSP
  --       "typescript-language-server", -- TypeScript LSP
  --       "vtsls",
  --       "rust-analyzer", -- Rust LSP
  --       "html-lsp", -- HTML LSP
  --       -- "html", -- HTML (LSP, html-lsp)
  --       "css-lsp", -- CSS LSP
  --       -- "cssls", -- CSS, SCSS, LESS (LSP, css-lsp)
  --       "vue-language-server", -- Vue LSP
  --       "just-lsp",
  --       "json-lsp",
  --       "terraform-ls",
  --       -- "bashls", -- Bash (LSP, bash-language-server)
  --       "bash-language-server",
  --       "docker-compose-language-service",
  --       "dockerfile-language-server",
  --       "emmet-language-server",
  --       "marksman", -- Markdown (LSP)
  --       "markdown-oxide",
  --       "postgrestools",
  --       "basedpyright", -- Python (LSP, better fork of pyright) -- Replaces `pyright`

  --       -- "biome", -- JavaScript, TypeScript (LSP, Linter, Formatter) -- TODO: Needs testing to replace eslint.
  --       "clangd", -- C, C++ (LSP)
  --       -- "eslint_lsp", -- JavaScript, TypeScript (LSP, eslint_lsp) -- Replaces `eslint_d`
  --       -- 'pyright', -- Python (LSP) -- Replaced by `basedpyright`
  --       "ruff", -- Python (LSP, Linter, Formatter)
  --       -- 'ts_ls', -- JavaScript, TypeScript (LSP, typescript-language-server) -- Replaced by `vtsls`
  --       "typos-lsp", -- * (LSP, typos-lsp, Code Spell Checker)
  --       -- "vimls", -- VimScript (LSP, vim-language-server)
  --       "vim-language-server",
  --       "vtsls", -- JavaScript, TypeScript, Vue via vue_ls -- Replaces `ts_ls`
  --       -- "vue_ls", -- Vue (LSP, vue-language-server)
  --       "yaml-language-server", -- YAML (LSP, yaml-language-server)
  --       -- "nil",
  --       -- "nixfmt",

  --       -- "tailwindcss-language-server@0.0.27",
  --       -- "tailwindcss-language-server@0.12.18",
  --       -- "tailwindcss-language-server",

  --       -- Formatters (for conform.nvim and general use)
  --       "stylua",
  --       -- "goimports",
  --       -- Note: gofmt comes with Go installation, not managed by Mason
  --       "prettier",
  --       "prettierd",
  --       "isort",
  --       "beautysh",
  --       -- "biome",
  --       "black",
  --       "fixjson",
  --       "sqlfmt",
  --       "sql-formatter",
  --       "shfmt",
  --       -- "nixpkgs-fmt",

  --       -- Linters and diagnostics
  --       -- "golangci-lint",
  --       "eslint_d",
  --       "luacheck", -- Lua linting
  --       "shellcheck",
  --       -- "markdownlint", -- Markdown linting
  --       -- "markdown-toc",
  --       -- "markdownlint-cli2",
  --       "yamllint", -- YAML linting
  --       "jsonlint", -- JSON linting

  --       -- Additional useful tools
  --       -- "delve", -- Go debugger

  --       -- Optional but useful additions
  --       --
  --       --
  --       -- mine...
  --       -- "chrome-debug-adapter",
  --       -- "firefox-debug-adapter",
  --       "js-debug-adapter",
  --       "terraform",
  --     },
  --   },
  --   config = function(_, opts)
  --     -- PATH is handled by core.mason-path for consistency
  --     require("mason").setup(opts)

  --     -- Auto-install ensure_installed tools with better error handling
  --     local mr = require("mason-registry")
  --     local function ensure_installed()
  --       for _, tool in ipairs(opts.ensure_installed) do
  --         if mr.has_package(tool) then
  --           local p = mr.get_package(tool)
  --           if not p:is_installed() then
  --             mega.notify("Mason: Installing " .. tool .. "...", vim.log.levels.INFO)
  --             p:install():once("closed", function()
  --               if p:is_installed() then
  --                 mega.notify("Mason: Successfully installed " .. tool, vim.log.levels.INFO)
  --               else
  --                 mega.notify("Mason: Failed to install " .. tool, vim.log.levels.ERROR)
  --               end
  --             end)
  --           end
  --         else
  --           mega.notify("Mason: Package '" .. tool .. "' not found", vim.log.levels.WARN)
  --         end
  --       end
  --     end

  --     if mr.refresh then
  --       mr.refresh(ensure_installed)
  --     else
  --       ensure_installed()
  --     end
  --   end,
  -- },
  { "onsails/lspkind.nvim" },
  {
    "stevearc/aerial.nvim", -- Toggled list of classes, methods etc in current file
    keys = {
      { "<leader>ls", "<cmd>AerialToggle<CR>", mode = { "n", "x", "o" }, desc = "[lsp] aerial toggle" },
    },
    opts = {
      cmd = { "AerialToggle" },
      backends = { "lsp", "treesitter" },
      attach_mode = "global",
      close_on_select = true,
      layout = {
        default_direction = "prefer_right",
        close_on_select = false,
        max_width = 35,
        min_width = 35,
      },
      show_guides = true,
      open_automatic = function(bufnr)
        local aerial = require("aerial")
        return vim.api.nvim_win_get_width(0) > 120
          and aerial.num_symbols(bufnr) > 0
          and not aerial.was_closed()
          and not vim.tbl_contains({ "markdown" }, vim.bo[bufnr].ft)
      end,
      -- Use nvim-navic icons
      icons = {
        File = "󰈙 ",
        Module = " ",
        Namespace = "󰌗 ",
        Package = " ",
        Class = "󰌗 ",
        Method = "󰆧 ",
        Property = " ",
        Field = " ",
        Constructor = " ",
        Enum = "󰕘",
        Interface = "󰕘",
        Function = "󰊕 ",
        Variable = "󰆧 ",
        Constant = "󰏿 ",
        String = "󰀬 ",
        Number = "󰎠 ",
        Boolean = "◩ ",
        Array = "󰅪 ",
        Object = "󰅩 ",
        Key = "󰌋 ",
        Null = "󰟢 ",
        EnumMember = " ",
        Struct = "󰌗 ",
        Event = " ",
        Operator = "󰆕 ",
        TypeParameter = "󰊄 ",
      },
    },
    config = function(_, opts)
      require("aerial").setup(opts)
      vim.api.nvim_set_hl(0, "AerialLine", { link = "PmenuSel" })
    end,
  },
  {
    "mhanberg/output-panel.nvim",
    lazy = false,
    keys = {
      {
        "<leader>lip",
        ":OutputPanel<CR>",
        desc = "lsp: open output panel",
      },
    },
    cmd = { "OutputPanel" },
    opts = { max_buffer_size = 5000 },
  },
  {
    cond = false,
    -- FIXME: this is a no go; crashes rpc content chunk things
    "synic/refactorex.nvim",
    ft = "elixir",
    opts = {
      auto_update = true,
      pin_version = nil,
    },
  },
  {
    "rachartier/tiny-inline-diagnostic.nvim",
    event = "VeryLazy",
    priority = 2000, -- needs to be loaded in first
    opts = {
      hi = {
        error = "DiagnosticError",
        warn = "DiagnosticWarn",
        info = "DiagnosticInfo",
        hint = "DiagnosticHint",
        arrow = "Normal",
        background = "CursorLine",
        mixing_color = "None",
      },
      signs = {
        left = "",
        right = "",
        diag = "",
        arrow = "",
        up_arrow = "",
        -- arrow = "  ",
        -- up_arrow = "  ",
        vertical = "",
        vertical_end = "",
      },
      blend = {
        factor = 0.27,
      },
      options = {
        multiple_diag_under_cursor = true,
        format = function(d)
          local msg = d.message
          local icon = Icons.lsp[vim.diagnostic.severity[d.severity]:lower()]
          if d.source == "typos" then
            msg = msg:gsub("should be", "󰁔"):gsub("`", "")
          elseif d.source == "Lua Diagnostics." then
            msg = msg:gsub("%.$", "")
          end

          local source = (d.source or ""):gsub(" ?%.$", "") -- trailing dot for lua_ls
          local rule = d.code and ": " .. d.code or ""

          -- return string.format("%s %s\r\n%s", icon, d.source, d.message)
          return string.format("%s %s [%s]", icon, msg, ("%s%s"):format(source, rule))
          -- return string.format("%s [%s]", msg, ("%s%s"):format(source, rule))
        end,
      },
    },
    config = function(_, opts) require("tiny-inline-diagnostic").setup(opts) end,
  },
  {
    "rachartier/tiny-code-action.nvim",
    dependencies = {
      { "nvim-lua/plenary.nvim" },
    },
    event = "LspAttach",
    opts = { picker = "select" },
  },
  {
    -- cond = false,
    "luckasRanarison/tailwind-tools.nvim",
    dependencies = { "neovim/nvim-lspconfig" },
    build = ":UpdateRemotePlugins",
    name = "tailwind-tools",
    -- opts = function()
    --   local _ok_lsp, lsp = pcall(dofile, vim.fn.stdpath("config") .. "/plugin/lsp/init.lua")
    --   return {
    --     server = {
    --       override = false,
    --       -- on_attach = lsp.on_attach,
    --     },
    --   }
    -- end,
    opts = { server = { override = false } },
  },
  {
    "dnlhc/glance.nvim",
    enabled = false,
    config = function()
      -- Glance
      local actions = require("glance").actions
      require("glance").setup({
        use_trouble_qf = true,
        detached = true,
        height = 25,
        border = {
          enable = true,
          top_char = "―",
          bottom_char = "―",
        },
        list = {
          position = "left",
          width = 0.33,
        },
        indent_lines = {
          enable = true,
          icon = " ",
        },
        -- mappings = {
        --   list = {
        --     ["<c-s>l"] = actions.enter_win("preview"),
        --     ["<c-s>h"] = actions.enter_win("preview"),
        --   },
        --   preview = {
        --     ["<c-s>l"] = actions.enter_win("list"),
        --     ["<c-s>h"] = actions.enter_win("list"),
        --     ["q"] = actions.close,
        --   },
        -- },
        folds = {
          fold_closed = "",
          fold_open = "",
          folded = true,
        },
        hooks = {
          -- Don't open glance when there is only one result and it is located in the current buffer, open otherwise
          before_open = function(results, open, jump, _method)
            local uri = vim.uri_from_bufnr(0)
            if #results == 1 then
              local target_uri = results[1].uri or results[1].targetUri

              if target_uri == uri then
                jump(results[1])
              else
                open(results)
              end
            else
              open(results)
            end
          end,
        },
      })
    end,
  },
  -- {
  --   "pmizio/typescript-tools.nvim",
  --   ft = { "typescript", "typescriptreact", "javascript", "javascriptreact", "vue" },
  --   config = function()
  --     local lsp = dofile(vim.fn.stdpath("config") .. "/plugin/lsp/init.lua")
  --     require("typescript-tools").setup({
  --       filetypes = {
  --         "javascript",
  --         "javascriptreact",
  --         "typescript",
  --         "typescriptreact",
  --         "vue",
  --       },
  --       settings = {
  --         tsserver_plugins = {
  --           "@vue/typescript-plugin",
  --         },
  --       },
  --       capabilities = lsp.capabilities(),
  --     })
  --   end,
  -- },
}
