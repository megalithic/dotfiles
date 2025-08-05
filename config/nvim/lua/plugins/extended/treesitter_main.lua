local SETTINGS = require("config.options")

if SETTINGS.ts_branch == "master" then return {} end

local include_surrounding_whitespace = {
  ["@function.outer"] = true,
  ["@class.outer"] = true,
  ["@parameter.outer"] = true,
}

local function should_disable(lang, bufnr)
  local disable_max_size = 2000000 -- 2MB
  local size = vim.fn.getfsize(vim.api.nvim_buf_get_name(bufnr or 0))
  -- size will be -2 if it doesn't fit into a number
  if size > disable_max_size or size == -2 then return true end

  if vim.tbl_contains({ "ruby" }, lang) then return true end

  return false
end

return {
  -- { "brianhuster/treesitter-endwise.nvim" },
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,
    build = { function() require("nvim-treesitter").install(require("config.options").ts_ensure_installed) end, ":TSUpdate" },
    config = function(_, opts)
      require("nvim-treesitter").setup()

      local installed = require("nvim-treesitter.config").get_installed("parsers")
      local not_installed = vim.tbl_filter(function(parser) return not vim.tbl_contains(installed, parser) end, require("config.options").ts_ensure_installed)
      if #not_installed > 0 then require("nvim-treesitter").install(not_installed) end

      local syntax_on = {
        asciidoc = true,
        elixir = true,
        php = true,
      }

      local group = vim.api.nvim_create_augroup("mega-treesitter", { clear = true })
      -- Augroup("mega_treesitter", {
      --   {
      --     -- Update the cursor column to match current window size
      --     event = { "FileType" }, -- BufWinEnter instead of WinEnter?
      --     command = function(args)
      --       local bufnr = args.buf
      --       local filetype = vim.api.nvim_get_option_value("filetype", { buf = bufnr })
      --       if filetype == "" then return end -- Stops if no filetype is detected.

      --       local ok, parser = pcall(vim.treesitter.get_parser, bufnr)
      --       if not ok or not parser then
      --         vim.notify(string.format("Missing ts parser %s for bufnr %d", parser, bufnr), L.WARN)
      --         return
      --       end

      --       if vim.treesitter.language.add(filetype) then
      --         vim.treesitter.start(bufnr, filetype)
      --       else
      --         vim.notify(string.format("Missing ts parser for %s", filetype), L.WARN)
      --       end

      --       local ft = vim.bo[bufnr].filetype
      --       if syntax_on[ft] then vim.bo[bufnr].syntax = "on" end

      --       vim.schedule(function()
      --         -- vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
      --         vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
      --       end)
      --     end,
      --   },
      --   {
      --     event = { "User" },
      --     pattern = "TSUpdate",
      --     command = function(_args)
      --       -- local parsers = require("nvim-treesitter.parsers")

      --       -- parsers.lua = {
      --       --   tier = 0,
      --       --
      --       --   ---@diagnostic disable-next-line: missing-fields
      --       --   install_info = {
      --       --     path = "~/plugins/tree-sitter-lua",
      --       --     files = { "src/parser.c", "src/scanner.c" },
      --       --   },
      --       -- }
      --     end,
      --   },
      -- })

      vim.api.nvim_create_autocmd("FileType", {
        group = group,
        callback = function(args)
          local bufnr = args.buf
          local filetype = vim.api.nvim_get_option_value("filetype", { buf = bufnr })
          if filetype == "" then return end -- Stops if no filetype is detected.

          local ok, parser = pcall(vim.treesitter.get_parser, bufnr)
          if not ok or not parser then
            -- vim.notify(string.format("Missing ts parser %s for bufnr %d", parser, bufnr), L.WARN)
            return
          end

          pcall(vim.treesitter.start)
          -- if vim.treesitter.language.add(filetype) then
          --   vim.treesitter.start(bufnr, filetype)
          -- else
          --   vim.notify(string.format("Missing ts parser for %s", filetype), L.WARN)
          -- end

          local ft = vim.bo[bufnr].filetype
          if syntax_on[ft] then vim.bo[bufnr].syntax = "on" end

          vim.schedule(function()
            -- vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
            vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
          end)
        end,
      })

      vim.api.nvim_create_autocmd("User", {
        group = group,
        pattern = "TSUpdate",
        callback = function()
          local parsers = require("nvim-treesitter.parsers")

          -- parsers.lua = {
          --   tier = 0,
          --
          --   ---@diagnostic disable-next-line: missing-fields
          --   install_info = {
          --     path = "~/plugins/tree-sitter-lua",
          --     files = { "src/parser.c", "src/scanner.c" },
          --   },
          -- }
        end,
      })
      -- -- Activates highlights for supported filetypes or
      -- -- manually with `:lua vim.treesitter.start()`
      -- -- - `:h vim.treesitter.start()`, `:h vim.treesitter.language.add()`
      -- vim.api.nvim_create_autocmd("FileType", {
      --   callback = function(args)
      --     local buf = args.buf
      --     local filetype = vim.api.nvim_get_option_value("filetype", { buf = buf })
      --     if filetype == "" then return end -- Stops if no filetype is detected.

      --     -- Checks if a parser is available for the filetype.
      --     if vim.treesitter.language.add(filetype) then
      --       -- Activates the parser for the current buffer.
      --       vim.treesitter.start(buf, filetype)
      --       -- Sets other options for the current buffer.
      --       if filetype == "asciidoc" then
      --         vim.bo[buf].syntax = "on" -- Only for currently in tree-sitter-asciidoc unsupported inline syntax.
      --       end
      --     end

      --     vim.schedule(function()
      --       -- vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
      --       vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
      --     end)
      --   end,
      -- })

      -- vim.api.nvim_create_autocmd("User", {
      --   pattern = "TSUpdate",
      --   callback = function()
      --     require("nvim-treesitter").install(require("config.options").ts_ensure_installed)

      --     -- FOR INSTALLING CUSTOM PARSERS
      --     -- require('nvim-treesitter.parsers').<lang> = {
      --     -- ---@diagnostic disable-next-line missing-fields
      --     --   install_info = {
      --     --     url = 'https://github.com/<user>/tree-sitter-<lang>', -- git repo
      --     --     -- path = '~/projects/tree-sitter-<lang>', -- local path
      --     --     revision = '<rev-id>',
      --     --   },
      --     --   -- WARN: `tier = 2` is important for custom parsers
      --     --   -- `norm_languages()` in config.lua checks vor `tier < 4`
      --     --   -- see: https://github.com/nvim-treesitter/nvim-treesitter/blob/0140c29b31d56be040697176ae809ba0c709da02/lua/nvim-treesitter/config.lua#L95
      --     --   -- tiers: 1: stable, 2: unstable, 3: unmaintained, 4 or nil: unsupported
      --     --   --        supported = tier < 4
      --     --   tier = 2,
      --     -- }
      --   end,
      -- })

      local map = vim.keymap.set

      -- Globally map Tree-sitter text object binds
      local function textobj_map(key, query)
        local outer = "@" .. query .. ".outer"
        local inner = "@" .. query .. ".inner"
        local opts = {
          desc = "Selection for " .. query .. " text objects",
          silent = true,
        }
        map("x", "i" .. key, function() require("nvim-treesitter-textobjects.select").select_textobject(inner, "textobjects") end, opts)
        map("x", "a" .. key, function() require("nvim-treesitter-textobjects.select").select_textobject(outer, "textobjects") end, opts)
        map("o", "i" .. key, function() require("nvim-treesitter-textobjects.select").select_textobject(inner, "textobjects") end, opts)
        map("o", "a" .. key, function() require("nvim-treesitter-textobjects.select").select_textobject(outer, "textobjexts") end, opts)
      end

      textobj_map("$", "math")
      textobj_map("m", "math")
      textobj_map("f", "call")
      textobj_map("F", "function")
      textobj_map("L", "loop")
      textobj_map("c", "conditional")
      textobj_map("C", "class")
      textobj_map("/", "comment")
      textobj_map("a", "parameter") -- also applies to arguments and array elements
      textobj_map("r", "return")

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
        zsh = "bash",
      }

      for ft, parser in pairs(ft_to_parser_aliases) do
        vim.treesitter.language.register(parser, ft)
      end

      -- extra icons that do not have a filetype entry in
      -- mini.icons
      local icon_overrides = {
        plantuml = "",
        ebnf = "󱘎",
        chart = "",
        nroff = "󰗚",
      }

      local get_icon = nil

      local ft_conceal = function(match, _, source, pred, metadata)
        ---@cast pred integer[]
        local capture_id = pred[2]
        if not metadata[capture_id] then metadata[capture_id] = {} end

        local node = match[pred[2]]
        local node_text = vim.treesitter.get_node_text(node, source)

        local ft = vim.filetype.match({ filename = "a." .. node_text })
        node_text = ft or non_filetype_match_injection_language_aliases[node_text] or node_text

        if not get_icon then get_icon = require("mini.icons").get end
        metadata.conceal = icon_overrides[node_text] or get_icon("filetype", node_text) or "󰡯"
      end

      vim.treesitter.query.add_directive("ft-conceal!", ft_conceal, { force = true })

      -- require("nvim-treesitter.install").prefer_git = true
      -- require("nvim-treesitter.configs").setup(opts)
    end,
  },

  {
    "yorickpeterse/nvim-tree-pairs",
    main = "tree-pairs",
    opts = true,
    keys = {
      { "%", mode = { "n", "v", "o" } },
    },
  },
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    branch = "main",
    event = { "LazyFile" },
    opts = {
      select = {
        include_surrounding_whitespace = function(capture) return include_surrounding_whitespace[capture.query_string] or false end,
      },
    },
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
  -- {
  --   "nvim-treesitter/nvim-treesitter-textobjects",
  --   branch = "main",
  --   event = { "LazyFile" },
  --   opts = {
  --     select = {
  --       include_surrounding_whitespace = function(capture) return include_surrounding_whitespace[capture.query_string] or false end,
  --     },
  --   },
  -- },
  -- { "RRethy/nvim-treesitter-textsubjects", cond = true, dependencies = { "nvim-treesitter/nvim-treesitter" } },
  -- {
  --   "mfussenegger/nvim-treehopper",
  --   event = "LazyFile",
  --   config = function() require("tsht").config.hint_keys = { "h", "j", "f", "d", "n", "v", "s", "l", "a" } end,
  -- },
  -- { "RRethy/nvim-treesitter-endwise", dependencies = { "nvim-treesitter/nvim-treesitter" } },
  -- {
  --   "nvim-treesitter/nvim-treesitter-context",
  --   dependencies = { "nvim-treesitter/nvim-treesitter" },
  --   -- keys = {
  --   --   {
  --   --     "[[",
  --   --     function() require("treesitter-context").go_to_context(-vim.v.count1) end,
  --   --   },
  --   --   {
  --   --     "]]",
  --   --     function() require("treesitter-context").go_to_context(vim.v.count1) end,
  --   --   },
  --   -- },
  --   config = function()
  --     require("treesitter-context").setup({
  --       max_lines = 3,
  --       trim_scope = "outer",
  --       separator = "🮏", --, "TreesitterContextBorder", -- alts: 🮑🮏▁‾▁▁ ─ ▄─▁-_‾
  --       multiwindow = false,
  --     })
  --   end,
  -- },
  {
    "andymass/vim-matchup",
    -- dependencies = { "nvim-treesitter/nvim-treesitter" },
    lazy = false,
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
  -- {
  --   "David-Kunz/treesitter-unit",
  --   keys = {
  --     { "iu", ":lua require\"treesitter-unit\".select()<CR>", mode = { "x" } },
  --     { "iu", ":<c-u>lua require\"treesitter-unit\".select()<CR>", mode = { "o" } },
  --     { "au", ":lua require\"treesitter-unit\".select(true)<CR>", mode = { "x" } },
  --     { "au", ":<c-u>lua require\"treesitter-unit\".select(true)<CR>", mode = { "o" } },
  --   },
  --   dependencies = { "nvim-treesitter/nvim-treesitter" },
  -- },
  -- { "yorickpeterse/nvim-tree-pairs", dependencies = { "nvim-treesitter/nvim-treesitter" }, opts = {} },
  {
    "laytan/tailwind-sorter.nvim",
    cond = false,
    event = "VeryLazy",
    dependencies = {
      -- "nvim-treesitter/nvim-treesitter",
      "nvim-lua/plenary.nvim",
    },
    build = "cd formatter && npm i && npm run build",
    opts = {
      on_save_enabled = true,
      on_save_pattern = { "*.html", "*.js", "*.jsx", "*.tsx", "*.twig", "*.hbs", "*.php", "*.heex", ".ex" }, -- The file patterns to watch and sort.
    },
  },
  -- {
  --   "HiPhish/rainbow-delimiters.nvim",
  --   dependencies = { "nvim-treesitter/nvim-treesitter" },
  --   lazy = false,
  --   config = function()
  --     local rainbow = require("rainbow-delimiters")
  --     vim.g.rainbow_delimiters = {
  --       strategy = {
  --         [""] = rainbow.strategy["global"],
  --         vim = rainbow.strategy["local"],
  --       },
  --       query = {
  --         [""] = "rainbow-delimiters",
  --         lua = "rainbow-blocks",
  --         html = "rainbow-tags",
  --       },
  --       highlight = {
  --         "RainbowDelimiterRed",
  --         "RainbowDelimiterYellow",
  --         "RainbowDelimiterBlue",
  --         "RainbowDelimiterOrange",
  --         "RainbowDelimiterGreen",
  --         "RainbowDelimiterViolet",
  --         "RainbowDelimiterCyan",
  --       },
  --       blacklist = { "c", "cpp" },
  --     }
  --   end,
  -- },
}
