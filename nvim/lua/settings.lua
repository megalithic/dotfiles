-- [ settings.. ] --------------------------------------------------------------

vim.cmd('filetype plugin indent on')
vim.cmd('syntax on')

-- vim.cmd("runtime vimrc")

vim.g.mapleader = ","
vim.g.maplocalleader = ","

-- presently working ->
-- vim.o.autowrite     = true
-- vim.o.cedit         = "<C-R>"  -- open command line window
-- vim.o.clipboard     = "unnamedplus"
-- vim.o.cmdheight     = 1
-- vim.o.colorcolumn   = '+0'
-- vim.o.completeopt   = "menuone,noinsert,noselect"
-- vim.o.cursorline    = false
-- vim.o.fileencodings = "utf-8,gbk,ucs-bom,cp936,gb18030,big5,latin1"
-- vim.o.foldlevel     = 99
-- vim.o.hidden        = true
-- vim.o.ignorecase    = true
-- vim.o.laststatus    = 2
-- vim.o.modeline      = true
-- vim.o.modelines     = 3
-- vim.o.mouse         = "a"
-- vim.o.previewheight = 8
-- vim.o.shortmess     = "filnxtToOFc"
-- vim.o.smartcase     = true
-- vim.o.splitbelow    = true
-- vim.o.statusline    = "%t %h%w%m%r %=%(%l,%c%V %= %P%)"
-- vim.o.termguicolors = false
-- vim.o.termguicolors = true
-- vim.o.updatetime    = 300


-- presently untested ->
vim.o.autoindent=true        -- Indented text
vim.o.autoread=true          -- Pick up external changes to files
vim.o.autowrite=true         -- Write files when navigating with :next/:previous
vim.o.backspace="indent,eol,start"
vim.o.belloff="all"       -- Bells are annoying
vim.o.breakindent=true       -- Wrap long lines *with* indentation
vim.o.breakindentopt="shift:2"
-- if empty($SSH_CONNECTION) && has('clipboard')
--   vim.o.clipboard=unnamed  -- Use clipboard register

