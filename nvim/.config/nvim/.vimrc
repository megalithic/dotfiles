" -- [ mappings ] --------------------------------------------------------------

let mapleader = ','
let maplocalleader = " "

" noremap ; :

" -- ( overrides ) --
" Help
noremap <C-]> K

" Copy to system clipboard
noremap Y y$

" Better buffer navigation
"noremap J }
"noremap K {
noremap H ^
noremap L $
vnoremap L g_

" Start search on current word under the cursor
nnoremap <leader>/ /<CR>

" Start reverse search on current word under the cursor
nnoremap <leader>? ?<CR>

" Faster sort
vnoremap <leader>S :!sort<CR>

" Command mode conveniences
noremap <leader>: :!
noremap <leader>; :<Up>

" Remap VIM 0 to first non-blank character
map 0 ^

" ## Selections
" reselect pasted content:
nnoremap gV `[v`]
" select all text in the file
nnoremap <leader>v ggVG
" Easier linewise reselection of what you just pasted.
nnoremap <leader>V V`]
" gi already moves to 'last place you exited insert mode', so we'll map gI to
" something similar: move to last change
nnoremap gI `.
" reselect visually selected content:
xnoremap > >gv

" ## Indentions
" Indent/dedent/autoindent what you just pasted.
nnoremap <lt>> V`]<
nnoremap ><lt> V`]>
nnoremap =- V`]=

" Don't overwrite blackhole register with selection
" https://www.reddit.com/r/vim/comments/clccy4/pasting_when_selection_touches_eol/
xnoremap p "_c<c-r>"<esc>
xmap P p

" Better window navigation
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

" Better save and quit
silent! unmap <leader>w
nnoremap <silent><leader>w :w<CR>
nnoremap <silent><leader>W :w !sudo -S tee > /dev/null %<CR>
cmap w!! w !sudo tee > /dev/null %
nnoremap <leader>q :q<CR>

" open a (new)file in a new vsplit
" nnoremap <silent><leader>o :vnew<CR>:e<space><C-d>
" nnoremap <leader>o :vnew<CR>:e<space>

" Background (n)vim
vnoremap <C-z> <ESC>zv`<ztgv

" Default to case insensitive search
nnoremap / /\v
vnoremap / /\v

" always paste from 0 register to avoid pasting deleted text (from r/vim)
xnoremap <silent> p p:let @"=@0<CR>


function! Show_position()
  return ":\<c-u>echo 'start=" . string(getpos("v")) . " end=" . string(getpos(".")) . "'\<cr>gv"
endfunction
vmap <expr> <leader>P Show_position()

" flip between two last edited files/alternate/buffer
" nnoremap <Leader><Leader> <C-^>

" Don't overwrite blackhole register with selection
" https://www.reddit.com/r/vim/comments/clccy4/pasting_when_selection_touches_eol/
" xnoremap p "_c<c-r>"<esc>
" xmap P p

vnoremap <C-r> "hy:%Subvert/<C-r>h//gc<left><left><left>

" clear incsearch term
nnoremap <silent><ESC> :syntax sync fromstart<CR>:nohlsearch<CR>:redrawstatus!<CR><ESC>

" REF: https://github.com/savq/dotfiles/blob/master/nvim/init.lua#L90-L101
"      https://github.com/neovim/neovim/issues/4495#issuecomment-207825278
" nnoremap z= :setlocal spell<CR>z=

" -- [ options ] ---------------------------------------------------------------
set autoindent        " Indented text
set autoread          " Pick up external changes to files
set autowrite         " Write files when navigating with :next/:previous
set backspace=indent,eol,start
set belloff=all       " Bells are annoying
set breakindent       " Wrap long lines *with* indentation
set breakindentopt=shift:2

if empty($SSH_CONNECTION) && has('clipboard')
  set clipboard=unnamed  " Use clipboard register

  " Share X windows clipboard. NOT ON NEOVIM -- neovim automatically uses
  " system clipboard when xclip/xsel/pbcopy/lemonade are available.
  if has('nvim') && !has('mac')
    set clipboard=unnamedplus
  elseif has('unnamedplus')
    set clipboard+=unnamedplus
  endif
