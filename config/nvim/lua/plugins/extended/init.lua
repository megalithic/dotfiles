local fmt = string.format
local map = vim.keymap.set
local SETTINGS = require("mega.settings")
local icons = SETTINGS.icons

return {
  {
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
    { "ConradIrwin/vim-bracketed-paste" }, -- FIXME: delete?
    { "ryvnf/readline.vim", event = "CmdlineEnter" },
    -- { "brenoprata10/nvim-highlight-colors", opts = { enable_tailwind = true } },
    {
      "NvChad/nvim-colorizer.lua",
      event = { "BufReadPre" },
      config = function() require("colorizer").setup(SETTINGS.colorizer) end,
    },
    -- "gc" to comment visual regions/lines
    { "numToStr/Comment.nvim", opts = {} },
    {
      "folke/trouble.nvim",
      cmd = { "TroubleToggle", "Trouble" },
      opts = {
        auto_open = false,
        use_diagnostic_signs = true, -- en
      },
    },
    {
      "folke/which-key.nvim",
      version = "2.1.0",
      pin = true,
      event = "VeryLazy",
      init = function()
        vim.o.timeout = true
        vim.o.timeoutlen = 300
      end,
      opts = {
        -- preset = "modern",
        plugins = {
          marks = true, -- shows a list of your marks on ' and `
          registers = true, -- shows your registers on " in NORMAL or <C-r> in INSERT mode
          -- the presets plugin, adds help for a bunch of default keybindings in Neovim
          -- No actual key bindings are created
          spelling = {
            enabled = true, -- enabling this will show WhichKey when pressing z= to select spelling suggestions
            suggestions = 20, -- how many suggestions should be shown in the list?
          },
          presets = {
            operators = false, -- adds help for operators like d, y, ... and registers them for motion / text object completion
            motions = false, -- adds help for motions
            text_objects = true, -- help for text objects triggered after entering an operator
            windows = false, -- default bindings on <c-w>
            nav = true, -- misc bindings to work with windows
            z = true, -- bindings for folds, spelling and others prefixed with z
            g = true, -- bindings for prefixed with g
          },
        },
        -- add operators that will trigger motion and text object completion
        -- to enable all native operators, set the preset / operators plugin above
        operators = { gc = "Comments" },
        key_labels = {
          -- override the label used to display some keys. It doesn't effect WK in any other way.
          -- For example:
          ["<space>"] = "SPC",
          ["<cr>"] = "RET",
          ["<tab>"] = "TAB",
        },
        icons = {
          breadcrumb = "»", -- symbol used in the command line area that shows your active key combo
          separator = "➜", -- symbol used between a key and it's label
          group = "+", -- symbol prepended to a group
        },
        window = {
          border = "none", -- none, single, double, shadow
          position = "bottom", -- bottom, top
          margin = { 1, 0, 1, 0 }, -- extra window margin [top, right, bottom, left]
          padding = { 1, 1, 1, 1 }, -- extra window padding [top, right, bottom, left]
        },
        -- window = { border = mega.get_border() },
        -- layout = { align = "center" },
        hidden = { ":w", "<silent>", "<cmd>", "<Cmd>", "<CR>", "call", "lua", "^:", "^ " }, -- hide mapping boilerplate
        show_help = true, -- show help message on the command line when the popup is visible
        triggers = "auto", -- automatically setup triggers
        -- triggers = {"<leader>"} -- or specifiy a list manually
        triggers_blacklist = {
          n = { ":" },
          c = { ":" },
        },
      },
      config = function(_, opts) -- This is the function that runs, AFTER loading
        local wk = require("which-key")
        wk.setup(opts)
        -- wk.add({
        --   { "<leader>c", group = "[c]ode" },
        --   { "<leader>d", group = "[d]ocument" },
        --   { "<leader>e", group = "[e]dit files" },
        --   { "<leader>e", group = "[e]dit files" },
        -- })

        -- Document existing key chains
        wk.register({
          ["<leader>c"] = { name = "[c]ode", _ = "which_key_ignore" },
          ["<leader>d"] = { name = "[d]ocument", _ = "which_key_ignore" },
          ["<leader>e"] = {
            name = "+edit files",
            r = { function() require("mega.utils").lsp.rename_file() end, "rename file (lsp) to <input>" },
            s = { [[<cmd>SaveAsFile<cr>]], "save file as <input>" },
            e = "oil: open (edit)", -- NOTE: change in plugins/extended/oil.lua
            v = "oil: open (vsplit)", -- NOTE: change in plugins/extended/oil.lua
            d = {
              function()
                if vim.fn.confirm("Duplicate file?", "&Yes\n&No", 2, "Question") == 1 then vim.cmd("Duplicate") end
              end,
              "duplicate file?",
            },
            D = {
              function()
                if vim.fn.confirm("Delete file?", "&Yes\n&No", 2, "Question") == 1 then vim.cmd("Delete!") end
              end,
              "delete file?",
            },
            yp = {
              function()
                vim.cmd([[let @+ = expand("%")]])
                vim.notify(fmt("yanked %s to clipboard", vim.fn.expand("%")))
              end,
              "yank path to clipboard",
            },
          },

          ["<leader>f"] = {
            name = "[f]ind (" .. vim.g.picker .. ")",
            _ = "which_key_ignore",
          },
          ["<leader>l"] = {
            name = "[l]sp",
            c = { name = "[c]ode [a]ctions" },
            i = { name = "[i]nfo" },
            s = { name = "[s]ymbols" },
            -- w = { name = "[w]orkspace" },
            _ = "which_key_ignore",
          },
          ["<leader>g"] = { name = "[g]it", _ = "which_key_ignore" },
          ["<leader>n"] = { name = "[n]otes", _ = "which_key_ignore" },
          ["<leader>p"] = { name = "[p]lugins", _ = "which_key_ignore" },
          ["<leader>r"] = { name = "[r]ename", _ = "which_key_ignore" },
          ["<leader>t"] = { name = "[t]erminal", _ = "which_key_ignore" },
          ["<leader>z"] = { name = "[z]k", _ = "which_key_ignore" },
          ["<localleader>d"] = { name = "[d]ebug", _ = "which_key_ignore" },
          ["<localleader>g"] = { name = "[g]it", _ = "which_key_ignore" },
          ["<localleader>h"] = { name = "[h]unk", _ = "which_key_ignore" },
          ["<localleader>r"] = { name = "[r]epl", _ = "which_key_ignore" },
          ["<localleader>t"] = { name = "[t]est", _ = "which_key_ignore" },
          ["<localleader>s"] = { name = "[s]pell", _ = "which_key_ignore" },
        })
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
        { "<leader><leader>h", function() require("smart-splits").swap_buf_left() end, desc = "swap left" },
        { "<leader><leader>j", function() require("smart-splits").swap_buf_down() end, desc = "swap down" },
        { "<leader><leader>k", function() require("smart-splits").swap_buf_up() end, desc = "swap up" },
        { "<leader><leader>l", function() require("smart-splits").swap_buf_right() end, desc = "swap right" },
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
        enable_close_on_slash = false, -- Auto close on trailing </
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

  { -- lua alternative to the official codeium.vim plugin https://github.com/Exafunction/codeium.vim
    "monkoose/neocodeium",
    event = "InsertEnter",
    cmd = "NeoCodeium",
    opts = {
      filetypes = {
        DressingInput = false,
        TelescopePrompt = false,
        noice = false, -- sometimes triggered in error-buffers
        text = false, -- `pass` passwords editing filetype is plaintext
        ["rip-substitute"] = true,
      },
      silent = true,
      show_label = false, -- signcolumn label for number of suggestions
    },
    init = function()
      -- disable while recording
      vim.api.nvim_create_autocmd("RecordingEnter", { command = "NeoCodeium disable" })
      vim.api.nvim_create_autocmd("RecordingLeave", { command = "NeoCodeium enable" })
    end,
    keys = {
			-- stylua: ignore start
			{ "<C-y>", function() require("neocodeium").accept() end, mode = "i", desc = "󰚩 Accept full suggestion" },
			{ "<C-t>", function() require("neocodeium").accept_line() end, mode = "i", desc = "󰚩 Accept line" },
			-- { "<C-w>", function() require("neocodeium").accept_word() end, mode = "i", desc = "󰚩 Accept word" },
			{ "<C-d>", function() require("neocodeium").cycle(1) end, mode = "i", desc = "󰚩 Next suggestion" },
      -- stylua: ignore end
      {
        "<leader>oa",
        function()
          vim.cmd.NeoCodeium("toggle")
          local on = require("neocodeium.options").options.enabled
          require("config.utils").notify("NeoCodeium", on and "enabled" or "disabled", "info")
        end,
        desc = "󰚩 NeoCodeium Suggestions",
      },
    },
  },
}
