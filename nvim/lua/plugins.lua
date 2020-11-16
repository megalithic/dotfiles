-- Add the in built Cfilter plugin. Replaces QFGrep.
vim.cmd 'packadd cfilter'
vim.cmd 'packadd packer.nvim'

local init = function ()
  use {'wbthomason/packer.nvim', opt = true}

  -- Search
  use {
    'junegunn/fzf',
    run = './install --bin'
  }
  use {
    'junegunn/fzf.vim',
    config = "require('p.fzf')"
  }

  -- Text Object plugins
  use {
    'wellle/targets.vim',
    'tpope/vim-surround',
    'coderifous/textobj-word-column.vim',
    'tommcdo/vim-exchange',
    'chaoren/vim-wordmotion'
  }

  -- Tim pope essentials
  use {
    'tpope/vim-commentary',
    'tpope/vim-repeat',
    'tpope/vim-sleuth'
  }

  -- Show indentation levels
  use 'Yggdroot/indentLine'

  -- For autocompletion
  use {
    'nvim-lua/completion-nvim',
    config = "require('p.completion')"
  }
  use 'steelsojka/completion-buffers'

  -- For tmux
  use 'tmux-plugins/vim-tmux-focus-events'

  -- Git support
  use 'nvim-lua/plenary.nvim'
  use {
    'lewis6991/gitsigns.nvim',
    config =  "require('p.gitsigns')",
    branch = 'main'
  }
  use {
    'rhysd/git-messenger.vim',
    cmd = 'GitMessenger'
  }
  use 'rhysd/conflict-marker.vim'
  use 'salcode/vim-interactive-rebase-reverse'
  -- Boost vim command line mode
  use 'vim-utils/vim-husk'
  -- Rainbow Parentheses
  use 'luochen1990/rainbow'

  use {
    'nvim-treesitter/nvim-treesitter',
    config = "require('treesitter')",
  }

  -- LSP
  use {
    'neovim/nvim-lspconfig',
    config = "require('lc.config')",
  }

  use {
    'glepnir/galaxyline.nvim',
    branch = 'main',
    config = "require('p.statusline')",
    requires = { 'kyazdani42/nvim-web-devicons' }
  }
end

return require('packer').startup(init)
