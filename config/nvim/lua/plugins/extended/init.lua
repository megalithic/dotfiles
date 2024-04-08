local SETTINGS = require("mega.settings")
return {
  -- ( UI-continued ) --------------------------------------------------------------------
  { "lukas-reineke/virt-column.nvim", opts = { char = SETTINGS.virt_column_char }, event = "VimEnter" },
  {
    "lukas-reineke/indent-blankline.nvim",
    event = { "LazyFile" },
    main = "ibl",
    opts = {
      indent = {
        char = SETTINGS.indent_char,
        smart_indent_cap = false,
      },
      scope = {
        enabled = false,
      },
      exclude = { filetypes = { "markdown" } },
    },
  },
  {
    "mbbill/undotree",
    cmd = "UndotreeToggle",
    -- keys = { { "<leader>U", "<Cmd>UndotreeToggle<CR>", desc = "undotree: toggle" } },
    config = function()
      vim.g.undotree_TreeNodeShape = "◦" -- Alternative: '◉'
      vim.g.undotree_SetFocusWhenToggle = 1
      vim.g.undotree_DiffCommand = "diff -u"
    end,
  },
  {
    "mrjones2014/smart-splits.nvim",
    lazy = false,
    commit = "36bfe63246386fc5ae2679aa9b17a7746b7403d5",
    opts = { at_edge = "stop" },
    -- build = "./kitty/install-kittens.bash",
    keys = {
      { "<A-h>", function() require("smart-splits").resize_left() end },
      { "<A-l>", function() require("smart-splits").resize_right() end },
      -- moving between splits
      { "<C-h>", function() require("smart-splits").move_cursor_left() end },
      { "<C-j>", function() require("smart-splits").move_cursor_down() end },
      { "<C-k>", function() require("smart-splits").move_cursor_up() end },
      { "<C-l>", function() require("smart-splits").move_cursor_right() end },
      -- swapping buffers between windows
      { "<leader><leader>h", function() require("smart-splits").swap_buf_left() end, desc = "swap left" },
      { "<leader><leader>j", function() require("smart-splits").swap_buf_down() end, desc = "swap down" },
      { "<leader><leader>k", function() require("smart-splits").swap_buf_up() end, desc = "swap up" },
      { "<leader><leader>l", function() require("smart-splits").swap_buf_right() end, desc = "swap right" },
    },
  },

  {
    "monaqa/dial.nvim",
    keys = {
      { "<C-a>", function() return require("dial.map").inc_normal() end, expr = true, desc = "Increment" },
      { "<C-x>", function() return require("dial.map").dec_normal() end, expr = true, desc = "Decrement" },
    },
    config = function()
      local augend = require("dial.augend")
      require("dial.config").augends:register_group({
        default = {
          augend.integer.alias.decimal,
          augend.integer.alias.hex,
          augend.date.alias["%Y/%m/%d"],
          augend.constant.alias.bool,
          augend.semver.alias.semver,
          augend.constant.new({ elements = { "let", "const" } }),
          augend.constant.new({ elements = { ":ok", ":error" } }),
        },
      })
    end,
  },

  -- ( LSP ) -------------------------------------------------------------------
  { "onsails/lspkind.nvim" },
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      { "williamboman/mason-lspconfig.nvim" },
      {
        "WhoIsSethDaniel/mason-tool-installer.nvim",
        opts = {
          ensure_installed = {
            "black",
            "eslint_d",
            "eslint_d",
            "isort",
            "prettier",
            "prettierd",
            "ruff",
            "stylua",
            -- "rubocop",
          },
          automatic_installation = true,
        },
      },
      {
        "williamboman/mason.nvim",
        config = function()
          local tools = {
            "luacheck",
            "prettier",
            "prettierd",
            "selene",
            "shellcheck",
            "shfmt",
            -- "solargraph",
            "stylua",
            "yamlfmt",
            -- "black",
            -- "buf",
            -- "cbfmt",
            -- "deno",
            -- "elm-format",
            -- "eslint_d",
            -- "fixjson",
            -- "flake8",
            -- "goimports",
            -- "isort",
          }

          require("mason").setup()
          local mr = require("mason-registry")
          for _, tool in ipairs(tools) do
            local p = mr.get_package(tool)
            if not p:is_installed() then p:install() end
          end

          require("mason-lspconfig").setup({
            automatic_installation = true,
          })
        end,
      },
      { "nvim-lua/lsp_extensions.nvim" },
      { "b0o/schemastore.nvim" },
      {
        "icholy/lsplinks.nvim",
        config = function()
          local lsplinks = require("lsplinks")
          lsplinks.setup()
          vim.keymap.set("n", "gx", lsplinks.gx)
        end,
      },
      {
        "j-hui/fidget.nvim",
        config = function()
          require("fidget").setup({
            progress = {
              display = {
                done_icon = "✓",
              },
            },
            notification = {
              view = {
                group_separator = "─────", -- digraph `hh`
              },
              window = {
                winblend = 0,
              },
            },
          })
        end,
      },
      {
        "mhanberg/output-panel.nvim",
        keys = {
          {
            "<leader>lip",
            ":OutputPanel<CR>",
            desc = "lsp: open output panel",
          },
        },
        event = "LspAttach",
        cmd = { "OutputPanel" },
        config = function() require("output_panel").setup() end,
      },
      {
        "Fildo7525/pretty_hover",
        event = "LspAttach",
        opts = { border = _G.mega.current_border() },
      },
      {
        "lewis6991/hover.nvim",
        keys = { "K", "gK" },
        config = function()
          require("hover").setup({
            init = function()
              require("hover.providers.lsp")
              require("hover.providers.gh")
              require("hover.providers.gh_user")
              require("hover.providers.jira")
              require("hover.providers.man")
              require("hover.providers.dictionary")
            end,
            preview_opts = {
              border = _G.mega.current_border(),
            },
            -- Whether the contents of a currently open hover window should be moved
            -- to a :h preview-window when pressing the hover keymap.
            preview_window = true,
            title = false,
          })
        end,
      },
    },
  },
  { "kevinhwang91/nvim-bqf", ft = "qf", opts = {
    preview = {
      winblend = 0,
    },
  } },
  {
    "yorickpeterse/nvim-pqf",
    event = "BufReadPre",
    config = function()
      local icons = require("mega.icons")
      require("pqf").setup({
        signs = {
          error = icons.lsp.error,
          warning = icons.lsp.warn,
          info = icons.lsp.info,
          hint = icons.lsp.hint,
        },
        show_multiple_lines = true,
        max_filename_length = 40,
      })
    end,
  },
  {
    "folke/trouble.nvim",
    branch = "dev",
    cmd = { "TroubleToggle", "Trouble" },
    opts = {
      auto_open = false,
      use_diagnostic_signs = true, -- en
    },
  },

  -- ( Development ) -----------------------------------------------------------
  {
    "kevinhwang91/nvim-hclipboard",
    event = "InsertCharPre",
    config = function() require("hclipboard").start() end,
  },
  {
    "altermo/ultimate-autopair.nvim",
    event = { "InsertEnter", "TermEnter", "CursorMoved" },
    branch = "v0.6", --recomended as each new version will have breaking changes
    opts = {
      cmap = false,
    },
  },
  { "tpope/vim-dispatch" },
  -- {
  --   "tdfacer/explain-it.nvim",
  --   requires = {
  --     "rcarriga/nvim-notify",
  --   },
  --   config = function()
  --     require("explain-it").setup({
  --       -- Prints useful log messages
  --       debug = true,
  --       -- Customize notification window width
  --       max_notification_width = 20,
  --       -- Retry API calls
  --       max_retries = 3,
  --       -- Customize response text file persistence location
  --       output_directory = "/tmp/chat_output",
  --       -- Toggle splitting responses in notification window
  --       split_responses = false,
  --       -- Set token limit to prioritize keeping costs low, or increasing quality/length of responses
  --       token_limit = 2000,
  --     })
  --   end,
  -- },

  {
    "danymat/neogen",
    cmd = "Neogen",
    dependencies = { "nvim-treesitter/nvim-treesitter", "hrsh7th/vim-vsnip" },
    keys = {
      -- {
      --   "gcd",
      --   function() require("neogen").generate({}) end,
      --   desc = "comment: neogen comment",
      -- },
      {
        "<leader>cc",
        function() require("neogen").generate({}) end,
        desc = "comment: neogen comment",
      },
    },
    opts = function()
      local M = {}
      M.snippet_engine = "vsnip"
      M.languages = {}
      M.languages.python = { template = { annotation_convention = "google_docstrings" } }
      M.languages.typescript = { template = { annotation_convention = "tsdoc" } }
      M.languages.typescriptreact = M.languages.typescript
      return M
    end,
  },
  {
    -- TODO: https://github.com/avucic/dotfiles/blob/master/nvim_user/.config/nvim/lua/user/configs/dadbod.lua
    "kristijanhusak/vim-dadbod-ui",
    dependencies = "tpope/vim-dadbod",
    cmd = { "DBUI", "DBUIToggle", "DBUIAddConnection" },
    init = function()
      vim.g.db_ui_use_nerd_fonts = 1
      vim.g.db_ui_show_database_icon = 1
      vim.g.db_ui_auto_execute_table_helpers = 1
      -- _G.mega.nnoremap("<leader>db", "<cmd>DBUIToggle<CR>", "dadbod: toggle")
    end,
  },
  {
    "nacro90/numb.nvim",
    event = "CmdlineEnter",
    config = function() require("numb").setup() end,
  },
  { "tpope/vim-eunuch", cmd = { "Move", "Rename", "Remove", "Delete", "Mkdir", "SudoWrite", "Chmod" } },
  {
    "tpope/vim-abolish",
    event = "CmdlineEnter",
    keys = {
      {
        "<C-s>",
        ":S/<C-R><C-W>//<LEFT>",
        mode = "n",
        silent = false,
        desc = "abolish: replace word under the cursor (line)",
      },
      {
        "<C-s>",
        ":%S/<C-r><C-w>//c<left><left>",
        mode = "n",
        silent = false,
        desc = "abolish: replace word under the cursor (file)",
      },
      {
        "<C-r>",
        [["zy:'<'>S/<C-r><C-o>"//c<left><left>]],
        mode = "x",
        silent = false,
        desc = "abolish: replace word under the cursor (visual)",
      },
    },
  },
  { "tpope/vim-rhubarb", event = { "VeryLazy" } },
  { "tpope/vim-repeat", lazy = false },
  { "tpope/vim-unimpaired", event = { "VeryLazy" } },
  { "tpope/vim-apathy", event = { "VeryLazy" } },
  { "tpope/vim-scriptease", event = { "VeryLazy" }, cmd = { "Messages", "Mess", "Noti" } },
  { "lambdalisue/suda.vim", event = { "VeryLazy" } },
  { "EinfachToll/DidYouMean", event = { "BufNewFile" }, init = function() vim.g.dym_use_fzf = true end },
  { "ConradIrwin/vim-bracketed-paste" }, -- FIXME: delete?
  { "ryvnf/readline.vim", event = "CmdlineEnter" },

  -- ( Motions/Textobjects ) ---------------------------------------------------
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    opts = {
      jump = { nohlsearch = true, autojump = false },
      prompt = {
        -- Place the prompt above the statusline.
        win_config = { row = -3 },
      },
      search = {
        multi_window = false,
        mode = "exact",
        exclude = {
          "cmp_menu",
          "flash_prompt",
          "qf",
          function(win)
            -- Floating windows from bqf.
            if vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(win)):match("BqfPreview") then return true end

            -- Non-focusable windows.
            return not vim.api.nvim_win_get_config(win).focusable
          end,
        },
      },
      modes = {
        search = {
          enabled = false,
        },
        char = {
          keys = { "f", "F", "t", "T", ";" }, -- NOTE: using "," here breaks which-key
        },
      },
    },
    keys = {
      {
        "s",
        mode = { "n", "x", "o" },
        function() require("flash").jump() end,
      },
      {
        "m",
        mode = { "o", "x" },
        function() require("flash").treesitter() end,
      },
      { "vv", mode = { "n", "o", "x" }, function() require("flash").treesitter() end },
      {
        "r",
        function() require("flash").remote() end,
        mode = "o",
        desc = "Remote Flash",
      },
      {
        "<c-s>",
        function() require("flash").toggle() end,
        mode = { "c" },
        desc = "Toggle Flash Search",
      },
      {
        "R",
        function() require("flash").treesitter_search() end,
        mode = { "o", "x" },
        desc = "Flash Treesitter Search",
      },
    },
  },
  {
    "Wansmer/treesj",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      {
        "AndrewRadev/splitjoin.vim",
        init = function()
          vim.g.splitjoin_split_mapping = ""
          vim.g.splitjoin_join_mapping = ""
        end,
      },
    },
    cmd = {
      "TSJSplit",
      "TSJJoin",
      "TSJToggle",
      "SplitjoinJoin",
      "SplitjoinSplit",
      "SplitjoinToggle",
    },
    keys = {
      {
        "gJ",
        function()
          if require("treesj.langs")["presets"][vim.bo.filetype] then
            vim.cmd("TSJToggle")
          else
            vim.cmd("SplitjoinToggle")
          end
        end,
        desc = "splitjoin: toggle lines",
      },
    },
    opts = {
      use_default_keymaps = false,
      max_join_length = tonumber(vim.g.default_colorcolumn),
    },
  },

  -- ( Notes/Docs ) ------------------------------------------------------------
  {
    "gaoDean/autolist.nvim",
    event = {
      "BufRead **.md,**.neorg,**.org",
      "BufNewFile **.md,**.neorg,**.org",
    },
    version = "2.3.0",
    config = function()
      local al = require("autolist")
      al.setup()
      al.create_mapping_hook("i", "<CR>", al.new)
      al.create_mapping_hook("i", "<Tab>", al.indent)
      al.create_mapping_hook("i", "<S-Tab>", al.indent, "<C-d>")
      al.create_mapping_hook("n", "o", al.new)
      al.create_mapping_hook("n", "<C-c>", al.invert_entry)
      al.create_mapping_hook("n", "<C-x>", al.invert_entry)
      al.create_mapping_hook("n", "O", al.new_before)
    end,
  },
  {
    "lukas-reineke/headlines.nvim",
    event = {
      "BufRead **.md,**.yaml,**.neorg,**.org",
      "BufNewFile **.md,**.yaml,**.neorg,**.org",
    },
    dependencies = "nvim-treesitter",
    config = function()
      require("headlines").setup({
        markdown = {
          source_pattern_start = "^```",
          source_pattern_end = "^```$",
          dash_pattern = "-",
          dash_highlight = "Dash",
          dash_string = "󰇜",
          quote_highlight = "Quote",
          quote_string = "┃",
          headline_pattern = "^#+",
          headline_highlights = { "Headline1", "Headline2", "Headline3", "Headline4", "Headline5", "Headline6" },
          fat_headlines = true,
          fat_headline_upper_string = "▃",
          fat_headline_lower_string = "🬂",
          codeblock_highlight = "CodeBlock",
          bullets = {},
          bullet_highlights = {},
          -- bullets = { "◉", "○", "✸", "✿" },
          -- bullet_highlights = {
          --   "@text.title.1.marker.markdown",
          --   "@text.title.2.marker.markdown",
          --   "@text.title.3.marker.markdown",
          --   "@text.title.4.marker.markdown",
          --   "@text.title.5.marker.markdown",
          --   "@text.title.6.marker.markdown",
          -- },
        },
        yaml = {
          dash_pattern = "^---+$",
          dash_highlight = "Dash",
        },
      })
    end,
  },

  -- ( Syntax/Languages/langs ) ------------------------------------------------------
  { "ii14/emmylua-nvim", ft = "lua" },
  -- { "elixir-editors/vim-elixir", ft = "elixir" }, -- nvim exceptions thrown when not installed
  { "imsnif/kdl.vim", ft = "kdl" },
  { "chr4/nginx.vim", ft = "nginx" },
  { "fladson/vim-kitty", ft = "kitty" },
  { "SirJson/fzf-gitignore", config = function() vim.g.fzf_gitignore_no_maps = true end },
  { "justinsgithub/wezterm-types" },
  {
    "axelvc/template-string.nvim",
    event = { "LazyFile" },
    ft = {
      "typescript",
      "typescriptreact",
      "javascript",
      "javascriptreact",
    },
  },
}
