" ▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁
" ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
"
"   ┌┬┐┌─┐┌─┐┌─┐┬  ┬┌┬┐┬ ┬┬┌─┐
"   │││├┤ │ ┬├─┤│  │ │ ├─┤││   :: DOTFILES > nvim/init.vim
"   ┴ ┴└─┘└─┘┴ ┴┴─┘┴ ┴ ┴ ┴┴└─┘
"   Brought to you by: Seth Messer / @megalithic
"
" ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
" ▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔

if !1 | finish | endif     " FIXME: danger, will robinson!

scriptencoding utf-16      " allow emojis in vimrc
filetype plugin indent on  " try to recognize filetypes and load related plugins


"===========================================================
" SETTINGS
"===========================================================

" Enable syntax highlighting.
"
syntax on

" General vim settings.
"
set autoindent        " Indented text
set autoread          " Pick up external changes to files
set autowrite         " Write files when navigating with :next/:previous
set background=dark
set backspace=indent,eol,start
set belloff=all       " Bells are annoying
set breakindent       " Wrap long lines *with* indentation
set breakindentopt=shift:2
if empty($SSH_CONNECTION) && has('clipboard')
  set clipboard=unnamed  " Use clipboard register

  " Share X windows clipboard. NOT ON NEOVIM -- neovim automatically uses
  " system clipboard when xclip/xsel/pbcopy are available.
  if has('nvim') && !has('mac')
    set clipboard=unnamedplus
  elseif has('unnamedplus')
    set clipboard+=unnamedplus
  endif
endif
" set colorcolumn=81,82 " Highlight 81 and 82 columns
set conceallevel=2
set complete=.,w,b    " Sources for term and line completions
" set completeopt=menu,menuone,noinsert,noselect
set completeopt=menu,menuone,preview,noselect,noinsert
set dictionary=/usr/share/dict/words
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
set lazyredraw        " should make scrolling faster
set matchpairs=(:),{:},[:]
set mouse=nva         " Mouse support in different modes
set mousemodel=popup  " Set the behaviour of mouse
set mousehide         " Hide mouse when typing text
set nobackup          " No backup files
set nocompatible      " No Vi support
set noemoji           " don't assume all emoji are double width (@wincent)
set noexrc            " Disable reading of working directory vimrc files
set nohlsearch        " Don't highlight search results by default
set nojoinspaces      " No to double-spaces when joining lines
set noshowcmd         " No to showing command in bottom-right corner
set noshowmatch       " No jumping jumping cursors when matching pairs
set noshowmode        " No to showing mode in bottom-left corner
set noswapfile        " No backup files
" set nowrapscan        " Don't wrap searches around
" set number            " Show line numbers
set nrformats=        " No to oct/hex support when doing CTRL-a/x
set path=**
" set relativenumber    " Show relative numbers
set ruler
set scrolloff=5       " Start scrolling when we're 5 lines away from margins
set shiftwidth=2
set shortmess+=c      " Don't show insert mode completion messages
set sidescrolloff=15
set sidescroll=5
set signcolumn=auto   " Only render sign column when needed
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
let s:undoDir="/tmp/.undodir_" . $USER
if !isdirectory(s:undoDir)
  call mkdir(s:undoDir, "", 0700)
