local execute, fn = vim.api.nvim_command, vim.fn
local packer_install_path = fn.stdpath('data')..'/site/pack/packer/opt/packer.nvim'
local packer_exists = pcall(vim.cmd, [[packadd packer.nvim]])

if fn.empty(fn.glob(packer_install_path)) > 0 then
    print("packer.nvim is NOT installed -> installing...")
    execute('!git clone https://github.com/wbthomason/packer.nvim ' .. packer_install_path)
end

-- execute('packadd packer.nvim')
vim.cmd([[packadd packer.nvim]])
vim.cmd([[autocmd BufWritePost plugins.lua PackerCompile]])

local packer = require('packer')

return packer.startup({
        function(use)
            -- (packer) --
            use {'wbthomason/packer.nvim', opt=true,
                config = function()
                    print("pre PackerComiple")
                  mg.autocmd("BufWritePost plugins.lua PackerCompile")
                print("post PackerComiple")
                end
            }

            -- (lsp/completion/snippets/diagnostics) --
            use {'nvim-lua/completion-nvim', opt=true}
            use {'steelsojka/completion-buffers', after='completion-nvim', opt=true}
            use {'hrsh7th/vim-vsnip', opt=true}
            use {'hrsh7th/vim-vsnip-integ', after='vim-vsnip', opt=true}
            use {'neovim/nvim-lspconfig', opt=true}
            -- use 'nvim-lua/popup.nvim'
            -- use 'nvim-lua/plenary.nvim'
            -- -- use 'nvim-lua/telescope.nvim'
            -- use 'nvim-lua/lsp-status.nvim'
            -- use 'nvim-lua/lsp_extensions.nvim'

            -- -- (ui) --
            use {'trevordmiller/nova-vim', config = function()
                vim.o.background = 'dark'
                vim.cmd([[ colorscheme nova ]])
            end}
            use 'norcalli/nvim-colorizer.lua'
            use 'dm1try/golden_size'
            use 'ryanoasis/vim-devicons'
            use 'junegunn/rainbow_parentheses.vim'

            -- (file navigatgion) --
            use {'junegunn/fzf', 
                run = function() vim.fn['fzf#install']() end, 
                config = function() 
                    vim.g.fzf_layout = { window = { width= 0.6, height= 0.5 } }
                    -- vim.g.fzf_action = { 'ctrl-s' = 'split', 'ctrl-v' = 'vsplit', 'enter' = 'vsplit' }
                    vim.g.fzf_preview_window = {'right:50%:hidden', 'alt-p'}
                end
            }
            use {'junegunn/fzf.vim', 
                config = function() 
                    mg.map('n', '<Leader>m', '<cmd>Files<CR>')
                end
            }
            use 'rhysd/clever-f.vim' 

            -- (text objects) --
            use{'tpope/vim-rsi'}
            use{'kana/vim-operator-user'}
            -- -- provide ai and ii for indent blocks
            -- -- provide al and il for current line
            -- -- provide a_ and i_ for underscores
            -- -- provide a- and i-
            use{'kana/vim-textobj-user'}                                            -- https://github.com/kana/vim-textobj-user/wiki
            -- use{'kana/vim-textobj-function'}                                        -- function text object (af/if)
            use{'kana/vim-textobj-indent'}                                          -- for indent level (ai/ii)
            use{'kana/vim-textobj-line'}                                            -- for current line (al/il)
            use{'nelstrom/vim-textobj-rubyblock'}              -- ruby block text object (ar/ir)
            use{'andyl/vim-textobj-elixir'}                                         -- elixir block text object (ae/ie)
                  -- let g:vim_textobj_elixir_mapping = 'E'
            use{'glts/vim-textobj-comment'}                                        -- comment text object (ac/ic)
            use{'michaeljsmith/vim-indent-object'}
            use{'machakann/vim-textobj-delimited'}                                  -- - d/D   for underscore section (e.g. `did` on foo_b|ar_baz -> foo__baz)
            use{'gilligan/textobj-lastpaste'}                                       -- - P     for last paste
            use{'mattn/vim-textobj-url'}                                            -- - u     for url
            use{'rhysd/vim-textobj-anyblock'}                                       -- - '', \"\", (), {}, [], <>
            use{'arthurxavierx/vim-caser'}                                          -- https://github.com/arthurxavierx/vim-caser#usage
            use{'Julian/vim-textobj-variable-segment'}                              -- variable parts (av/iv)
            use{'sgur/vim-textobj-parameter'}                                       -- function parameters (a,/i,)
                  -- let g:vim_textobj_parameter_mapping = ','
            use{'wellle/targets.vim'}                                               -- improved targets line cin) next parens) https://github.com/wellle/targets.vim/blob/master/cheatsheet.md

            -- (the rest..) --
            use {'Raimondi/delimitMate', config = function() vim.g.delimitMate_expand_cr = 0 end}
            use 'tpope/vim-endwise'
            use {'rstacruz/vim-closer', after='vim-endwise'}
            use 'tpope/vim-eunuch' 
            use 'tpope/vim-abolish'
            use 'tpope/vim-rhubarb'
            use 'tpope/vim-repeat'
            use 'tpope/vim-surround'
            use {'tpope/vim-commentary', 
                config = function()
                    mg.map('n', '<Leader>c', '<cmd>Commentary<CR>')
                    mg.map('x', '<Leader>c', '<cmd>Commentary<CR>')
                end
            }
            use 'tpope/vim-unimpaired'
            use 'EinfachToll/DidYouMean' 
            use 'jordwalke/VimAutoMakeDirectory' 
            use 'ConradIrwin/vim-bracketed-paste' 
            use 'sickill/vim-pasta' 

            -- (langs) --
            use 'sheerun/vim-polyglot'
        end
    })

