return {
  activate = function()
    mega.inspect("activating package settings.lua..")

    -- indentLine
    vim.g.indentLine_enabled = 1
    vim.g.indentLine_color_gui = "#556874"
    vim.g.indentLine_char = "│"
    vim.g.indentLine_bufTypeExclude = {"help", "terminal", "nerdtree", "tagbar", "startify", "fzf"}
    vim.g.indentLine_bufNameExclude = {"_.*", "NERD_tree.*", "startify", "fzf"}
    vim.g.indentLine_faster = 1
    vim.g.indentLine_setConceal = 0

    -- nvim-colorizer
    local has_installed, p = pcall(require, "colorizer")
    if not has_installed then
      return
    end

    -- https://github.com/norcalli/nvim-colorizer.lua/issues/4#issuecomment-543682160
    p.setup(
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

    -- golden_ratio
    local function ignore_by_buftype(types)
      local buftype = vim.api.nvim_buf_get_option(vim.api.nvim_get_current_buf(), "buftype")
      for _, type in pairs(types) do
        if type == buftype then
          return 1
        end
      end
    end

    local golden_size = require("golden_size")
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

    -- fzf
    vim.g.fzf_command_prefix = "Fzf"
    vim.g.fzf_layout = {window = {width = 0.6, height = 0.5}}
    vim.g.fzf_action = {enter = "vsplit"}
    vim.g.fzf_preview_window = {"right:50%", "alt-p"}
    mega.map("n", "<Leader>m", "<cmd>FzfFiles<CR>")
    mega.map("n", "<Leader>a", "<cmd>FzfRg<CR>")
    mega.map("n", "<Leader>A", "<ESC>:exe('FzfRg '.expand('<cword>'))<CR>")

    -- lspfuzzy
    -- require("lspfuzzy").setup(
    --   {
    --     methods = "all" -- either 'all' or a list of LSP methods (see below)
    --   }
    -- )

    -- vim-sneak
    vim.g["sneak#label"] = true

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
    local gitsigns_installed, p = pcall(require, "gitsigns")
    if not gitsigns_installed then
      return
    end
    p.setup(
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

    -- delimitMate
    vim.g.delimitMate_expand_cr = 0

    -- vim-test
    vim.api.nvim_exec(
      [[
" custom test display strategy:
function! TerminalSplit(cmd)
echom  "termianlsplit"
echom a:cmd
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
    local ts = require "nvim-treesitter.configs"
    ts.setup {
      ensure_installed = "maintained",
      highlight = {enable = true},
      textobjects = {
        select = {
          enable = true,
          keymaps = {
            -- use capture groups from textobjects.scm or define your own
            ["af"] = "@function.outer",
            ["if"] = "@function.inner",
            ["ac"] = "@class.outer",
            ["ic"] = "@class.inner"
          }
        },
        move = {
          enable = true,
          goto_next_start = {
            ["]m"] = "@function.outer",
            ["]]"] = "@class.outer"
          },
          goto_next_end = {
            ["]M"] = "@function.outer",
            ["]["] = "@class.outer"
          },
          goto_previous_start = {
            ["[m"] = "@function.outer",
            ["[["] = "@class.outer"
          },
          goto_previous_end = {
            ["[M"] = "@function.outer",
            ["[]"] = "@class.outer"
          }
        }
      }
    }
  end
}
