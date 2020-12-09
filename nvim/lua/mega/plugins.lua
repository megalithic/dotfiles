return {
  activate = function()
    mega.inspect("activating plugins.lua..")

    local packer_exists = pcall(vim.cmd, [[packadd packer.nvim]])
    local packer_repo_url = "https://github.com/wbthomason/packer.nvim"
    local packer_install_path = string.format("%s/site/pack/packer/opt/", vim.fn.stdpath("data"))

    -- Again, thieved from TJ Devries..
    if not packer_exists then
      if vim.fn.input("Download Packer? (y for yes) -> ") ~= "y" then
        return
      end

      vim.fn.mkdir(packer_install_path, "p")

      print("-> downloading packer.nvim...")
      vim.fn.system(string.format("git clone %s %s/%s", packer_repo_url, packer_install_path, "packer.nvim"))

      vim.cmd([[packadd packer.nvim]])
      vim.cmd("PackerSync")

      print("-> packer.nvim installed.")
      return
    end

    -- vim.api.nvim_exec([[autocmd BufWritePost plugins.lua PackerCompile]], true)

    return require("packer").startup(
      {
        function(use)
          -- (packer) --
          use {
            "wbthomason/packer.nvim",
            opt = true
          }

          -- (lsp, completion, snippets, diagnostics, et al) --
          use "nvim-lua/popup.nvim"
          use "nvim-lua/plenary.nvim"
          use {
            "neovim/nvim-lspconfig",
            as = "lspconfig",
            config = function()
              mega.load("lc", "mega.lc", "activate")
            end,
            requires = {
              "nvim-lua/completion-nvim",
              "steelsojka/completion-buffers",
              "hrsh7th/vim-vsnip",
              "hrsh7th/vim-vsnip-integ"
            }
          }
          use "nvim-lua/lsp-status.nvim"
          use "nvim-lua/lsp_extensions.nvim"

          -- (ui) --
          use {
            "trevordmiller/nova-vim",
            config = function()
              mega.load("nova", "mega.colors.nova", "activate")
            end
          }
          use {
            "norcalli/nvim-colorizer.lua",
            config = function()
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
                  tmux = {names = false},
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
          }
          use {
            "dm1try/golden_size",
            config = function()
              local function ignore_by_buftype(types)
                local buftype = vim.api.nvim_buf_get_option(vim.api.nvim_get_current_buf(), "buftype")
                for _, type in pairs(types) do
                  if type == buftype then
                    return 1
                  end
                end
              end

              local golden_size = require("golden_size")
              -- set the callbacks, preserve the defaults
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
          }
          use "ryanoasis/vim-devicons"
          use "junegunn/rainbow_parentheses.vim"

          -- (file navigatgion) --
          use {
            "junegunn/fzf",
            run = function()
              vim.fn["fzf#install"]()
            end,
            config = function()
              -- vim.g.fzf_layout = {window = {width = 0.6, height = 0.5}}
              -- vim.g.fzf_action = {enter = "vsplit"}
              -- vim.g.fzf_preview_window = {"right:50%:hidden", "alt-p"}
              vim.g.fzf_command_prefix = "Fzf"
              vim.g.fzf_layout = {window = {width = 0.6, height = 0.5}}
              vim.g.fzf_action = {enter = "vsplit"}
              vim.g.fzf_preview_window = {"right:50%", "alt-p"}
            end
          }
          use {
            "junegunn/fzf.vim",
            config = function()
              mega.map("n", "<Leader>m", "<cmd>FzfFiles<CR>")
              mega.map("n", "<Leader>a", "<cmd>FzfRg<CR>")
            end
          }
          use {
            "rhysd/clever-f.vim",
            config = function()
              vim.g.clever_f_across_no_line = 1
              vim.g.clever_f_fix_key_direction = 1
              vim.g.clever_f_timeout_ms = 2000
              vim.g.clever_f_show_prompt = 1

              -- keep the original functionality to jump between found chars
              mega.map("n", ";", "<Plug>(clever-f-repeat-forward)")
              mega.map("n", ",", "<Plug>(clever-f-repeat-back)")
            end
          }
          -- use {
          --   "justinmk/vim-sneak",
          --   config = function()
          --     vim.g["sneak#label"] = 1
          --     mega.map("n", "f", "<Plug>Sneak_s")
          --     mega.map("n", "F", "<Plug>Sneak_S")
          --   end
          -- }
          use "wellle/visual-split.vim"

          -- (text objects) --
          use {"tpope/vim-rsi"}
          use {"kana/vim-operator-user"}
          -- -- provide ai and ii for indent blocks
          -- -- provide al and il for current line
          -- -- provide a_ and i_ for underscores
          -- -- provide a- and i-
          use {"kana/vim-textobj-user"} -- https://github.com/kana/vim-textobj-user/wiki
          use {"kana/vim-textobj-function"} -- function text object (af/if)
          use {"kana/vim-textobj-indent"} -- for indent level (ai/ii)
          use {"kana/vim-textobj-line"} -- for current line (al/il)
          use {"nelstrom/vim-textobj-rubyblock"} -- ruby block text object (ar/ir)
          use {"andyl/vim-textobj-elixir"} -- elixir block text object (ae/ie)
          use {"glts/vim-textobj-comment"} -- comment text object (ac/ic)
          use {"michaeljsmith/vim-indent-object"}
          use {"machakann/vim-textobj-delimited"} -- - d/D   for underscore section (e.g. `did` on foo_b|ar_baz -> foo__baz)
          use {"gilligan/textobj-lastpaste"} -- - P     for last paste
          use {"mattn/vim-textobj-url"} -- - u     for url
          use {"rhysd/vim-textobj-anyblock"} -- - '', \"\", (), {}, [], <>
          use {"arthurxavierx/vim-caser"} -- https://github.com/arthurxavierx/vim-caser#usage
          use {"Julian/vim-textobj-variable-segment"} -- variable parts (av/iv)
          use {
            "sgur/vim-textobj-parameter",
            config = function()
              vim.g.vim_textobj_parameter_mapping = ","
            end
          } -- function parameters (a,/i,)
          use {"wellle/targets.vim"} -- improved targets line cin) next parens) https://github.com/wellle/targets.vim/blob/master/cheatsheet.md

          -- (git, vcs, et al) --
          use "tpope/vim-fugitive"
          use {"keith/gist.vim", run = "chmod -HR 0600 ~/.netrc"}
          use "wsdjeg/vim-fetch" -- vim path/to/file.ext:12:3
          use "mattn/webapi-vim"
          use "rhysd/conflict-marker.vim"
          use "itchyny/vim-gitbranch"
          use {
            "rhysd/git-messenger.vim",
            config = function()
              vim.g.git_messenger_no_default_mappings = true
              vim.g.git_messenger_max_popup_width = 100
              vim.g.git_messenger_max_popup_height = 100

              mega.map("n", "<Leader>gb", "<cmd>GitMessenger<CR>")
            end
          }
          use {
            "lewis6991/gitsigns.nvim",
            requires = {
              "nvim-lua/plenary.nvim"
            },
            config = function()
              local has_installed, p = pcall(require, "gitsigns")
              if not has_installed then
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
            end
          }

          -- (development, writing, et al) --
          use "tpope/vim-projectionist" -- projectionist.vim
          use "janko/vim-test" -- test.vim
          use "tpope/vim-ragtag" -- ragtag.vim
          use "axvr/zepl.vim"
          use "rizzatti/dash.vim"
          use "skywind3000/vim-quickui"
          use "sgur/vim-editorconfig"
          use "zenbro/mirror.vim"
          use "metakirby5/codi.vim"
          use "junegunn/goyo.vim"
          use "junegunn/limelight.vim"

          -- (the rest..) --
          use {
            "Raimondi/delimitMate",
            config = function()
              vim.g.delimitMate_expand_cr = 0
            end
          }
          use "tpope/vim-endwise"
          use {"rstacruz/vim-closer", after = "vim-endwise"}
          use "tpope/vim-eunuch"
          use "tpope/vim-abolish"
          use "tpope/vim-rhubarb"
          use "tpope/vim-repeat"
          use "tpope/vim-surround"
          use "tpope/vim-commentary"
          use "tpope/vim-unimpaired"
          use "EinfachToll/DidYouMean"
          use "jordwalke/VimAutoMakeDirectory"
          use "ConradIrwin/vim-bracketed-paste"
          use "sickill/vim-pasta"
          -- use {'AndrewRadev/splitjoin.vim', config = function()
          --     -- vim.g.splitjoin_split_mapping = ''
          --     -- vim.g.splitjoin_join_mapping = ''

          --     -- mega.map("n", "sj", "<cmd>SplitjoinSplit<CR>")
          --     -- mega.map("n", "sk", "<cmd>SplitjoinJoin<CR>")
          -- end}
          -- :Messages <- view messages in quickfix list
          -- :Verbose  <- view verbose output in preview window.
          -- :Time     <- measure how long it takes to run some stuff.
          use "tpope/vim-scriptease"
          use "christoomey/vim-tmux-navigator"
          use "tmux-plugins/vim-tmux-focus-events"
          use "christoomey/vim-tmux-runner"

          -- (langs, syntax, et al) --
          use "tpope/vim-rails" -- rails.vim
          use "gleam-lang/gleam.vim"
          use "vim-erlang/vim-erlang-runtime"
          use "Zaptic/elm-vim"
          use "antew/vim-elm-analyse"
          use "elixir-lang/vim-elixir"
          use "avdgaag/vim-phoenix"
          use "lucidstack/hex.vim"
          use "neoclide/jsonc.vim"
          use "gerrard00/vim-mocha-only"
          use "plasticboy/vim-markdown"
          use {
            "iamcco/markdown-preview.nvim",
            run = function()
              vim.fn["mkdp#util#install"]()
            end
          }
          use "florentc/vim-tla"
          use "euclidianace/betterlua.vim"
          use "andrejlevkovitch/vim-lua-format"
          use "yyq123/vim-syntax-logfile"
          use "jparise/vim-graphql"
          use "sheerun/vim-polyglot"
        end
      }
    )
  end
}