-- local paq_install_path = fn.stdpath('data')..'/site/pack/paq/opt/paq-nvim'
-- if fn.empty(fn.glob(paq_install_path)) > 0 then
--     print "paq-nvim is NOT installed -> installing..."
--     execute('!git clone https://github.com/savq/paq-nvim.git ' .. paq_install_path)
-- end
--
-- execute 'packadd paq-nvim'
--
-- cmd [[ autocmd BufWritePost plugins.lua silent PaqClean ]]
-- cmd [[ autocmd BufWritePost plugins.lua silent PaqUpdate ]]
-- cmd [[ autocmd BufWritePost plugins.lua silent PaqInstall ]]

-- local Paq = require('paq-nvim')
-- local paq = Paq.paq

-- paq{'savq/paq-nvim', opt=true}

-- -- (lsp/completion/diagnostics) --
-- paq 'neovim/nvim-lspconfig'
-- paq 'nvim-lua/completion-nvim'
-- paq 'nvim-lua/popup.nvim'
-- paq 'nvim-lua/plenary.nvim'
-- -- paq 'nvim-lua/telescope.nvim'
-- paq 'nvim-lua/lsp-status.nvim'
-- paq 'nvim-lua/lsp_extensions.nvim'

-- -- paq 'nvim-treesitter/nvim-treesitter'
-- -- paq 'nvim-treesitter/nvim-treesitter-textobjects'
-- -- paq 'nvim-treesitter/completion-treesitter'
-- -- paq 'nvim-treesitter/nvim-treesitter-refactor'
-- -- paq 'nvim-treesitter/playground'

-- -- (ui) --
-- paq 'trevordmiller/nova-vim'
-- paq 'norcalli/nvim-colorizer.lua'
-- paq 'dm1try/golden_size'

-- -- (file navigatgion) --
-- paq 'junegunn/fzf' -- must run -> `:call fzf#install()`
-- paq 'junegunn/fzf.vim'
-- paq 'rhysd/clever-f.vim' 

-- -- (the rest..) --
-- paq 'Raimondi/delimitMate'
-- paq 'rstacruz/vim-closer'
-- paq 'tpope/vim-endwise'
-- paq 'tpope/vim-eunuch' 
-- paq 'tpope/vim-abolish'
-- paq 'tpope/vim-rhubarb'
-- paq 'tpope/vim-repeat'
-- paq 'tpope/vim-surround'
-- paq 'tpope/vim-commentary'
-- paq 'tpope/vim-unimpaired'
-- paq 'EinfachToll/DidYouMean' 
-- paq 'jordwalke/VimAutoMakeDirectory' 
-- paq 'ConradIrwin/vim-bracketed-paste' 
-- paq 'sickill/vim-pasta' 

-- -- (langs) --
-- paq 'sheerun/vim-polyglot'

-- -- Paq.install()
-- -- Paq.update()
-- -- Paq.clean()
