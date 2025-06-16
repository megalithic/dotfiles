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
    config = function(_, opts)
      local hop = require("hop")
      hop.setup(opts)
    end,
  },
  {
    "jake-stewart/multicursor.nvim",
    event = "VeryLazy",
    config = function()
      local mc = require("multicursor-nvim")
      mc.setup()
      local map = vim.keymap.set

      map("n", "<localleader>c", mc.toggleCursor, { desc = "Toggle cursor" })
      map("x", "<localleader>c", function()
        mc.action(function(ctx)
          ctx:forEachCursor(function(cur) cur:splitVisualLines() end)
        end)
        mc.feedkeys("<Esc>", { remap = false, keycodes = true })
      end, { desc = "Create cursors from visual" })
      map({ "n", "x" }, "<localleader>v", function() mc.matchAddCursor(1) end, { desc = "Create cursors from word/selection" })
      map("x", "<localleader>m", mc.matchCursors, { desc = "Match cursors from visual" })
      map("x", "<localleader>s", mc.splitCursors, { desc = "Split cursors from visual" })
      map("n", "<localleader>a", mc.alignCursors, { desc = "Align cursors" })

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
    ---@type Flash.Config
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

  -- {
  --   "windwp/nvim-autopairs",
  --   enabled = false,
  --   lazy = true,
  --   opts = { check_ts = true },
  --   config = function(_, opts)
  --     local npairs = require("nvim-autopairs")
  --     npairs.setup()

  --     npairs.add_rules(require("nvim-autopairs.rules.endwise-elixir"))
  --     npairs.add_rules(require("nvim-autopairs.rules.endwise-lua"))
  --     npairs.add_rules(require("nvim-autopairs.rules.endwise-ruby"))
  --   end,
  -- },

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
  -- {
  --   "leobeosab/brr.nvim",
  --   cmd = { "Scratch", "ScratchList" },
  --   opts = {
  --     root = vim.g.notes_path .. "/scratch", -- Root where all scratch files are stored, I throw mine in an Obsidian vault
  --     style = {
  --       width = 0.8, -- 0-1, 1 being full width, 0 being, well, 0
  --       height = 0.8, -- 0-1
  --       title_padding = 2, -- number of spaces as padding in the top border title
  --     },
  --   },
  --   keys = { -- You'll probably want to change my weird keybinds, these are just examples
  --     { "<leader>.", "<cmd>Scratch scratch.md<cr>", desc = "Open persistent scratch" },
  --     { "<leader>sd", "<cmd>Scratch<cr>", desc = "Open daily scratch" },
  --     { "<leader>sf", "<cmd>ScratchList<cr>", desc = "Find scratch" },
  --   },
  -- },

  -- {
  --   "luckasRanarison/tailwind-tools.nvim",
  --   dependencies = { "nvim-lspconfig" },
  --   build = ":UpdateRemotePlugins",
  --   name = "tailwind-tools",
  --   opts = {
  --     server = {
  --       override = true,
  --       settings = {},
  --     },
  --   },
  --   config = function(_, opts)
  --     local function find_tailwind_root_phoenix(fname)
  --       local util = require("lspconfig.util")
  --       local phoenix_root = util.root_pattern("mix.exs")(fname)
  --       if phoenix_root then
  --         if vim.fn.isdirectory(phoenix_root) == 1 then return phoenix_root end
  --       end
  --       return util.root_pattern("package.json", "tailwind.config.js", "vite.config.js")(fname)
  --     end

  --     opts.server.root_dir = find_tailwind_root_phoenix

  --     require("tailwind-tools").setup(opts)
  --   end,
  -- },

  -- {
  --   "dbernheisel/tailwind-tools.nvim",
  --   branch = "db-extend-root-and-on-attach",
  --   name = "tailwind-tools",
  --   build = ":UpdateRemotePlugins",
  --   dependencies = {
  --     "nvim-treesitter/nvim-treesitter",
  --     "nvim-telescope/telescope.nvim", -- optional
  --     "neovim/nvim-lspconfig", -- optional
  --   },
  --   opts = {},
  -- }

  -- {
  --   "luckasRanarison/tailwind-tools.nvim",
  --   lazy = true,
  --   name = "tailwind-tools",
  --   build = ":UpdateRemotePlugins",
  --   init = function()
  --     vim.api.nvim_create_autocmd("LspAttach", {
  --       callback = function(args)
  --         local client = vim.lsp.get_client_by_id(args.data.client_id)
  --         if client and client.name == "tailwindcss" then
  --           require("tailwind-tools")
  --           return true
  --         end
  --       end,
  --     })
  --   end,
  --   opts = {
  --     conceal = {
  --       symbol = "…",
  --     },
  --   },
  --   config = function(_, opts)
  --     local function find_tailwind_root_phoenix(fname)
  --       local util = require("lspconfig.util")
  --       local phoenix_root = util.root_pattern("mix.exs")(fname)
  --       if phoenix_root then
  --         if vim.fn.isdirectory(phoenix_root) == 1 then return phoenix_root end
  --       end
  --       return util.root_pattern("package.json", "tailwind.config.js", "vite.config.js")(fname)
  --     end

  --     opts = vim.tbl_extend("keep", opts, {
  --       server = {
  --         override = true,
  --         root_dir = find_tailwind_root_phoenix,
  --         settings = {},
  --       },
  --     })

  --     require("tailwind-tools").setup(opts)
  --     -- custom.cmp_format.before = require("tailwind-tools.cmp").lspkind_format
  --   end,
  -- },
  { "neovim/nvim-lspconfig" },
  {
    --[[
    local ensure_installed_tools = {
      'stylua',
      'prettierd',
      'biome',
      'bash-language-server',
      'marksman',
      'elixir-ls',
      'lua-language-server',
      'vtsls',
      'tailwindcss-language-server',
      'markdownlint-cli2',
      'markdown-toc',
      'js-debug-adapter',
      'emmet-language-server',
    }
    local unique_tools = {}
    for _, tool in ipairs(ensure_installed_tools) do
      unique_tools[tool] = true
    end
    require('mason-tool-installer').setup {
      ensure_installed = vim.tbl_keys(unique_tools),
    }
    --]]
    -- FIXME: this still wants mason itself..
    cond = false,
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    opts = {
      ensure_installed = {
        "black",
        "eslint_d",
        "isort",
        "prettier",
        "prettierd",
        "ruff",
        "stylua",
        "nixpkgs-fmt",
        -- "tailwindcss-language-server@0.12.18",
        -- "tailwindcss-language-server@0.0.27",
      },
    },
  },
  { "nvim-lua/lsp_extensions.nvim" },
  { "b0o/schemastore.nvim" },
  {
    cond = false,
    "Bekaboo/dropbar.nvim",
    -- optional, but required for fuzzy finder support
    -- dependencies = {
    --   "nvim-telescope/telescope-fzf-native.nvim",
    --   build = "make",
    -- },
    name = "dropbar",
    -- config = function()
    --   local dropbar_api = require("dropbar.api")
    --   -- vim.keymap.set("n", "<Leader>;", dropbar_api.pick, { desc = "Pick symbols in winbar" })
    --   vim.keymap.set("n", "[;", dropbar_api.goto_context_start, { desc = "Go to start of current context" })
    --   vim.keymap.set("n", "];", dropbar_api.select_next_context, { desc = "Select next context" })
    -- end,
    event = { "BufReadPost", "BufNewFile" },
    -- keys = {
    --   Keymap({ "n" }, "<leader>p", function() require("dropbar.api").pick(vim.v.count ~= 0 and vim.v.count) end, "Toggle dropbar menu"),
    -- },
    opts = {},
  },
  -- { "SmiteshP/nvim-navic" },
  { "onsails/lspkind.nvim" },
  {
    "stevearc/aerial.nvim", -- Toggled list of classes, methods etc in current file
    opts = {
      cmd = { "AerialToggle" },
      attach_mode = "global",
      close_on_select = true,
      layout = {
        min_width = 30,
        default_direction = "prefer_right",
      },
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
    -- keys = {
    --   { "<C-t>", "<cmd>AerialToggle<CR>", mode = { "n", "x", "o" }, desc = "Aerial Toggle" },
    -- },
  },
  {
    -- FIXME: https://github.com/mhanberg/output-panel.nvim/issues/5
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
  -- {
  --   -- FIXME: this is a no go; crashes rpc
  --   enabled = false,
  --   "synic/refactorex.nvim",
  --   ft = "elixir",
  --   opts = {
  --     auto_update = true,
  --     pin_version = nil,
  --   },
  -- },
}
