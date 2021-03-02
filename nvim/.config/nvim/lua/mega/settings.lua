mega.inspect("activating package settings.lua..")

-- [prose,wiki,md] -------------------------------------------------------------
vim.g.goyo_width = 120
vim.g.goyo_height = "50%"
vim.g["pencil#conceallevel"] = 0
vim.g["pencil#wrapModeDefault"] = "soft"

vim.g.markdown_enable_conceal = 1
vim.g.wiki_root = "~/Documents/_wiki"
vim.g.wiki_filetypes = {"md"}
vim.g.wiki_link_target_type = "md"
vim.g.wiki_map_link_create = "CreateLinks" -- cannot use anonymous functions
vim.cmd [[
  function! CreateLinks(text) abort
    return substitute(tolower(a:text), '\s\+', '-', 'g')
  endfunction
]]

vim.g.vimwiki_list = {
  {path = "~/Documents/notes/", syntax = "markdown", ext = ".md", auto_tags = 1, auto_diary_index = 1},
  {path = "~/Documents/wiki/", syntax = "markdown", ext = ".md", auto_tags = 1}
}

vim.g.nv_search_paths = {"~/Documents/notes/"}
vim.g.zettel_format = "%Y%m%d-%H%M%S"
-- vim.g.zettel_format = "%Y%m%d%H%M-%S"
-- vim.g.zettel_options = [{},{"front_matter" : {"tags" : ""}, "template" :  "~/Templates/zettel.tpl"}]
vim.g.zettel_fzf_command = "rg --column --line-number --ignore-case --no-heading --color=always "
--
-- nnoremap <leader>vt :VimwikiSearchTags<space>
-- nnoremap <leader>vs :VimwikiSearch<space>
-- nnoremap <leader>gt :VimwikiRebuildTags!<cr>:ZettelGenerateTags<cr><c-l>
-- nnoremap <leader>zl :ZettelSearch<cr>
-- nnoremap <leader>zn :ZettelNew<cr><cr>:4d<cr>:w<cr>ggA
-- nnoremap <leader>bl :VimwikiBacklinks<cr>
-- let g:vimwiki_list = [{'path': '~/Documents/notes/', 'syntax': 'markdown', 'ext': '.md', 'auto_tags': 1, 'auto_diary_index': 1},
--                      \{'path': '~/Documents/wiki/', 'syntax': 'markdown', 'ext': '.md', 'auto_tags': 1}]

-- let g:nv_search_paths = ['~/Documents/notes/']

-- " Filename format. The filename is created using strftime() function
-- let g:zettel_format = "%y%m%d-%H%M"

-- let g:zettel_fzf_command = "rg --column --line-number --ignore-case --no-heading --color=always "

-- " Set template and custom header variable for the second Wiki
-- " let g:zettel_options = [{"front_matter" : {"tags" : ""}, "template" :  "./vimztl.tpl"},{}]

-- nnoremap <leader>sn/ :NV<CR>

-- nnoremap <leader>zn :ZettelNew<space>
-- nnoremap <leader>z<leader>i :ZettelGenerateLinks<CR>
-- nnoremap <leader>z<leader>t :ZettelGenerateTags<CR>

-- [lexima] ------------------------------------------------------------------
-- vim.g.lexima_enable_basic_rules = 0
-- vim.g.lexima_enable_newline_rules = 0
-- vim.g.lexima_enable_endwise_rules = 1

-- [fixcursorhold] -------------------------------------------------------------
vim.g.cursorhold_updatetime = 100

-- [lspfuzzy] --------------------------------------------------------------------
require("lspfuzzy").setup(
  {
    methods = "all" -- either 'all' or a list of LSP methods (see below)
  }
)

-- [lspsaga] -------------------------------------------------------------------
require("lspsaga").init_lsp_saga {
  use_saga_diagnostic_sign = false,
  border_style = 2,
  finder_action_keys = {
    open = "<CR>",
    vsplit = "v",
    split = "s",
    -- quit = {"q", [[\<ESC>]]}
    quit = {"<ESC>", "q"}
  }
}

-- [beacon] --------------------------------------------------------------------
vim.g.beacon_size = 90
vim.g.beacon_minimal_jump = 25
vim.g.beacon_shrink = 0
vim.g.beacon_ignore_filetypes = {"fzf"}

-- [surround] ------------------------------------------------------------------
-- vim.g.surround_mappings_style = "surround"
-- require "surround".setup {}

-- [nvim_comment] --------------------------------------------------------------
-- require("nvim_comment").setup()

-- [kommentary] ----------------------------------------------------------------
-- require('kommentary.config').configure_language("default", {
--         prefer_single_line_comments = true
--     })
--     require('kommentary.config').configure_language("lua", {
--         single_line_comment_string = "--",
--         prefer_single_line_comments = true
--     })

