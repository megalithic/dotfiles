return {
  {
    "rktjmp/lush.nvim",
    lazy = false,
    priority = 1001,
    config = function()
      mega.pcall("theme failed to load because", function(colorscheme)
        local theme = fmt("mega.lush_theme.%s", colorscheme)
        local ok, lush_theme = pcall(require, theme)
        if ok then
          vim.g.colors_name = colorscheme
          package.loaded[theme] = nil

          require("lush")(lush_theme)
        else
          pcall(vim.cmd.colorscheme, colorscheme)
        end

        -- NOTE: always make available my lushified-color palette
        mega.colors = require("mega.lush_theme.colors")
      end, vim.g.colorscheme)
    end,
  },
  {
    "farmergreg/vim-lastplace",
    lazy = false,
    init = function()
      vim.g.lastplace_ignore = "gitcommit,gitrebase,svn,hgcommit,oil,megaterm,neogitcommit,gitrebase"
      vim.g.lastplace_ignore_buftype = "quickfix,nofile,help,terminal"
      vim.g.lastplace_open_folds = true
    end,
  },
  { "nvim-tree/nvim-web-devicons", config = function() require("nvim-web-devicons").setup() end },
  {
    "NvChad/nvim-colorizer.lua",
    event = { "BufReadPre" },
    config = function()
      require("colorizer").setup({
        filetypes = { "*", "!lazy", "!gitcommit", "!NeogitCommitMessage", "!oil" },
        buftype = { "*", "!prompt", "!nofile", "!oil" },
        user_default_options = {
          RGB = false, -- #RGB hex codes
          RRGGBB = true, -- #RRGGBB hex codes
          names = false, -- "Name" codes like Blue or blue
          RRGGBBAA = true, -- #RRGGBBAA hex codes
          AARRGGBB = true, -- 0xAARRGGBB hex codes
          rgb_fn = true, -- CSS rgb() and rgba() functions
          hsl_fn = true, -- CSS hsl() and hsla() functions
          -- css = true, -- Enable all CSS features: rgb_fn, hsl_fn, names, RGB, RRGGBB
          css_fn = true, -- Enable all CSS *functions*: rgb_fn, hsl_fn
          sass = { enable = false, parsers = { "css" } }, -- Enable sass colors
          -- Available modes for `mode`: foreground, background,  virtualtext
          mode = "background", -- Set the display mode.
          virtualtext = "■",
        },
        -- all the sub-options of filetypes apply to buftypes
        buftypes = {},
      })
    end,
  },
  {
    "mrjones2014/smart-splits.nvim",
    lazy = false,
    opts = { at_edge = "stop" },
    build = "./kitty/install-kittens.bash",
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
        },
      })
    end,
  },
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      { "onsails/lspkind.nvim" },
      { "b0o/schemastore.nvim" },
      { "folke/neodev.nvim" },
      {
        "williamboman/mason.nvim",
        cmd = { "Mason" },
        opts = {
          registries = {
            "lua:mason.registry",
            "github:mason-org/mason-registry",
          },
          ui = {
            border = mega.get_border(),
          },
        },
      },
      {
        "williamboman/mason-lspconfig.nvim",
        lazy = true,
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
        opts = { border = _G.mega.get_border() },
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
              border = _G.mega.get_border(),
            },
            -- Whether the contents of a currently open hover window should be moved
            -- to a :h preview-window when pressing the hover keymap.
            preview_window = true,
            title = false,
          })
        end,
      },
      {
        "Wansmer/symbol-usage.nvim",
        event = "LspAttach",
        config = {
          text_format = function(symbol)
            local res = {}
            local ins = table.insert

            -- local round_start = { "", "SymbolUsageRounding" }
            -- local round_end = { "", "SymbolUsageRounding" }

            if symbol.references then
              local usage = symbol.references <= 1 and "usage" or "usages"
              local num = symbol.references == 0 and "no" or symbol.references
              -- ins(res, round_start)
              ins(res, { "󰌹 ", "SymbolUsageRef" })
              ins(res, { ("%s %s"):format(num, usage), "SymbolUsageContent" })
              if #res > 0 then table.insert(res, { " ", "NonText" }) end
              -- ins(res, round_end)
            end

            if symbol.definition then
              if #res > 0 then table.insert(res, { " ", "NonText" }) end
              -- ins(res, round_start)
              ins(res, { "󰳽 ", "SymbolUsageDef" })
              ins(res, { symbol.definition .. " defs", "SymbolUsageContent" })
              if #res > 0 then table.insert(res, { " ", "NonText" }) end
              -- ins(res, round_end)
            end

            if symbol.implementation then
              if #res > 0 then table.insert(res, { " ", "NonText" }) end
              -- ins(res, round_start)
              ins(res, { "󰡱 ", "SymbolUsageImpl" })
              ins(res, { symbol.implementation .. " impls", "SymbolUsageContent" })
              if #res > 0 then table.insert(res, { " ", "NonText" }) end
              -- ins(res, round_end)
            end

            return res
          end,
          -- text_format = function(symbol)
          --   local fragments = {}
          --
          --   if symbol.references then
          --     local usage = symbol.references <= 1 and "usage" or "usages"
          --     local num = symbol.references == 0 and "no" or symbol.references
          --     table.insert(fragments, { ("%s %s"):format(num, usage), "SymbolUsageContent" })
          --   end
          --
          --   if symbol.definition then
          --     table.insert(fragments, { symbol.definition .. " defs", "SymbolUsageContent" })
          --   end
          --
          --   if symbol.implementation then
          --     table.insert(fragments, { symbol.implementation .. " impls", "SymbolUsageContent" })
          --   end
          --
          --   -- return table.concat(fragments, ", ")
          --   return fragments
          -- end,
        },
      },
    },
    config = function()
      require("mason").setup()
      require("mason-lspconfig").setup({
        ensure_installed = {
          "sqlls",
          "clangd",
          "cssls",
          "denols",
          "emmet_language_server",
          "eslint",
          "gopls",
          "lua_ls",
          "marksman",
          "pylsp",
        },
      })
    end,
  },
  {
    "folke/trouble.nvim",
    cmd = { "TroubleToggle", "Trouble" },
    config = {
      auto_open = false,
      use_diagnostic_signs = true, -- en
    },
  },

  -- Fuzzy Finder (files, lsp, etc)
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
      { "r", function() require("flash").remote() end, mode = "o", desc = "Remote Flash" },
      { "<c-s>", function() require("flash").toggle() end, mode = { "c" }, desc = "Toggle Flash Search" },
      {
        "R",
        function() require("flash").treesitter_search() end,
        mode = { "o", "x" },
        desc = "Flash Treesitter Search",
      },
    },
  },
  { "lukas-reineke/virt-column.nvim", opts = { char = "│" }, event = "VimEnter" },
  {
    "lukas-reineke/indent-blankline.nvim",
    event = { "VeryLazy" },
    main = "ibl",
    opts = {
      indent = {
        char = "┊",
        smart_indent_cap = true,
      },
      scope = {
        enabled = false,
      },
    },
  },
  {
    "echasnovski/mini.indentscope",
    version = "*",
    main = "mini.indentscope",
    event = { "VeryLazy" },
    opts = {
      symbol = "┊", -- alts: ┊│┆ ┊  ▎││ ▏▏
      -- mappings = {
      --   goto_top = "<leader>k",
      --   goto_bottom = "<leader>j",
      -- },
      options = {
        try_as_border = true,
      },
      draw = {
        animation = function() return 0 end,
      },
    },
  },
  {
    "echasnovski/mini.pick",
    cmd = "Pick",
    opts = {},
  },
  {
    "echasnovski/mini.comment",
    event = "VeryLazy",
    config = function()
      require("mini.comment").setup({
        ignore_blank_lines = true,
        hooks = {
          pre = function() require("ts_context_commentstring.internal").update_commentstring({}) end,
        },
      })
    end,
  },
  {
    -- NOTE: only using for `gct` binding in mappings.lua
    "numToStr/Comment.nvim",
    opts = true,
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
          headline_pattern = "^#+",
          headline_highlights = { "Headline1", "Headline2", "Headline3", "Headline4", "Headline5", "Headline6" },
          codeblock_highlight = "CodeBlock",
        },
        yaml = {
          dash_pattern = "^---+$",
          dash_highlight = "Dash",
        },
      })
    end,
  },

  {
    "stevearc/oil.nvim",
    cmd = { "Oil" },
    enabled = vim.g.explorer == "oil",
    cond = vim.g.explorer == "oil",
    config = function()
      local icons = mega.icons
      local icon_file = vim.trim(icons.lsp.kind.File)
      local icon_dir = vim.trim(icons.lsp.kind.Folder)
      local permission_hlgroups = setmetatable({
        ["-"] = "OilPermissionNone",
        ["r"] = "OilPermissionRead",
        ["w"] = "OilPermissionWrite",
        ["x"] = "OilPermissionExecute",
      }, {
        __index = function() return "OilDir" end,
      })

      local type_hlgroups = setmetatable({
        ["-"] = "OilTypeFile",
        ["d"] = "OilTypeDir",
        ["f"] = "OilTypeFifo",
        ["l"] = "OilTypeLink",
        ["s"] = "OilTypeSocket",
      }, {
        __index = function() return "OilTypeFile" end,
      })

      require("oil").setup({
        trash = false,
        skip_confirm_for_simple_edits = true,
        trash_command = "trash-cli",
        prompt_save_on_select_new_entry = false,
        use_default_keymaps = false,
        is_always_hidden = function(name, _bufnr) return name == ".." end,
        -- columns = {
        --   "icon",
        --   -- "permissions",
        --   -- "size",
        --   -- "mtime",
        -- },

        columns = {
          {
            "type",
            icons = {
              directory = "d",
              fifo = "f",
              file = "-",
              link = "l",
              socket = "s",
            },
            highlight = function(type_str) return type_hlgroups[type_str] end,
          },
          {
            "permissions",
            highlight = function(permission_str)
              local hls = {}
              for i = 1, #permission_str do
                local char = permission_str:sub(i, i)
                table.insert(hls, { permission_hlgroups[char], i - 1, i })
              end
              return hls
            end,
          },
          { "size", highlight = "Special" },
          { "mtime", highlight = "Number" },
          {
            "icon",
            default_file = icon_file,
            directory = icon_dir,
            add_padding = false,
          },
        },
        view_options = {
          show_hidden = true,
        },
        keymaps = {
          ["g?"] = "actions.show_help",
          ["gs"] = "actions.change_sort",
          ["gx"] = "actions.open_external",
          ["g."] = "actions.toggle_hidden",
          ["gd"] = {
            desc = "Toggle detail view",
            callback = function()
              local oil = require("oil")
              local config = require("oil.config")
              if #config.columns == 1 then
                oil.set_columns({ "icon", "permissions", "size", "mtime" })
              else
                oil.set_columns({ "type", "icon" })
              end
            end,
          },
          ["<CR>"] = "actions.select",
          ["gp"] = function()
            local oil = require("oil")
            local entry = oil.get_cursor_entry()
            if entry["type"] == "file" then
              local dir = oil.get_current_dir()
              local fileName = entry["name"]
              local fullName = dir .. fileName

              require("mega.utils").preview_file(fullName)
            else
              return ""
            end
          end,
        },
      })
    end,
    keys = {
      {
        "<leader>ev",
        function()
          -- vim.cmd([[vertical rightbelow split|vertical resize 60]])
          vim.cmd([[vertical rightbelow split]])
          require("oil").open()
        end,
        desc = "oil: open (vsplit)",
      },
      {
        "<leader>ee",
        function() require("oil").open() end,
        desc = "oil: open (edit)",
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
    "kevinhwang91/nvim-hclipboard",
    event = "InsertCharPre",
    config = function() require("hclipboard").start() end,
  },
  {
    "altermo/ultimate-autopair.nvim",
    event = { "InsertEnter" },
    branch = "v0.6", --recomended as each new version will have breaking changes
    config = true,
  },
  { "tpope/vim-dispatch" },
}
