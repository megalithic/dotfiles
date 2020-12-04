-- Only required if you have packer in your `opt` pack
local packer_exists = pcall(vim.cmd, [[packadd packer.nvim]])

if not packer_exists then
  if vim.fn.input("Download Packer? (y for yes)") ~= "y" then
    return
  end

  local directory = string.format(
    '%s/site/pack/packer/opt/',
    vim.fn.stdpath('data')
  )

  vim.fn.mkdir(directory, 'p')

  local out = vim.fn.system(string.format(
    'git clone %s %s',
    'https://github.com/wbthomason/packer.nvim',
    directory .. '/packer.nvim'
  ))

  print(out)
  print("Downloading packer.nvim...")

  return
end

vim.cmd [[ packadd packer.nvim ]]
vim.cmd [[ autocmd BufWritePost plugins.lua PackerCompile ]]

return require('packer').startup(function()
    use { 'wbthomason/packer.nvim', opt = true }
    -- use { 'wbthomason/packer.nvim',
	-- 	config = function()
    --         vim.cmd [[ autocmd BufWritePost plugins.lua PackerCompile ]]
	-- 	end
	-- }

    use {
      'trevordmiller/nova-vim',
      config = require('p.nova'),
      as = 'colorscheme',
   }
   use { 'dm1try/golden_size', config = require('p.golden_size') }
   -- use { 'norcalli/nvim-colorizer.lua', config = require('p.colorizer') }

   use { 'junegunn/fzf', run = function() vim.fn['fzf#install']() end }
   use { 'junegunn/fzf.vim' }

   use { 'christoomey/vim-tmux-navigator' } --, config = require'plugins.tmuxnavigator' }

   use { 'sheerun/vim-polyglot' }
end)