-- [conflict-marker] -----------------------------------------------------------
-- disable the default highlight group
vim.g.conflict_marker_highlight_group = ""
-- Include text after begin and end markers
vim.g.conflict_marker_begin = "^<<<<<<< .*$"
vim.g.conflict_marker_end = "^>>>>>>> .*$"

-- [nvim-colorizer] ------------------------------------------------------------
-- https://github.com/norcalli/nvim-colorizer.lua/issues/4#issuecomment-543682160
local colorizer_installed, colorizer = pcall(require, "colorizer")
if colorizer_installed then
  colorizer.setup(
    {
      -- '*',
      -- '!vim',
      -- }, {
      css = {rgb_fn = true},
      scss = {rgb_fn = true},
      sass = {rgb_fn = true},
      stylus = {rgb_fn = true},
      vim = {names = false},
      tmux = {names = true},
      "eelixir",
      "javascript",
      "javascriptreact",
      "typescript",
      "typescriptreact",
      "zsh",
      "sh",
      "conf",
      "lua",
      html = {
        mode = "foreground"
      }
    }
  )
end

-- [focus] ---------------------------------------------------------------------
-- do
--   local focus = require("focus")
--   focus.enable = true
--   focus.width = 120
--   focus.height = 40
--   focus.cursorline = true
--   focus.signcolumn = true
--   focus.winhighlight = false
-- end

-- [golden_size] ---------------------------------------------------------------
local golden_size_installed, golden_size = pcall(require, "golden_size")
if golden_size_installed then
  local function ignore_by_buftype(types)
    local buftype = vim.api.nvim_buf_get_option(vim.api.nvim_get_current_buf(), "buftype")
    for _, type in pairs(types) do
      if type == buftype then
        return 1
      end
    end
  end
  golden_size.set_ignore_callbacks(
    {
      {
        ignore_by_buftype,
        {
          "Undotree",
          "quickfix",
          "nerdtree",
          "current",
          "Vista",
          "LuaTree",
          "nofile"
        }
      },
      {golden_size.ignore_float_windows}, -- default one, ignore float windows
      {golden_size.ignore_by_window_flag} -- default one, ignore windows with w:ignore_gold_size=1
    }
  )
end

-- [nvim-autopairs] ------------------------------------------------------------
require("nvim-autopairs").setup()
-- require('nvim-autopairs').setup({
--   pairs_map = {
--     ["'"] = "'",
--     ['"'] = '"',
--     ['('] = ')',
--     ['['] = ']',
--     ['{'] = '}',
--     ['`'] = '`',
--     ['$'] = '$'
--   }
-- })

-- [fzf] -----------------------------------------------------------------------
vim.g.fzf_command_prefix = "Fzf"
vim.g.fzf_layout = {window = {width = 0.5, height = 0.5}}
vim.g.fzf_action = {enter = "vsplit"}
vim.g.fzf_preview_window = {"right:40%", "alt-p"}
vim.env.FZF_DEFAULT_COMMAND = "fd --type f --hidden --follow --exclude '.git' --exclude 'node_modules'"
vim.api.nvim_exec(
  [[
  function! RipgrepFzf(query, fullscreen)
  let command_fmt = 'rg --column --line-number --no-heading --color=always -- %s || true'
  let initial_command = printf(command_fmt, shellescape(a:query))
  let reload_command = printf(command_fmt, '{q}')
  let spec = {'options': ['--phony', '--query', a:query, '--bind', 'change:reload:'.reload_command]}
  call fzf#vim#grep(initial_command, 1, fzf#vim#with_preview(spec), a:fullscreen)
  endfunction
  ]],
  false
)
vim.cmd([[command! -nargs=* -bang RG call RipgrepFzf(<q-args>, <bang>0)]])
vim.g.fzf_colors = {
  fg = {"fg", "Normal"},
  bg = {"bg", "Normal"},
  hl = {"fg", "IncSearch"},
  ["fg+"] = {"fg", "CursorLine", "CursorColumn", "Normal"},
  ["bg+"] = {"bg", "CursorLine", "CursorColumn"},
  ["hl+"] = {"fg", "IncSearch"},
  info = {"fg", "IncSearch"},
  border = {"fg", "Ignore"},
  prompt = {"fg", "Comment"},
  pointer = {"fg", "IncSearch"},
  marker = {"fg", "IncSearch"},
  spinner = {"fg", "IncSearch"},
  header = {"fg", "WildMenu"}
}
-- @evantravers:
-- vim.g.fzf_colors = {
--   fg = {"fg", "Normal"},
--   bg = {"bg", "Normal"},
--   hl = {"fg", "Comment"},
--   ["fg+"] = {"fg", "CursorLine", "CursorColumn", "Normal"},
--   ["bg+"] = {"bg", "CursorLine", "CursorColumn"},
--   ["hl+"] = {"fg", "Statement"},
--   info = {"fg", "PreProc"},
--   border = {"fg", "Ignore"},
--   prompt = {"fg", "Conditional"},
--   pointer = {"fg", "Exception"},
--   marker = {"fg", "Keyword"},
--   spinner = {"fg", "Label"},
--   header = {"fg", "Comment"}
-- }

