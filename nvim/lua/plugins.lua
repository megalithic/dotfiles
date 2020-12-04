vim.cmd [[ packadd packer.nvim ]]

vim.cmd [[ autocmd BufWritePost plugins.lua PackerCompile ]]

return require('packer').startup(function()
    use { 'wbthomason/packer.nvim', opt = true }

    use {
      'trevordmiller/nova-vim',
      config = require('p.nova'),
      as = 'colorscheme',
   }
   use { 'dm1try/golden_size', config = require('p.golden_size') }
   use { 'norcalli/nvim-colorizer.lua', config = require('p.colorizer') }

   use { 'junegunn/fzf', run = function() vim.fn['fzf#install']() end }
   use { 'junegunn/fzf.vim' }

   use { 'christoomey/vim-tmux-navigator' } --, config = require'plugins.tmuxnavigator' }

   use { 'sheerun/vim-polyglot' }
end)
