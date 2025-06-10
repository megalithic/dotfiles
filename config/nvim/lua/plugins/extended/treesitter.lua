local function should_disable(lang, bufnr)
  local disable_max_size = 2000000 -- 2MB
  local size = vim.fn.getfsize(vim.api.nvim_buf_get_name(bufnr or 0))
  -- size will be -2 if it doesn't fit into a number
  if size > disable_max_size or size == -2 then return true end

  if vim.tbl_contains({ "ruby" }, lang) then return true end

  return false
end

return {
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    event = "VeryLazy",
    opts = {
      ensure_installed = {
        "bash",
        "c",
        "cpp",
        "css",
        "csv",
        "comment", -- too slow still.
        -- "dap_repl",
        "devicetree",
        "dockerfile",
        "diff",
        "elixir",
        "elm",
        "embedded_template",
        "erlang",
        "fish",
        "git_config",
        "git_rebase",
        "gitattributes",
        "gitcommit",
        "gitignore",
        "gleam",
        "go",
        "graphql",
        "heex",
        "html",
        "javascript",
        "jq",
        "jsdoc",
        "json",
        "jsonc",
        "json5",
        "lua",
        "luadoc",
        "luap",
        "kotlin",
        "make",
        "markdown",
        "markdown_inline",
        "nix",
        -- "org",
        "perl",
        "printf",
        "psv",
        "python",
        "query",
        "regex",
        "ruby",
        "rust",
        "scss",
        "scheme",
        "sql",
        "surface",
        -- "teal",
        "terraform",
        "tmux",
        "toml",
        "tsv",
        "tsx",
        "typescript",
        "vim",
        "vimdoc",
        "yaml",
      },
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
      -- use bash parser for zsh files
      vim.treesitter.language.register("bash", "zsh")
      vim.treesitter.language.register("markdown", "livebook")

      -- FIX for `comments` parser https://github.com/stsewd/tree-sitter-comment/issues/22
      vim.api.nvim_create_autocmd("ColorScheme", {
        callback = function() vim.api.nvim_set_hl(0, "@lsp.type.comment", {}) end,
      })
    end,
    config = function(_, opts)
      local ft_to_parser_aliases = {
        dotenv = "bash",
        gitcommit = "NeogitCommitMessage",
        javascriptreact = "jsx",
        json = "jsonc",
        keymap = "devicetree",
        kittybuf = "bash",
        typescriptreact = "tsx",
        zsh = "bash",
        eelixir = "elixir",
        ex = "elixir",
        pl = "perl",
        bash = "sh", -- reversing these two from the treesitter source
        uxn = "uxntal",
        ts = "typescript",
      }

      for ft, parser in pairs(ft_to_parser_aliases) do
        vim.treesitter.language.register(parser, ft)
      end
      -- additional language registration
      vim.treesitter.language.register("json", { "chart" })

      require("nvim-treesitter.install").prefer_git = true
      require("nvim-treesitter.configs").setup(opts)
    end,
  },
  { "nvim-treesitter/nvim-treesitter-textobjects", cond = true, dependencies = { "nvim-treesitter/nvim-treesitter" } },
  { "RRethy/nvim-treesitter-textsubjects", cond = true, dependencies = { "nvim-treesitter/nvim-treesitter" } },
  { "RRethy/nvim-treesitter-endwise", dependencies = { "nvim-treesitter/nvim-treesitter" } },
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
      { "iu", ":lua require\"treesitter-unit\".select()<CR>", mode = { "x" } },
      { "iu", ":<c-u>lua require\"treesitter-unit\".select()<CR>", mode = { "o" } },
      { "au", ":lua require\"treesitter-unit\".select(true)<CR>", mode = { "x" } },
      { "au", ":<c-u>lua require\"treesitter-unit\".select(true)<CR>", mode = { "o" } },
    },
    dependencies = { "nvim-treesitter/nvim-treesitter" },
  },
  { "yorickpeterse/nvim-tree-pairs", dependencies = { "nvim-treesitter/nvim-treesitter" }, opts = {} },
  -- {
  --   "laytan/tailwind-sorter.nvim",
  --   cond = false,
  --   event = "VeryLazy",
  --   dependencies = {
  --     "nvim-treesitter/nvim-treesitter",
  --     "nvim-lua/plenary.nvim",
  --   },
  --   build = "cd formatter && npm i && npm run build",
  --   opts = {
  --     on_save_enabled = true,
  --     on_save_pattern = { "*.html", "*.js", "*.jsx", "*.tsx", "*.twig", "*.hbs", "*.php", "*.heex" }, -- The file patterns to watch and sort.
  --   },
  -- },
  {
    "HiPhish/rainbow-delimiters.nvim",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    lazy = false,
    config = function()
      local rainbow = require("rainbow-delimiters")
      vim.g.rainbow_delimiters = {
        strategy = {
          [""] = rainbow.strategy["global"],
          vim = rainbow.strategy["local"],
        },
        query = {
          [""] = "rainbow-delimiters",
          lua = "rainbow-blocks",
          html = "rainbow-tags",
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
        blacklist = { "c", "cpp" },
      }
    end,
  },
}