endif
let &undodir=s:undoDir
set undofile          " Maintain undo history
set updatetime=100    " Make GitGutter plugin more responsive
set viminfo=          " No backups
set wildcharm=<Tab>   " Defines the trigger for 'wildmenu' in mappings
set wildmenu          " Nice command completions
set wildmode=full
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
  set pumblend=10
  set pumheight=20      " Height of complete list
  set signcolumn=yes:2  " always showsigncolumn
  set switchbuf=useopen,split,usetab,vsplit
  set wildoptions+=pum
  set winblend=10

  set guicursor=
        \n:block-Cursor,
        \a:block-blinkon0,
        \i:ver25-blinkwait200-blinkoff150-blinkon200-CursorInsert,
        \r:blinkwait200-blinkoff150-blinkon200-CursorReplace,
        \v:CursorVisual,
        \c:ver25-blinkon300-CursorInsert

  " Set cursor shape based on mode (:h termcap-cursor-shape)
  " Vertical bar in insert mode
  let &t_SI = "\e[6 q"
  " Underline in replace mode
  let &t_SR = "\e[4 q"
  " Block in normal mode
  let &t_EI = "\e[2 q"

  let $VISUAL      = 'nvr -cc split --remote-wait +"setlocal bufhidden=delete"'
  let $GIT_EDITOR  = 'nvr -cc split --remote-wait +"setlocal bufhidden=delete"'
  let $EDITOR      = 'nvr -l'
  let $ECTO_EDITOR = 'nvr -l'

  let g:python_host_prog = '~/.asdf/shims/python'
  let g:python3_host_prog = '~/.asdf/shims/python3'

  " share data between nvim instances (registers etc)
  augroup SHADA
    autocmd!
    autocmd CursorHold,TextYankPost,FocusGained,FocusLost *
          \ if exists(':rshada') | rshada | wshada | endif
  augroup END
else
  set cryptmethod=blowfish2
  set listchars=eol:$,tab:>-,trail:-
  set ttymouse=xterm2
endif


"===========================================================
" FUNCTIONS
"
" ~/.dotfiles/nvim/autoload - custom functions
"===========================================================


"===========================================================
" TERMINAL CONFIGURATION
"
" ~/.dotfiles/nvim/plugin/terminal-settings.vim - Vim terminal tweaks
"===========================================================


"===========================================================
" MAPPINGS
"
" ~/.dotfiles/nvim/plugin/mappings.vim - custom mappings
"===========================================================
let mapleader = ","


"===========================================================
" PLUGINS
"===========================================================

" Automatically install vim-plug and run PlugInstall if vim-plug is not found.
if empty(glob('~/.config/nvim/autoload/plug.vim'))
  silent !curl -fLo ~/.config/nvim/autoload/plug.vim --create-dirs
        \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif
set runtimepath+=~/.config/nvim/autoload/plug.vim/

" Initialize vim-plug.
silent! if plug#begin('~/.config/nvim/plugged')

Plug 'tweekmonster/startuptime.vim'

"-----------------------------
" Styling related plugings
"-----------------------------
Plug 'trevordmiller/nova-vim' "nova-colors.vim
" ~/.dotfiles/nvim/plugin/nova-colors.vim - options
" Plug 'camspiers/animate.vim'
Plug 'itchyny/lightline.vim' "lightline.vim
Plug 'Yggdroot/indentLine' "indentLine.vim
Plug 'gcmt/taboo.vim' "taboo.vim
Plug 'TaDaa/vimade' "vimade.vim
Plug 'dm1try/golden_size'
" Plug 'megalithic/golden-ratio' " vertical split layout manager
" Plug 'zhaocai/GoldenView.Vim'
" Plug 'camspiers/lens.vim'
Plug 'junegunn/rainbow_parentheses.vim' " nicely colors nested pairs of [], (), {}
Plug 'norcalli/nvim-colorizer.lua'
Plug 'RRethy/vim-illuminate'
Plug 'jaxbot/semantic-highlight.vim'
Plug 'ryanoasis/vim-devicons'

"-----------------------------
" General behaviour plugins
"-----------------------------
Plug 'nelstrom/vim-visual-star-search'
Plug 'tommcdo/vim-lion' "lion.vim
" Plug 'chaoren/vim-wordmotion' "wordmotion.vim
Plug 'cohama/lexima.vim'
Plug 'tpope/vim-eunuch' "eunuch.vim
Plug 'tpope/vim-abolish'
" https://github.com/tpope/vim-abolish/blob/master/doc/abolish.txt#L146-L162
Plug 'tpope/vim-rhubarb'
Plug 'tpope/vim-repeat'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-commentary'
Plug '907th/vim-auto-save' "auto-save.vim
Plug 'rhysd/clever-f.vim' "clever-f.vim
" Plug 'justinmk/vim-sneak'
" Plug 'mbbill/undotree' "undotree.vim
Plug 'tpope/vim-unimpaired' "unimpaired.vim
Plug 'EinfachToll/DidYouMean' " Vim plugin which asks for the right file to open
Plug 'jordwalke/VimAutoMakeDirectory' " auto-makes the dir for you if it doesn't exist in the path
Plug 'ConradIrwin/vim-bracketed-paste' " correctly paste in insert mode
Plug 'sickill/vim-pasta' " context-aware pasting
" Plug 'psliwka/vim-smoothie' " smooth page up and down movements

