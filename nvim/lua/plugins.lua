-- local packer_exists = pcall(vim.cmd, [[packadd packer.nvim]])

-- local ensure_packer_nvim = function()
--   local packer_dir = string.format('%s/pack/packer/opt/packer.nvim', site_dir)
--   vfn.mkdir(packer_dir, 'p')
--   if not loop.fs_stat(packer_dir .. '/.git') then
--     execute([[git clone --depth=1 https://github.com/wbthomason/packer.nvim %s]], packer_dir)
--   end

--   vim.o.packpath = string.format('%s,%s', site_dir, vim.o.packpath)
--   require('fsouza.packed').setup()
--   require('packer').sync()
-- end

-- if not packer_exists then
local nvim_config_dir = string.format("%s/pack/packer/opt/", vim.fn.stdpath("config"))
local packer_dir = string.format('%s/packer.nvim', nvim_config_dir)

if not vim.loop.fs_stat(nvim_config_dir .. '/.git') then
  if vim.fn.input("Download Packer? (y for yes) ") ~= "y" then
    return
  end

  vim.fn.mkdir(nvim_config_dir, "p")

  local out =
    vim.fn.system(
    string.format(
      "git clone %s %s %s",
      "--depth=1",
      "https://github.com/wbthomason/packer.nvim",
      packer_dir
    )
  )

  print(out)
  print("Downloading packer.nvim...")

  return
end

local plugins = {
  {"https://github.com/wbthomason/packer.nvim", opt = true},
  {"https://github.com/antoinemadec/FixCursorHold.nvim"},
  {"https://github.com/andymass/vim-matchup"},
  {"https://github.com/tpope/vim-sensible", opt = true},
  -- {"https://github.com/jiangmiao/auto-pairs"},
  {
    "https://github.com/junegunn/fzf.vim",
    -- I have the bin globally, so don't build, and just grab plugin directory
    requires = {{"https://github.com/junegunn/fzf"}}
  },

  -- {"https://github.com/duggiefresh/vim-easydir"},
  {"https://github.com/907th/vim-auto-save"}, -- "auto-save.vim
  -- {"https://github.com/justinmk/vim-sneak"}
  {"https://github.com/rhysd/clever-f.vim"}, -- "clever-f.vim
  {"https://github.com/tpope/vim-unimpaired"}, -- "unimpaired.vim
  {"https://github.com/EinfachToll/DidYouMean"}, -- " Vim plugin which asks for the right file to open
  {"https://github.com/jordwalke/VimAutoMakeDirectory"}, -- " auto-makes the dir for you if it doesn't exist in the path
  {"https://github.com/ConradIrwin/vim-bracketed-paste"}, -- " correctly paste in insert mode
  {"https://github.com/sickill/vim-pasta"}, -- " context-aware pasting

  -- {"https://github.com/junegunn/vim-peekaboo"},
  -- {"https://github.com/eugen0329/vim-esearch"},
  -- {"https://github.com/mhinz/vim-sayonara", opt = true, cmd = "Sayonara"},

  {"https://github.com/nelstrom/vim-visual-star-search"},
  {"https://github.com/tpope/tpope-vim-abolish"},
  {"https://github.com/tpope/vim-projectionist"},
  {"https://github.com/janko/vim-test"}, -- test.vim
  {"https://github.com/tpope/vim-ragtag"}, -- ragtag.vim
  {"https://github.com/axvr/zepl.vim"},
  {"https://github.com/rizzatti/dash.vim"},
  {"https://github.com/skywind3000/vim-quickui"},
  {"https://github.com/sgur/vim-editorconfig"},
  {"https://github.com/zenbro/mirror.vim"}, -- " allows mirror'ed editing of files locally, to a specified ssh location via ~/.mirrors
  {"https://github.com/tpope/vim-surround"},
  {"https://github.com/tpope/vim-eunuch"},
  {"https://github.com/tpope/vim-repeat"},
  {"https://github.com/machakann/vim-sandwich"},
  {"https://github.com/tpope/vim-commentary"},


  {"https://github.com/tpope/vim-rsi"},
  {"https://github.com/kana/vim-operator-user"},
  -- " -- provide ai and ii for indent blocks
  -- " -- provide al and il for current line
  -- " -- provide a_ and i_ for underscores
  -- " -- provide a- and i-
  {"https://github.com/kana/vim-textobj-user"},                                           -- " https://github.com/kana/vim-textobj-user/wiki
  {"https://github.com/kana/vim-textobj-function"},                                       -- " function text object (af/if)
  {"https://github.com/kana/vim-textobj-indent"},                                         -- " for indent level (ai/ii)
  {"https://github.com/kana/vim-textobj-line"},                                           -- " for current line (al/il)
  {"https://github.com/nelstrom/vim-textobj-rubyblock"},                                  -- " ruby block text object (ar/ir)
  {"https://github.com/andyl/vim-textobj-elixir"},                                        -- " elixir block text object (ae/ie)
  -- let g:vim_textobj_elixir_mapping = 'E'
  {"https://github.com/glts/vim-textobj-comment"},                                        -- " comment text object (ac/ic)
  {"https://github.com/michaeljsmith/vim-indent-object"},
  {"https://github.com/machakann/vim-textobj-delimited"},                                 -- " - d/D   for underscore section (e.g. `did` on foo_b|ar_baz -> foo__baz)
  {"https://github.com/gilligan/textobj-lastpaste"},                                      -- " - P     for last paste
  {"https://github.com/mattn/vim-textobj-url"},                                           -- " - u     for url
  {"https://github.com/rhysd/vim-textobj-anyblock"},                                      -- " - '', \"\", (), {}, [], <>
  {"https://github.com/arthurxavierx/vim-caser"},                                         -- " https://github.com/arthurxavierx/vim-caser#usage
  {"https://github.com/Julian/vim-textobj-variable-segment"},                             -- " variable parts (av/iv)
  {"https://github.com/sgur/vim-textobj-parameter"},                                      -- " function parameters (a,/i,)
  -- let g:vim_textobj_parameter_mapping = ','
  {"https://github.com/wellle/targets.vim"},                                              -- " improved targets line cin) next parens) https://github.com/wellle/targets.vim/blob/master/cheatsheet.md
  -- {"https://github.com/wincent/loupe"},
  -- {"https://github.com/wincent/terminus"},
  {"https://github.com/tommcdo/vim-lion"},
  {"https://github.com/christoomey/vim-tmux-navigator", opt = true},
  {"https://github.com/tmux-plugins/vim-tmux-focus-events"},
  {"https://github.com/christoomey/vim-tmux-runner"},
  {"https://github.com/rhysd/devdocs.vim"},
  -- {"https://github.com/fcpg/vim-waikiki"},

  -- LSP/Autocompletion {{{
  {
    "https://github.com/neovim/nvim-lspconfig",
    cond = "vim.fn.has('nvim-0.5.0')",
    config = function()
      require "lc.config"
    end,
    requires = {
      {
        "https://github.com/tjdevries/lsp_extensions.nvim",
        config = function()
          require "p.statusline".activate()
        end
      },
      {"https://github.com/tjdevries/nlua.nvim"}
    }
  },
  {
    "https://github.com/nvim-lua/completion-nvim",
    requires = {
      {
        "https://github.com/steelsojka/completion-buffers",
        cond = "vim.fn.has('nvim-0.5.0')"
      },
      {"https://github.com/hrsh7th/vim-vsnip"},
      {"https://github.com/hrsh7th/vim-vsnip-integ"}
    }
  },
  {
    "https://github.com/nvim-treesitter/nvim-treesitter",
    cond = "vim.fn.has('nvim-0.5.0')",
    config = function()
      require "p.treesitter"
    end,
    requires = {
      "https://github.com/nvim-treesitter/playground",
      cmd = "TSPlaygroundToggle"
    }
  },
  -- }}}

  -- Syntax {{{
  {"https://github.com/HerringtonDarkholme/yats.vim"},
  {"https://github.com/peitalin/vim-jsx-typescript"},
  {"https://github.com/tpope/vim-rails"},
  {"https://github.com/gleam-lang/gleam.vim"},
  {"https://github.com/vim-erlang/vim-erlang-runtime"},
  {"https://github.com/Zaptic/elm-vim"},
  {"https://github.com/antew/vim-elm-analyse"},
  {"https://github.com/elixir-lang/vim-elixir"},
  {"https://github.com/avdgaag/vim-phoenix"},
  -- " Plug 'mhinz/vim-mix-format', { 'for': ['elixir', 'eelixir']} " (see https://github.com/dense-analysis/ale/pull/3106)
  -- " let g:mix_format_on_save = 1
  -- " let g:mix_format_silent_errors = 0

  {"https://github.com/lucidstack/hex.vim"},
  {"https://github.com/neoclide/jsonc.vim"},
  {"https://github.com/gerrard00/vim-mocha-only"},
  {"https://github.com/plasticboy/vim-markdown"},
  {"https://github.com/iamcco/markdown-preview.nvim"}, -- { 'do': { -> mkdp#util#install() }, 'for': ['markdown', 'vim-plug']}
  {"https://github.com/florentc/vim-tla"},
  {"https://github.com/euclidianace/betterlua.vim"},
  {"https://github.com/tjdevries/nlua.nvim"},
  {"https://github.com/andrejlevkovitch/vim-lua-format"},
  {"https://github.com/yyq123/vim-syntax-logfile"},
  {"https://github.com/jparise/vim-graphql"},

  {
    "https://github.com/plasticboy/vim-markdown",
    requires = {{"https://github.com/godlygeek/tabular"}}
  },
  {"https://github.com/jez/vim-github-hub"},
  {
    "https://github.com/fatih/vim-go",
    run = ":GoUpdateBinaries",
    opt = true,
    ft = {"go"}
  },

  {"https://github.com/sheerun/vim-polyglot"},

  -- Linters & Code quality {{{
  {"https://github.com/dense-analysis/ale"},
  {
    "https://github.com/lukas-reineke/format.nvim",
    config = function()
      require "p.format"
    end,

    -- config = function()
    --   require "format".setup {
    --     lua = {
    --       {
    --         cmd = {
    --           function(file)
    --             return string.format(
    --               "luafmt -i 2 -l %s -w replace %s",
    --               vim.bo.textwidth,
    --               file
    --             )
    --           end
    --         }
    --       }
    --     }
    --   }
    -- end
  },
  -- }}}

  -- Git {{{
  {
    "https://github.com/tpope/vim-fugitive",
    requires = {
      {"https://github.com/tpope/vim-rhubarb"}
    }
  },

  {"https://github.com/keith/gist.vim"},       --  { 'do': 'chmod -HR 0600 ~/.netrc' } " gist.vim
  {"https://github.com/wsdjeg/vim-fetch"},     -- vim path/to/file.ext:12:3
  {
    "https://github.com/rhysd/git-messenger.vim",
    opt = true,
    cmd = "GitMessenger",
    keys = "<Plug>(git-messenger)"
  },
  -- {
  --   "https://github.com/lewis6991/gitsigns.nvim",
  --   config = function()
  --     require "p.gitsigns"
  --   end,
  --   branch = 'main'
  -- }
  -- }}}

  -- Writing {{{
  {"https://github.com/junegunn/goyo.vim", opt = true, cmd = "Goyo"},
  {
    "https://github.com/junegunn/limelight.vim",
    opt = true,
    cmd = "Limelight"
  },
  -- }}}

  -- Themes, UI & styling {{{
  {
    "https://github.com/junegunn/rainbow_parentheses.vim",
    -- ft = lisps,
    cmd = "RainbowParentheses",
    -- event = "InsertEnter *",
    config = "vim.cmd[[RainbowParentheses]]"
  },
  {"https://github.com/trevordmiller/nova-vim"},
  {"https://github.com/sainnhe/gruvbox-material", opt = true},
  {"https://github.com/pbrisbin/vim-colors-off", opt = true},
  {"https://github.com/Yggdroot/indentLine", opt = true},
  {"https://github.com/dm1try/golden_size",
    config = function()
      require "p.golden_size"
    end
  }, 
  {
    "https://github.com/norcalli/nvim-colorizer.lua",
    config = function()
      require "p.colorizer"
    end
  },
  {"https://github.com/ryanoasis/vim-devicons"},

  -- {"https://github.com/andreypopp/vim-colors-plain", opt = true},
  -- {"https://github.com/liuchengxu/space-vim-theme", opt = true},
  -- {"https://github.com/rakr/vim-two-firewatch", opt = true},
  -- {"https://github.com/logico-dev/typewriter", opt = true},
  -- {"https://github.com/arzg/vim-substrata", opt = true},
  -- {"https://github.com/haishanh/night-owl.vim", opt = true},
  -- {"https://github.com/lifepillar/vim-gruvbox8", opt = true},
  -- {"https://github.com/bluz71/vim-moonfly-colors", opt = true}
}

if packer ~= nil then
  packer.init(
    {
      package_root = string.format("%s/pack", vim.fn.stdpath("config")),
      display = {
        open_cmd = "100vnew [packer]"
      }
    }
  )

  return packer.startup(
    function(use)
      for _, config in ipairs(plugins) do
        use(config)
      end
    end
  )
end

-- vim.cmd 'packadd cfilter'
-- vim.cmd 'packadd packer.nvim'

-- local init = function ()
--   use {'wbthomason/packer.nvim', opt = true}

--   -- Search
--   use {
--     'junegunn/fzf',
--     run = './install --bin'
--   }
--   use {
--     'junegunn/fzf.vim',
--     config = "require('p.fzf')"
--   }

--   -- Text Object plugins
--   use {
--     'wellle/targets.vim',
--     'tpope/vim-surround',
--     'coderifous/textobj-word-column.vim',
--     'tommcdo/vim-exchange',
--     'chaoren/vim-wordmotion'
--   }

--   -- Tim pope essentials
--   use {
--     'tpope/vim-commentary',
--     'tpope/vim-repeat',
--     'tpope/vim-sleuth'
--   }

--   -- Show indentation levels
--   use 'Yggdroot/indentLine'

--   -- For autocompletion
--   use {
--     'nvim-lua/completion-nvim',
--     config = "require('p.completion')"
--   }
--   use 'steelsojka/completion-buffers'

--   -- For tmux
--   use 'tmux-plugins/vim-tmux-focus-events'

--   -- Git support
--   use 'nvim-lua/plenary.nvim'
--   use {
--     'lewis6991/gitsigns.nvim',
--     config =  "require('p.gitsigns')",
--     branch = 'main'
--   }
--   use {
--     'rhysd/git-messenger.vim',
--     cmd = 'GitMessenger'
--   }
--   use 'rhysd/conflict-marker.vim'
--   use 'salcode/vim-interactive-rebase-reverse'
--   -- Boost vim command line mode
--   use 'vim-utils/vim-husk'
--   -- Rainbow Parentheses
--   use 'luochen1990/rainbow'

--   use {
--     'nvim-treesitter/nvim-treesitter',
--     config = "require('treesitter')",
--   }

--   -- LSP
--   use {
--     'neovim/nvim-lspconfig',
--     config = "require('lc.config')",
--   }

--   use {
--     'glepnir/galaxyline.nvim',
--     branch = 'main',
--     config = "require('p.statusline')",
--     requires = { 'kyazdani42/nvim-web-devicons' }
--   }
-- end

-- return require('packer').startup(init)
