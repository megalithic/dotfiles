-- lua/plugins/treesitter.lua
-- Treesitter configuration (main branch)
-- Main branch: plugin handles parser installation, nvim handles highlighting via vim.treesitter.start()

-- Parsers to install
local parsers = {
  -- Core
  "c",
  "lua",
  "luadoc",
  "luap",
  "vim",
  "vimdoc",
  "query",
  "regex",
  "printf",

  -- Elixir
  "elixir",
  "heex",
  "eex",
  "surface",
  "erlang",

  -- Web
  "html",
  "css",
  "scss",
  "javascript",
  "typescript",
  "tsx",
  "jsdoc",
  "json",
  "json5",
  "svelte",
  "graphql",

  -- Config/Data
  "yaml",
  "toml",
  "xml",
  "bibtex",
  "markdown",
  "markdown_inline",
  "editorconfig",

  -- Shell
  "bash",
  "zsh",
  "fish",

  -- Other langs
  "devicetree",
  "nix",
  "python",
  "rust",
  "go",
  "ruby",
  "swift",
  "sql",

  -- Git
  "gitcommit",
  "git_rebase",
  "git_config",
  "gitignore",
  "gitattributes",
  "diff",

  -- Misc
  "dockerfile",
  "make",
  "comment",
  "just",
  "requirements",
}

-- Filetypes where treesitter indentation is broken/worse than default
vim.g.ts_ignore_indent = { "zsh", "bash", "markdown", "javascript" }

local syntax_on = {}
local lsp_semantic_token_on = {}

-- Filetypes to enable treesitter highlighting for
local function get_ts_filetypes()
  local filetypes = {}
  for _, parser in ipairs(parsers) do
    for _, ft in ipairs(vim.treesitter.language.get_filetypes(parser)) do
      filetypes[ft] = true
    end
  end
  return vim.tbl_keys(filetypes)
end

