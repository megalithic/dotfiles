mega.treesitter = mega.treesitter or {
  install_attempted = {},
}

-- When visiting a file with a type we don't have a parser for, ask me if I want to install it.
function mega.treesitter.ensure_parser_installed()
  local WAIT_TIME = 6000
  local parsers = require("nvim-treesitter.parsers")
  local lang = parsers.get_buf_lang()
  local fmt = string.format
  if
    parsers.get_parser_configs()[lang]
    and not parsers.has_parser(lang)
    and not mega.treesitter.install_attempted[lang]
  then
    vim.schedule(function()
      vim.cmd("TSInstall " .. lang)
      mega.treesitter.install_attempted[lang] = true
      vim.notify(fmt("Installing Treesitter parser for %s", lang), "info", {
        title = "Nvim Treesitter",
        icon = mega.icons.misc.down,
        timeout = WAIT_TIME,
      })
    end)
  end
end

return function()
  local parsers = require("nvim-treesitter.parsers")
  local rainbow_enabled = { "dart" }

  mega.augroup("TSParserCheck", {
    {
      event = "FileType",
      desc = "Treesitter: install missing parsers",
      command = mega.treesitter.ensure_parser_installed,
    },
  })

  require("nvim-treesitter.configs").setup({
    ensure_installed = {
      "bash",
      "c",
      "comment",
      "cpp",
      "css",
      "dart",
      "dockerfile",
      "eex",
      "elixir",
      "elm",
      "erlang",
      "fish",
      "go",
      "graphql",
      "heex",
      "help",
      "html",
      "javascript",
      "jsdoc",
      "json",
      "json5",
      "jsonc",
      "lua",
      "lua",
      "make",
      "markdown",
      "nix",
      "perl",
      "python",
      "query",
      "regex",
      "ruby",
      "rust",
      "rust",
      "scheme",
      "scss",
      "surface",
      "toml",
      "tsx",
      "typescript",
      "vim",
      "yaml",
    },
    ignore_install = { "phpdoc" }, -- list of parser which cause issues or crashes

    highlight = {
      enable = true,
      -- Setting this to true will run `:h syntax` and tree-sitter at the same time.
      -- Set this to `true` if you depend on 'syntax' being enabled (like for indentation).
      -- Using this option may slow down your editor, and you may see some duplicate highlights.
      -- Instead of true it can also be a list of languages
      additional_vim_regex_highlighting = {},
      use_languagetree = true,
    },
    autotag = { enable = true },
    context_commentstring = {
      enable = true,
      enable_autocmd = false,
      config = {
        lua = "-- %s",
        fish = "# %s",
        toml = "# %s",
        yaml = "# %s",
        ["eruby.yaml"] = "# %s",
      },
    },
    matchup = { enable = true },
    incremental_selection = {
      enable = true,
      keymaps = {
        -- mappings for incremental selection (visual mappings)
        init_selection = "<leader>v", -- maps in normal mode to init the node/scope selection
        node_incremental = "<leader>v", -- increment to the upper named parent
        node_decremental = "<leader>V", -- decrement to the previous node
        scope_incremental = "grc", -- increment to the upper scope (as defined in locals.scm)
      },
    },
    indent = {
      enable = true,
      disable = { "yaml" },
    },
    textobjects = {
      lookahead = true,
      select = {
        enable = true,
        keymaps = {
          ["af"] = "@function.outer",
          ["if"] = "@function.inner",
          ["ac"] = "@class.outer",
          ["ic"] = "@class.inner",
          ["aC"] = "@conditional.outer",
          ["iC"] = "@conditional.inner",
          -- FIXME: this is unusable
          -- https://github.com/nvim-treesitter/nvim-treesitter-textobjects/issues/133 is resolved
          -- ['ax'] = '@comment.outer',
        },
      },
      swap = {
        enable = true,
        swap_next = {
          ["[w"] = "@parameter.inner",
        },
        swap_previous = {
          ["]w"] = "@parameter.inner",
        },
      },
      move = {
        enable = true,
        set_jumps = true, -- whether to set jumps in the jumplist
        goto_next_start = {
          ["]m"] = "@function.outer",
          ["]]"] = "@class.outer",
        },
        goto_previous_start = {
          ["[m"] = "@function.outer",
          ["[["] = "@class.outer",
        },
      },
      lsp_interop = {
        enable = true,
        border = mega.get_border(),
        peek_definition_code = {
          ["<leader>df"] = "@function.outer",
          ["<leader>dF"] = "@class.outer",
        },
      },
    },
    endwise = {
      enable = true,
    },
    rainbow = {
      enable = true,
      -- disable = vim.tbl_filter(function(p)
      --   local disable = true
      --   for _, lang in pairs(rainbow_enabled) do
      --     if p == lang then
      --       disable = false
      --     end
      --   end
      --   return disable
      -- end, parsers.available_parsers()),

      disable = { "json", "jsonc", "html" },
      extended_mode = true, -- Highlight also non-parentheses delimiters, boolean or table: lang -> boolean
      max_file_lines = nil, -- Do not enable for files with more than 1000 lines, int
      colors = {
        "royalblue3",
        "darkorange3",
        "seagreen3",
        "firebrick",
        "darkorchid3",
      },
    },
    autopairs = { enable = true },
    query_linter = {
      enable = true,
      use_virtual_text = true,
      lint_events = { "BufWrite", "CursorHold" },
    },
  })
end
