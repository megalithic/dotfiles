local SETTINGS = require("mega.settings")

return {
  {
    { "tpope/vim-eunuch", cmd = { "Move", "Rename", "Remove", "Delete", "Mkdir", "SudoWrite", "Chmod" } },
    { "tpope/vim-rhubarb", event = { "VeryLazy" } },
    { "tpope/vim-repeat", lazy = false },
    { "tpope/vim-unimpaired", event = { "VeryLazy" } },
    { "tpope/vim-apathy", event = { "VeryLazy" } },
    { "tpope/vim-scriptease", event = { "VeryLazy" }, cmd = { "Messages", "Mess", "Noti" } },
    { "tpope/vim-sleuth" }, -- Detect tabstop and shiftwidth automatically
    { "EinfachToll/DidYouMean", event = { "BufNewFile" }, init = function() vim.g.dym_use_fzf = true end },
    { "ryvnf/readline.vim", event = "CmdlineEnter" },
    {
      "farmergreg/vim-lastplace",
      lazy = false,
      init = function()
        vim.g.lastplace_ignore = "gitcommit,gitrebase,svn,hgcommit,oil,megaterm,neogitcommit,gitrebase"
        vim.g.lastplace_ignore_buftype = "quickfix,nofile,help,terminal"
        vim.g.lastplace_open_folds = true
      end,
    },
    {
      "NvChad/nvim-colorizer.lua",
      enabled = false, -- presently using mini-hipatterns
      event = { "BufReadPre" },
      config = function() require("colorizer").setup(SETTINGS.colorizer) end,
    },
    {
      "numToStr/Comment.nvim",
      opts = {
        ignore = "^$", -- ignore blank lines
      },
      config = function(_, opts) require("Comment").setup(opts) end,
    },
    {
      "folke/trouble.nvim",
      cmd = { "TroubleToggle", "Trouble" },
      opts = {
        auto_open = false,
        use_diagnostic_signs = true,
      },
    },
    {
      "mrjones2014/smart-splits.nvim",
      lazy = false,
      commit = "36bfe63246386fc5ae2679aa9b17a7746b7403d5",
      opts = { at_edge = "stop" },
      keys = {
        { "<A-h>", function() require("smart-splits").resize_left() end },
        { "<A-l>", function() require("smart-splits").resize_right() end },
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
          mode = { "n", "x", "o" },
          function() require("flash").jump() end,
        },
        { "m", mode = { "o", "x" }, function() require("flash").treesitter() end },
        -- { "vn", mode = { "n", "o", "x" }, function() require("flash").treesitter() end },
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
          "S",
          function() require("flash").treesitter_search() end,
          mode = { "o", "x" },
          desc = "Flash Treesitter Search",
        },
      },
    },
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
        enable_close = true, -- Auto close tags
        enable_rename = true, -- Auto rename pairs of tags
        enable_close_on_slash = true, -- Auto close on trailing </
      },
    },
  },
  {
    "windwp/nvim-autopairs",
    enabled = true,
    cond = false,
    lazy = true,
    config = function()
      local npairs = require("nvim-autopairs")
      npairs.setup()

      npairs.add_rules(require("nvim-autopairs.rules.endwise-elixir"))
      npairs.add_rules(require("nvim-autopairs.rules.endwise-lua"))
      npairs.add_rules(require("nvim-autopairs.rules.endwise-ruby"))
    end,
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
    opts = {
      windowCreationCommand = "botright vsplit %",
    },
    config = function(_, opts) require("grug-far").setup(opts) end,
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
    cond = false,
    event = "VeryLazy",

    "tzachar/highlight-undo.nvim",
    opts = {},
  },
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
    "folke/lazydev.nvim",
    ft = "lua",
    opts = {
      library = {
        { path = "${3rd}/luv/library", words = { "vim%.uv" } },
        { path = "lazy.nvim", words = { "LazyVim" } },
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
    -- Meta type definitions for the Lua platform Luvit.
    -- SEE: https://github.com/Bilal2453/luvit-meta
    "Bilal2453/luvit-meta",

    lazy = true,
  },
  {
    "mcauley-penney/visual-whitespace.nvim",
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
  -- <C-n> to select next word with new cursor
  {
    "brenton-leighton/multiple-cursors.nvim",
    version = "*",
    enabled = false,
    opts = {
      pre_hook = function()
        if pcall(require, "cmp") then require("cmp").setup({ enabled = false }) end
      end,
      post_hook = function()
        if pcall(require, "cmp") then require("cmp").setup({ enabled = true }) end
      end,
    },
    keys = {
      -- {"<C-j>", "<Cmd>MultipleCursorsAddDown<CR>", mode = {"n", "x"}, desc = "Add cursor and move down"},
      -- {"<C-k>", "<Cmd>MultipleCursorsAddUp<CR>", mode = {"n", "x"}, desc = "Add cursor and move up"},
      { "<C-x>", "<Cmd>MultipleCursorsMouseAddDelete<CR>", mode = { "n", "i" }, desc = "Add or remove cursor" },
      { "<C-n>", "<Cmd>MultipleCursorsAddMatches<CR>", mode = { "n", "x" }, desc = "Add cursors to cword" },
      -- {"<Leader>d", "<Cmd>MultipleCursorsAddJumpNextMatch<CR>", mode = {"n", "x"}, desc = "Add cursor and jump to next cword"},
      -- {"<Leader>D", "<Cmd>MultipleCursorsJumpNextMatch<CR>", mode = {"n", "x"}, desc = "Jump to next cword"},
      -- {"<leader>l", "<Cmd>MultipleCursorsLock<CR>", mode = {"n", "x"}, desc = "Lock virtual cursors"},
    },
  },
}
