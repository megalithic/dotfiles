local ts_ok, _ = pcall(require, "nvim-treesitter")
if not ts_ok then
  return
end

vim.opt.indentexpr = "nvim_treesitter#indent()"

local ft_to_parser = require("nvim-treesitter.parsers").filetype_to_parsername
ft_to_parser.json = "jsonc"
ft_to_parser.keymap = "devicetree"

mega.treesitter = mega.treesitter or {
  install_attempted = {},
}

-- When visiting a file with a type we don't have a parser for, ask me if I want to install it.
function mega.treesitter.ensure_parser_installed()
  local WAIT_TIME = 6000
  local ignored_langs = {}
  local parsers = require("nvim-treesitter.parsers")
  local lang = parsers.get_buf_lang()
  local fmt = string.format
  if
    parsers.get_parser_configs()[lang]
    and not parsers.has_parser(lang)
    and not mega.treesitter.install_attempted[lang]
  then
    vim.schedule(function()
      if vim.tbl_contains(ignored_langs, lang) then
        return
      end
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
    "cpp",
    "css",
    "comment",
    "devicetree",
    "dockerfile",
    "eex",
    "elixir",
    "elm",
    "erlang",
    "fish",
    "go",
    "graphql",
    "html",
    "heex",
    "help",
    "javascript",
    "markdown",
    "markdown_inline",
    "jsdoc",
    "json",
    "jsonc",
    "json5",
    "lua",
    "make",
    "nix",
    "perl",
    "python",
    "query",
    "regex",
    "ruby",
    "rust",
    "scss",
    "scheme",
    "surface",
    "toml",
    "tsx",
    "typescript",
    "vim",
    "yaml",
  },
  highlight = {
    enable = true,
    -- Setting this to true will run `:h syntax` and tree-sitter at the same time.
    -- Set this to `true` if you depend on 'syntax' being enabled (like for indentation).
    -- Using this option may slow down your editor, and you may see some duplicate highlights.
    -- Instead of true it can also be a list of languages
    additional_vim_regex_highlighting = {},
    use_languagetree = true,
  },
  indent = { enable = true },
  autotag = { enable = true },
  tree_docs = {
    enable = true,
    keymaps = {
      doc_node_at_cursor = "gdd",
      doc_all_in_range = "gdd",
      edit_doc_at_cursor = "gde",
    },
  },
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
  rainbow = {
    enable = true,
    disable = { "json", "jsonc", "html" },
    extended_mode = true, -- Highlight also non-parentheses delimiters, boolean or table: lang -> boolean
    max_file_lines = nil, -- Do not enable for files with more than 1000 lines, int
  },
  incremental_selection = {
    enable = true,
    keymaps = {
      -- mappings for incremental selection (visual mappings)
      init_selection = "<leader>gv", -- maps in normal mode to init the node/scope selection
      node_incremental = "<leader>gv", -- increment to the upper named parent
      node_decremental = "<leader>gV", -- decrement to the previous node
      scope_incremental = "grc", -- (grc) increment to the upper scope (as defined in locals.scm)
    },
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
  -- textobjects = {
  --   move = {
  --     enable = true,
  --     set_jumps = true,

  --     goto_next_start = {
  --       ["]p"] = "@parameter.inner",
  --       ["]m"] = "@function.outer",
  --       ["]]"] = "@class.outer",
  --     },
  --     goto_next_end = {
  --       ["]M"] = "@function.outer",
  --       ["]["] = "@class.outer",
  --     },
  --     goto_previous_start = {
  --       ["[p"] = "@parameter.inner",
  --       ["[m"] = "@function.outer",
  --       ["[["] = "@class.outer",
  --     },
  --     goto_previous_end = {
  --       ["[M"] = "@function.outer",
  --       ["[]"] = "@class.outer",
  --     },
  --   },

  --   select = {
  --     enable = true,
  --     keymaps = {
  --       ["af"] = "@function.outer",
  --       ["if"] = "@function.inner",

  --       ["ac"] = "@conditional.outer",
  --       ["ic"] = "@conditional.inner",

  --       ["aa"] = "@parameter.outer",
  --       ["ia"] = "@parameter.inner",

  --       ["av"] = "@variable.outer",
  --       ["iv"] = "@variable.inner",
  --     },
  --   },

  --   -- REF: https://github.com/tjdevries/config_manager/blob/master/xdg_config/nvim/after/plugin/treesitter.lua#L31-L54
  --   -- swap = {
  --   --   enable = true,
  --   --   swap_next = swap_next,
  --   --   swap_previous = swap_prev,
  --   -- },
  -- },
  -- refactor = {
  --   highlight_definitions = { enable = true },
  --   highlight_current_scope = { enable = false },

  --   smart_rename = {
  --     enable = false,
  --     keymaps = {
  --       -- mapping to rename reference under cursor
  --       smart_rename = "grr",
  --     },
  --   },
  --   navigation = {
  --     enable = false,
  --     keymaps = {
  --       goto_definition = "gnd", -- mapping to go to definition of symbol under cursor
  --       list_definitions = "gnD", -- mapping to list all definitions in current file
  --     },
  --   },
  -- },
  query_linter = {
    enable = false,
    use_virtual_text = true,
    lint_events = { "BufWrite", "CursorHold" },
  },
  playground = {
    enable = true,
    disable = {},
    updatetime = 25, -- Debounced time for highlighting nodes in the playground from source code
    persist_queries = true, -- Whether the query persists across vim sessions
    keybindings = {
      toggle_query_editor = "o",
      toggle_hl_groups = "i",
      toggle_injected_languages = "t",
      toggle_anonymous_nodes = "a",
      toggle_language_display = "I",
      focus_language = "f",
      unfocus_language = "F",
      update = "R",
      goto_node = "<cr>",
      show_help = "?",
    },
  },
})
mega.conf("nvim-ts-autotag", {
  config = {
    filetypes = {
      "html",
      "xml",
      "javascript",
      "typescriptreact",
      "javascriptreact",
      "vue",
      "elixir",
      "heex",
    },
  },
})

-- nvim-treehopper
require("tsht").config.hint_keys = { "h", "j", "f", "d", "n", "v", "s", "l", "a" }

mega.conf("treesitter-context", {
  config = {
    multiline_threshold = 4,
    separator = { "▁", "TreesitterContextBorder" }, -- ─▁
    mode = "topline",
  },
})
