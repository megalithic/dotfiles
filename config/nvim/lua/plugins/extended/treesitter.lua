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
        "make",
        "markdown",
        "markdown_inline",
        "nix",
        "org",
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
        "teal",
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
      }

      for ft, parser in pairs(ft_to_parser_aliases) do
        vim.treesitter.language.register(parser, ft)
      end

      -- local non_filetype_match_injection_language_aliases = {
      --   ex = "elixir",
      --   pl = "perl",
      --   bash = "sh", -- reversing these two from the treesitter source
      --   uxn = "uxntal",
      --   ts = "typescript",
      -- }

      -- -- extra fallbacks for icons that do not have a filetype entry in nvim-
      -- -- devicons
      -- local icon_fallbacks = {
      --   mermaid = "󰈺",
      --   plantuml = "",
      --   ebnf = "󱘎",
      --   chart = "",
      --   nroff = "",
      -- }

      -- local get_icon = nil

      -- local ft_conceal = function(match, _, source, pred, metadata)
      --   ---@cast pred integer[]
      --   local capture_id = pred[2]
      --   if not metadata[capture_id] then metadata[capture_id] = {} end

      --   local node = match[pred[2]]
      --   local node_text = vim.treesitter.get_node_text(node, source)

      --   local ft = vim.filetype.match({ filename = "a." .. node_text })
      --   node_text = ft or non_filetype_match_injection_language_aliases[node_text] or node_text

      --   if not get_icon then get_icon = require("nvim-web-devicons").get_icon_by_filetype end
      --   metadata.conceal = get_icon(node_text) or icon_fallbacks[node_text] or "󰡯"
      -- end

      -- local offset_first_n = function(match, _, _, pred, metadata)
      --   ---@cast pred integer[]
      --   local capture_id = pred[2]
      --   if not metadata[capture_id] then metadata[capture_id] = {} end

      --   local range = metadata[capture_id].range or { match[capture_id]:range() }
      --   local offset = pred[3] or 0

      --   range[4] = range[2] + offset
      --   metadata[capture_id].range = range
      -- end

      -- -- predicates for formatting of query files
      -- vim.treesitter.query.add_predicate("has-type?", function(match, _, _, pred)
      --   local node = match[pred[2]]
      --   if not node then return true end

      --   local types = { unpack(pred, 3) }
      --   local type = node:type()
      --   for _, value in pairs(types) do
      --     if value == type then return true end
      --   end
      --   return false
      -- end, true)

      -- vim.treesitter.query.add_predicate("is-start-of-line?", function(match, _, _, pred)
      --   local node = match[pred[2]]
      --   if not node then return true end
      --   local start_row, start_col = node:start()
      --   return vim.fn.indent(start_row + 1) == start_col
      -- end)

      -- vim.treesitter.query.add_directive("offset-first-n!", offset_first_n, true)
      -- vim.treesitter.query.add_directive("ft-conceal!", ft_conceal, true)

      require("nvim-treesitter.install").prefer_git = true
      require("nvim-treesitter.configs").setup(opts)
    end,
  },
  { "nvim-treesitter/nvim-treesitter-textobjects", cond = true, dependencies = { "nvim-treesitter/nvim-treesitter" } },
  { "RRethy/nvim-treesitter-textsubjects", cond = true, dependencies = { "nvim-treesitter/nvim-treesitter" } },
  { "nvim-treesitter/nvim-tree-docs", cond = true, dependencies = { "nvim-treesitter/nvim-treesitter" } },
  { "pricehiller/nvim-treesitter-endwise", branch = "fix/iter-matches", dependencies = { "nvim-treesitter/nvim-treesitter" } },
  {
    "nvim-treesitter/nvim-treesitter-context",
    -- event = { "BufReadPost" },
    keys = {
      {
        "[[",
        function() require("treesitter-context").go_to_context(-vim.v.count1) end,
      },
      {
        "]]",
        function() require("treesitter-context").go_to_context(vim.v.count1) end,
      },
    },
    opts = {
      -- enable = true,
      separator = "▁", --, "TreesitterContextBorder", -- alts: ‾▁▁ ─ ▄─▁-_‾
      -- min_window_height = 5,
      max_lines = 2, -- How many lines the window should span. Values <= 0 mean no limi
      trim_scope = "outer",
      patterns = { -- Match patterns for TS nodes. These get wrapped to match at word boundaries.
        -- For all filetypes
        -- Note that setting an entry here replaces all other patterns for this entry.
        -- By setting the 'default' entry below, you can control which nodes you want to
        -- appear in the context window.
        default = {
          "class",
          "function",
          "method",
          "for", -- These won't appear in the context
          "while",
          "if",
          "switch",
          "case",
          "element",
          "call",
        },
      },
      exact_patterns = {},
      zindex = 20, -- The Z-index of the context window
      mode = "cursor", -- Line used to calculate context. Choices: 'cursor', 'topline'
    },
    config = function(_, opts) require("treesitter-context").setup(opts) end,
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
      { "iu", ":lua require\"treesitter-unit\".select()<CR>", mode = { "x" } },
      { "iu", ":<c-u>lua require\"treesitter-unit\".select()<CR>", mode = { "o" } },
      { "au", ":lua require\"treesitter-unit\".select(true)<CR>", mode = { "x" } },
      { "au", ":<c-u>lua require\"treesitter-unit\".select(true)<CR>", mode = { "o" } },
    },
    dependencies = { "nvim-treesitter/nvim-treesitter" },
  },
  { "yorickpeterse/nvim-tree-pairs", dependencies = { "nvim-treesitter/nvim-treesitter" }, opts = {} },
  {
    "laytan/tailwind-sorter.nvim",
    cond = false,
    event = "VeryLazy",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-lua/plenary.nvim",
    },
    build = "cd formatter && npm i && npm run build",
    opts = {
      on_save_enabled = true,
      on_save_pattern = { "*.html", "*.js", "*.jsx", "*.tsx", "*.twig", "*.hbs", "*.php", "*.heex" }, -- The file patterns to watch and sort.
    },
  },
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
  {
    "mtrajano/tssorter.nvim",
    cmd = "TSSort",
    version = "*", -- latest stable version, use `main` to keep up with the latest changes
    opts = {
      sortables = {
        markdown = { -- filetype
          list = { -- sortable name
            node = "list_item", -- treesitter node to capture
            ordinal = "inline", -- OPTIONAL: nested node to do the sorting by. If this is not specified it will just sort based on
            -- node's text contents.

            -- It's possible that for the ordinal config above the node name could be one of multiple values. For example in markdown
            -- if you would like to sort by the task status this value could be `task_list_marker_unchecked` or `task_list_marker_checked`
            -- depending on that task status. In this case you could pass a table to ordinal and it would match based on the first one found.
            -- ordinal = {'task_list_marker_unchecked', 'task_list_marker_checked'}

            -- OPTIONAL: function that takes in two nodes and returns true when first node should come first
            -- these are just tsnodes so you have all that functionality available to you
            -- if ordinals are specified in the config above they will be included at the end
            order_by = function(node1, node2, ordinal1, ordinal2)
              if ordinal1 and ordinal2 then return ordinal1 < ordinal2 end

              -- TODO: add more helpers to make it easier to interact with these
              local line1 = require("tssorter.tshelper").get_text(node1)
              local line2 = require("tssorter.tshelper").get_text(node2)

              return line1 < line2
            end,
          },
        },
        lua = {
          list = {
            node = "field",
          },
          assign = {
            node = "assignment_statement", -- treesitter node to capture

            -- ordinal = 'inline', -- OPTIONAL: nested node to do the sorting by. If this is not specified it will just sort based on
            -- node's text contents.

            -- OPTIONAL: function that takes in two nodes and returns true when first node should come first
            -- these are just tsnodes so you have all that functionality available to you
            -- if ordinals are specified in the config above they will be included at the end
            order_by = function(node1, node2, ordinal1, ordinal2)
              if ordinal1 and ordinal2 then return ordinal1 < ordinal2 end
              local line1 = require("tssorter.tshelper").get_text(node1)
              local line2 = require("tssorter.tshelper").get_text(node2)
              print(line1, line2)
              return line1 < line2
            end,
          },
        },
      },
    },
  },
}
