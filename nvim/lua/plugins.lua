vim.cmd [[ packadd paq-nvim ]]
vim.cmd [[ autocmd BufWritePost plugins.lua PaqInstall ]]
vim.cmd [[ autocmd BufWritePost plugins.lua PaqUpdate ]]
vim.cmd [[ autocmd BufWritePost plugins.lua PaqClean ]]

local Paq = require'paq-nvim'
local paq = Paq.paq
paq{'savq/paq-nvim', opt=true}

paq 'neovim/nvim-lspconfig'

paq 'nvim-lua/completion-nvim'
paq 'nvim-lua/popup.nvim'
paq 'nvim-lua/plenary.nvim'
-- paq 'nvim-lua/telescope.nvim'
paq 'nvim-lua/lsp-status.nvim'
paq 'nvim-lua/lsp_extensions.nvim'

-- paq 'nvim-treesitter/nvim-treesitter'
-- paq 'nvim-treesitter/nvim-treesitter-textobjects'
-- paq 'nvim-treesitter/completion-treesitter'
-- paq 'nvim-treesitter/nvim-treesitter-refactor'
-- paq 'nvim-treesitter/playground'

--paq 'lervag/vimtex'
--paq 'lervag/wiki.vim'
--paq 'vim-pandoc/vim-pandoc'
-- paq 'vim-pandoc/vim-pandoc-syntax'

paq 'trevordmiller/nova-vim'
--paq 'itchyny/lightline.vim'
paq 'norcalli/nvim-colorizer.lua'

paq 'dm1try/golden_size'

-- paq 'junegunn/vim-easy-align'
paq 'junegunn/fzf' -- must run -> `:call fzf#install()`
paq 'junegunn/fzf.vim'

--vim.g.fzf_action = { 'ctrl-s' = 'split', 'ctrl-v' = 'vsplit', 'enter' = 'vsplit' }
vim.g.fzf_layout = { window = { width= 0.6, height= 0.5 } }
vim.g.fzf_preview_window = {'right:50%:hidden', 'alt-p'}

--utils.gmap("n", "<Leader>m", '<cmd>Files<CR>')

paq 'Raimondi/delimitMate'
--      let delimitMate_expand_cr = 0
paq 'rstacruz/vim-closer'
paq 'tpope/vim-endwise'
paq 'tpope/vim-eunuch' --"eunuch.vim
paq 'tpope/vim-abolish'
--" https://github.com/tpope/vim-abolish/blob/master/doc/abolish.txt#L146-L162
paq 'tpope/vim-rhubarb'
paq 'tpope/vim-repeat'
paq 'tpope/vim-surround'
--" paq 'machakann/vim-sandwich'
paq 'tpope/vim-commentary'
--paq '907th/vim-auto-save'-- "auto-save.vim
paq 'rhysd/clever-f.vim' --"clever-f.vim
--" paq 'justinmk/vim-sneak'
paq 'tpope/vim-unimpaired'-- "unimpaired.vim
paq 'EinfachToll/DidYouMean' --" Vim plugin which asks for the right file to open
paq 'jordwalke/VimAutoMakeDirectory' --" auto-makes the dir for you if it doesn't exist in the path
paq 'ConradIrwin/vim-bracketed-paste' --" correctly paste in insert mode
paq 'sickill/vim-pasta' --" context-aware pasting

paq 'sheerun/vim-polyglot'

-- Paq.install()
-- Paq.update()
-- Paq.clean()

-- vim.fn['fzf#install']()

-- execute post-plugin-install scripts
-- vim.cmd [[ call fzf#install() ]]

---- Only required if you have packer in your `opt` pack
--local packer_exists = pcall(vim.cmd, [[packadd packer.nvim]])
--
--if not packer_exists then
--  if vim.fn.input("Download Packer? (y for yes)") ~= "y" then
--    return
--  end
--
--  local directory = string.format(
--    '%s/site/pack/packer/opt/',
--    vim.fn.stdpath('data')
--    )
--
--  vim.fn.mkdir(directory, 'p')
--
--  local out = vim.fn.system(string.format(
--      'git clone %s %s',
--      'https://github.com/wbthomason/packer.nvim',
--      directory .. '/packer.nvim'
--    ))
--
--  print(out)
--  print("Downloading packer.nvim...")
--
--  return
--end
--
--vim.cmd [[ packadd packer.nvim ]]
--vim.cmd [[ autocmd BufWritePost plugins.lua PackerCompile ]]
--
--return require('packer').startup(function()
--  use { 'wbthomason/packer.nvim', opt = true }
--  -- use { 'wbthomason/packer.nvim',
--  -- 	config = function()
--  --         vim.cmd [[ autocmd BufWritePost plugins.lua PackerCompile ]]
--  -- 	end
--  -- }
--
--  use {
--    'trevordmiller/nova-vim',
--    config = require('p.nova'),
--    as = 'colorscheme',
--  }
--
--  use { 'dm1try/golden_size', config = require('p.golden_size') }
--  -- use { 'norcalli/nvim-colorizer.lua', config = require('p.colorizer') }
--
--  use { 'junegunn/fzf', run = function() vim.fn['fzf#install']() end }
--  use { 'junegunn/fzf.vim' }
--  -- use {'junegunn/fzf',
--  --   run = ':call fzf#install()',
--  --   config = require('p.fzf')
--  -- }
--
--  -- use { 'junegunn/fzf.vim',
--  --   config = require('p.fzf')
--  -- }
--
--  use { 'christoomey/vim-tmux-navigator' } --, config = require'plugins.tmuxnavigator' }
--
--  use { 'tpope/vim-repeat' }
--
--  use { 'tpope/vim-surround' }
--  -- use { 'machakann/vim-sandwich'
--  use { 'tpope/vim-commentary' }
--
--  use { 'Raimondi/delimitMate' }
--  --vim.g.delimitMate_expand_cr = 0
--  use { 'tpope/vim-endwise' }
--  use { 'rstacruz/vim-closer' }
--  use { 'tpope/vim-eunuch' } 
--  use { 'tpope/vim-abolish' }
--
--  use { 'sheerun/vim-polyglot' }
--end)