--   -- Share X windows clipboard. NOT ON NEOVIM -- neovim automatically uses
--   -- system clipboard when xclip/xsel/pbcopy are available.
--   if has('nvim') && !has('mac')
--     vim.o.clipboard=unnamedplus
--   elseif has('unnamedplus')
--     vim.o.clipboard+=unnamedplus
--   endif
-- endif
vim.o.clipboard="unnamedplus"
vim.o.colorcolumn=81 -- Highlight 81 and 82 columns
vim.o.conceallevel=2
vim.o.complete=".,w,b"    -- Sources for term and line completions
vim.o.completeopt="menuone,noinsert,noselect" -- Don't auto select first one
vim.o.dictionary="/usr/share/dict/words"
vim.o.spellfile="$HOME/.dotfiles/nvim/spell/en.utf-8.add"
vim.o.spelllang="en"
vim.o.expandtab = true        -- Use spaces instead of tabs
vim.o.foldlevelstart=20
vim.o.foldmethod="indent" -- Simple and fast
vim.o.foldtext=""
vim.o.formatoptions="cqj" -- Default format options
vim.o.gdefault=true          -- Always do global substitutes
vim.o.history=200       -- Keep 200 changes of undo history
vim.o.infercase=true         -- Smart casing when completing
vim.o.ignorecase=true        -- Search in case-insensitively
vim.o.incsearch=true         -- Go to search results immediately
vim.o.laststatus=2      -- We want a statusline
vim.o.linespace=0       -- Line height of things like, the statusline
vim.o.cmdheight=1
vim.o.lazyredraw=true        -- should make scrolling faster
vim.o.matchpairs="(:),{:},[:],<:>"
-- vim.o.matchpairs+=<:>             -- Match, to be used with %
-- try
--   vim.o.matchpairs+=《:》,〈:〉,［:］,（:）,「:」,『:』,‘:’,“:”
-- catch /^Vim\%((\a\+)\)\=:E474
-- endtry
vim.o.mouse="nva"         -- Mouse support in different modes
vim.o.mousemodel="popup"  -- Set the behaviour of mouse
vim.o.mousehide=true         -- Hide mouse when typing text
vim.o.nobackup=true          -- No backup files
vim.o.nocompatible=true      -- No Vi support
vim.o.noemoji=true           -- don't assume all emoji are double width (@wincent)
vim.o.noexrc=true            -- Disable reading of working directory vimrc files
vim.o.nohlsearch=true        -- Don't highlight search results by default
vim.o.nojoinspaces=true      -- No to double-spaces when joining lines
vim.o.noshowcmd=true         -- No to showing command in bottom-right corner
vim.o.noshowmatch=true       -- No jumping jumping cursors when matching pairs
vim.o.noshowmode=true        -- No to showing mode in bottom-left corner
vim.o.noswapfile=true        -- No backup files
-- vim.o.nowrapscan        -- Don't wrap searches around
-- vim.o.number            -- Show line numbers
vim.o.nrformats="alpha,hex,octal"        -- No to oct/hex support when doing CTRL-a/x
-- vim.o.path=**
-- vim.o.relativenumber    -- Show relative numbers
vim.o.ruler=true
-- vim.o.scrolloff=5       -- Start scrolling when we're 5 lines away from margins
vim.o.shiftwidth=2
-- vim.o.shortmess+=c                          -- Don't show insert mode completion messages
vim.o.sidescrolloff=15
vim.o.sidescroll=5
vim.o.showbreak="↳"      -- Use this to wrap long lines
vim.o.smartcase  =true       -- Case-smart searching
vim.o.smarttab=true
vim.o.splitbelow=true        -- Split below current window
vim.o.splitright =true       -- Split window to the right
vim.o.synmaxcol=500     -- Syntax highlight first 500 chars, for performance
vim.o.t_Co=256          -- 256 color support
vim.o.tabstop=2
-- if has("termguicolors")
--   vim.o.termguicolors -- Enable 24-bit color support if available
-- endif
vim.o.textwidth=80
vim.o.timeoutlen=1500   -- Give some time for multi-key mappings
-- Don't set ttimeoutlen to zero otherwise it will break terminal cursor block
-- to I-beam and back functionality set by the t_SI and t_EI variables.
vim.o.ttimeoutlen=10
vim.o.ttyfast=true
-- Set the persistent undo directory on temporary private fast storage.
-- let s:undoDir="/tmp/.undodir_" . $USER
-- if !isdirectory(s:undoDir)
--   call mkdir(s:undoDir, "", 0700)
-- endif
-- let &undodir=s:undoDir
vim.o.undofile=true          -- Maintain undo history
vim.o.updatetime=100    -- Make async plugin more responsive
vim.o.viminfo=false          -- No backups
vim.o.wildcharm="<Tab>"   -- Defines the trigger for 'wildmenu' in mappings
vim.o.wildmenu =true         -- Nice command completions
vim.o.wildmode="full"
-- vim.o.wildignore+=*.o,*.obj,*.bin,*.dll,*.exe
-- vim.o.wildignore+=*/.git/*,*/.svn/*,*/__pycache__/*,*/build/**
-- vim.o.wildignore+=*.pyc
-- vim.o.wildignore+=*.DS_Store
-- vim.o.wildignore+=*.aux,*.bbl,*.blg,*.brf,*.fls,*.fdb_latexmk,*.synctex.gz
vim.o.wrap =true             -- Wrap long lines

  vim.o.diffopt="filler,internal,algorithm:histogram,indent-heuristic"
  vim.o.inccommand="nosplit"
  vim.o.list=true
  -- vim.o.listchars=tab:\ \ ,trail:-
  vim.o.listchars="tab:\ \ ,trail:·"
  -- vim.o.listchars=tab:»·,trail:·
  -- vim.o.listchars=tab:▸\ ,eol:¬,extends:›,precedes:‹,trail:·,nbsp:⚋
  -- vim.o.listchars=tab:»\ ,eol:¬,extends:›,precedes:‹,trail:·,nbsp:⚋
  -- vim.o.listchars=tab:»\ ,extends:›,precedes:‹,trail:·,nbsp:⚋
  -- vim.o.pumblend=10
  vim.o.pumheight=20      -- Height of complete list
  vim.o.signcolumn="yes:2"  -- always showsigncolumn
  vim.o.switchbuf="useopen,vsplit,split,usetab"
  -- vim.o.wildoptions+=pum
  vim.o.wildoptions="pum"
  -- vim.o.winblend=10
  vim.o.jumpoptions="stack"

  -- vim.o.guicursor=
  --       \n:block-Cursor,
  --       \a:block-blinkon0,
  --       \i:ver25-blinkwait200-blinkoff150-blinkon200-CursorInsert,
  --       \r:blinkwait200-blinkoff150-blinkon200-CursorReplace,
  --       \v:CursorVisual,
  --       \c:ver25-blinkon300-CursorInsert

  -- -- Set cursor shape based on mode (:h termcap-cursor-shape)
  -- -- Vertical bar in insert mode
  -- let &t_SI = "\e[6 q"
  -- -- Underline in replace mode
  -- let &t_SR = "\e[4 q"
  -- -- Block in normal mode
  -- let &t_EI = "\e[2 q"

  -- let $VISUAL      = 'nvr -cc split --remote-wait +"setlocal bufhidden=delete"'
  -- let $GIT_EDITOR  = 'nvr -cc split --remote-wait +"setlocal bufhidden=delete"'
  -- let $EDITOR      = 'nvr -l'
  -- let $ECTO_EDITOR = 'nvr -l'

  -- let g:python_host_prog = '~/.asdf/shims/python'
  -- let g:python3_host_prog = '~/.asdf/shims/python3'

  -- share data between nvim instances (registers etc)
  -- augroup SHADA
  --   autocmd!
  --   autocmd CursorHold,TextYankPost,FocusGained,FocusLost *
  --         \ if exists(':rshada') | rshada | wshada | endif
  -- augroup END

-- cmd("scriptencoding utf-16")
-- cmd("syntax on")
-- cmd("filetype plugin indent on")

-- go.compatible = false
-- go.encoding = 'UTF-8'
-- go.termguicolors = true
-- go.background = 'dark'

-- go.hidden = true
-- go.timeoutlen = 500
-- go.updatetime = 100
-- go.ttyfast = true
-- go.scrolloff = 8

-- go.showcmd = true
-- go.wildmenu = true

-- wo.number = true
-- wo.numberwidth = 6
-- wo.relativenumber = true
-- wo.signcolumn = "yes"
-- wo.cursorline = true

-- go.expandtab = true
-- go.smarttab = true
-- go.tabstop = 4
-- go.cindent = true
-- go.shiftwidth = 4
-- go.softtabstop = 4
-- go.autoindent = true
-- go.clipboard = "unnamedplus"

-- wo.wrap = true
-- bo.textwidth = 300
-- bo.formatoptions = "qrn1"

-- go.hlsearch = true
-- go.ignorecase = true
-- go.smartcase = true

-- go.backup = false
-- go.writebackup = false
-- go.undofile = true
-- go.backupdir = "/tmp/"
-- go.directory = "/tmp/"
-- go.undodir = "/tmp/"

-- -- Map <leader> to space
-- U.map("n", "<SPACE>", "<Nop>")
-- g.mapleader = ","


-- [ disable some built-ins ] --------------------------------------------------

vim.g.loaded_tutor_mode_plugin = 1
vim.g.loaded_gzip              = 1
vim.g.loaded_tar               = 1
vim.g.loaded_tarPlugin         = 1
vim.g.loaded_zip               = 1
vim.g.loaded_zipPlugin         = 1
vim.g.loaded_getscript         = 1
vim.g.loaded_getscriptPlugin   = 1
vim.g.loaded_vimball           = 1
vim.g.loaded_vimballPlugin     = 1
vim.g.loaded_matchit           = 1
vim.g.loaded_matchparen        = 1
vim.g.loaded_2html_plugin      = 1
vim.g.loaded_logiPat           = 1
vim.g.loaded_rrhelper          = 1
vim.g.loaded_netrw             = 1
vim.g.loaded_netrwPlugin       = 1
vim.g.loaded_netrwSettings     = 1
vim.g.loaded_netrwFileHandlers = 1

-- -- For highlighting yanked region
-- cmd('au TextYankPost * silent! lua vim.highlight.on_yank({ higroup = "HighlightedyankRegion", timeout = 120 })')