else
  " for linux
  set clipboard+=unnamedplus
endif

set colorcolumn=81 " Highlight column 81
set conceallevel=2
set complete=.,w,b    " Sources for term and line completions
set completeopt=menuone,noinsert,noselect " Don't auto select first one
" set nocursorcolumn
set cursorline
set dictionary=/usr/share/dict/words
set spellfile=$HOME/.dotfiles/nvim/.config/nvim/spell/en.utf-8.add
set spelllang=en
set nospell
set expandtab         " Use spaces instead of tabs
set foldlevelstart=20
set foldmethod=indent " Simple and fast
set foldtext=""
set formatoptions=cqj " Default format options
set gdefault          " Always do global substitutes
set history=200       " Keep 200 changes of undo history
set infercase         " Smart casing when completing
set ignorecase        " Search in case-insensitively
set incsearch         " Go to search results immediately
set laststatus=2      " We want a statusline
set linespace=0       " Line height of things like, the statusline
set cmdheight=1
set lazyredraw        " should make scrolling faster
set matchpairs=(:),{:},[:]
set matchpairs+=<:>             " Match, to be used with %
" try
  set matchpairs+=《:》,〈:〉,［:］,（:）,「:」,『:』,‘:’,“:”
" catch /^Vim\%((\a\+)\)\=:E474
" endtry
set mouse=nva         " Mouse support in different modes
set mousemodel=popup  " Set the behaviour of mouse
set mousehide         " Hide mouse when typing text
set nobackup          " No backup files
set nocompatible      " No Vi support
set noemoji           " don't assume all emoji are double width (@wincent)
set noexrc            " Disable reading of working directory vimrc files
set hlsearch        " Don't highlight search results by default
set nojoinspaces      " No to double-spaces when joining lines
set noshowcmd         " No to showing command in bottom-right corner
set noshowmatch       " No jumping jumping cursors when matching pairs
set noshowmode        " No to showing mode in bottom-left corner
set noswapfile        " No backup files
" set nowrapscan        " Don't wrap searches around
set number            " Show line numbers
set nrformats=alpha,hex,octal        " No to oct/hex support when doing CTRL-a/x
set path=**
" set relativenumber    " Show relative numbers
set ruler
" set scrolloff=5       " Start scrolling when we're 5 lines away from margins
set shiftwidth=2
set shortmess+=c                          " Don't show insert mode completion messages
set sidescrolloff=15
set sidescroll=5
set showbreak=↳       " Use this to wrap long lines
set smartcase         " Case-smart searching
set smarttab
set splitbelow        " Split below current window
set splitright        " Split window to the right
set synmaxcol=500     " Syntax highlight first 500 chars, for performance
set t_Co=256          " 256 color support
set tabstop=2
if has("termguicolors")
  set termguicolors " Enable 24-bit color support if available
endif
set textwidth=80
set timeoutlen=1500   " Give some time for multi-key mappings
" Don't set ttimeoutlen to zero otherwise it will break terminal cursor block
" to I-beam and back functionality set by the t_SI and t_EI variables.
set ttimeoutlen=10
set ttyfast
" Set the persistent undo directory on temporary private fast storage.
let s:undoDir=$HOME . "/.cache/nvim/undo"
if !isdirectory(s:undoDir)
  call mkdir(s:undoDir, "", 0700)
