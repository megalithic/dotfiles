local SETTINGS = require("mega.settings")

return {
  {
    -- {
    --   "max397574/better-escape.nvim",
    --   config = function() require("better_escape").setup() end,
    -- },
    {
      "farmergreg/vim-lastplace",
      lazy = false,
      init = function()
        vim.g.lastplace_ignore = "gitcommit,gitrebase,svn,hgcommit,oil,megaterm,neogitcommit,gitrebase"
        vim.g.lastplace_ignore_buftype = "quickfix,nofile,help,terminal"
        vim.g.lastplace_open_folds = true
      end,
    },
    { "tpope/vim-eunuch", cmd = { "Move", "Rename", "Remove", "Delete", "Mkdir", "SudoWrite", "Chmod" } },
    { "tpope/vim-rhubarb", event = { "VeryLazy" } },
    { "tpope/vim-repeat", lazy = false },
    { "tpope/vim-unimpaired", event = { "VeryLazy" } },
    { "tpope/vim-apathy", event = { "VeryLazy" } },
    { "tpope/vim-scriptease", event = { "VeryLazy" }, cmd = { "Messages", "Mess", "Noti" } },
    { "tpope/vim-sleuth" }, -- Detect tabstop and shiftwidth automatically
    { "EinfachToll/DidYouMean", event = { "BufNewFile" }, init = function() vim.g.dym_use_fzf = true end },
    -- { "ConradIrwin/vim-bracketed-paste" }, -- FIXME: delete?
    { "ryvnf/readline.vim", event = "CmdlineEnter" },
    -- { "brenoprata10/nvim-highlight-colors", opts = { enable_tailwind = true } },
    {
      "NvChad/nvim-colorizer.lua",
      event = { "BufReadPre" },

      config = function() require("colorizer").setup(SETTINGS.colorizer) end,
    },
    {
      "numToStr/Comment.nvim",
      cond = true,
      opts = {
        ignore = "^$", -- ignore blank lines
      },
      config = function(_, opts)
        -- require("Comment.ft")
        --   -- Set only line comment
        --   .set("heex", { "<%!-- %s --%>" })
        -- Or set both line and block commentstring
        -- .set("javascript", { "//%s", "/*%s*/" })

        require("Comment").setup(opts)
      end,
    },
    -- {
    --   "folke/ts-comments.nvim",
    --   cond = false,
    --   opts = {
    --     langs = {
    --       elixir = "# %s",
    --       eelixir = "# %s",
    --       heex = [[<%!-- %s --%>]],
    --     },
    --   },
    -- },
    {
      "folke/trouble.nvim",
      cmd = { "TroubleToggle", "Trouble" },
      opts = {
        auto_open = false,
        use_diagnostic_signs = true, -- en
      },
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
        {
          "<C-h>",
          function()
            require("smart-splits").move_cursor_left()
            vim.cmd.normal("zz")
          end,
        },
        { "<C-j>", function() require("smart-splits").move_cursor_down() end },
        { "<C-k>", function() require("smart-splits").move_cursor_up() end },
        {
          "<C-l>",
          function()
            require("smart-splits").move_cursor_right()
            vim.cmd.normal("zz")
          end,
        },
        -- swapping buffers between windows
        -- { "<leader><leader>h", function() require("smart-splits").swap_buf_left() end, desc = "swap left" },
        -- { "<leader><leader>j", function() require("smart-splits").swap_buf_down() end, desc = "swap down" },
        -- { "<leader><leader>k", function() require("smart-splits").swap_buf_up() end, desc = "swap up" },
        -- { "<leader><leader>l", function() require("smart-splits").swap_buf_right() end, desc = "swap right" },
      },
    },
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
          -- mode = { "n" },
          mode = { "n", "x", "o" },
          function() require("flash").jump() end,
        },
        -- { "m", mode = { "o", "x" }, function() require("flash").treesitter() end },
        { "vn", mode = { "n", "o", "x" }, function() require("flash").treesitter() end },
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
    -- {
    --   "stevearc/conform.nvim",
    --   lazy = false,
    --   keys = {
    --     {
    --       "<leader>f",
    --       function() require("conform").format({ async = true, lsp_fallback = true }) end,
    --       mode = "",
    --       desc = "[F]ormat buffer",
    --     },
    --   },
    --   opts = {
    --     notify_on_error = false,
    --     format_on_save = function(bufnr)
    --       -- Disable "format_on_save lsp_fallback" for languages that don't
    --       -- have a well standardized coding style. You can add additional
    --       -- languages here or re-enable it for the disabled ones.
    --       local disable_filetypes = { c = true, cpp = true }
    --       return {
    --         timeout_ms = 500,
    --         lsp_fallback = not disable_filetypes[vim.bo[bufnr].filetype],
    --       }
    --     end,
    --     formatters_by_ft = {
    --       lua = { "stylua" },
    --       -- Conform can also run multiple formatters sequentially
    --       -- python = { "isort", "black" },
    --       --
    --       -- You can use a sub-list to tell conform to run *until* a formatter
    --       -- is found.
    --       -- javascript = { { "prettierd", "prettier" } },
    --     },
    --   },
    -- },
  },
  {
    "nacro90/numb.nvim",
    event = "CmdlineEnter",
    opts = {},
  },
  {
    "windwp/nvim-ts-autotag",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      aliases = {
        ["elixir"] = "html",
        ["heex"] = "html",
        ["phoenix_html"] = "html",
      },
      opts = {

        -- Defaults
        enable_close = true, -- Auto close tags
        enable_rename = true, -- Auto rename pairs of tags
        enable_close_on_slash = true, -- Auto close on trailing </
      },
      -- Also override individual filetype configs, these take priority.
      -- Empty by default, useful if one of the "opts" global settings
      -- doesn't work well in a specific filetype
      -- per_filetype = {
      --   ["html"] = {
      --     enable_close = false,
      --   },
      -- },
    },
  },
  {
    "windwp/nvim-autopairs",
    cond = true,
    lazy = true,
    config = function()
      local npairs = require("nvim-autopairs")
      npairs.setup()

      npairs.add_rules(require("nvim-autopairs.rules.endwise-elixir"))
      npairs.add_rules(require("nvim-autopairs.rules.endwise-lua"))
      npairs.add_rules(require("nvim-autopairs.rules.endwise-ruby"))
    end,
  },
  { -- auto-pair
    -- EXAMPLE config of the plugin: https://github.com/Bekaboo/nvim/blob/master/lua/configs/ultimate-autopair.lua
    "altermo/ultimate-autopair.nvim",
    cond = false,
    branch = "v0.6", -- recommended as each new version will have breaking changes
    event = { "InsertEnter", "CmdlineEnter" },
    opts = {
      bs = {
        space = "balance",
        cmap = false, -- keep my `<BS>` mapping for the cmdline
      },
      fastwarp = {
        map = "<D-f>",
        rmap = "<D-F>", -- backwards
        hopout = true,
        nocursormove = true,
        multiline = false,
      },
      cr = { autoclose = true },
      space = { enable = true },
      space2 = { enable = true },

      config_internal_pairs = {
        { "'", "'", nft = { "markdown" } }, -- since used as apostroph
        { "\"", "\"", nft = { "vim" } }, -- vimscript uses quotes as comments
      },
      -- INFO custom keys need to be "appended" to the opts as a list
      { "*", "*", ft = { "markdown" } }, -- italics
      { "__", "__", ft = { "markdown" } }, -- bold
      { [[\"]], [[\"]], ft = { "zsh", "json", "applescript" } }, -- escaped quote

      { -- commit scope (= only first word) for commit messages
        "(",
        "): ",
        ft = { "gitcommit" },
        cond = function(_) return not vim.api.nvim_get_current_line():find(" ") end,
      },

      -- for keymaps like `<C-a>`
      { "<", ">", ft = { "vim" } },
      { "<", ">", ft = { "lua" }, cond = function(fn) return fn.in_string() end },
    },
  },
  {
    "kevinhwang91/nvim-bqf",
    ft = "qf",
    opts = {
      preview = {
        winblend = 0,
      },
    },
  },
  {
    "yorickpeterse/nvim-pqf",
    event = "BufReadPre",
    config = function()
      local icons = require("mega.settings").icons
      require("pqf").setup({
        signs = {
          error = { text = icons.lsp.error, hl = "DiagnosticSignError" },
          warning = { text = icons.lsp.warn, hl = "DiagnosticSignWarn" },
          info = { text = icons.lsp.info, hl = "DiagnosticSignInfo" },
          hint = { text = icons.lsp.hint, hl = "DiagnosticSignHint" },
        },
        show_multiple_lines = true,
        max_filename_length = 40,
      })
    end,
  },
  { "lambdalisue/suda.vim", event = { "VeryLazy" } },
  {
    "OXY2DEV/helpview.nvim",
    lazy = false,
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
    },
  },
  {
    "MagicDuck/grug-far.nvim",
    config = function()
      require("grug-far").setup({
        windowCreationCommand = "botright vsplit %",
      })
    end,
    cmd = {
      "GrugFar",
    },
    keys = {
      {
        "<localleader>er",
        [[<Cmd>GrugFar<CR>]],
        desc = "[grugfar] find and replace",
      },
      {
        "<localleader>eR",
        function() require("grug-far").grug_far({ prefills = { search = vim.fn.expand("<cword>") } }) end,
        desc = "[grugfar] find and replace current word",
      },
      {
        "<C-r>",
        [[:<C-U>lua require('grug-far').with_visual_selection({ prefills = { paths = vim.fn.expand("%") } })<CR>]],
        mode = { "v", "x" },
        desc = "[grugfar] find and replace visual selection",
      },
    },
  },
  {
    "tzachar/highlight-undo.nvim",
    event = "VeryLazy",
    config = true,
  },
  { "elixir-editors/vim-elixir", enabled = true },
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    lazy = false,
    opts = {
      filesystem = {
        filtered_items = {
          hide_dotfiles = false,
        },
      },
      event_handlers = {
        {
          event = "file_opened",
          handler = function() vim.cmd.Neotree("close") end,
          id = "close-on-enter",
        },
      },
    },
    config = function(_, opts) require("neo-tree").setup(opts) end,
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
      "MunifTanjim/nui.nvim",
    },
    cmd = {
      "Neotree",
    },
    keys = {
      {
        "<C-.>",
        function() vim.cmd.Neotree("reveal", "toggle=true") end,
        mode = "n",
        desc = "Toggle Neotree",
      },
    },
  },
  {
    "jiaoshijie/undotree",
    dependencies = "nvim-lua/plenary.nvim",
    config = true,
    keys = { -- load the plugin only when using it's keybinding:
      { "<leader>eu", "<cmd>lua require('undotree').toggle()<cr>", desc = "[u]ndo tree" },
    },
    opts = {
      float_diff = false, -- using float window previews diff, set this `true` will disable layout option
      layout = "left_bottom", -- "left_bottom", "left_left_bottom"
      position = "right", -- "right", "bottom"
      ignore_filetype = { "undotree", "undotreeDiff", "qf", "TelescopePrompt", "spectre_panel", "tsplayground" },
      window = {
        winblend = 0,
      },
      keymaps = {
        ["j"] = "move_next",
        ["k"] = "move_prev",
        ["gj"] = "move2parent",
        ["J"] = "move_change_next",
        ["K"] = "move_change_prev",
        ["<cr>"] = "action_enter",
        ["<tab>"] = "enter_diffbuf",
        ["q"] = "quit",
      },
    },
  },
  {
    "folke/lazydev.nvim",
    -- dependencies = {
    -- 	{ 'https://github.com/Bilal2453/luvit-meta', lazy = true }, -- optional `vim.uv` typings
    -- },
    ft = "lua",
    opts = {
      library = {
        { path = "luvit-meta/library", words = { "vim%.uv" } },
        { path = "wezterm-types", mods = { "wezterm" } },
        {
          path = vim.env.HOME .. "/.hammerspoon/Spoons/EmmyLua.spoon/annotations",
          words = { "hs" },
        },
      },
    },
  },
  {
    "mcauley-penney/visual-whitespace.nvim",
    branch = "async",
    config = function()
      local U = require("mega.utils")
      -- local ws_bg = U.get_hl_hex({ name = "Visual" })["bg"]
      -- local ws_fg = U.get_hl_hex({ name = "Comment" })["fg"]

      local ws_bg = U.hl.get_hl("Visual", "bg")
      local ws_fg = U.hl.get_hl("Comment", "fg")

      require("visual-whitespace").setup({
        highlight = { bg = ws_bg, fg = ws_fg },
        nl_char = "¬",
        excluded = {
          filetypes = { "aerial" },
          buftypes = { "help" },
        },
      })
    end,
  },
  {
    "aaron-p1/match-visual.nvim",
    opts = {
      min_length = 3,
    },
    init = function() vim.api.nvim_set_hl(0, "VisualMatch", { link = "MatchParen" }) end,
  },
}
