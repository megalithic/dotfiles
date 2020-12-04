local execute, fn, cmd, go = vim.api.nvim_command, vim.fn, vim.cmd, vim.o
local install_path = fn.stdpath('data')..'/site/pack/paqs/opt/paq-nvim'

if fn.empty(fn.glob(install_path)) > 0 then
    print "paq-nvim is NOT installed.."
    execute('!git clone https://github.com/savq/paq-nvim.git '..install_path)
    execute 'packadd paq-nvim'
else
    -- print "paq-nvim is installed.."
end

cmd [[ packadd paq-nvim ]]
-- cmd [[ autocmd BufWritePost plugins.lua PaqClean | PaqInstall | PaqUpdate ]]
-- cmd [[ autocmd BufWritePost plugins.lua PaqClean | PaqInstall | PaqUpdate ]]
cmd [[ autocmd BufWritePost plugins.lua silent PaqClean ]]
cmd [[ autocmd BufWritePost plugins.lua silent PaqUpdate ]]
cmd [[ autocmd BufWritePost plugins.lua silent PaqInstall ]]

local Paq = require'paq-nvim'
local paq = Paq.paq

paq{'savq/paq-nvim', opt=true}

-- (lsp/completion/diagnostics) --
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

-- (ui) --
paq 'trevordmiller/nova-vim'
paq 'norcalli/nvim-colorizer.lua'
paq 'dm1try/golden_size'

-- (file navigatgion) --
paq 'junegunn/fzf' -- must run -> `:call fzf#install()`
paq 'junegunn/fzf.vim'
paq 'rhysd/clever-f.vim' 

-- (the rest..) --
paq 'Raimondi/delimitMate'
paq 'rstacruz/vim-closer'
paq 'tpope/vim-endwise'
paq 'tpope/vim-eunuch' 
paq 'tpope/vim-abolish'
paq 'tpope/vim-rhubarb'
paq 'tpope/vim-repeat'
paq 'tpope/vim-surround'
paq 'tpope/vim-commentary'
paq 'tpope/vim-unimpaired'
paq 'EinfachToll/DidYouMean' 
paq 'jordwalke/VimAutoMakeDirectory' 
paq 'ConradIrwin/vim-bracketed-paste' 
paq 'sickill/vim-pasta' 

-- (langs) --
paq 'sheerun/vim-polyglot'

-- Paq.install()
-- Paq.update()
-- Paq.clean()