"-----------------------------
" Movements/Text Objects, et al
"-----------------------------
Plug 'kana/vim-operator-user'
" -- provide ai and ii for indent blocks
" -- provide al and il for current line
" -- provide a_ and i_ for underscores
" -- provide a- and i-
Plug 'kana/vim-textobj-user'                                      " https://github.com/kana/vim-textobj-user/wiki
Plug 'kana/vim-textobj-entire'                                    " entire buffer text object (vae)
Plug 'kana/vim-textobj-function'                                  " function text object (vaf)
Plug 'kana/vim-textobj-indent'                                    " for indent level (vai)
Plug 'kana/vim-textobj-line'                                      " for current line (val)
Plug 'nelstrom/vim-textobj-rubyblock', { 'for': ['ruby'] }        " ruby block text object (vir)
Plug 'duff/vim-textobj-elixir', { 'for': ['elixir', 'eelixir'] }  " eliXir block text object (vix/vax)
Plug 'glts/vim-textobj-comment'                                   " comment text object (vac)
Plug 'michaeljsmith/vim-indent-object'
Plug 'machakann/vim-textobj-delimited'                            " - d/D   for underscore section (e.g. `did` on foo_b|ar_baz -> foo__baz)
Plug 'gilligan/textobj-lastpaste'                                 " - P     for last paste
Plug 'mattn/vim-textobj-url'                                      " - u     for url
Plug 'rhysd/vim-textobj-anyblock'                                 " - '', \"\", (), {}, [], <>
Plug 'arthurxavierx/vim-caser'                                    " https://github.com/arthurxavierx/vim-caser#usage
Plug 'Julian/vim-textobj-variable-segment'                        " https://github.com/Julian/vim-textobj-variable-segment#vim-textobj-variable-segment
Plug 'wellle/targets.vim'                                         " improved targets line cin) next parens)
" ^--- https://github.com/wellle/targets.vim/blob/master/cheatsheet.md

"-----------------------------
" File management plugins
"-----------------------------
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --no-bash' }
Plug 'junegunn/fzf.vim' " fzf.vim
" Plug 'liuchengxu/vim-clap', { 'do': ':Clap install-binary!' }
" Plug 'vn-ki/coc-clap'

" Plug 'scrooloose/nerdtree', { 'on': ['NERDTreeToggle', 'NERDTreeFind'] }
" ~/.dotfiles/nvim/plugin/nerdtree.vim - options, mappings, function, events
" Plug 'Xuyuanp/nerdtree-git-plugin', { 'on': ['NERDTreeToggle', 'NERDTreeFind'] }
" ~/.dotfiles/nvim/plugin/nerdtree-git-plugin.vim - options

Plug 'mhinz/vim-grepper' " grepper.vim
Plug 'junegunn/vim-slash' " slash.vim
Plug 'mattn/vim-findroot', {'for': ['javascript']} " findroot.vim
Plug 'tpope/vim-dispatch'

"-----------------------------
" Completion plugins
"-----------------------------
if has('nvim') && executable('yarn') && executable('node')
  Plug 'neoclide/coc.nvim', {'do': 'yarn install --frozen-lockfile'} " coc.vim
  " Plug 'liuchengxu/vista.vim' " vista.vim
  " Plug 'elixir-lsp/elixir-ls', { 'do': { -> g:ElixirLS.compile() } }
endif

if has('nvim')
  " Plug 'neovim/nvim-lsp'
  Plug 'haorenW1025/diagnostic-nvim'
  Plug 'haorenW1025/completion-nvim'
  Plug 'wbthomason/lsp-status.nvim'
  Plug 'steelsojka/completion-buffers'
  Plug 'hrsh7th/vim-vsnip'
  Plug 'hrsh7th/vim-vsnip-integ'

  " SLOW (treesitter things):
  " Plug 'nvim-treesitter/nvim-treesitter'
  " Plug 'vigoux/completion-treesitter'
