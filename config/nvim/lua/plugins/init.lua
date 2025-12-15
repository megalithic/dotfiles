return {
  -- { "tpope/vim-eunuch", cmd = { "Move", "Rename", "Remove", "Delete", "Mkdir", "SudoWrite", "Chmod" } },
  -- { "tpope/vim-rhubarb", event = { "VeryLazy" } },
  -- { "tpope/vim-repeat", lazy = false },
  -- { "tpope/vim-unimpaired", event = { "VeryLazy" } },
  -- { "tpope/vim-apathy", event = { "VeryLazy" } },
  -- { "tpope/vim-scriptease", event = { "VeryLazy" }, cmd = { "Messages", "Mess", "Noti" } },
  -- { "tpope/vim-sleuth" }, -- Detect tabstop and shiftwidth automatically
  -- {
  --   "max397574/better-escape.nvim",
  --   event = { "InsertEnter" },
  --   config = function()
  --     require("better_escape").setup({
  --       timeout = vim.o.timeoutlen,
  --       default_mappings = false,
  --       mappings = {
  --         i = { k = { j = "<esc>" } },
  --         c = { k = { j = "<esc>" } },
  --         -- HACK: move the cursor back before escaping
  --         v = { k = { j = "j<esc>" } },
  --       },
  --     })
  --   end,
  -- },
  { "tjdevries/lazy-require.nvim" },
  {
    "EinfachToll/DidYouMean",
    event = { "BufNewFile" },
    init = function() vim.g.dym_use_fzf = true end,
  },
  -- { "ryvnf/readline.vim", event = "CmdlineEnter" },
  {
    "farmergreg/vim-lastplace",
    lazy = false,
    init = function()
      vim.g.lastplace_ignore = "gitcommit,gitrebase,svn,hgcommit,oil,megaterm,neogitcommit,gitrebase"
      vim.g.lastplace_ignore_buftype = "quickfix,nofile,help,terminal"
      vim.g.lastplace_open_folds = true
    end,
  },
  -- {
  --   "numToStr/Comment.nvim",
  --   opts = {
  --     ignore = "^$", -- ignore blank lines
  --   },
  --   config = function(_, opts)
  --     require("Comment").setup(opts)
  --   end,
  -- },
  {
    "mrjones2014/smart-splits.nvim",
    lazy = false,
    commit = "36bfe63246386fc5ae2679aa9b17a7746b7403d5",
    opts = { at_edge = "stop" },
    keys = {
      {
        "<A-h>",
        function() require("smart-splits").resize_left() end,
      },
      {
        "<A-l>",
        function() require("smart-splits").resize_right() end,
      },
      {
        "<C-h>",
        function()
          require("smart-splits").move_cursor_left()
          vim.cmd.normal("zz")
        end,
      },
      {
        "<C-j>",
        function() require("smart-splits").move_cursor_down() end,
      },
      {
        "<C-k>",
        function() require("smart-splits").move_cursor_up() end,
      },
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
  -- {
  --   "yehuohan/hop.nvim",
  --   event = "VeryLazy",
  --   opts = { match_mappings = { "noshift", "zh", "zh_sc" } },
  --   keys = {
  --     -- {
  --     --   "f",
  --     --   mode = { "n", "x", "o" },
  --     --   "<Cmd>HopCharCL<CR>",
  --     -- },
  --     -- {
  --     --   "F",
  --     --   mode = { "n", "x", "o" },
  --     --   "<Cmd>HopAnywhereCL<CR>",
  --     -- },
  --     -- {
  --     --   "s",
  --     --   mode = { "n", "x" },
  --     --   "<Cmd>HopChar<CR>",
  --     -- },
  --     -- {
  --     --   "S",
  --     --   mode = { "n", "x" },
  --     --   "<Cmd>HopWord<CR>",
  --     -- },
  --   },
  --   config = function(_, opts)
  --     require("hop").setup(opts)
  --   end,
  -- },
  -- {
  --   "jake-stewart/multicursor.nvim",
  --   event = "VeryLazy",
  --   config = function()
  --     local mc = require("multicursor-nvim")
  --     mc.setup()
  --     local map = vim.keymap.set

  --     map("n", "<localleader>c", mc.toggleCursor, { desc = "[mc] toggle cursor" })
  --     map("x", "<localleader>c", function()
  --       mc.action(function(ctx)
  --         ctx:forEachCursor(function(cur)
  --           cur:splitVisualLines()
  --         end)
  --       end)
  --       mc.feedkeys("<Esc>", { remap = false, keycodes = true })
  --     end, { desc = "[mc] create cursors from visual" })
  --     map({ "n", "x" }, "<localleader>v", function()
  --       mc.matchAddCursor(1)
  --     end, { desc = "[mc] create cursors from word/selection" })
  --     map("x", "<localleader>m", mc.matchCursors, { desc = "[mc] match cursors from visual" })
  --     map("x", "<localleader>s", mc.splitCursors, { desc = "[mc] split cursors from visual" })
  --     map("n", "<localleader>a", mc.alignCursors, { desc = "[mc] align cursors" })

  --     mc.addKeymapLayer(function(layer)
  --       local hop = require("hop")
  --       local move_mc = require("hop.jumper").move_multicursor
  --       layer({ "n", "x" }, "s", function()
  --         hop.char({ jump = move_mc })
  --       end)
  --       layer({ "n", "x" }, "S", function()
  --         hop.word({ jump = move_mc })
  --       end)
  --       layer({ "n", "x", "o" }, "f", "f")
  --       layer({ "n", "x", "o" }, "F", "F")
  --       layer({ "n", "x" }, "<leader>j", function()
  --         hop.vertical({ jump = move_mc })
  --       end)
  --       layer({ "n", "x" }, "<leader>k", function()
  --         hop.vertical({ jump = move_mc })
  --       end)

  --       layer({ "n", "x" }, "n", function()
  --         mc.matchAddCursor(1)
  --       end)
  --       layer({ "n", "x" }, "N", function()
  --         mc.matchAddCursor(-1)
  --       end)
  --       layer({ "n", "x" }, "m", function()
  --         mc.matchSkipCursor(1)
  --       end)
  --       layer({ "n", "x" }, "M", function()
  --         mc.matchSkipCursor(-1)
  --       end)
  --       layer("n", "<leader><Esc>", mc.disableCursors)
  --       layer("n", "<Esc>", function()
  --         if mc.cursorsEnabled() then
  --           mc.clearCursors()
  --         else
  --           mc.enableCursors()
  --         end
  --       end)
  --     end)
  --   end,
  -- },
  -- {
  --   enabled = false,
  --   "chrisgrieser/nvim-spider",
  --   keys = function()
  --     local spider = require("spider")
  --
  --     local motion = function(key)
  --       return function() spider.motion(key) end
  --     end
  --
  --     local mappings = {
  --       { "w", motion("w"), "Word forward", mode = { "n", "o", "x" } },
  --       { "e", motion("e"), "󰯊 end of subword", mode = { "n", "o", "x" } },
  --       { "b", motion("b"), "󰯊 beginning of subword", mode = { "n", "o", "x" } },
  --       { "ge", motion("ge"), "Backward to end of word", mode = { "n", "o", "x" } },
  --     }
  --
  --     return vim.fn.get_lazy_keys_conf(mappings, "Spider Motions")
  --   end,
  --
  --   lazy = true,
  -- },
  -- {
  --   enabled = false,
  --   "chrisgrieser/nvim-various-textobjs",
  --   event = "VeryLazy",
  --   opts = {
  --     keymaps = {
  --       useDefaults = true,
  --     },
  --   },
  --   keys = {
  --     { -- subword
  --       "<Space>",
  --       function()
  --         -- for deletions use the outer subword, otherwise the inner
  --         local scope = vim.v.operator == "d" and "outer" or "inner"
  --         require("various-textobjs").subword(scope)
  --       end,
  --       mode = "o",
  --       desc = "󰬞 subword",
  --     },
  --   },
  -- },
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    keys = {
      {
        "s",
        mode = { "n", "x", "o" },
        function() require("flash").jump() end,
      },
    },
    -- opts = {
    --   highlight = {
    --     backdrop = false,
    --   },
    --   -- jump = {
    --   --   autojump = true,
    --   --   nohlsearch = true,
    --   -- },
    --   labels = "asdfqwerzxcv", -- Limit labels to left side of the keyboard
    --   modes = {
    --     char = {
    --       char_actions = function()
    --         return {
    --           [";"] = "next",
    --           ["F"] = "left",
    --           ["f"] = "right",
    --         }
    --       end,
    --       enabled = true,
    --       keys = { "f", "F", "t", "T", ";" },
    --       highlight = {
    --         backdrop = false,
    --       },
    --       jump_labels = false,
    --       multi_line = true,
    --     },
    --     search = {
    --       enabled = true,
    --       highlight = {
    --         backdrop = false,
    --       },
    --       jump = {
    --         autojump = false,
    --       },
    --     },
    --   },
    --   prompt = {
    --     win_config = { border = "none" },
    --   },
    --   -- search = {
    --   --   wrap = true,
    --   -- },
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
  -- {
  --   "kevinhwang91/nvim-bqf",
  --   ft = "qf",
  --   opts = {
  --     preview = {
  --       winblend = 0,
  --     },
  --   },
  -- },
  -- {
  --   "yorickpeterse/nvim-pqf",
  --   event = "BufReadPre",
  --   config = function()
  --     require("pqf").setup({
  --       signs = {
  --         error = { text = Icons.lsp.error, hl = "DiagnosticSignError" },
  --         warning = { text = Icons.lsp.warn, hl = "DiagnosticSignWarn" },
  --         info = { text = Icons.lsp.info, hl = "DiagnosticSignInfo" },
  --         hint = { text = Icons.lsp.hint, hl = "DiagnosticSignHint" },
  --       },
  --       show_multiple_lines = true,
  --       max_filename_length = 40,
  --     })
  --   end,
  -- },
  { "lambdalisue/suda.vim", event = { "VeryLazy" } },
  {
    "OXY2DEV/helpview.nvim",
    ft = "help",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
    },
  },
  {
    "MagicDuck/grug-far.nvim",
    ---@type grug.far.Options
    ---@diagnostic disable-next-line: missing-fields
    opts = {
      windowCreationCommand = "topleft 75vsplit",
      engines = {
        ripgrep = {
          placeholders = {
            search = "ex: foo    foo([a-z0-9]*)    fun\\(",
            replacement = "ex: bar    ${1}_foo    $$MY_ENV_VAR ",
            filesFilter = "ex: *.lua     *.{css,js}    **/docs/*.md",
            flags = "ex: --help, Ignore Case (-i), Match Whole World (-w), --replace= (empty replace) --multiline (-U)",
            paths = "ex: /foo/bar   ../   ./hello\\ world/   ./src/foo.lua",
          },
        },
      },

      openTargetWindow = {
        preferredLocation = "right",
      },

      keymaps = {
        replace = { n = "<localleader>r" },
        qflist = { n = "<localleader>q" },
        syncLocations = { n = "<localleader>a" },
        syncLine = { n = "<localleader>l" },
        close = { n = "<localleader>c" },
        historyOpen = { n = "<localleader>h" },
        historyAdd = { n = "<localleader>H" },
        refresh = { n = "<localleader>R" },
        openLocation = { n = "<localleader>o" },
        openNextLocation = { n = "<down>" },
        openPrevLocation = { n = "<up>" },
        gotoLocation = { n = "<enter>" },
        pickHistoryEntry = { n = "<enter>" },
        abort = { n = "<localleader>b" },
        help = { n = "g?" },
        toggleShowCommand = { n = "<localleader>p" },
        swapEngine = { n = "<localleader>e" },
        previewLocation = { n = "<localleader>i" },
        swapReplacementInterpreter = { n = "<localleader>x" },
      },
    },
    keys = {
      {
        "<leader>fR",
        mode = { "n", "x" },
        function() require("grug-far").open({ prefills = { paths = vim.fn.expand("%") } }) end,
        desc = "[F]ind",
      },
      {
        "<leader>fr",
        mode = { "n", "x" },
        function() require("grug-far").open() end,
        desc = "[F]ind",
      },
    },
  },
  -- {
  --   "nvim-neo-tree/neo-tree.nvim",
  --   branch = "v3.x",
  --   lazy = false,
  --   opts = {
  --     filesystem = {
  --       filtered_items = {
  --         hide_dotfiles = false,
  --       },
  --     },
  --     event_handlers = {
  --       {
  --         event = "file_opened",
  --         handler = function()
  --           vim.cmd.Neotree("close")
  --         end,
  --         id = "close-on-enter",
  --       },
  --     },
  --   },
  --   config = function(_, opts)
  --     require("neo-tree").setup(opts)
  --   end,
  --   dependencies = {
  --     "nvim-lua/plenary.nvim",
  --     "nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
  --     "MunifTanjim/nui.nvim",
  --   },
  --   cmd = {
  --     "Neotree",
  --   },
  --   keys = {
  --     {
  --       "<C-.>",
  --       function()
  --         vim.cmd.Neotree("reveal", "toggle=true")
  --       end,
  --       mode = "n",
  --       desc = "Toggle Neotree",
  --     },
  --   },
  -- },
  {
    "folke/lazydev.nvim",
    ft = "lua",
    opts = function()
      local paths = {
        { path = "${3rd}/luv/library", words = { "vim%.uv" } },
        { path = "lazy.nvim", words = { "LazyVim" } },
        { path = "luvit-meta/library", words = { "vim%.uv" } },
        { path = "wezterm-types", mods = { "wezterm" } },
        {
          path = vim.env.HOME .. ".config/hammerspoon/Spoons/EmmyLua.spoon/annotations",
          words = { "hs" },
        },
      }

      return { library = paths }
    end,
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
  -- {
  --   "ghostty",
  --   -- dir = "/Applications/Ghostty.app/Contents/Resources/vim/vimfiles/",
  --   dir = "/nix/store/a0qaly4bc5g6ml49jr76daz915mb74l1-home-manager-applications/Applications/Ghostty.app/Contents/Resources/vim/vimfiles/",
  --   lazy = false,
  -- },
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
  --   -- TODO: Add timeout option for popup menu | like which-key
  --   "otavioschwanck/arrow.nvim", -- Harpoon like alternative
  --   event = "VeryLazy",
  --   lazy = true,
  --   opts = {
  --     show_icons = true,
  --     leader_key = "\\",
  --     buffer_leader_key = "<A-\\>",
  --     always_show_path = true,
  --     separate_by_branch = true,
  --   },
  -- },

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
  { "brianhuster/unnest.nvim" },
  {
    "kawre/neotab.nvim",
    event = "InsertEnter",
    opts = {
      behavior = "nested",
      pairs = {
        { open = "(", close = ")" },
        { open = "[", close = "]" },
        { open = "{", close = "}" },
        { open = "'", close = "'" },
        { open = '"', close = '"' },
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
          triggers = {
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
  {
    "stevearc/quicker.nvim",
    lazy = false,
    opts = {
      keys = {
        {
          "+",
          function() require("quicker").expand({ before = 2, after = 2, add_to_existing = true }) end,
          desc = "Expand quickfix context",
        },
        {
          "-",
          function() require("quicker").collapse() end,
          desc = "Collapse quickfix context",
        },
      },
    },
  },
  {
    "mbbill/undotree",
    cmd = "UndotreeToggle",
    keys = {
      {
        "<leader>u",
        vim.cmd.UndotreeToggle,
        noremap = true,
        desc = "Toggle [U]ndotree",
      },
    },
    init = function()
      vim.g.undotree_WindowLayout = 2
      vim.g.undotree_SplitWidth = 50
      vim.g.undotree_SetFocusWhenToggle = 1
    end,
  },

  -- winbar, floating top right
  -- {
  --   "b0o/incline.nvim",
  --   event = "VeryLazy",
  --   opts = {
  --     ignore = { buftypes = function(_, buftype) return buftype ~= "" and buftype ~= "terminal" end },
  --     window = {
  --       padding = 0,
  --       margin = { horizontal = 0 },
  --     },
  --     render = function(props)
  --       -- Terminal rendering
  --       local ok_term, term_manager = pcall(dofile, vim.fn.stdpath("config") .. "/after/plugin/term")
  --       if not ok_term then return end
  --
  --       local term_idx = term_manager.get_current_term_idx(props.win)
  --       if term_idx ~= nil then
  --         local terms = term_manager.get_terms()
  --         local term_components = {}
  --         for i, term in ipairs(terms) do
  --           local highlight = i == term_idx and "TerminalWinbarFocus"
  --             or term:is_visible() and "TerminalWinbarVisible"
  --             or "Normal"
  --           table.insert(term_components, { " " .. i .. " ", group = highlight })
  --         end
  --
  --         table.insert(term_components, 1, "   ")
  --
  --         return term_components
  --       end
  --
  --       -- Typical rendering
  --
  --       local devicons = require("nvim-web-devicons")
  --
  --       -- Filename
  --       local buf_path = vim.api.nvim_buf_get_name(props.buf)
  --       local dirname = vim.fn.fnamemodify(buf_path, ":~:.:h")
  --       local dirname_component = { dirname, group = "Comment" }
  --
  --       local filename = vim.fn.fnamemodify(buf_path, ":t")
  --       if filename == "" then filename = "[No Name]" end
  --       local diagnostic_level = nil
  --       for _, diagnostic in ipairs(vim.diagnostic.get(props.buf)) do
  --         diagnostic_level = math.min(diagnostic_level or 999, diagnostic.severity)
  --       end
  --       local filename_hl = diagnostic_level == vim.diagnostic.severity.HINT and "DiagnosticHint"
  --         or diagnostic_level == vim.diagnostic.severity.INFO and "DiagnosticInfo"
  --         or diagnostic_level == vim.diagnostic.severity.WARN and "DiagnosticWarn"
  --         or diagnostic_level == vim.diagnostic.severity.ERROR and "DiagnosticError"
  --         or "Normal"
  --       local filename_component = { filename, group = filename_hl }
  --
  --       -- Modified icon
  --       local modified = vim.bo[props.buf].modified
  --       local modified_component = modified and { " ● ", group = "BufferCurrentMod" } or ""
  --
  --       local ft_icon, ft_color = devicons.get_icon_color(filename)
  --       local icon_component = ft_icon and { " ", ft_icon, " ", guifg = ft_color } or ""
  --
  --       return {
  --         modified_component,
  --         icon_component,
  --         " ",
  --         filename_component,
  --         " ",
  --         dirname_component,
  --         " ",
  --       }
  --     end,
  --   },
  -- },

  -- LSP notifications
  -- {
  --   "j-hui/fidget.nvim",
  --   event = "VeryLazy",
  --   opts = {
  --     notification = { window = { normal_hl = "Normal" } },
  --     integration = {
  --       ["nvim-tree"] = { enable = false },
  --       ["xcodebuild-nvim"] = { enable = false },
  --     },
  --   },
  -- },
  { "saghen/filler-begone.nvim" },

  -- forces plugins to use CursorLineSign
  { "jake-stewart/force-cul.nvim", opts = {} },
  {
    "codethread/qmk.nvim",
    ft = "keymap",
    enabled = false,
    event = "VeryLazy",
    opts = {
      name = "LAYOUT_leeloo",
      variant = "zmk",
      -- layout = {
      --   "x x x x x _ _ _ _ _ _ _ _ _ x x x x x",
      --   "x x x x x x _ _ _ _ _ _ _ x x x x x x",
      --   "x x x x x x _ _ _ _ _ _ _ x x x x x x",
      --   "x x x x x x _ _ _ _ _ _ _ x x x x x x",
      --   "x x x x x x x x x _ x x x x x x x x x",
      --   "x x x x x _ x x x _ x x x _ x x x x x",
      -- },
    },
  },
}