-- [vim-polyglot] --------------------------------------------------------------
vim.g.polyglot_disabled = {
  "typescript",
  "typescriptreact",
  "typescript.tsx",
  "javascriptreact",
  "markdown",
  "md",
  "graphql",
  "lua",
  "tsx",
  "jsx",
  "sass",
  "scss",
  "css",
  "elm",
  "elixir",
  "eelixir",
  "ex",
  "exs",
  "zsh",
  "sh"
}

-- [quickscope] ----------------------------------------------------------------
vim.g.qs_enable = 1
vim.g.qs_highlight_on_keys = {"f", "F", "t", "T"}
vim.g.qs_buftype_blacklist = {"terminal", "nofile"}
vim.g.qs_lazy_highlight = 1

-- [textobj_parameter] ---------------------------------------------------------
vim.g.vim_textobj_parameter_mapping = ","

-- [git_messenger] -------------------------------------------------------------
vim.g.git_messenger_no_default_mappings = true
vim.g.git_messenger_max_popup_width = 100
vim.g.git_messenger_max_popup_height = 100
mega.map("n", "<Leader>gb", "<cmd>GitMessenger<CR>")

-- [indentLine/indent_blankline] -----------------------------------------------
-- set concealcursor=n
-- vim.g.indentLine_char = "│"
-- vim.g.indentLine_first_char = vim.g.indentLine_char
-- vim.g.indentLine_showFirstIndentLevel = 1
-- -- " vim.g.indentLine_color_gui = onedark#GetColors().cursor_grey.gui
-- vim.g.indentLine_bgcolor_gui = "NONE"
-- vim.g.indentLine_setConceal = 0
-- vim.g.indentLine_fileTypeExclude = {"help", "defx", "vimwiki", "prcomment"}
-- vim.g.indentLine_autoResetWidth = 0
-- vim.g.indent_blankline_space_char = " "
-- vim.g.indent_blankline_debug = true

-- [gitsigns] ------------------------------------------------------------------
local gitsigns_installed, gitsigns = pcall(require, "gitsigns")
if gitsigns_installed then
  -- https://github.com/JoosepAlviste/dotfiles/blob/master/config/nvim/lua/j/gitsigns.lua
  gitsigns.setup(
    {
      signs = {
        add = {hl = "DiffAdd", text = "│"},
        change = {hl = "DiffChange", text = "│"},
        delete = {hl = "DiffDelete", text = "_"},
        topdelete = {hl = "DiffDelete", text = "‾"},
        changedelete = {hl = "DiffChange", text = "~"}
      },
      keymaps = {
        -- Default keymap options
        noremap = true,
        buffer = true,
        ["n ]g"] = {expr = true, '&diff ? \']g\' : \'<cmd>lua require"gitsigns".next_hunk()<CR>\''},
        ["n [g"] = {expr = true, '&diff ? \'[g\' : \'<cmd>lua require"gitsigns".prev_hunk()<CR>\''},
        ["n <leader>hs"] = '<cmd>lua require"gitsigns".stage_hunk()<CR>',
        ["n <leader>hu"] = '<cmd>lua require"gitsigns".undo_stage_hunk()<CR>',
        ["n <leader>hr"] = '<cmd>lua require"gitsigns".reset_hunk()<CR>',
        ["n <leader>hp"] = '<cmd>lua require"gitsigns".preview_hunk()<CR>',
        ["n <leader>hb"] = '<cmd>lua require"gitsigns".blame_line()<CR>'
      },
      watch_index = {
        interval = 1000
      },
      sign_priority = 6,
      status_formatter = nil -- Use default
    }
  )
end

-- [vim-test] ------------------------------------------------------------------
vim.api.nvim_exec(
  [[
  function! TerminalSplit(cmd)
  vert new | set filetype=test | call termopen(['/usr/local/bin/zsh', '-c', a:cmd], {'curwin':1})
  endfunction

  let g:test#custom_strategies = {'terminal_split': function('TerminalSplit')}
  let g:test#strategy = 'terminal_split'
  let g:test#filename_modifier = ':.'
  let g:test#preserve_screen = 0

  nmap <silent> <leader>tf :TestFile<CR>
  nmap <silent> <leader>tt :TestVisit<CR>
  nmap <silent> <leader>tn :TestNearest<CR>
  nmap <silent> <leader>tl :TestLast<CR>
  nmap <silent> <leader>tv :TestVisit<CR>
  nmap <silent> <leader>ta :TestSuite<CR>
  nmap <silent> <leader>tP :A<CR>
  nmap <silent> <leader>tp :AV<CR>
  nmap <silent> <leader>to :copen<CR>
  ]],
  false
)