return {
  -- Endwise: auto-insert `end` after `do`, `def`, `if`, etc.
  -- Note: No setup() function - plugin auto-attaches via vim.on_key
  {
    "brianhuster/treesitter-endwise.nvim",
    lazy = false, -- Must not be lazy loaded per README
  },

  -- Core treesitter (main branch)
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,
    build = ":TSUpdate",
    init = function()
      -- Enable highlighting on FileType
      vim.api.nvim_create_autocmd("FileType", {
        pattern = get_ts_filetypes(),
        group = vim.api.nvim_create_augroup("mega.treesitter", { clear = true }),
        callback = function(args)
          local bufnr = args.buf
          local filetype = args.match

          local language = vim.treesitter.language.get_lang(filetype) or filetype
          if not vim.treesitter.language.add(language) then return end

          -- Skip special buffers
          if vim.bo[bufnr].buftype ~= "" then return end

          -- Skip large files (> 1MB)
          local size = vim.fn.getfsize(vim.api.nvim_buf_get_name(bufnr))
          if size > 1000000 or size == -2 then return end

          -- Enable treesitter highlighting
          -- pcall(vim.treesitter.start, bufnr)

          -- vim.wo.foldmethod = "expr"
          -- vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"

          -- Use treesitter for indentation (unless in ignore list)
          if not vim.list_contains(vim.g.ts_ignore_indent or {}, filetype) then
            vim.bo[bufnr].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
          end

          vim.treesitter.start(bufnr, language)

          local ft = vim.bo[bufnr].filetype
          if syntax_on[ft] then vim.bo[bufnr].syntax = "on" end

          if not lsp_semantic_token_on[ft] then vim.lsp.semantic_tokens.enable(false, { bufnr = bufnr }) end
        end,
      })

      -- require("nvim-treesitter").setup({
      --   auto_install = false,
      -- })

      -- Register filetype aliases
      vim.treesitter.language.register("bash", "dotenv")
      vim.treesitter.language.register("elixir", "eelixir")
      vim.treesitter.language.register("markdown", "mdx")

      -- Install parsers (async) - main branch API
      local install = require("nvim-treesitter.install")
      install.install(parsers)
    end,
  },

  -- Treesitter context (sticky function headers)
  -- {
  --   "nvim-treesitter/nvim-treesitter-context",
  --   event = "VeryLazy",
  --   opts = {
  --     max_lines = 3,
  --     trim_scope = "outer",
  --     separator = "─",
  --     multiwindow = false,
  --   },
  -- },
  {
    "nvim-treesitter/nvim-treesitter-context",
    event = { "BufRead", "BufNewFile" },
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    opts = {
      enable = true,
      max_lines = 3,
      min_window_height = 30,
      line_numbers = true,
      multiline_threshold = 3,
      trim_scope = "outer",
      mode = "cursor",
      separator = nil,
      zindex = 20,
      on_attach = nil,
    },
  },

  {
    "windwp/nvim-ts-autotag",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    event = { "BufReadPre", "BufNewFile", "InsertEnter" },
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
  --   "Wansmer/treesj",
  --   keys = {
  --     {
  --       "<leader>s",
  --       mode = { "n" },
  --       function() require("treesj").toggle() end,
  --       desc = "Toggle treesj split join",
  --     },
  --   },
  --   opts = {
  --     use_default_keymaps = false,
  --   },
  -- },

  {
    "mtrajano/tssorter.nvim",
    cmd = "TSSort",
    ---@module "tssorter"
    ---@type TssorterOpts
    opts = {},
  },

  -- Textobjects (main branch)
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    branch = "main",
    event = "VeryLazy",
    config = function()
      -- Main branch: no setup() needed, configure via vim.g or just use keymaps directly

      -- Function textobjects
      vim.keymap.set(
        { "x", "o" },
        "af",
        function() require("nvim-treesitter-textobjects.select").select_textobject("@function.outer", "textobjects") end,
        { desc = "Select outer function" }
      )
      vim.keymap.set(
        { "x", "o" },
        "if",
        function() require("nvim-treesitter-textobjects.select").select_textobject("@function.inner", "textobjects") end,
        { desc = "Select inner function" }
      )

      -- Class textobjects
      vim.keymap.set(
        { "x", "o" },
        "ac",
        function() require("nvim-treesitter-textobjects.select").select_textobject("@class.outer", "textobjects") end,
        { desc = "Select outer class" }
      )
      vim.keymap.set(
        { "x", "o" },
        "ic",
        function() require("nvim-treesitter-textobjects.select").select_textobject("@class.inner", "textobjects") end,
        { desc = "Select inner class" }
      )

      -- Parameter/argument textobjects
      vim.keymap.set(
        { "x", "o" },
        "aa",
        function() require("nvim-treesitter-textobjects.select").select_textobject("@parameter.outer", "textobjects") end,
        { desc = "Select outer argument" }
      )
      vim.keymap.set(
        { "x", "o" },
        "ia",
        function() require("nvim-treesitter-textobjects.select").select_textobject("@parameter.inner", "textobjects") end,
        { desc = "Select inner argument" }
      )

      -- Block textobjects
      vim.keymap.set(
        { "x", "o" },
        "ab",
        function() require("nvim-treesitter-textobjects.select").select_textobject("@block.outer", "textobjects") end,
        { desc = "Select outer block" }
      )
      vim.keymap.set(
        { "x", "o" },
        "ib",
        function() require("nvim-treesitter-textobjects.select").select_textobject("@block.inner", "textobjects") end,
        { desc = "Select inner block" }
      )

      -- Comment textobjects
      vim.keymap.set(
        { "x", "o" },
        "a/",
        function() require("nvim-treesitter-textobjects.select").select_textobject("@comment.outer", "textobjects") end,
        { desc = "Select outer comment" }
      )

      -- Move to next/prev function
      vim.keymap.set(
        { "n", "x", "o" },
        "]f",
        function() require("nvim-treesitter-textobjects.move").goto_next_start("@function.outer", "textobjects") end,
        { desc = "Next function start" }
      )
      vim.keymap.set(
        { "n", "x", "o" },
        "]F",
        function() require("nvim-treesitter-textobjects.move").goto_next_end("@function.outer", "textobjects") end,
        { desc = "Next function end" }
      )
      vim.keymap.set(
        { "n", "x", "o" },
        "[f",
        function() require("nvim-treesitter-textobjects.move").goto_previous_start("@function.outer", "textobjects") end,
        { desc = "Previous function start" }
      )
      vim.keymap.set(
        { "n", "x", "o" },
        "[F",
        function() require("nvim-treesitter-textobjects.move").goto_previous_end("@function.outer", "textobjects") end,
        { desc = "Previous function end" }
      )

      -- Move to next/prev class
      vim.keymap.set(
        { "n", "x", "o" },
        "]c",
        function() require("nvim-treesitter-textobjects.move").goto_next_start("@class.outer", "textobjects") end,
        { desc = "Next class start" }
      )
      vim.keymap.set(
        { "n", "x", "o" },
        "[c",
        function() require("nvim-treesitter-textobjects.move").goto_previous_start("@class.outer", "textobjects") end,
        { desc = "Previous class start" }
      )
    end,
  },

  -- Treesitter unit (select by treesitter node)
  {
    "David-Kunz/treesitter-unit",
    keys = {
      { "iu", ':lua require"treesitter-unit".select()<CR>', mode = { "x" }, desc = "Select unit" },
      { "iu", ':<c-u>lua require"treesitter-unit".select()<CR>', mode = { "o" }, desc = "Select unit" },
      { "au", ':lua require"treesitter-unit".select(true)<CR>', mode = { "x" }, desc = "Select unit (outer)" },
      { "au", ':<c-u>lua require"treesitter-unit".select(true)<CR>', mode = { "o" }, desc = "Select unit (outer)" },
    },
  },

  -- Rainbow delimiters
  {
    url = "https://gitlab.com/HiPhish/rainbow-delimiters.nvim",
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      local rd = require("rainbow-delimiters")
      vim.g.rainbow_delimiters = {
        strategy = {
          [""] = rd.strategy.global,
          vim = rd.strategy["local"],
          -- Disable for filetypes without rainbow-delimiters queries
          -- nix = rd.strategy.noop,
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
        -- Skip buffers without treesitter parsers (floating windows, popups, etc.)
        condition = function(bufnr)
          -- Skip non-normal buffers (floating windows, popups, etc.)
          local buftype = vim.bo[bufnr].buftype
          if buftype ~= "" then return false end

          -- Skip if no filetype
          local filetype = vim.bo[bufnr].filetype
          if filetype == "" then return false end

          -- Check if treesitter parser exists for this buffer
          local ok, parser = pcall(vim.treesitter.get_parser, bufnr)
          return ok and parser ~= nil
        end,
      }
    end,
  },

  { "yorickpeterse/nvim-tree-pairs", event = "VeryLazy", opts = {} },
  {
    "andymass/vim-matchup",
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
}