endif
let &undodir=s:undoDir
set undofile          " Maintain undo history
set undolevels=1000   " How many undos
set undoreload=10000  " number of lines to save for undo
set updatetime=100    " Make async plugin more responsive
set viminfo=          " No backups
set wildcharm=<Tab>   " Defines the trigger for 'wildmenu' in mappings
set wildmenu          " Nice command completions
set wildmode=full
set wildmode=longest:full,full
set wildignore+=*.o,*.obj,*.bin,*.dll,*.exe
set wildignore+=*/.git/*,*/.svn/*,*/__pycache__/*,*/build/**
set wildignore+=*.pyc
set wildignore+=*.DS_Store
set wildignore+=*.aux,*.bbl,*.blg,*.brf,*.fls,*.fdb_latexmk,*.synctex.gz
set wrap              " Wrap long lines

" Options specific to Neovim or Vim.
if has("nvim")
  set diffopt=filler,internal,algorithm:histogram,indent-heuristic
  set inccommand=nosplit
  set list
  " set listchars=tab:\ \ ,trail:-
  set listchars=tab:\ \ ,trail:·
  " set listchars=tab:»·,trail:·
  " set listchars=tab:▸\ ,eol:¬,extends:›,precedes:‹,trail:·,nbsp:⚋
  " set listchars=tab:»\ ,eol:¬,extends:›,precedes:‹,trail:·,nbsp:⚋
  " set listchars=tab:»\ ,extends:›,precedes:‹,trail:·,nbsp:⚋
  " set pumblend=10
  set pumheight=20      " Height of complete list
  set signcolumn=yes    " always showsigncolumn
  set switchbuf=useopen,vsplit,split,usetab
  set wildoptions+=pum
  " set winblend=10
  set winminwidth=15
  set jumpoptions=stack
  set cursorlineopt=number
  set guicursor=n-v-c:block,i-ci-ve:ver25,r-cr:hor20,o:hor50
        \,a:blinkwait700-blinkoff400-blinkon250-Cursor/lCursor
        \,sm:block-blinkwait175-blinkoff150-blinkon175

  " Set cursor shape based on mode (:h termcap-cursor-shape)
  " Vertical bar in insert mode
  let &t_SI = "\e[6 q"
  " Underline in replace mode
  let &t_SR = "\e[4 q"
  " Block in normal mode
  let &t_EI = "\e[2 q"

  " Inform vim how to enable undercurl in wezterm
  let &t_Cs = "\e[60m"
  " Inform vim how to disable undercurl in wezterm (this disables all underline modes)
  let &t_Ce = "\e[24m"

  " supposed to be undercurl things?
  let &t_Cs = "\e[4:3m"
  let &t_Ce = "\e[4:0m"

  let $VISUAL      = 'nvr -cc split --remote-wait +"setlocal bufhidden=delete"'
  " let $GIT_EDITOR  = 'nvr -cc split --remote-wait +"setlocal bufhidden=delete"'
  let $EDITOR      = 'nvr -l'
  let $ECTO_EDITOR = 'nvr -l'
  let $TERM        = 'xterm-kitty'

  let g:python_host_prog = '~/.asdf/shims/python'
  let g:python3_host_prog = '~/.asdf/shims/python3'

  " share data between nvim instances (registers etc)
  augroup SHADA
    autocmd!
    autocmd CursorHold,TextYankPost,FocusGained,FocusLost *
          \ if exists(':rshada') | rshada | wshada | endif
  augroup END
else
  set emoji                 " treat emojis 😄 as full width characters
  set cryptmethod=blowfish2
  set listchars=eol:$,tab:>-,trail:-
  set ttymouse=xterm2
endif

""" Vim 8
if !has('nvim')
    syntax enable
    set ruler
    set showcmd
    set autoread
    set wildmenu
    set hlsearch
    set incsearch
    set autoindent
    set foldmethod=indent
endif

""" Netrw
let g:netrw_banner = 0        " no banner
let g:netrw_liststyle = 3     " tree style listing
let g:netrw_dirhistmax = 0    " no netrw history

" Disable unnecessary internal plugins
" let g:loaded_netrw        = 1
let g:loaded_netrwPlugin  = 1
let g:loaded_2html_plugin = 1
let g:loaded_gzip         = 1
let g:loaded_gzip         = 1
let g:loaded_matchit      = 1
let g:loaded_matchparen   = 1
let g:loaded_remote_plugins = 1
let g:loaded_spec         = 1
let g:loaded_spellfile_plugin = 1
let g:loaded_tar          = 1
let g:loaded_tarPlugin    = 1
let g:loaded_tutor_mode_plugin = 1
let g:loaded_zipPlugin    = 1


""" Custom Commands
command! Code execute ":!code -g %:p\:" . line('.') . ":" . col('.')
cabbrev code Code