-- [nvim-treesitter] -----------------------------------------------------------
local ts_installed, treesitter = pcall(require, "nvim-treesitter.configs")
if ts_installed then
  -- local parser_configs = require "nvim-treesitter.parsers".get_parser_configs()
  -- parser_configs.elixir = {
  --   install_info = {
  --     url = "~/.config/treesitter/tree-sitter-elixir",
  --     files = {"src/parser.c"}
  --   },
  --   filetype = "elixir",
  --   used_by = {"eelixir"}
  -- }
  treesitter.setup(
    {
      ensure_installed = {
        "bash",
        "c",
        "cpp",
        "css",
        "elm",
        "erlang",
        "elixir",
        "fennel",
        "html",
        "jsdoc",
        "javascript",
        "json",
        "lua",
        "nix",
        "python",
        "regex",
        "ruby",
        "rust",
        "toml",
        "tsx",
        "typescript",
        "yaml"
      },
      highlight = {enable = true},
      indent = {enable = true}
      -- textobjects = {
      --   select = {
      --     enable = true,
      --     keymaps = {
      --       -- use capture groups from textobjects.scm or define your own
      --       ["af"] = "@function.outer",
      --       ["if"] = "@function.inner",
      --       ["aC"] = "@class.outer",
      --       ["iC"] = "@class.inner",
      --       ["ac"] = "@conditional.outer",
      --       ["ic"] = "@conditional.inner",
      --       ["ae"] = "@block.outer",
      --       ["ie"] = "@block.inner",
      --       ["al"] = "@loop.outer",
      --       ["il"] = "@loop.inner",
      --       ["is"] = "@statement.inner",
      --       ["as"] = "@statement.outer",
      --       ["ad"] = "@comment.outer",
      --       ["am"] = "@call.outer",
      --       ["im"] = "@call.inner"
      --     }
      --   },
      --   move = {
      --     enable = true,
      --     goto_next_start = {
      --       ["]m"] = "@function.outer",
      --       ["]]"] = "@class.outer"
      --     },
      --     goto_next_end = {
      --       ["]M"] = "@function.outer",
      --       ["]["] = "@class.outer"
      --     },
      --     goto_previous_start = {
      --       ["[m"] = "@function.outer",
      --       ["[["] = "@class.outer"
      --     },
      --     goto_previous_end = {
      --       ["[M"] = "@function.outer",
      --       ["[]"] = "@class.outer"
      --     }
      --   }
      -- }
    }
  )
end

-- [vim-projectionist] ---------------------------------------------------------
vim.g.projectionist_heuristics = {
  ["mix.exs"] = {
    ["lib/**/views/*_view.ex"] = {
      ["type"] = "view",
      ["alternate"] = "test/{dirname}/views/{basename}_view_test.exs",
      ["template"] = {
        "defmodule {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}View do",
        "  use {dirname|camelcase|capitalize}, :view",
        "end"
      }
    },
    ["test/**/views/*_view_test.exs"] = {
      ["type"] = "test",
      ["alternate"] = "lib/{dirname}/views/{basename}_view.ex",
      ["template"] = {
        "defmodule {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}ViewTest do",
        "  use ExUnit.Case, async: true",
        "",
        "  alias {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}View",
        "end"
      }
    },
    ["lib/**/live/*_live.ex"] = {
      ["type"] = "liveview",
      ["alternate"] = "test/{dirname}/views/{basename}_live_test.exs",
      ["template"] = {
        "defmodule {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}Live do",
        "  use {dirname|camelcase|capitalize}, :live_view",
        "end"
      }
    },
    ["test/**/live/*_live_test.exs"] = {
      ["type"] = "test",
      ["alternate"] = "lib/{dirname}/live/{basename}_live.ex",
      ["template"] = {
        "defmodule {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}LiveTest do",
        "  use ExUnit.Case, async: true",
        "",
        "  alias {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}Live",
        "end"
      }
    },
    ["lib/*.ex"] = {
      ["type"] = "source",
      ["alternate"] = "test/{}_test.exs",
      ["template"] = {
        "defmodule {camelcase|capitalize|dot} do",
        "",
        "end"
      }
    },
    ["test/*_test.exs"] = {
      ["type"] = "test",
      ["alternate"] = "lib/{}.ex",
      ["template"] = {
        "defmodule {camelcase|capitalize|dot}Test do",
        "  use ExUnit.Case, async: true",
        "",
        "  alias {camelcase|capitalize|dot}",
        "end"
      }
    }
  }
}
