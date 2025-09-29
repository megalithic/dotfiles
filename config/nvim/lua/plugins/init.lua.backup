return {
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
    "numToStr/Comment.nvim",
    opts = {
      ignore = "^$", -- ignore blank lines
    },
    config = function(_, opts) require("Comment").setup(opts) end,
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
  -- {
  --   "FluxxField/smart-motion.nvim",
  --   opts = {
  --     keys = "fjdksleirughtynm",
  --     highlight = {
  --       dim = "SmartMotionDim",
  --       hint = "SmartMotionHint",
  --       first_char = "SmartMotionFirstChar",
  --       second_char = "SmartMotionSecondChar",
  --       first_char_dim = "SmartMotionFirstCharDim",
  --     },
  --     multi_line = true,

  --     presets = {
  --       lines = false,
  --       words = true,
  --       search = true,
  --       delete = true,
  --       yank = true,
  --       change = true,
  --     },
  --   },
  -- },
  {
    "yehuohan/hop.nvim",
    event = "VeryLazy",
    opts = { match_mappings = { "noshift", "zh", "zh_sc" } },
    keys = {
      -- {
      --   "f",
      --   mode = { "n", "x", "o" },
      --   "<Cmd>HopCharCL<CR>",
      -- },
      -- {
      --   "F",
      --   mode = { "n", "x", "o" },
      --   "<Cmd>HopAnywhereCL<CR>",
      -- },
      -- {
      --   "s",
      --   mode = { "n", "x" },
      --   "<Cmd>HopChar<CR>",
      -- },
      -- {
      --   "S",
      --   mode = { "n", "x" },
      --   "<Cmd>HopWord<CR>",
      -- },
    },
    config = function(_, opts) require("hop").setup(opts) end,
  },
  {
    "jake-stewart/multicursor.nvim",
    event = "VeryLazy",
    config = function()
      local mc = require("multicursor-nvim")
      mc.setup()
      local map = vim.keymap.set

      map("n", "<localleader>c", mc.toggleCursor, { desc = "[mc] toggle cursor" })
      map("x", "<localleader>c", function()
        mc.action(function(ctx)
          ctx:forEachCursor(function(cur) cur:splitVisualLines() end)
        end)
        mc.feedkeys("<Esc>", { remap = false, keycodes = true })
      end, { desc = "[mc] create cursors from visual" })
      map({ "n", "x" }, "<localleader>v", function() mc.matchAddCursor(1) end, { desc = "[mc] create cursors from word/selection" })
      map("x", "<localleader>m", mc.matchCursors, { desc = "[mc] match cursors from visual" })
      map("x", "<localleader>s", mc.splitCursors, { desc = "[mc] split cursors from visual" })
      map("n", "<localleader>a", mc.alignCursors, { desc = "[mc] align cursors" })

      mc.addKeymapLayer(function(layer)
        local hop = require("hop")
        local move_mc = require("hop.jumper").move_multicursor
        layer({ "n", "x" }, "s", function() hop.char({ jump = move_mc }) end)
        layer({ "n", "x" }, "S", function() hop.word({ jump = move_mc }) end)
        layer({ "n", "x", "o" }, "f", "f")
        layer({ "n", "x", "o" }, "F", "F")
        layer({ "n", "x" }, "<leader>j", function() hop.vertical({ jump = move_mc }) end)
        layer({ "n", "x" }, "<leader>k", function() hop.vertical({ jump = move_mc }) end)

        layer({ "n", "x" }, "n", function() mc.matchAddCursor(1) end)
        layer({ "n", "x" }, "N", function() mc.matchAddCursor(-1) end)
        layer({ "n", "x" }, "m", function() mc.matchSkipCursor(1) end)
        layer({ "n", "x" }, "M", function() mc.matchSkipCursor(-1) end)
        layer("n", "<leader><Esc>", mc.disableCursors)
        layer("n", "<Esc>", function()
          if mc.cursorsEnabled() then
            mc.clearCursors()
          else
            mc.enableCursors()
          end
        end)
      end)
    end,
  },
  -- {
  --   "folke/flash.nvim",
  --   event = "VeryLazy",
  --   enabled = false,
  --   opts = {
  --     jump = { nohlsearch = true, autojump = false },
  --     prompt = {
  --       -- Place the prompt above the statusline.
  --       win_config = { row = -3 },
  --     },
  --     search = {
  --       multi_window = false,
  --       mode = "exact",
  --       exclude = {
  --         "cmp_menu",
  --         "flash_prompt",
  --         "qf",
  --         function(win)
  --           -- Floating windows from bqf.
  --           if vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(win)):match("BqfPreview") then return true end

  --           -- Non-focusable windows.
  --           return not vim.api.nvim_win_get_config(win).focusable
  --         end,
  --       },
  --     },
  --     modes = {
  --       search = {
  --         enabled = false,
  --       },
  --       char = {
  --         keys = { "f", "F", "t", "T", ";" }, -- NOTE: using "," here breaks which-key
  --         char_actions = function(motion)
  --           return {
  --             -- clever-f style
  --             [motion:lower()] = "next",
  --             [motion:upper()] = "prev",
  --           }
  --         end,
  --       },
  --     },
  --   },
  --   keys = {
  --     {
  --       "s",
  --       mode = { "n", "x", "o" },
  --       function() require("flash").jump() end,
  --     },
  --     { "m", mode = { "o", "x" }, function() require("flash").treesitter() end },
  --     -- { "vn", mode = { "n", "o", "x" }, function() require("flash").treesitter() end },
  --     {
  --       "r",
  --       function() require("flash").remote() end,
  --       mode = "o",
  --       desc = "Remote Flash",
  --     },
  --     {
  --       "<c-s>",
  --       function() require("flash").toggle() end,
  --       mode = { "c" },
  --       desc = "Toggle Flash Search",
  --     },
  --     {
  --       "S",
  --       function() require("flash").treesitter_search() end,
  --       mode = { "o", "x" },
  --       desc = "Flash Treesitter Search",
  --     },
  --   },
  -- },
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    opts = {},
    keys = {
      { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash" },
      { "S", mode = { "n" }, function() require("flash").treesitter() end, desc = "Flash Treesitter" },
      { "m", mode = { "o", "x" }, function() require("flash").treesitter() end },
      { "r", mode = "o", function() require("flash").remote() end, desc = "Remote Flash" },
      { "R", mode = { "o", "x" }, function() require("flash").treesitter_search() end, desc = "Treesitter Search" },
      { "<c-s>", mode = { "c" }, function() require("flash").toggle() end, desc = "Toggle Flash Search" },
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
        enable_close_on_slash = false, -- Auto close on trailing </
      },
    },
  },
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    opts = {
      check_ts = true,
      enable_moveright = true,
      -- fast_wrap = {
      --   map = "<c-e>",
      -- },
    },
    config = function(_, opts)
      local npairs = require("nvim-autopairs")
      npairs.setup(opts)

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
      local icons = require("config.options").icons
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
  -- {
  --   "OXY2DEV/helpview.nvim",
  --   lazy = false,
  --   dependencies = {
  --     "nvim-treesitter/nvim-treesitter",
  --   },
  -- },
  {
    "MagicDuck/grug-far.nvim",
    config = function(_, opts) require("grug-far").setup(opts) end,
    cmd = {
      "GrugFar",
    },
    keys = {
      {
        "<leader>sr",
        [[<Cmd>GrugFar<CR>]],
        desc = "[grugfar] find and replace",
      },
      {
        "<leader>sR",
        function() require("grug-far").open({ prefills = { search = vim.fn.expand("<cword>") } }) end,
        desc = "[grugfar] find and replace current word",
      },
      {
        "<C-r>",
        [[:<C-U>lua require('grug-far').with_visual_selection({ prefills = { paths = vim.fn.expand("%") } })<CR>]],
        mode = { "v", "x" },
        desc = "[grugfar] find and replace visual selection",
      },
      {
        "<leader>sr",
        [[:<C-U>lua require('grug-far').with_visual_selection({ prefills = { paths = vim.fn.expand("%") } })<CR>]],
        mode = { "v", "x" },
        desc = "[grugfar] find and replace visual selection",
      },
    },
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
  -- {
  --   -- Meta type definitions for the Lua platform Luvit.
  --   -- SEE: https://github.com/Bilal2453/luvit-meta
  --   "Bilal2453/luvit-meta",
  --   lazy = true,
  -- },
  -- {
  --   "mcauley-penney/visual-whitespace.nvim",
  --   config = function()
  --     local U = require("config.utils")
  --     -- local ws_bg = U.get_hl_hex({ name = "Visual" })["bg"]
  --     -- local ws_fg = U.get_hl_hex({ name = "Comment" })["fg"]

  --     local ws_bg = U.hl.get_hl("Visual", "bg")
  --     local ws_fg = U.hl.get_hl("Comment", "fg")

  --     require("visual-whitespace").setup({
  --       highlight = { bg = ws_bg, fg = ws_fg },
  --       nl_char = "¬",
  --       excluded = {
  --         filetypes = { "aerial" },
  --         buftypes = { "help" },
  --       },
  --     })
  --   end,
  -- },
  {
    "ghostty",
    dir = "/Applications/Ghostty.app/Contents/Resources/vim/vimfiles/",
    lazy = false,
  },
  {
    "wurli/contextindent.nvim",
    -- This is the only config option; you can use it to restrict the files
    -- which this plugin will affect (see :help autocommand-pattern).
    opts = { pattern = "*" },
    dependencies = { "nvim-treesitter/nvim-treesitter" },
  },
  { "darfink/vim-plist" },
  {
    "axelvc/template-string.nvim",
    opts = {
      filetypes = { "typescript", "javascript", "typescriptreact", "javascriptreact", "vue" },
      remove_template_string = true,
      restore_quotes = {
        normal = [[']],
        jsx = [["]],
      },
    },
    event = "InsertEnter",
    ft = { "typescript", "javascript", "typescriptreact", "javascriptreact", "vue" },
  },
  -- {
  --   "folke/edgy.nvim",
  --   opts = function(_, opts)
  --     for _, pos in ipairs({ "top", "bottom", "left", "right" }) do
  --       opts[pos] = opts[pos] or {}
  --       table.insert(opts[pos], {
  --         ft = "megaterm",
  --         size = { height = 0.3, width = 0.3 },
  --         title = "%{b:megaterm.id}: %{b:term_title}",
  --         filter = function(_buf, win)
  --           local edgy_filter = vim.w[win].megaterm_win
  --             and vim.w[win].megaterm_win.position == pos
  --             and vim.w[win].megaterm_win.relative == "editor"
  --             and not vim.w[win].trouble_preview

  --           return edgy_filter
  --         end,
  --       })
  --     end
  --   end,
  -- },
  {
    -- TODO: Add timeout option for popup menu | like which-key
    "otavioschwanck/arrow.nvim", -- Harpoon like alternative
    event = "VeryLazy",
    lazy = true,
    opts = {
      show_icons = true,
      leader_key = "\\",
      buffer_leader_key = "<A-\\>",
      always_show_path = true,
      separate_by_branch = true,
    },
  },

  {
    "samjwill/nvim-unception",
    lazy = false,
    init = function()
      -- vim.g.unception_open_buffer_in_new_tab = true
      vim.g.unception_enable_flavor_text = false
      vim.g.unception_block_while_host_edits = true
    end,
  },

  {
    "willothy/flatten.nvim",
    version = "*",
    lazy = false,
    priority = 1001,
    opts = {
      callbacks = {
        should_block = function(argv)
          -- adds support for kubectl edit, sops and probably many other tools
          return vim.startswith(argv[#argv], "/tmp") or require("flatten").default_should_block(argv)
        end,
      },
      window = { open = "smart" },
    },
  },

  {
    "kawre/neotab.nvim",
    event = "InsertEnter",
    --- @module 'neotab'
    opts = {
      behavior = "nested", ---@type ntab.behavior
      pairs = { ---@type ntab.pair[]
        { open = "(", close = ")" },
        { open = "[", close = "]" },
        { open = "{", close = "}" },
        { open = "'", close = "'" },
        { open = "\"", close = "\"" },
        { open = "`", close = "`" },
        { open = "<", close = ">" },
      },
      smart_punctuators = {
        enabled = true,
        semicolon = {
          enabled = true,
          ft = { "javascript", "typescript", "javascriptreact", "typescriptreact", "rust" },
        },
        escape = {
          enabled = true,
          triggers = { ---@type table<string, ntab.trigger>
            -- [','] = {
            -- 	pairs = {
            -- 		{ open = "'", close = "'" },
            -- 		{ open = '"', close = '"' },
            -- 		{ open = '{', close = '}' },
            -- 		{ open = '[', close = ']' },
            -- 	},
            -- 	format = '%s ', -- ", "
            -- },
            ["="] = {
              pairs = {
                { open = "(", close = ")" },
              },
              ft = { "javascript", "typescript" },
              format = " %s> ", -- ` => `
              -- string.match(text_between_pairs, cond)
              cond = "^$", -- match only pairs with empty content
            },
          },
        },
      },
    },
  },
}