endif

"-----------------------------
" Git plugins
"-----------------------------
Plug 'tpope/vim-fugitive' " fugitive.vim
Plug 'mhinz/vim-signify' " signify.vim
Plug 'rhysd/git-messenger.vim' " git-messenger.vim
" Plug 'APZelos/blamer.nvim' " blamer.vim
Plug 'keith/gist.vim', { 'do': 'chmod -HR 0600 ~/.netrc' } " gist.vim
Plug 'wsdjeg/vim-fetch'
Plug 'mattn/webapi-vim'
Plug 'rhysd/conflict-marker.vim'

"-----------------------------
" Development plugins
"-----------------------------
Plug 'tpope/vim-rails' " rails.vim
Plug 'tpope/vim-projectionist' " projectionist.vim
Plug 'dense-analysis/ale' " ale.vim
Plug 'janko/vim-test' " test.vim
Plug 'tpope/vim-ragtag' " ragtag.vim
Plug 'rhysd/reply.vim'
Plug 'axvr/zepl.vim'

" Sleuth and EditorConfig will adjust style and indent either heuristically
" (former) or explicitly (later). Note, EditorConfig will take precedence if
" a .editorconfig file is found.
" Plug 'tpope/vim-sleuth'
" ~/.dotfiles/nvim/after/plugin/sleuth.vim - overrides
Plug 'sgur/vim-editorconfig'

" allows mirror'ed editing of files locally, to a specified ssh location via ~/.mirrors
Plug 'zenbro/mirror.vim'
Plug 'ChristianChiarulli/codi.vim'

"-----------------------------
" Filetype/Syntax/Lang plugins
"-----------------------------
" Plug 'andys8/vim-elm-syntax', {'for': ['elm']}
Plug 'Zaptic/elm-vim', {'for': ['elm']}
Plug 'antew/vim-elm-analyse', { 'for': ['elm'] }
Plug 'elixir-lang/vim-elixir', { 'for': ['elixir', 'eelixir'] }
Plug 'avdgaag/vim-phoenix', { 'for': ['elixir', 'eelixir'] }
Plug 'lucidstack/hex.vim', { 'for': ['elixir', 'eelixir']}
Plug 'neoclide/jsonc.vim', { 'for': ['json', 'jsonc'] }
Plug 'gerrard00/vim-mocha-only', { 'for': ['javascript', 'javscriptreact', 'typescript', 'typescript.tsx'] }
Plug 'plasticboy/vim-markdown' , { 'for': ['markdown', 'vimwiki'] }
Plug 'iamcco/markdown-preview.nvim', {'for':'markdown', 'do':  ':call mkdp#util#install()', 'frozen': 1}
Plug 'florentc/vim-tla'
Plug 'sheerun/vim-polyglot' "polyglot.vim

"-----------------------------
" tmux support
"-----------------------------
Plug 'christoomey/vim-tmux-navigator'
" ~/.dotfiles/nvim/plugin/tmux-navigator.vim - options, mappings
Plug 'tmux-plugins/vim-tmux-focus-events'
Plug 'christoomey/vim-tmux-runner' " needed for tmux/hotkey integration with vim

" Finalize vim-plug.
call plug#end()
endif


" Load up the match it plugin which provides smart % XML/HTML matching.
runtime macros/matchit.vim


"===========================================================
" AUTOCMDS
"
" ~/.dotfiles/nvim/plugin/autocmds.vim - customizations
" ~/.dotfiles/nvim/ftplugin            - file type options, mappings
" ~/.dotfiles/nvim/after/ftplugin      - file type overrides
"===========================================================


"===========================================================
" IABBREV
"===========================================================

iabbrev cabbb Co-authored-by: Bijan Boustani <bijanbwb@gmail.com>


"===========================================================
" COLOR SCHEME
"===========================================================

set background=dark
let g:nova_transparent = 1
silent! colorscheme nova

" vim:ft=vim
