if vim.g.treesitter_branch == "main" then
  return {}
end

local function should_disable(lang, bufnr)
  local fname = vim.api.nvim_buf_get_name(bufnr)
  local disable_max_size = 2000000 -- 2MB
  local size = vim.fn.getfsize(vim.api.nvim_buf_get_name(bufnr or 0))
  -- size will be -2 if it doesn't fit into a number
  if size > disable_max_size or size == -2 then
    return true
  end

  -- for some reason, right now, these two files crash nvim
  if vim.tbl_contains({ "CLAUDE.md", "AGENTS.md" }, vim.fn.fnamemodify(fname, ":t")) then
    return true
  end

  if vim.tbl_contains({ "ruby" }, lang) then
    return true
  end

  return false
end

return {
  { "fei6409/log-highlight.nvim", event = "BufRead *.log", opts = {} },
  { "brianhuster/treesitter-endwise.nvim" },
  {
    "mtrajano/tssorter.nvim",
    version = "*",
    opts = {
      sortables = {
        elixir = {
          alias = {
            node = "call",
            ordinal = "arguments",
          },
          alias_group = {
            node = "alias",
          },
        },
      },
    },
    config = function()
      vim.api.nvim_create_user_command("Sort", function()
        require("tssorter").sort({})
      end, { nargs = 0 })
    end,
  },
  -- {
  --   "yorickpeterse/nvim-tree-pairs",
  --   main = "tree-pairs",
  --   opts = true,
  --   keys = {
  --     { "%", mode = { "n", "v", "o" } },
  --   },
  -- },
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "master",
    build = ":TSUpdate",
    event = { "LazyFile", "VeryLazy" },
    -- lazy = false,
    opts = {
      ensure_installed = vim.g.treesitter_ensure_installed,
      ignore_install = { "comment" },
      auto_install = true,
      sync_install = false,
      highlight = {
        enable = vim.g.vscode ~= 1,
        disable = should_disable,
        use_languagetree = true,
        -- Some languages depend on vim's regex highlighting system (such as Ruby) for indent rules.
        --  If you are experiencing weird indenting issues, add the language to
        --  the list of additional_vim_regex_highlighting and disabled languages for indent.
        additional_vim_regex_highlighting = {
          "ruby",
          "python",
          "vim",
        },
      },
      indent = {
        enable = true,
        disable = function(lang, bufnr)
          if vim.tbl_contains({ "lua" }, lang) then
            return true
          else
            return should_disable(lang, bufnr)
          end
        end,
      },
      endwise = { enable = true },
      matchup = {
        enable = true,
        include_match_words = true,
        disable = function(lang, bufnr)
          if vim.tbl_contains({ "ruby", "typescriptreact", "javascriptreact", "typescript", "javascript" }, lang) then
            return true
          else
            return should_disable(lang, bufnr)
          end
        end,
        disable_virtual_text = false,
      },
      incremental_selection = {
        enable = true,
        keymaps = {
          -- `vn` and `m` start flash.treesitter
          init_selection = "<cr>",
          node_incremental = "<cr>",
          node_decremental = "<bs>",
          scope_incremental = false,
        },
      },
    },
    init = function()
      -- vim.g.loaded_nvim_treesitter = 1
      -- FIX for `comments` parser https://github.com/stsewd/tree-sitter-comment/issues/22
      vim.api.nvim_create_autocmd("ColorScheme", {
        callback = function()
          vim.api.nvim_set_hl(0, "@lsp.type.comment", {})
        end,
      })
    end,
    config = function(_, opts)
      local ft_to_parser_aliases = {
        dotenv = "bash",
        gitcommit = "NeogitCommitMessage",
        javascriptreact = "jsx",
        chart = "json",
        json = "jsonc",
        keymap = "devicetree",
        kittybuf = "bash",
        livebook = "markdown",
        typescriptreact = "tsx",
        eelixir = "elixir",
        ex = "elixir",
        pl = "perl",
        bash = "sh", -- reversing these two from the treesitter source
        uxn = "uxntal",
        ts = "typescript",
        kbd = "lisp",
        zsh = "bash",
      }

      for ft, parser in pairs(ft_to_parser_aliases) do
        vim.treesitter.language.register(parser, ft)
      end

      require("nvim-treesitter.install").prefer_git = true
      require("nvim-treesitter.configs").setup(opts)
    end,
  },
  -- {
  --   "lewis6991/ts-install.nvim",
  --   build = ":TS update",
  --   config = function()
  --     require("ts-install").setup({
  --       auto_install = true,
  --       ignore_install = {
  --         "verilog",
  --         "tcl",
  --         "tmux",
  --       },
  --       parsers = {
  --         zsh = {
  --           install_info = {
  --             url = "https://github.com/tree-sitter-grammars/tree-sitter-zsh",
  --             branch = "master",
  --           },
  --         },
  --       },
  --     })
  --   end,
  -- },
  { "nvim-treesitter/nvim-treesitter-textobjects", cond = true, dependencies = { "nvim-treesitter/nvim-treesitter" } },
  -- { "RRethy/nvim-treesitter-textsubjects", cond = true, dependencies = { "nvim-treesitter/nvim-treesitter" } },
  -- {
  --   "mfussenegger/nvim-treehopper",
  --   event = "LazyFile",
  --   config = function() require("tsht").config.hint_keys = { "h", "j", "f", "d", "n", "v", "s", "l", "a" } end,
  -- },
  {
    "nvim-treesitter/nvim-treesitter-context",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    -- keys = {
    --   {
    --     "[[",
    --     function() require("treesitter-context").go_to_context(-vim.v.count1) end,
    --   },
    --   {
    --     "]]",
    --     function() require("treesitter-context").go_to_context(vim.v.count1) end,
    --   },
    -- },
    config = function()
      require("treesitter-context").setup({
        max_lines = 3,
        trim_scope = "outer",
        separator = "🮏", --, "TreesitterContextBorder", -- alts: 🮑🮏▁‾▁▁ ─ ▄─▁-_‾
        multiwindow = false,
      })
    end,
  },
  {
    "andymass/vim-matchup",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    event = { "BufReadPost", "BufNewFile" },
    init = function()
      vim.g.matchup_matchparen_nomode = "i"
      vim.g.matchup_delim_noskips = 1 -- recognize symbols within comments
      vim.g.matchup_matchparen_deferred_show_delay = 400
      vim.g.matchup_matchparen_deferred_hide_delay = 400
      vim.g.matchup_matchparen_offscreen = {}
      -- vim.g.matchup_matchparen_offscreen = {
      --   method = "popup",
      --   -- fullwidth = true,
      --   highlight = "TreesitterContext",
      --   border = "",
      -- }
      vim.g.matchup_matchparen_deferred = 1
      vim.g.matchup_matchparen_timeout = 300
      vim.g.matchup_matchparen_insert_timeout = 60
      vim.g.matchup_surround_enabled = 1 -- defaulted 0
      vim.g.matchup_motion_enabled = 1 -- defaulted 0
      vim.g.matchup_text_obj_enabled = 1
    end,
  },
  {
    "David-Kunz/treesitter-unit",
    keys = {
      { "iu", ':lua require"treesitter-unit".select()<CR>', mode = { "x" } },
      { "iu", ':<c-u>lua require"treesitter-unit".select()<CR>', mode = { "o" } },
      { "au", ':lua require"treesitter-unit".select(true)<CR>', mode = { "x" } },
      { "au", ':<c-u>lua require"treesitter-unit".select(true)<CR>', mode = { "o" } },
    },
    dependencies = { "nvim-treesitter/nvim-treesitter" },
  },
  -- {
  --   "yorickpeterse/nvim-tree-pairs",
  --   main = "tree-pairs",
  --   opts = {},
  --   keys = {
  --     { "%", mode = { "n", "v", "o" } },
  --   },
  -- },
  {
    "HiPhish/rainbow-delimiters.nvim",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    lazy = false,
    init = function()
      vim.g.rainbow_delimiters = {
        strategy = {
          [""] = "rainbow-delimiters.strategy.global",
          vim = "rainbow-delimiters.strategy.local",
        },
        query = {
          [""] = "rainbow-delimiters",
          lua = "rainbow-blocks",
          html = "rainbow-tags",
        },
        priority = {
          [""] = 110,
          lua = 210,
        },
        highlight = {
          "RainbowDelimiterRed",
          "RainbowDelimiterYellow",
          "RainbowDelimiterBlue",
          "RainbowDelimiterOrange",
          "RainbowDelimiterGreen",
          "RainbowDelimiterViolet",
          "RainbowDelimiterCyan",
        },
      }
    end,
  },
}
