mega.inspect("activating package settings.lua..")

-- indentLine
vim.g.indentLine_enabled = 1
vim.g.indentLine_color_gui = "#556874"
vim.g.indentLine_char = "│"
vim.g.indentLine_bufTypeExclude = {"help", "terminal", "nerdtree", "tagbar", "startify", "fzf"}
vim.g.indentLine_bufNameExclude = {"_.*", "NERD_tree.*", "startify", "fzf"}
vim.g.indentLine_fileTypeExclude = {"text", "markdown"}
vim.g.indentLine_faster = 1
vim.g.indentLine_setConceal = 0

-- nvim-colorizer
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

-- golden_ratio
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

-- fzf
vim.g.fzf_command_prefix = "Fzf"
vim.g.fzf_layout = {window = {width = 0.6, height = 0.5}}
vim.g.fzf_action = {enter = "vsplit"}
vim.g.fzf_preview_window = {"right:50%", "alt-p"}
mega.map("n", "<Leader>m", "<cmd>FzfFiles<CR>")
mega.map("n", "<Leader>a", "<cmd>FzfRg<CR>")
mega.map("n", "<Leader>A", "<ESC>:exe('FzfRg '.expand('<cword>'))<CR>")
vim.api.nvim_exec(
  [[
    function! RipgrepFzf(query, fullscreen)
      let command_fmt = 'rg --column --line-number --no-heading --color=always --smart-case -- %s || true'
      let initial_command = printf(command_fmt, shellescape(a:query))
      let reload_command = printf(command_fmt, '{q}')
      let spec = {'options': ['--phony', '--query', a:query, '--bind', 'change:reload:'.reload_command]}
      call fzf#vim#grep(initial_command, 1, fzf#vim#with_preview(spec), a:fullscreen)
    endfunction
    command! -nargs=* -bang Rg call RipgrepFzf(<q-args>, <bang>0)
    ]],
  true
)

-- vim-polyglot
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

-- lspfuzzy
require("lspfuzzy").setup(
  {
    methods = "all" -- either 'all' or a list of LSP methods (see below)
  }
)

-- vim-sneak
-- vim.g["sneak#label"] = true

-- quickscope
-- vim.g.qs_enable = 1
-- vim.g.qs_highlight_on_keys = {"f", "F", "t", "T"}
-- vim.g.qs_lazy_highlight = 1

-- textobj_parameter
vim.g.vim_textobj_parameter_mapping = ","

-- git_messenger
vim.g.git_messenger_no_default_mappings = true
vim.g.git_messenger_max_popup_width = 100
vim.g.git_messenger_max_popup_height = 100
mega.map("n", "<Leader>gb", "<cmd>GitMessenger<CR>")

-- gitsigns
local gitsigns_installed, gitsigns = pcall(require, "gitsigns")
if gitsigns_installed then
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

-- delimitMate
vim.g.delimitMate_expand_cr = 0

-- vim-test
vim.api.nvim_exec(
  [[
" custom test display strategy:
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
" https://github.com/megalithic/dotfiles/blob/8a9f7d9913f586f1ed5f400525ffa04906691311/nvim_hybrid/plugin/helpers.vim
nmap <silent> <leader>to :copen<CR>
]],
  false
)

-- treesitter
-- local ts_installed, treesitter = pcall(require, "nvim-treesitter.configs")
-- if ts_installed then
--   treesitter.setup(
--     {
--       ensure_installed = {
--         "bash",
--         "c",
--         "cpp",
--         "css",
--         "elm",
--         "erlang",
--         "fennel",
--         "html",
--         "jsdoc",
--         "javascript",
--         "json",
--         "lua",
--         "nix",
--         "python",
--         "regex",
--         "ruby",
--         "rust",
--         "toml",
--         "tsx",
--         "typescript",
--         "yaml"
--       },
--       highlight = {enable = true},
--       indent = {enable = true},
--       textobjects = {
--         select = {
--           enable = true,
--           keymaps = {
--             -- use capture groups from textobjects.scm or define your own
--             ["af"] = "@function.outer",
--             ["if"] = "@function.inner",
--             ["aC"] = "@class.outer",
--             ["iC"] = "@class.inner",
--             ["ac"] = "@conditional.outer",
--             ["ic"] = "@conditional.inner",
--             ["ae"] = "@block.outer",
--             ["ie"] = "@block.inner",
--             ["al"] = "@loop.outer",
--             ["il"] = "@loop.inner",
--             ["is"] = "@statement.inner",
--             ["as"] = "@statement.outer",
--             ["ad"] = "@comment.outer",
--             ["am"] = "@call.outer",
--             ["im"] = "@call.inner"
--           }
--         },
--         move = {
--           enable = true,
--           goto_next_start = {
--             ["]m"] = "@function.outer",
--             ["]]"] = "@class.outer"
--           },
--           goto_next_end = {
--             ["]M"] = "@function.outer",
--             ["]["] = "@class.outer"
--           },
--           goto_previous_start = {
--             ["[m"] = "@function.outer",
--             ["[["] = "@class.outer"
--           },
--           goto_previous_end = {
--             ["[M"] = "@function.outer",
--             ["[]"] = "@class.outer"
--           }
--         }
--       }
--     }
--   )
-- end

-- vim-projectionist
vim.g.projectionist_heuristics = {
  ["*.rb"] = {
    ["lib/*.rb"] = {
      ["alternate"] = "spec/{}_spec.rb",
      ["type"] = "source"
    },
    ["spec/*_spec.rb"] = {
      ["alternate"] = "lib/{}.rb",
      ["type"] = "test"
    }
  },
  ["*.go"] = {
    ["*.go"] = {
      ["alternate"] = "{}_test.go",
      ["type"] = "source"
    },
    ["*_test.go"] = {
      ["alternate"] = "{}.go",
      ["type"] = "test"
    }
  },
  ["*.py"] = {
    ["*.py"] = {
      ["alternate"] = "{}_test.py",
      ["type"] = "source"
    },
    ["*_test.py"] = {
      ["alternate"] = "{}.py",
      ["type"] = "test"
    }
  },
  ["package.json"] = {
    ["src/*.js"] = {
      ["alternate"] = "{}.test.js",
      ["type"] = "source"
    },
    ["src/*.test.js"] = {
      ["alternate"] = "src/{}.js",
      ["type"] = "test"
    }
  },
  ["*.js"] = {
    ["*.test.js"] = {
      ["alternate"] = "{}.js",
      ["type"] = "test"
    },
    ["*.js"] = {
      ["alternate"] = "{}.test.js",
      ["type"] = "source"
    }
  },
  ["*.c|*.h|*.cpp|*.hpp"] = {
    ["*.c"] = {["alternate"] = {"{}.h"}},
    ["*.cpp"] = {["alternate"] = {"{}.h", "{}.hpp"}},
    ["*.h"] = {["alternate"] = {"{}.cpp", "{}.c"}},
    ["*.hpp"] = {["alternate"] = "{}.cpp"}
  },
  ["mix.exs"] = {
    ["lib/*_live.ex"] = {
      ["alternate"] = "lib/{}_live.html.leex",
      ["type"] = "source"
    },
    ["lib/*.ex"] = {
      ["alternate"] = "test/{}_test.exs",
      ["type"] = "source"
    },
    ["test/*_test.exs"] = {
      ["alternate"] = "lib/{}.ex",
      ["type"] = "test"
    },
    ["lib/*.html.leex"] = {
      ["alternate"] = "lib/{}.ex",
      ["type"] = "live_view"
    }
  }
}
