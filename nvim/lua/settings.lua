-- Global vim options
vim.o.laststatus         = 2
vim.o.updatetime         = 100
vim.o.scrolloff          = 3
vim.o.sidescrolloff      = 5
vim.o.textwidth          = 78
vim.o.linespace          = 0
vim.o.exrc               = true
vim.o.secure             = true
vim.o.showcmd            = true
vim.o.showmatch          = true
vim.o.ruler              = true
vim.o.autoindent         = true
vim.o.errorbells         = false
vim.o.modeline           = true
vim.o.joinspaces         = false
vim.o.showmode           = false
vim.o.splitbelow         = true
vim.o.splitright         = true
vim.o.foldenable         = false
vim.o.undofile           = true
vim.o.hidden             = true
vim.o.autochdir          = false
vim.o.hlsearch           = true
vim.o.startofline        = false
vim.o.ignorecase         = true
vim.o.smartcase          = true
vim.o.magic              = true
vim.o.autoread           = true
vim.o.termguicolors      = true
vim.o.fileformat         = 'unix'
vim.o.inccommand         = 'split'
vim.o.switchbuf          = 'useopen'
vim.o.encoding           = 'utf-8'

-- Disable providers
vim.g.loaded_python3_provider = 0
vim.g.loaded_python_provider  = 0
vim.g.loaded_ruby_provider    = 0
vim.g.loaded_perl_provider    = 0
vim.g.loaded_node_provider    = 0

-- Disable built-in plugins
vim.g.loaded_netrw            = 1
vim.g.loaded_netrwPlugin      = 1
vim.g.loaded_matchparen       = 1
vim.g.loaded_matchit          = 1
vim.g.loaded_2html_plugin     = 1
vim.g.loaded_getscriptPlugin  = 1
vim.g.loaded_gzip             = 1
vim.g.loaded_logipat          = 1
vim.g.loaded_rrhelper         = 1
vim.g.loaded_spellfile_plugin = 1
vim.g.loaded_tarPlugin        = 1
vim.g.loaded_vimballPlugin    = 1
vim.g.loaded_zipPlugin        = 1

-- Map leader
vim.g.mapleader = ","
-- vim.g.maplocalleader = ","

-- Needs to be set before loading quickr-cscope
vim.g.quickr_cscope_keymaps   = 0
-- Needs to be set before vimtex gets loaded, else it complains
vim.g.tex_flavor = 'latex'
vim.g.vimtex_view_general_viewer = 'qpdfview'
vim.g.vimtex_view_general_options = '--unique \\@pdf\\#src:@tex:@line:@col'
vim.g.vimtex_view_general_options_latexmk = '--unique'
-- Needs to be before togglelist gets loadded
vim.g.toggle_list_no_mappings = 1
-- Enable rainbow brackets everywhere
vim.g.rainbow_active = 1

-- Settings using nvim.api
-- Needs to be set before vim-sneak is loaded
-- vim.api.nvim_command('let g:sneak#label = 1')
-- vim.api.nvim_command('let g:sneak#s_next = 1')
-- vim.api.nvim_command('let g:sneak#use_ic_scs = 0')
-- We do this to prevent the loading of the system fzf.vim plugin. This is
-- present at least on Arch/Manjaro
vim.api.nvim_command('set rtp-=/usr/share/vim/vimfiles')
vim.api.nvim_command('set shada="NONE"')
vim.api.nvim_command('set mouse-=a')
vim.api.nvim_command('set formatoptions+=o')
vim.api.nvim_command('set formatoptions+=j')
vim.api.nvim_command('set completeopt=menuone,noinsert,noselect')
vim.api.nvim_command('set shortmess+=c')
vim.api.nvim_command('set wildmenu')
vim.api.nvim_command('set wildmode=longest:full,full')
vim.api.nvim_command('set wildoptions=pum')
vim.api.nvim_command('set pumblend=30')
vim.api.nvim_command('set signcolumn=yes:2')
vim.api.nvim_command('set sessionoptions-=blank')
vim.api.nvim_command('set backspace=indent,eol,start')
vim.api.nvim_command('set diffopt=filler,internal,algorithm:histogram,indent-heuristic')
-- Load out custom colorscheme
vim.api.nvim_command('set background=dark')
vim.api.nvim_set_var('nova-transparent', 1)
vim.api.nvim_command('colorscheme nova')
-- Do not create any backups or swap file
vim.api.nvim_command('set nobackup')
vim.api.nvim_command('set nowritebackup')
vim.api.nvim_command('set noswapfile')
-- Blinking box cursor in (n) / blinking pipe in (i)
-- vim.api.nvim_command("set guicursor=")
-- vim.api.nvim_command('/\n:block-Cursor,')
-- vim.api.nvim_command('/\a:block-blinkon0,')
-- vim.api.nvim_command('/\i:ver25-blinkwait200-blinkoff150-blinkon200-CursorInsert,')
-- vim.api.nvim_command('/\r:blinkwait200-blinkoff150-blinkon200-CursorReplace,')
-- vim.api.nvim_command('/\v:CursorVisual,')
-- vim.api.nvim_command('/\c:ver25-blinkon300-CursorInsert')
