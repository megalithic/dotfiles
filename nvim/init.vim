scriptencoding utf-16      " allow emojis in vimrc
set nocompatible           " vim, not vi
syntax on                  " syntax highlighting
filetype plugin indent on  " try to recognize filetypes and load rel' plugins

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

" ░░░░░░░░░░░░░░░ installs {{{

if empty(glob('~/.config/nvim/autoload/plug.vim'))
  silent !curl -fLo ~/.config/nvim/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  au! User VimEnter * PlugInstall --sync | source $MYVIMRC
endif
set runtimepath+=~/.config/nvim/autoload/plug.vim/

silent! if plug#begin('~/.config/nvim/plugins')

Plug 'andymass/vim-matchup'
Plug 'antew/vim-elm-analyse', { 'for': ['elm'] }
Plug 'avdgaag/vim-phoenix', { 'for': ['elixir','eelixir'] }
Plug 'chemzqm/vim-jsx-improve', { 'for': ['javascript', 'javascriptreact', 'javascript.jsx'] }
Plug 'christoomey/vim-tmux-navigator' " needed for tmux/hotkey integration with vim
Plug 'christoomey/vim-tmux-runner' " needed for tmux/hotkey integration with vim
Plug 'cohama/lexima.vim'
Plug 'ConradIrwin/vim-bracketed-paste' " correctly paste in insert mode
Plug 'darfink/vim-plist'
Plug 'docunext/closetag.vim' " will auto-close the opening tag as soon as you type </
Plug 'editorconfig/editorconfig-vim'
Plug 'EinfachToll/DidYouMean' " Vim plugin which asks for the right file to open
Plug 'elixir-lang/vim-elixir', { 'for': ['elixir', 'eelixir'] }
Plug 'GrzegorzKozub/vim-elixirls', { 'do': ':ElixirLsCompileSync' }
Plug 'gruvbox-community/gruvbox'
Plug 'hail2u/vim-css3-syntax', { 'for': 'css' }
Plug 'hauleth/pivotaltracker.vim', { 'for': ['gitcommit'] }
Plug 'HerringtonDarkholme/yats.vim', { 'for': ['typescript', 'typescriptreact', 'typescript.tsx'] }
Plug 'honza/vim-snippets'
Plug 'iamcco/markdown-preview.nvim', {'for':'markdown', 'do':  ':call mkdp#util#install()', 'frozen': 1}
Plug 'itchyny/lightline.vim'
" Plug 'itspriddle/vim-marked', { 'for': ['markdown', 'vimwiki'] }
Plug 'janko-m/vim-test', {'on': ['TestFile', 'TestLast', 'TestNearest', 'TestSuite', 'TestVisit'] } " tester for js and ruby
Plug 'jordwalke/VimAutoMakeDirectory' " auto-makes the dir for you if it doesn't exist in the path
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': 'yes \| ./install --all' }
Plug 'junegunn/fzf.vim'
Plug 'junegunn/rainbow_parentheses.vim' " nicely colors nested pairs of [], (), {}
Plug 'junegunn/vim-easy-align'
Plug 'junegunn/vim-plug'
Plug 'keith/gist.vim', { 'do': 'chmod -HR 0600 ~/.netrc' }
Plug 'wsdjeg/vim-fetch'
Plug 'liuchengxu/vim-which-key'
Plug 'lucidstack/hex.vim', { 'for': ['elixir', 'eelixir']}
Plug 'mattn/webapi-vim'
Plug 'mbbill/undotree', { 'on': 'UndotreeToggle' }
Plug 'megalithic/golden-ratio' " vertical split layout manager
Plug 'mhinz/vim-startify'
Plug 'neoclide/jsonc.vim', { 'for': ['json','jsonc'] }
Plug 'neoclide/coc-neco'
if executable('yarn') && executable('node')
  let g:coc_global_extensions = [
        \ 'coc-bookmark',
        \ 'coc-calc',
        \ 'coc-css',
        \ 'coc-diagnostic',
        \ 'coc-dictionary',
        \ 'coc-eslint',
        \ 'coc-elixir',
        \ 'coc-git',
        \ 'coc-github',
        \ 'coc-gitignore',
        \ 'coc-gocode',
        \ 'coc-highlight',
        \ 'coc-html',
        \ 'coc-json',
        \ 'coc-lists',
        \ 'coc-lua',
        \ 'coc-marketplace',
        \ 'coc-prettier',
        \ 'coc-python',
        \ 'coc-rls',
        \ 'coc-sh',
        \ 'coc-snippets',
        \ 'coc-solargraph',
        \ 'coc-svg',
        \ 'coc-syntax',
        \ 'coc-tailwindcss',
        \ 'coc-tslint-plugin',
        \ 'coc-tsserver',
        \ 'coc-vimlsp',
        \ 'coc-vimtex',
        \ 'coc-word',
        \ 'coc-yaml',
        \ 'coc-yank',
        \ ]
  Plug 'neoclide/coc.nvim', {'do': 'yarn install --frozen-lockfile'}
endif
Plug 'othree/csscomplete.vim', { 'for': 'css' }
Plug 'pangloss/vim-javascript', { 'for': 'javascript' }
Plug 'peitalin/vim-jsx-typescript', { 'for': ['javascript', 'typescript'] }
Plug 'plasticboy/vim-markdown' , { 'for': ['markdown', 'vimwiki'] }
Plug 'powerman/vim-plugin-AnsiEsc' " supports ansi escape codes for documentation from lc/lsp/etc
Plug 'rizzatti/dash.vim'
Plug 'RRethy/vim-hexokinase'
Plug 'rhysd/git-messenger.vim'
Plug 'sakhnik/nvim-gdb', { 'do': ':!./install.sh \| UpdateRemotePlugins' }
Plug 'Shougo/neco-vim'
Plug 'sickill/vim-pasta' " context-aware pasting
Plug 'svermeulen/vim-yoink'
Plug 'TaDaa/vimade'
Plug 'tmux-plugins/vim-tmux-focus-events'
Plug 'tpope/vim-abolish'
Plug 'tpope/vim-commentary'
Plug 'tpope/vim-eunuch'
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-git'
" Plug 'tpope/vim-markdown'
Plug 'tpope/vim-projectionist'
Plug 'tpope/vim-ragtag'
Plug 'tpope/vim-rails', {'for': 'ruby,erb,yaml,ru,haml'}
Plug 'tpope/vim-repeat'
Plug 'tpope/vim-rhubarb'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-unimpaired' " https://github.com/tpope/vim-unimpaired/blob/master/doc/unimpaired.txt
Plug 'trevordmiller/nova-vim'
Plug 'unblevable/quick-scope' " highlights f/t type of motions, for quick horizontal movements
Plug 'vim-ruby/vim-ruby', { 'for': 'ruby' }
Plug 'w0rp/ale'
Plug 'Yggdroot/indentLine'
" Plug 'megalithic/elm-vim', { 'for': ['elm'] }
Plug 'andys8/vim-elm-syntax', {'for': ['elm']}
Plug 'zenbro/mirror.vim' " allows mirror'ed editing of files locally, to a specified ssh location via ~/.mirrors
Plug 'sheerun/vim-polyglot'
Plug 'ryanoasis/vim-devicons' " has to be last according to docs
Plug 'vimwiki/vimwiki' " (more vimwiki things: https://github.com/skbolton/titan/blob/master/states/nvim/nvim/plugin/wiki.vim)
" Plug 'lervag/wiki.vim'

" ## Movements/Text Objects, et al
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

call plug#end()
endif

"}}}
" ░░░░░░░░░░░░░░░ options {{{

" ---- Search
set ignorecase
set smartcase

" ---- Tab completion
set wildmode=list:longest,full
set wildignore=*.swp,*.o,*.so,*.exe,*.dll

" ---- Scroll
set scrolloff=5               " Start scrolling when we're 8 lines away from margins
set sidescrolloff=15
set sidescroll=5

" ---- Tab settings
set tabstop=2
set shiftwidth=2
set expandtab
set backspace=eol,indent,start

" ---- Hud
set ruler
set number
set nowrap
set fillchars=vert:\│,fold:·
" set fillchars=vert:┃ " for vsplits
" set fillchars+=fold:· " for folds
" set colorcolumn=80
set nocursorline              " Highlight current line
set cmdheight=1
" set cpoptions+=$            " dollar sign while changing
set synmaxcol=250             " set max syntax highlighting column to sane level
set visualbell t_vb=          " no visual bell
set t_ut=                     " fix 256 colors in tmux http://sunaku.github.io/vim-256color-bce.html
set laststatus=2

if has('nvim') &&  matchstr(execute('silent version'), 'NVIM v\zs[^\n-]*') >= '0.4.0'
  set inccommand=nosplit " interactive find replace preview
  set wildoptions+=pum
  set signcolumn=yes:2          " always showsigncolumn
  set pumblend=10
  set winblend=10
  if exists('+pumheight')
    set pumheight=30
  endif
endif

" ---- Show
set noshowmode                " Hide showmode because of the powerline plugin
set noshowcmd                 " Hide incomplete cmds down the bottom
set showmatch                 " Highlight matching bracket

" ---- Buffers
set hidden
set autoread                  " auto read external file changes
set switchbuf=useopen,split,usetab

" ---- Backup directories
set backupdir=~/.config/nvim/backups,.
set directory=~/.config/nvim/swaps,.
if exists('&undodir')
  set undodir=~/.config/nvim/undo,.
endif

" ---- Swap and backups
set noswapfile
set nobackup
set nowritebackup
set backupcopy=yes "HMR things - https://parceljs.org/hmr.html#safe-write

" ---- Dictionary and spelling
set dictionary+=/usr/share/dict/words
set nospell             " Disable spellchecking by default
set spelllang=en_us,en_gb
set spellfile=~/.config/nvim/spell/en.utf-8.add

" ---- Undo
" Keep undo history across sessions, by storing in file.
silent !mkdir ~/.config/nvim/undo > /dev/null 2>&1
set undodir=~/.config/nvim/undo
set undofile

" ---- clipboard
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

" ---- Timeouts
set timeoutlen=500 ttimeoutlen=0    " Reduce Command timeout for faster escape and O
set updatetime=300

" ---- Split behaviors
set splitright                      " Set up new vertical splits positions
set splitbelow                      " Set up new horizontal splits positions

" ---- Diff opts
set diffopt-=internal
set diffopt+=indent-heuristic,algorithm:patience
set diffopt+=filler,internal,algorithm:histogram,indent-heuristic

" ---- GUI/Cursor
if has('termguicolors')
  " Don't need this in xterm-256color, but do need it inside tmux.
  " (See `:h xterm-true-color`.)
  if &term =~# 'tmux-256color'
    set termguicolors

    let &t_8f="\e[38;2;%ld;%ld;%ldm"
    let &t_8b="\e[48;2;%ld;%ld;%ldm"
    let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"
    let &t_8b = "\<Esc>[48;2;%lu;%lu;%lum"
  endif
endif

if has('nvim')
  let $VISUAL      = 'nvr -cc split --remote-wait +"setlocal bufhidden=delete"'
  let $GIT_EDITOR  = 'nvr -cc split --remote-wait +"setlocal bufhidden=delete"'
  let $EDITOR      = 'nvr -l'
  let $ECTO_EDITOR = 'nvr -l'

  " share data between nvim instances (registers etc)
  augroup SHADA
    autocmd!
    autocmd CursorHold,TextYankPost,FocusGained,FocusLost *
          \ if exists(':rshada') | rshada | wshada | endif
  augroup END
endif

"}}}
" ░░░░░░░░░░░░░░░ mappings/remaps {{{

let mapleader=','
let maplocalleader=','

" Fancy macros
nnoremap q <Nop>
nnoremap Q @q
vnoremap Q :norm @q<cr>

" esc mechanisms
imap jk <ESC>

" Jump key
nnoremap ` '
nnoremap ' `

" Change pane
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l
" ## Splits with vim-tmux-navigator
nnoremap <silent><C-h> :TmuxNavigateLeft<CR>
nnoremap <silent><C-j> :TmuxNavigateDown<CR>
nnoremap <silent><C-k> :TmuxNavigateUp<CR>
nnoremap <silent><C-l> :TmuxNavigateRight<CR>

" Turn off search highlight
nnoremap <localleader>/ :nohlsearch<CR>

" ## Writing / quitting
silent! unmap <leader>w
nnoremap <silent><leader>w :w<CR>
nnoremap <silent><leader>W :w !sudo tee %<CR>
nnoremap <leader>q :q<CR>

" open a (new)file in a new vsplit
nnoremap <silent><leader>o :vnew<CR>:e<space><C-d>

" Background (n)vim
vnoremap <C-z> <ESC>zv`<ztgv

" Default to case insensitive search
nnoremap / /\v
vnoremap / /\v

" Don't overwrite blackhole register with selection
" https://www.reddit.com/r/vim/comments/clccy4/pasting_when_selection_touches_eol/
xnoremap p "_c<c-r>"<esc>
xmap P p

" clear incsearch term
nnoremap <silent><ESC> :syntax sync fromstart<CR>:nohlsearch<CR>:redrawstatus!<CR><ESC>

" Start substitute on current word under the cursor
nnoremap <leader>s :%s///gc<Left><Left><Left>

" Start search on current word under the cursor
nnoremap <leader>/ /<CR>

" Start reverse search on current word under the cursor
nnoremap <leader>? ?<CR>

" Faster sort
vnoremap <leader>s :!sort<CR>

" Command mode conveniences
noremap <leader>: :!
noremap <leader>; :<Up>

" Remap VIM 0 to first non-blank character
map 0 ^

" Easier to type, however, i hurt my muscle memory when on remote vim  for now
noremap H ^
noremap L $
vnoremap L g_

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

" ## Indentions
" Indent/dedent/autoindent what you just pasted.
nnoremap <lt>> V`]<
nnoremap ><lt> V`]>
nnoremap =- V`]=

" make the tab key match bracket pairs
silent! unmap [%
silent! unmap ]%
map <Tab> %
smap <Tab> %
noremap <Tab> %
nnoremap <Tab> %
vnoremap <Tab> %
xnoremap <Tab> %

" Quick edit of certain files
map <leader>ev :vnew! ~/.dotfiles/nvim/init.vim<CR>
map <leader>ek :vnew! ~/.dotfiles/kitty/kitty.conf<CR>
map <leader>eg :vnew! ~/.gitconfig<CR>
map <leader>et :vnew! ~/.dotfiles/tmux/tmux.conf.symlink<CR>
map <leader>ez :vnew! ~/.dotfiles/zsh/zshrc.symlink<CR>

" ## Join and Split Lines
" Keep the cursor in place while joining lines
nnoremap J mzJ`z
" Split line (sister to [J]oin lines above)
" The normal use of S is covered by cc, so don't worry about shadowing it.
nnoremap S i<CR><ESC>^mwgk:silent! s/\v +$//<CR>:noh<CR>`w

" Easily escape terminel
" tnoremap <leader><esc> <C-\><C-n><esc><cr>

" Copy command
vnoremap <C-x> :!pbcopy<CR>
vnoremap <C-c> :w !pbcopy<CR><CR>

" mbbill/undotree
nnoremap <F7> :UndotreeToggle<CR>

" These create newlines like o and O but stay in normal mode
nmap zj o<Esc>
nmap zk O<Esc>

" ## buffers
nnoremap <leader>bd :bdelete<cr>
nnoremap <leader>bf :bfirst<cr>
nnoremap <leader>bl :blast<cr>
nnoremap <leader>bn :bnext<cr>
nnoremap <leader>bp :bprevious<cr>
nnoremap <leader>b# :b#<cr>
nnoremap <leader>bx :%bd\|e#<cr>

"}}}
" ░░░░░░░░░░░░░░░ autocommands {{{

augroup general
  au!

  " if more than 1 files are passed to vim as arg, open them in vertical splits
  if argc() > 1
    silent vertical all
  endif

  autocmd BufRead * nohls

  " save all files on focus lost, ignoring warnings about untitled buffers
  " autocmd FocusLost * silent! wa

  au FocusGained  * checktime "Refresh file when vim gets focus
  au BufEnter     * checktime
  au WinEnter     * checktime
  " au CursorHold   * checktime " throws errors?
  au InsertEnter  * checktime

  " Refresh lightline when certain things happen
  " au TextChanged,InsertLeave,BufWritePost * call lightline#update()
  au BufWritePost * call lightline#update()

  " Handle window resizing
  au VimResized * execute "normal! \<c-w>="

  " No formatting on o key newlines
  au BufNewFile,BufEnter * set formatoptions-=o

  " " Trim trailing whitespace (presently uses w0rp/ale for this)
  " function! <SID>TrimWhitespace()
  "   let l = line(".")
  "   let c = col(".")
  "   keeppatterns %s/\v\s+$//e
  "   call cursor(l, c)
  " endfunction
  " au FileType * au BufWritePre <buffer> :call <SID>TrimWhitespace()

  " Remember cursor position between vim sessions
  au BufReadPost *
        \ if line("'\"") > 0 && line ("'\"") <= line("$") |
        \   exe "normal! g'\"" |
        \ endif

  " Hide status bar while using fzf commands
  if has('nvim')
    au! FileType fzf
    au  FileType fzf set laststatus=0 | au BufLeave,WinLeave <buffer> set laststatus=2
  endif

  " Auto-close preview window when completion is done.
  au! InsertLeave,CompleteDone * if pumvisible() == 0 | pclose | endif

  " When terminal buffer ends allow to close it
  if has('nvim')
    au TermClose * noremap <buffer><silent><CR> :bd!<CR>
    au TermClose * noremap <buffer><silent><ESC> :bd!<CR>
    au! TermOpen * setlocal nonumber norelativenumber
    au! TermOpen * if &buftype == 'terminal'
          \| set nonumber norelativenumber
          \| endif
  endif

  " coc.nvim - highlight all occurences of word under cursor
  " disable for now: annoying while on tmate and other things
  " au CursorHold * silent call CocActionAsync('highlight')

  " Name tmux window/tab based on current opened buffer
  " au BufReadPost,FileReadPost,BufNewFile,BufEnter *
  " au BufReadPre,FileReadPre,BufNewFile,BufEnter *
  "       \ let tw = system("tmux display-message -p '\\#W'")
  "       \| echo "current tmux window: " . tw
  "       \| call system("tmux rename-window 'nvim | " . expand("%:t") . "'")
  " au VimLeave * call system("tmux rename-window '" . tw . "'")

  " ----------------------------------------------------------------------------
  " ## Toggle certain accoutrements when entering and leaving a buffer & window

  " toggle syntax / dim / inactive (comment out when tadaa/vimade supports TUI)
  " au WinEnter,BufEnter * silent set number relativenumber " call RainbowParentheses
  " au WinLeave,BufLeave * silent set nonumber norelativenumber " call RainbowParentheses!

  " toggle linenumbering and cursorline
  " au BufEnter,FocusGained,InsertLeave * silent set relativenumber cursorline
  " au BufLeave,FocusLost,InsertEnter   * silent set norelativenumber nocursorline

  au BufEnter,VimEnter,WinEnter,BufWinEnter * silent setl number relativenumber
  au BufLeave,WinLeave * silent setl nonumber norelativenumber

  " toggle colorcolumn when in insertmode only
  au InsertEnter * silent set colorcolumn=80
  au InsertLeave * if &filetype != "markdown"
                            \ | silent set colorcolumn=""
                            \ | endif

  " Open QuickFix horizontally with line wrap
  au FileType qf wincmd J | setlocal wrap

  " Preview window with line wrap
  au WinEnter * if &previewwindow | setlocal wrap | endif

  autocmd! FileType which_key
  autocmd  FileType which_key set laststatus=0 noshowmode noruler
        \| autocmd BufLeave <buffer> set laststatus=2 showmode ruler

  " reload vim configuration (aka vimrc)
  command! ReloadVimConfigs so $MYVIMRC
    \| echo 'configs reloaded!'
augroup END

augroup mirrors
  au!
  " ## Automagically update remote files via scp
  au BufWritePost ~/.dotfiles/private/homeassistant/* silent! :MirrorPush ha
  au BufWritePost ~/.dotfiles/private/domains/nginx/* silent! :MirrorPush nginx
  au BufWritePost ~/.dotfiles/private/domains/fathom/* silent! :MirrorPush fathom
augroup END

function s:fzf_buf_in() abort
  echo
  set laststatus=0
  set noruler
  set nonumber
  set norelativenumber
  set signcolumn=no
endfunction

function s:fzf_buf_out() abort
  set laststatus=2
  set ruler
endfunction

augroup fzf
  autocmd!
  autocmd FileType fzf call s:fzf_buf_in()
  autocmd BufEnter \v[0-9]+;#FZF$ call s:fzf_buf_in()
  autocmd BufLeave \v[0-9]+;#FZF$ call s:fzf_buf_out()
  autocmd TermClose \v[0-9]+;#FZF$ call s:fzf_buf_out()
augroup END

augroup gitcommit
  au!

  " pivotalTracker.vim
  let g:pivotaltracker_name = "smesser"
  autocmd FileType gitcommit setlocal completefunc=pivotaltracker#stories
  autocmd FileType gitcommit setlocal omnifunc=pivotaltracker#stories

  function! BufReadIndex()
    " Use j/k in status
    setl nohlsearch
    nnoremap <buffer> <silent> j :call search('^#\t.*','W')<Bar>.<CR>
    nnoremap <buffer> <silent> k :call search('^#\t.*','Wbe')<Bar>.<CR>
  endfunction

  function! BufEnterCommit()
    " Start in insert mode for commit
    normal gg0
    if getline('.') ==? ''
      start
    end

    " disable coc.nvim for gitcommit
    " autocmd BufNew,BufEnter *.json,*.vim,*.lua execute "silent! CocEnable"
    " autocmd InsertEnter * execute "silent! CocDisable"

    " Allow automatic formatting of bulleted lists and blockquotes
    " https://github.com/lencioni/dotfiles/blob/master/.vim/after/ftplugin/gitcommit.vim
    setlocal comments+=fb:*
    setlocal comments+=fb:-
    setlocal comments+=fb:+
    setlocal comments+=b:>

    setlocal formatoptions+=c " Auto-wrap comments using textwidth
    setlocal formatoptions+=q " Allow formatting of comments with `gq`

    setlocal textwidth=72
    " setl spell
    " setl spelllang=en
    " setl nolist
    " setl nonumber
  endfunction

  au BufNewFile,BufRead .git/index setlocal nolist
  au BufReadPost fugitive://* set bufhidden=delete
  au BufReadCmd *.git/index exe BufReadIndex()
  au BufEnter *.git/index silent normal gg0j
  au BufEnter *COMMIT_EDITMSG,*PULLREQ_EDITMSG exe BufEnterCommit()
  au FileType gitcommit,gitrebase exe BufEnterCommit()

  " co-authored-by iabbreviations only used during gitcommit messages
  au FileType gitcommit,gitrebase :iabbrev <buffer> cabjj Co-authored-by: Joe Jobes <jmrjobes@gmail.com>
  au FileType gitcommit,gitrebase :iabbrev <buffer> cabtw Co-authored-by: Tony Winn <hi@tonywinn.me>
  au FileType gitcommit,gitrebase :iabbrev <buffer> cabjw Co-authored-by: Jeff Weiss <jweiss@enbala.com>
  au FileType gitcommit,gitrebase :iabbrev <buffer> caban Co-authored-by: Alan Nguyen <anguyen@enbala.com>
augroup END

augroup ft_elixir
  au!
  au FileType elixir,eelixir nnoremap <silent> <buffer> <leader>ed orequire IEx; IEx.pry<ESC>:w<CR>
  au FileType elixir,eelixir nnoremap <silent> <buffer> <leader>ep o\|> <ESC>a
  au FileType elixir,eelixir nnoremap <silent> <buffer> <leader>ei o\|> IO.inspect()<ESC>i
  au FileType elixir,eelixir nnoremap <silent> <buffer> <leader>eil o\|> IO.inspect(label: "")<ESC>hi

  au FileType elixir,eelixir nnoremap <silent> <buffer> <leader>ex :IEx -S mix<CR>
if has('nvim')
  tnoremap <silent> <leader>x <C-\><C-n>:IEx -S mix<CR>
endif

  au FileType elixir,eelixir iabbrev epry  require IEx; IEx.pry
  au FileType elixir,eelixir iabbrev ep    \|>
  au FileType elixir,eelixir iabbrev ei    IO.inspect
  au FileType elixir,eelixir iabbrev eputs IO.puts

  " :Iex => open iex with current file compiled
  command! Iex :!iex -S mix %<cr>

  au FileType elixir,eelixir let g:which_key_map.e = {
        \ 'name' : '+elixir' ,
        \ 'i' : 'io.inspect',
        \ 'il' : 'io.inspect-with-label',
        \ 'd' : 'debug/iex.pry',
        \ 'p' : '|> pipeline',
        \ }
augroup END

augroup ft_elm
  au!
  au FileType elm nnoremap <leader>ep o\|> <ESC>a
  au FileType elm iabbrev ep    \|>

  au FileType elm let g:which_key_map.e = {
        \ 'name' : '+elm' ,
        \ 'p' : '|> pipeline',
        \ }
augroup END

augroup ft_clang
  autocmd FileType c setlocal tabstop=2 softtabstop=2 shiftwidth=2 expandtab
  autocmd FileType cpp setlocal tabstop=2 softtabstop=2 shiftwidth=2 expandtab
  autocmd FileType cs setlocal tabstop=2 softtabstop=2 shiftwidth=2 expandtab
  autocmd FileType c setlocal commentstring=/*\ %s\ */
  autocmd FileType c,cpp,cs setlocal commentstring=//\ %s
augroup END

"}}}
" ░░░░░░░░░░░░░░░ other settings {{{

" Fancy tag lookup
set tags=./tags;/,tags;/

" Visible whitespace
set listchars=tab:»·,trail:·
set listchars=tab:▸\ ,eol:¬,extends:›,precedes:‹,trail:·,nbsp:⚋
set nolist

" Soft-wrap for prose (TODO: confirm we need this; comes from evan)
command! -nargs=* Wrap set wrap linebreak nolist spell
let &showbreak='↪ '

" Alias the Eunuch commands (except for Move and Wall)
cabbrev remove <c-r>=getcmdpos() == 1 && getcmdtype() == ":" ? "Remove" : "remove"<cr>
cabbrev unlink <c-r>=getcmdpos() == 1 && getcmdtype() == ":" ? "Unlink" : "unlink"<cr>
cabbrev rename <c-r>=getcmdpos() == 1 && getcmdtype() == ":" ? "Rename" : "rename"<cr>
cabbrev chmod <c-r>=getcmdpos() == 1 && getcmdtype() == ":" ? "Chmod" : "chmod"<cr>
cabbrev mkdir <c-r>=getcmdpos() == 1 && getcmdtype() == ":" ? "Mkdir" : "mkdir"<cr>
cabbrev find <c-r>=getcmdpos() == 1 && getcmdtype() == ":" ? "Find" : "find"<cr>
cabbrev locate <c-r>=getcmdpos() == 1 && getcmdtype() == ":" ? "Locate" : "locate"<cr>
cabbrev sudowrite <c-r>=getcmdpos() == 1 && getcmdtype() == ":" ? "Sudowrite" : "sudowrite"<cr>
cabbrev sudoedit <c-r>=getcmdpos() == 1 && getcmdtype() == ":" ? "Sudoedit" : "sudoedit"<cr>

"}}}
" ░░░░░░░░░░░░░░░ plugin settings {{{

let g:startify_padding_left = 5
let g:startify_relative_path = 1
let g:startify_fortune_use_unicode = 1
let g:startify_change_to_vcs_root = 1
let g:startify_update_oldfiles = 1
let g:startify_use_env = 1
let g:startify_enable_special = 0
let g:startify_files_number = 10
let g:startify_session_persistence = 1
let g:startify_session_delete_buffers = 1
let g:startify_ascii = [' ', ' ϟ ' . (has('nvim') ? 'nvim' : 'vim') . '.', ' ']
let g:startify_custom_header = 'map(startify#fortune#boxed() + g:startify_ascii, "repeat(\" \", 5).v:val")'
let g:startify_custom_header_quotes = startify#fortune#predefined_quotes() + [
      \ ['Simplicity is a great virtue but it requires hard work to achieve it', 'and education to appreciate it. And to make matters worse: complexity sells better.', '', '― Edsger W. Dijkstra'],
      \ ['A common fallacy is to assume authors of incomprehensible code will be able to express themselves clearly in comments.'],
      \ ['Your time is limited, so don’t waste it living someone else’s life. Don’t be trapped by dogma — which is living with the results of other people’s thinking. Don’t let the noise of others’ opinions drown out your own inner voice. And most important, have the courage to follow your heart and intuition. They somehow already know what you truly want to become. Everything else is secondary.', '', '— Steve Jobs, June 12, 2005'],
      \ ['My take: Animations are something you earn the right to include when the rest of the experience is fast and intuitive.', '', '— @jordwalke'],
      \ ['If a feature is sometimes dangerous, and there is a better option, then always use the better option.', '', '- Douglas Crockford'],
      \ ['The best way to make your dreams come true is to wake up.', '', '― Paul Valéry'],
      \ ['Fast is slow, but continuously, without interruptions', '', '– Japanese proverb'],
      \ ['A language that doesn’t affect the way you think about programming is not worth knowing.', '- Alan Perlis'],
      \ ['Bad programmers worry about the code. Good programmers worry about data structures and their relationships', '' , '― Linus Torvalds']
      \ ]

let g:startify_bookmarks = [
    \{'d': '~/.dotfiles'},
    \]

let g:startify_list_order = [
      \ ['   Bookmarks'], 'bookmarks',
      \ ['   Sessions'], 'sessions',
      \ ['   Files'], 'files',
      \ ['   Directory'], 'dir',
      \ ['   Commands'], 'commands',
      \ ]

let g:startify_skiplist = [
      \ 'COMMIT_EDITMSG',
      \ '^/tmp',
      \ escape(fnamemodify(resolve($VIMRUNTIME), ':p'), '\') .'doc',
      \ 'plugged/.*/doc',
      \ 'pack/.*/doc',
      \ '.*/vimwiki/.*'
      \ ]

let g:startify_ascii = [
\ "                      .            .      ",
\ "                    .,;'           :,.    ",
\ "                  .,;;;,,.         ccc;.  ",
\ "                .;c::::,,,'        ccccc: ",
\ "                .::cc::,,,,,.      cccccc.",
\ "                .cccccc;;;;;;'     llllll.",
\ "                .cccccc.,;;;;;;.   llllll.",
\ "                .cccccc  ';;;;;;'  oooooo.",
\ "                'lllllc   .;;;;;;;.oooooo'",
\ "                'lllllc     ,::::::looooo'",
\ "                'llllll      .:::::lloddd'",
\ "                .looool       .;::coooodo.",
\ "                  .cool         'ccoooc.  ",
\ "                    .co          .:o:.    ",
\ "                      .           .'      ",
\ "",
\"                          neovim",
\"            hyperextensible Vim-based text editor",
\]
" let g:startify_custom_header = map(g:startify_ascii, "\"   \".v:val")
let g:startify_custom_header = 'map(startify#fortune#boxed() + g:startify_ascii, "repeat(\" \", 5).v:val")'

augroup MyStartify
  autocmd!
  autocmd User Startified setlocal cursorline
augroup END

" ## sheerun/polyglot
let g:polyglot_disabled = ['typescript', 'typescriptreact', 'typescript.tsx', 'javascriptreact', 'graphql', 'tsx', 'jsx', 'sass', 'scss', 'css', 'elm', 'elixir', 'eelixir', 'ex', 'exs']


" vimwiki/vimwiki
let g:vimwiki_list = [{'path': '~/Dropbox/wiki/',
                     \ 'auto_toc': 1,
                     \ 'auto_tags': 1,
                     \ 'auto_generate_links': 1,
                     \ 'auto_generate_tags': 1,
                     \ 'syntax': 'markdown',
                     \ 'list_margin': 0,
                     \ 'ext': '.md'}]
let g:vimwiki_global_ext = 0
nnoremap <localleader>nw<Space> :VimwikiSearch<cr>
command! -nargs=1 VimwikiNewNote write ~/Dropbox/wiki/notes/<args>
nnoremap <localleader>nw<CR> :VimwikiNewNote
map <M-Space> <Plug>VimwikiToggleListItem
nmap <A-n> <Plug>VimwikiNextLink
nmap <A-p> <Plug>VimwikiPrevLink
nmap <leader>nwi :vnew<CR><Plug>VimwikiIndex
nmap <leader>ndi :vnew<CR><Plug>VimwikiDiaryIndex


" ## rhysd/git-messenger
" let g:git_messenger_no_default_mappings = 1
" let g:git_messenger_include_diff = "none"
" let g:git_messenger_max_popup_width = "50"
" let g:git_messenger_max_popup_height = "25"
nmap <leader>gm <Plug>(git-messenger)

" ## junegunn/vim-easy-align
" Start interactive EasyAlign in visual mode (e.g. vipga)
xmap ga <Plug>(EasyAlign)
" Start interactive EasyAlign for a motion/text object (e.g. gaip)
nmap ga <Plug>(EasyAlign)

" ## andymass/vim-matchup
" let g:matchup_matchparen_deferred = 1
" let g:matchup_matchparen_hi_surround_always = 1
let g:matchup_matchparen_status_offscreen = 0

" ## liuchengxu/vim-which-key
" ref: https://github.com/sinecodes/dotfiles/blob/master/.vim/settings/rich/whichkey.vim
let g:which_key_use_floating_win = 1
let g:which_key_hspace = 15
let g:which_key_timeout = 150
let g:which_key_map = {
      \   'a': 'search-project-for',
      \   'A': 'search-project-for-cursor-word',
      \   'c': 'comment-line',
      \   'm': 'fzf-find-files',
      \   'M': 'markdown-preview',
      \   'o': 'new-file',
      \   'q': 'quit-buffer',
      \   's': 'substitute-for-cursor-word',
      \   'w': 'save-buffer',
      \   'W': 'sudo-save-buffer',
      \   '/': 'find-forward-cursor-word',
      \   '?': 'find-back-cursor-word',
      \   ';': 'last-command',
      \   ':': 'shell-command',
      \ }
let g:which_key_map.n = {
      \ 'name' : '+notes-wiki-journal',
      \ 'di' : 'diary',
      \ 'wi' : 'wiki',
      \ 'w<CR>' : 'new-wiki-note',
      \ 'w<Space>' : 'wiki-search',
      \ }
let g:which_key_map.g = {
      \ 'name' : '+git/vcs' ,
      \ 'b' : ['Gblame'       , 'blame'],
      \ 'c' : ['BCommits'     , 'commits-for-current-buffer'],
      \ 'C' : ['Gcommit'      , 'commit'],
      \ 'd' : ['Gdiff'        , 'diff'],
      \ 'e' : ['Gedit'        , 'edit'],
      \ 'l' : ['Glog'         , 'log'],
      \ 'r' : ['Gread'        , 'read'],
      \ 's' : ['Gstatus'      , 'status'],
      \ 'w' : ['Gwrite'       , 'write'],
      \ 'm' : ['GitMessenger' , 'messenger'],
      \ 'p' : ['Git push'     , 'push']
      \ }
let g:which_key_map.l = {
      \ 'name' : '+lsp/coc',
      \ 'd' : 'debugger',
      \ 'a' : 'code-action',
      \ 'A' : 'code-action-selected',
      \ 'R' : 'rename',
      \ 'n' : 'rename',
      \ 'c' : 'context-menu',
      \ 'o' : 'open-link',
      \ 'h' : 'hover',
      \ 'f' : 'format',
      \ 'F' : 'format-selected',
      \ 'l' : 'highlight',
      \ 'L' : 'unmark-highlight',
      \ 'r' : 'references',
      \ 's' : 'document-symbol',
      \ 'i' : 'toggle-indent-lines',
      \ 'S' : 'workspace-symbol',
      \ 'g' : {
      \   'name': '+goto',
      \   'd' : 'definition',
      \   'D' : 'dash-search',
      \   'i' : 'implementation',
      \   't' : 'type-definition',
      \   },
      \ 'D' : 'diagnostics-list',
      \ 'E' : 'extensions-list',
      \ 'G' : 'git-status-list',
      \ 'O' : 'outline-list',
      \ 'C' : 'commands-list',
      \ 'Y' : 'yank-list',
      \ }

let g:which_key_map.t = {
      \ 'name' : '+test',
      \ 'a' : 'test-all-suite',
      \ 'f' : 'test-file',
      \ 'n' : 'test-nearest',
      \ 't' : 'test-nearest',
      \ 'l' : 'test-last',
      \ 'v' : 'test-visited',
      \ 'p' : 'alternate-file',
      \ 'pv' : 'alternate-file-vertical',
      \ }
let g:which_key_map.b = {
      \ 'name' : '+buffer' ,
      \ 'd' : 'delete-buffer',
      \ 'f' : 'first-buffer',
      \ 'l' : 'last-buffer',
      \ 'n' : 'next-buffer',
      \ '#' : 'last-used-buffer',
      \ 'p' : 'previous-buffer',
      \ 'x' : 'purge-other-buffers',
      \ 'b' : 'buffers',
      \ }
let g:which_key_map.e = {
      \ 'name' : '+file-edits' ,
      \ 'k' : 'kitty.conf',
      \ 't' : 'tmux.conf',
      \ 'v' : 'init.vim',
      \ 'z' : 'zshrc',
      \ 'g' : 'gitconfig',
      \ }
nnoremap <silent> <leader> :<c-u>WhichKey ','<CR>
vnoremap <silent> <leader> :<c-u>WhichKeyVisual ','<CR>
call which_key#register(',', 'g:which_key_map')


" ## netrw
let g:netrw_winsize = -28 " absolute width of netrw window
let g:netrw_banner = 1 " do not display info on the top of window
let g:netrw_liststyle = 3 " tree-view
let g:netrw_sort_sequence = '[\/]$,*' " sort is affecting only: directories on the top, files below
let g:netrw_browse_split = 0 " use the previous window to open file
let g:netrw_altv = 1
function! ToggleVExplorer()
  if exists('t:expl_buf_num')
    let expl_win_num = bufwinnr(t:expl_buf_num)
    if expl_win_num != -1
      let cur_win_nr = winnr()
      exec expl_win_num . 'wincmd w'
      close
      exec cur_win_nr . 'wincmd w'
      unlet t:expl_buf_num
    else
      unlet t:expl_buf_num
    endif
  else
    exec '1wincmd w'
    Vexplore
    set number
    let t:expl_buf_num = bufnr('%')
  endif
endfunction
nnoremap <silent> <F2> :call ToggleVExplorer()<CR>

" ## junegunn/fzf
let g:fzf_action = {
      \ 'ctrl-s': 'split',
      \ 'ctrl-v': 'vsplit',
      \ 'enter': 'vsplit'
      \ }
let g:fzf_layout = { 'down': '~15%' }

" ## rg
if executable('rg')
  set grepprg=rg\ --vimgrep                                                       "Use ripgrep for grepping

  function! s:CompleteRg(arg_lead, line, pos)
    let l:args = join(split(a:line)[1:])
    return systemlist('get_completions rg ' . l:args)
  endfunction

  " Add support for ripgrep
  " https://github.com/dsifford/.dotfiles/blob/master/vim/.vimrc#L130
  let $BAT_THEME = 'base16' " REF: https://github.com/junegunn/fzf.vim/issues/732#issuecomment-437276088
  command! -bang -complete=customlist,s:CompleteRg -nargs=* Rg
        \ call fzf#vim#grep(
        \   'rg --column --line-number --no-heading --color=always --fixed-strings --smart-case --hidden --follow --glob "!{.git,deps,node_modules}/*" '.shellescape(<q-args>).'| tr -d "\017"', 1,
        \   <bang>0 ? fzf#vim#with_preview('up:40%')
        \           : fzf#vim#with_preview('right:50%', '?'),
        \   <bang>0)
  command! -bang -nargs=? -complete=dir Files
        \ call fzf#vim#files(<q-args>,
        \   <bang>0 ? fzf#vim#with_preview('up:40%')
        \           : fzf#vim#with_preview('right:50%', '?'),
        \   <bang>0)
  command! -bang -nargs=* WikiSearch
        \ call fzf#vim#grep(
        \  'rg --column --line-number --no-heading --color "always" '.shellescape(<q-args>).' '.$HOME.'/wiki/', 1,
        \  <bang>0 ? fzf#vim#with_preview({'options': '--delimiter : --nth 4..'}, 'up:40%')
        \          : fzf#vim#with_preview({'options': '--delimiter : --nth 4..'}, 'right:50%:hidden', '?'),
        \  <bang>0)

  nnoremap <leader>a <ESC>:Rg<SPACE>
  nnoremap <silent> <leader>A  <ESC>:exe('Rg '.expand('<cword>'))<CR>
  " Backslash as shortcut to ag
  nnoremap \ :Rg<SPACE>
endif

function! FZFWithDevIcons()
  let l:fzf_files_options = ' -m --bind ctrl-d:preview-page-down,ctrl-u:preview-page-up --preview "bat --theme="base16" --color always --style numbers {2..}"'

  function! s:files()
    let l:files = split(system($FZF_DEFAULT_COMMAND), '\n')
    return s:prepend_icon(l:files)
  endfunction

  function! s:prepend_icon(candidates)
    let result = []
    for candidate in a:candidates
      let filename = fnamemodify(candidate, ':p:t')
      let icon = WebDevIconsGetFileTypeSymbol(filename, isdirectory(filename))
      call add(result, printf("%s %s", icon, candidate))
    endfor

    return result
  endfunction

  function! s:edit_file(items)
    let items = a:items
    let i = 1
    let ln = len(items)
    while i < ln
      let item = items[i]
      let parts = split(item, ' ')
      let file_path = get(parts, 1, '')
      let items[i] = file_path
      let i += 1
    endwhile
    call s:Sink(items)
  endfunction

  let opts = fzf#wrap({})
  let opts.source = <sid>files()
  let s:Sink = opts['sink*']
  let opts['sink*'] = function('s:edit_file')
  let opts.options .= l:fzf_files_options
  call fzf#run(opts)

endfunction

function! FZFDevIcons()
  let l:fzf_files_options = '--preview "bat --theme="base16" --style=numbers,changes --preview-window=right:60%:wrap --color always {2..-1} | head -'.&lines.'"'

  function! s:files()
    let l:files = split(system($FZF_DEFAULT_COMMAND), '\n')
    return s:prepend_icon(l:files)
  endfunction

  function! s:prepend_icon(candidates)
    let l:result = []
    for l:candidate in a:candidates
      let l:filename = fnamemodify(l:candidate, ':p:t')
      let l:icon = WebDevIconsGetFileTypeSymbol(l:filename, isdirectory(l:filename))
      call add(l:result, printf('%s %s', l:icon, l:candidate))
    endfor

    return l:result
  endfunction

  function! s:edit_file(item)
    let l:pos = stridx(a:item, ' ')
    let l:file_path = a:item[pos+1:-1]
    execute 'silent vsp' l:file_path
  endfunction

  call fzf#run({
        \ 'source': <sid>files(),
        \ 'sink':   function('s:edit_file'),
        \ 'options': '-m ' . l:fzf_files_options,
        \ 'down':    '40%' })
endfunction

silent! unmap <leader>m
nnoremap <silent> <leader>m <ESC>:FZF --tiebreak=begin,length,index<CR>
" nnoremap <silent> <leader>m <ESC>:FZF --tiebreak=begin,length,index<CR>
" nnoremap <silent> <leader>m :call FZFWithDevIcons()<CR>
" nnoremap <silent> <leader>m :call FZFDevIcons()<CR>

function! s:change_branch(e)
  let l:_ = system('git checkout ' . a:e)
  :e!
  echom 'Changed branch to' . a:e
endfunction

function! s:change_remote_branch(e)
  let l:_ = system('git checkout --track ' . a:e)
  :e!
  echom 'Changed to remote branch' . a:e
endfunction

function! s:parse_pivotal_story(entry)
  let l:stories = pivotaltracker#stories('', '')
  let l:filtered = filter(l:stories, {_idx, val -> val.menu == a:entry[-1]})
  return l:filtered[0].word
endfunction

inoremap <expr> <c-x># fzf#complete(
      \ {
      \ 'source': map(pivotaltracker#stories('', ''), {_key, val -> val.menu}),
      \ 'reducer': function('<sid>parse_pivotal_story'),
      \ 'options': '-m',
      \ 'down': '20%'
      \ })

inoremap <expr> <c-x>t fzf#complete(
      \ {
      \ 'source': map(pivotaltracker#stories('', ''), {_key, val -> val.menu}),
      \ 'options': '-m',
      \ 'down': '20%'
      \ })

command! Gbranch call fzf#run(
      \ {
      \ 'source': 'git branch',
      \ 'sink': function('<sid>change_branch'),
      \ 'options': '-m',
      \ 'down': '20%'
      \ })

command! Grbranch call fzf#run(
      \ {
      \ 'source': 'git branch -r',
      \ 'sink': function('<sid>change_remote_branch'),
      \ 'options': '-m',
      \ 'down': '20%'
      \ })


" ## w0rp/ale
let g:ale_enabled = 1
let g:ale_completion_enabled = 0
let g:ale_lint_delay = 1000
let g:ale_echo_msg_format = '[%linter%] %s'
let g:ale_linters = {}
let g:ale_fixers = {
      \   '*': ['remove_trailing_lines', 'trim_whitespace'],
      \   'javascript': ['prettier_eslint'],
      \   'javascript.jsx': ['prettier_eslint'],
      \   'css': ['prettier'],
      \   'scss': ['prettier'],
      \   'json': ['prettier'],
      \   'elm': [],
      \   'elixir': ['mix_format'],
      \   'eelixir': ['mix_format'],
      \ }
let g:ale_elm_format_options = '--yes --elm-version=0.18'
let g:ale_javascript_eslint_use_global = 1
let g:ale_lint_on_text_changed = 'never'
let g:ale_lint_on_insert_leave = 0
let g:ale_lint_on_enter = 0
let g:ale_lint_on_save = 0
let g:ale_fix_on_save = 1


" gruvbox-community/gruvbox
let g:gruvbox_improved_strings=1
let g:gruvbox_improved_warnings=1
let g:gruvbox_italicize_strings=0
let g:gruvbox_guisp_fallback='fg'
let g:gruvbox_contrast_light='medium'
let g:gruvbox_contrast_dark='medium'
" silent! colorscheme gruvbox


" ## trevordmiller/nova-vim
" set background=light
if system('darkMode') =~ "Dark"
  set background=dark
endif
let g:nova_transparent = 1
silent! colorscheme nova


" ## RRethy/hexokinase
let g:Hexokinase_highlighters = ['virtual']
let g:Hexokinase_virtualText = '■'
" let g:Hexokinase_virtualText = '██'
let g:Hexokinase_ftAutoload = ['css', 'scss', 'sass', 'less']


" ## vim-devicons
" let g:WebDevIconsUnicodeDecorateFileNodesExtensionSymbols['vim'] = ''
let g:WebDevIconsUnicodeDecorateFolderNodesDefaultSymbol = ''
let g:WebDevIconsOS = 'Darwin'
let g:WebDevIconsUnicodeDecorateFolderNodes = 1
let g:WebDevIconsUnicodeDecorateFileNodesDefaultSymbol = ''
let g:WebDevIconsUnicodeDecorateFolderNodes = 1
let g:WebDevIconsUnicodeDecorateFolderNodesDefaultSymbol = ''
let g:WebDevIconsUnicodeDecorateFileNodesExtensionSymbols = {} " needed
let g:WebDevIconsUnicodeDecorateFileNodesExtensionSymbols['js'] = "\ue74e"
let g:WebDevIconsUnicodeDecorateFileNodesExtensionSymbols['jsx'] = "\ue74e"
let g:WebDevIconsUnicodeDecorateFileNodesExtensionSymbols['tsx'] = ''
let g:WebDevIconsUnicodeDecorateFileNodesExtensionSymbols['css'] = ''
let g:WebDevIconsUnicodeDecorateFileNodesExtensionSymbols['html'] = ''
let g:WebDevIconsUnicodeDecorateFileNodesExtensionSymbols['json'] = ''
let g:WebDevIconsUnicodeDecorateFileNodesExtensionSymbols['md'] = ''
let g:WebDevIconsUnicodeDecorateFileNodesExtensionSymbols['sql'] = ''
let g:WebDevIconsUnicodeDecorateFileNodesExtensionSymbols['ex'] = "\ue62d"
let g:WebDevIconsUnicodeDecorateFileNodesExtensionSymbols['exs'] = "\ue62d"
let g:WebDevIconsUnicodeDecorateFileNodesExtensionSymbols['elm'] = "\ue62c"

" ## vim-projectionist
let g:projectionist_heuristics = {
      \  'mix.exs': {
      \    'lib/*.ex': {
      \      'type': 'src',
      \      'alternate': 'test/{}_test.exs',
      \    },
      \    'test/*_test.exs': {
      \      'type': 'test',
      \      'alternate': 'lib/{}.ex',
      \    },
      \    "mix.exs": {
      \      "type": "mix"
      \    },
      \    "config/config.exs": {
      \      "type": "config"
      \    }
      \  }
      \}
" \      'test': "mix test test/{}_test.exs`=v:lnum ? ':'.v:lnum : ''`"

" ## elm-vim
let g:elm_jump_to_error = 1
let g:elm_make_output_file = '/dev/null'
let g:elm_make_show_warnings = 1
let g:elm_syntastic_show_warnings = 1
let g:elm_browser_command = 'open'
let g:elm_detailed_complete = 1
let g:elm_format_autosave = 1 " (presently disabled in w0rp/ale)
let g:elm_format_fail_silently = 0
let g:elm_format_options = "--elm-version=0.18"
let g:elm_setup_keybindings = 0

" ## rainbow_parentheses.vim
let g:rainbow#max_level = 10
let g:rainbow#pairs = [['(', ')'], ['[', ']'], ['{', '}']]

" ## tpope/vim-surround
let g:surround_indent = 0
vmap [ S]
vmap ( S)
vmap { S}
vmap ' S'
vmap " S"
vmap ` S`

" ## tadaa/vimade
let g:vimade = {}
let g:vimade.fadelevel = 0.6

" ## tpope/vim-markdown
" ## plasticboy/vim-markdown
let g:markdown_fenced_languages = [
      \ 'javascript', 'js=javascript', 'json=javascript',
      \ 'css', 'scss', 'sass',
      \ 'ruby', 'erb=eruby',
      \ 'python',
      \ 'haml', 'html',
      \ 'bash=sh', 'zsh', 'elm', 'elixir']
let g:vim_markdown_folding_disabled = 1
let g:vim_markdown_conceal = 0
let g:vim_markdown_conceal_code_blocks = 0
let g:vim_markdown_folding_style_pythonic = 0
let g:vim_markdown_override_foldtext = 0
let g:vim_markdown_follow_anchor = 1
let g:vim_markdown_frontmatter = 1
let g:vim_markdown_new_list_item_indent = 2
let g:vim_markdown_no_extensions_in_markdown = 1
let g:vim_markdown_math=1
let g:vim_markdown_strikethrough=1
set conceallevel=2


" # itspriddle/vim-marked
" # iamcco/vim-markdown-preview
" nnoremap <Leader>M :MarkedOpen<CR>
nnoremap <Leader>M :MarkdownPreview<CR>


" ## vim-plug
noremap <F5> :PlugUpdate<CR>
map <F5> :PlugUpdate<CR>
noremap <S-F5> :PlugClean!<CR>
map <S-F5> :PlugClean!<CR>


" ## fugitive
nnoremap <leader>gh :Gbrowse<CR>
vnoremap <leader>gh :Gbrowse<CR>
nnoremap <leader>gb :Gblame<CR>


"  ## Plug 'sakhnik/nvim-gdb'
function! RunDebugger()
  if (index(['rust'], &filetype) >= 0)
	  ":GdbStart rust-gdb -q -ex start -f `find target/debug/ -type f -executable`
	  :GdbStart rust-gdb -q -ex start -f target/debug/rust_playground
  elseif (index(['sh'], &filetype) >= 0)
	  :GdbStartBashDB bashdb %
  endif
endfunction
noremap <leader>ld :<C-u>call RunDebugger()<cr>

" Plug 'Shougo/vimproc.vim', {'do' : 'make'}
" Plug 'idanarye/vim-vebugger'
" nnoremap <F5>   :VBGcontinue<CR>
" autocmd FileType c,cpp  nnoremap <F6>   :VBGstartGDB %:r<CR>
" autocmd FileType python nnoremap <F6>   :VBGstartPDB3 %<CR>
" nnoremap <F7>   :VBGstepIn<CR>
" nnoremap <F8>   :VBGstepOver<CR>
" nnoremap <C-F8> :VBGtoggleBreakpointThisLine<CR>
" nnoremap <F10>  :VBGstepOut<CR>

" let g:vebugger_leader = '\'
" if !exists('g:vdebug_options')
"     let g:vdebug_options = {}
" endif
" let g:vdebug_options.break_on_open = 0


" ## gist/github
let g:gist_open_url = 1
let g:gist_default_private = 1
" Send visual selection to gist.github.com as a private, filetyped Gist
" Requires the gist command line too (brew install gist)
vnoremap <leader>G :Gist -po<CR>

" ## dash.vim
nmap <silent> <leader>lgD <Plug>DashSearch

" ## vim-commentary
nmap <leader>c :Commentary<CR>
vmap <leader>c :Commentary<CR>

" ## tmux-navigator
let g:tmux_navigator_no_mappings = 1
let g:tmux_navigator_save_on_switch = 2
let g:tmux_navigator_disable_when_zoomed = 0

" ## indentLine
let g:indentLine_enabled = 1
let g:indentLine_color_gui = '#556874'
let g:indentLine_char = '│'
let g:indentLine_bufTypeExclude = ['help', 'terminal', 'nerdtree', 'tagbar', 'startify']
let g:indentLine_bufNameExclude = ['_.*', 'NERD_tree.*', 'startify']

" ## golden-ratio
let g:golden_ratio_exclude_nonmodifiable = 1
let g:golden_ratio_wrap_ignored = 0
let g:golden_ratio_ignore_horizontal_splits = 1

" ## quick-scope
let g:qs_enable = 1
let g:qs_highlight_on_keys = ['f', 'F', 't', 'T']

" ## svermeulen/vim-yoink
let g:yoinkIncludeDeleteOperations = 1
let g:yoinkSyncSystemClipboardOnFocus = 0
let g:yoinkAutoFormatPaste = 1
nmap <special> <c-n> <plug>(YoinkPostPasteSwapForward)
nmap <special> <c-p> <plug>(YoinkPostPasteSwapBack)
nmap p <plug>(YoinkPaste_p)
nmap P <plug>(YoinkPaste_P)

" ## janko/vim-test (testing)
function! TerminalSplit(cmd)
  vert new | set filetype=test | call termopen(['/usr/local/bin/zsh', '-c', a:cmd], {'curwin':1})
endfunction

function! ElixirUmbrellaTransform(cmd) abort
  if match(a:cmd, 'vpp/') != -1
    return substitute(a:cmd, 'mix test vpp/apps/\([^/]*/\)\(.*\)', '(cd vpp/apps/\1 \&\& mix test \2)', '')
  else
    return a:cmd
  end
endfunction
let g:test#custom_transformations = {'elixir_umbrella': function('ElixirUmbrellaTransform')}
let g:test#transformation = 'elixir_umbrella'

" function! UmbrellaElixirTestTransform(cmd) abort
"   echo "a:cmd is: " . a:cmd

"   let testCommand = join(split(a:cmd)[0:-2])
"   let umbrellaTestFilePath = split(a:cmd)[-1]
"   let pathFragments = split(umbrellaTestFilePath, "/")
"   let appName = pathFragments[1]
"   let localTestPath = join(pathFragments[2:], "/")

"   echo "UmbrellaElixirTestTransform: " . testCommand

"   if a:cmd =~ 'sims/'
"     echo "in a:cmd =~ 'sims/'"
"     return a:cmd
"   endif

"   if a:cmd !~ 'apps/'
"     echo "in a:cmd !~ 'apps/'"
"     return a:cmd
"   endif

"   return join(["mix cmd --app ", appName, testCommand, localTestPath])
" endfunction
" let g:test#custom_transformations = {'elixir': function('UmbrellaElixirTestTransform')}
" let g:test#transformation = 'elixir'
let g:test#custom_strategies = {'terminal_split': function('TerminalSplit')}
let g:test#strategy = 'terminal_split'
let g:test#filename_modifier = ':.'
let g:test#preserve_screen = 0
let g:test#elixir#exunit#executable = 'mix test'
" let g:test#elixir#exunit#executable = 'MIX_ENV=test mix test'
nmap <silent> <leader>tf :TestFile<CR>
nmap <silent> <leader>tt :TestVisit<CR>
nmap <silent> <leader>tn :TestNearest<CR>
nmap <silent> <leader>tl :TestLast<CR>
nmap <silent> <leader>ta :TestSuite<CR>
nmap <silent> <leader>tv :TestVisit<CR>
nmap <silent> <leader>tp :A<CR>
nmap <silent> <leader>tpv :AV<CR>
" ref: https://github.com/Dkendal/dot-files/blob/master/nvim/.config/nvim/init.vim


"}}}
" ░░░░░░░░░░░░░░░ blink {{{

" REF: https://github.com/sedm0784/vimconfig/blob/master/_vimrc#L173
" Modified version of Damian Conway's Die Blinkënmatchen: highlight matches
"
" This is how long you want the blinking to last in milliseconds. If you're
" using an earlier Vim without the `+timers` feature, you need a much shorter
" blink time because Vim blocks while it waits for the blink to complete.
let s:blink_length = has('timers') ? 500 : 100

if has('timers')
  " This is the length of each blink in milliseconds. If you just want an
  " interruptible non-blinking highlight, set this to match s:blink_length
  " by uncommenting the line below
  let s:blink_freq = 50
  "let s:blink_freq = s:blink_length
  let s:blink_match_id = 0
  let s:blink_timer_id = 0
  let s:blink_stop_id = 0

  " Toggle the blink highlight. This is called many times repeatedly in order
  " to create the blinking effect.
  function! BlinkToggle(target_pat, timer_id)
    if s:blink_match_id > 0
      " Clear highlight
      call BlinkClear()
    else
      " Set highlight
      let s:blink_match_id = matchadd('ErrorMsg', a:target_pat, 101)
      redraw
    endif
  endfunction

  " Remove the blink highlight
  function! BlinkClear()
    call matchdelete(s:blink_match_id)
    let s:blink_match_id = 0
    redraw
  endfunction

  " Stop blinking
  "
  " Cancels all the timers and removes the highlight if necessary.
  function! BlinkStop(timer_id)
    " Cancel timers
    if s:blink_timer_id > 0
      call timer_stop(s:blink_timer_id)
      let s:blink_timer_id = 0
    endif
    if s:blink_stop_id > 0
      call timer_stop(s:blink_stop_id)
      let s:blink_stop_id = 0
    endif
    " And clear blink highlight
    if s:blink_match_id > 0
      call BlinkClear()
    endif
  endfunction

  augroup blink_matched
    autocmd!
    autocmd CursorMoved * call BlinkStop(0)
    autocmd InsertEnter * call BlinkStop(0)
  augroup END
endif

function! HLNext(blink_length, blink_freq)
  let target_pat = '\c\%#'.@/
  if has('timers')
    " Reset any existing blinks
    call BlinkStop(0)
    " Start blinking. It is necessary to call this now so that the match is
    " highlighted initially (in case of large values of a:blink_freq)
    call BlinkToggle(target_pat, 0)
    " Set up blink timers.
    let s:blink_timer_id = timer_start(a:blink_freq, function('BlinkToggle', [target_pat]), {'repeat': -1})
    let s:blink_stop_id = timer_start(a:blink_length, 'BlinkStop')
  else
    " Vim doesn't have the +timers feature. Just use Conway's original
    " code.
    "
    " Highlight the match
    let ring = matchadd('ErrorMsg', target_pat, 101)
    redraw
    " Wait
    exec 'sleep ' . a:blink_length . 'm'
    " Remove the highlight
    call matchdelete(ring)
    redraw
  endif
endfunction

" Set up maps for n and N that blink the match
execute printf('nnoremap <silent> n n:call HLNext(%d, %d)<cr>', s:blink_length, has('timers') ? s:blink_freq : s:blink_length)
execute printf('nnoremap <silent> N N:call HLNext(%d, %d)<cr>', s:blink_length, has('timers') ? s:blink_freq : s:blink_length)

" }}}
" ░░░░░░░░░░░░░░░ lightline/statusbar {{{

let status_timer = timer_start(1000, 'UpdateStatusBar', { 'repeat': -1 })
let g:lightline = {
      \   'colorscheme': 'nova',
      \   'component': {
      \     'modified': '%#ModifiedColor#%{LightlineModified()}',
      \   },
      \   'component_function': {
      \     'readonly': 'LightlineReadonly',
      \     'filename': 'LightlineFileName',
      \     'filetype': 'LightlineFileType',
      \     'fileformat': 'LightlineFileFormat',
      \     'branch': 'LightlineBranch',
      \     'lineinfo': 'LightlineLineInfo',
      \     'percent': 'LightlinePercent',
      \     'cocstatus': 'coc#status',
      \   },
      \   'component_expand': {
      \     'coc_error'        : 'LightlineCocErrors',
      \     'coc_warning'      : 'LightlineCocWarnings',
      \     'coc_info'         : 'LightlineCocInfos',
      \     'coc_hint'         : 'LightlineCocHints',
      \     'coc_fix'          : 'LightlineCocFixes',
      \   },
      \   'component_type': {
      \     'readonly': 'error',
      \     'modified': 'raw',
      \     'linter_checking': 'left',
      \     'linter_warnings': 'warning',
      \     'linter_errors': 'error',
      \     'linter_ok': 'left',
      \     'coc_error'        : 'error',
      \     'coc_warning'      : 'warning',
      \     'coc_info'         : 'tabsel',
      \     'coc_hint'         : 'middle',
      \     'coc_fix'          : 'middle',
      \   },
      \   'component_function_visible_condition': {
      \     'branch': '&buftype!="nofile"',
      \     'filename': '&buftype!="nofile"',
      \     'fileformat': '&buftype!="nofile"',
      \     'fileencoding': '&buftype!="nofile"',
      \     'filetype': '&buftype!="nofile"',
      \     'percent': '&buftype!="nofile"',
      \     'lineinfo': '&buftype!="nofile"',
      \     'time': '&buftype!="nofile"',
      \   },
      \   'active': {
      \     'left': [
      \       ['mode'],
      \       ['branch'],
      \       ['filename'],
      \       ['spell'],
      \       ['paste', 'readonly', 'modified'],
      \     ],
      \     'right': [
      \       ['lineinfo', 'percent'],
      \       ['cocstatus'],
      \       ['filetype', 'fileformat'],
      \     ],
      \   },
      \   'inactive': {
      \     'left': [ ['filename'], ['readonly', 'modified'] ],
      \     'right': [ ['lineinfo'], ['fileinfo' ] ],
      \   },
      \   'mode_map': {
      \     'n' : 'N',
      \     'i' : 'I',
      \     'R' : 'R',
      \     'v' : 'V',
      \     'V' : 'V-LINE',
      \     "\<C-v>": 'V-BLOCK',
      \     'c' : 'C',
      \     's' : 'S',
      \     'S' : 'S-LINE',
      \     "\<C-s>": 'S-BLOCK',
      \     't': 'T',
      \   },
      \ }

let g:lightline#ale#indicator_ok = "\uf42e  "
let g:lightline#ale#indicator_warnings = '  '
let g:lightline#ale#indicator_errors = '  '
let g:lightline#ale#indicator_checking = '  '

let g:coc_status_warning_sign = '  '
let g:coc_status_error_sign = '  '

function! UpdateStatusBar(timer)
  " call lightline#update()
endfunction

function! PrintStatusline(v)
  return &buftype ==? 'nofile' ? '' : a:v
endfunction

function! LightlineFileType()
  " return winwidth(0) > 70 ? (strlen(&filetype) ? WebDevIconsGetFileTypeSymbol() . ' '. &filetype : 'no ft') : ''
  return &filetype
endfunction

function! LightlineFileFormat()
  " return winwidth(0) > 70 ? (WebDevIconsGetFileFormatSymbol() . ' ' . &fileformat) : ''
  return &fileformat
endfunction

function! LightlineBranch()
  if exists('*fugitive#head')
    let l:branch = fugitive#head()
    return PrintStatusline(branch !=# '' ? ' ' . l:branch : '')
  endif
  return ''
endfunction

function! LightlineLineInfo()
  return PrintStatusline(printf("\ue0a1 %d/%d %d:%d", line('.'), line('$'), col('.'), col('$')))
endfunction

function! LightlinePercent()
  return PrintStatusline("\uf0c9 " . line('.') * 100 / line('$') . '%')
endfunction

function! LightlineReadonly()
  " return PrintStatusline(&ro ? "\ue0a2" : '')
  return PrintStatusline(&readonly && &filetype !=# 'help' ? '' : '')
endfunction

function! LightlineModified()
  return PrintStatusline(!&modifiable ? '-' : &modified ?
        \ '' : '')
endfunction

function! LightlineFileName()
  " Get the full path of the current file.
  let filepath =  expand('%:p')

  " If the filename is empty, then display nothing as appropriate.
  if empty(filepath)
    return '[No Name]'
  endif

  " Find the correct expansion depending on whether Vim has autochdir.
  let mod = (exists('+autochdir') && &autochdir) ? ':~' : ':~:.'

  " Apply the above expansion to the expanded file path and split by the separator.
  let shortened_filepath = fnamemodify(filepath, mod)
  if len(shortened_filepath) < 45
    return shortened_filepath
  endif

  " Ensure that we have the correct slash for the OS.
  let dirsep = has('win32') && ! &shellslash ? '\\' : '/'

  " Check if the filepath was shortened above.
  let was_shortened = filepath != shortened_filepath

  " Split the filepath.
  let filepath_parts = split(shortened_filepath, dirsep)

  " Take the first character from each part of the path (except the tidle and filename).
  let initial_position = was_shortened ? 0 : 1
  let excluded_parts = filepath_parts[initial_position:-2]
  let shortened_paths = map(excluded_parts, 'v:val[0]')

  " Recombine the shortened paths with the tilde and filename.
  let combined_parts = shortened_paths + [filepath_parts[-1]]
  let combined_parts = (was_shortened ? [] : [filepath_parts[0]]) + combined_parts

  " Recombine into a single string.
  let finalpath = join(combined_parts, dirsep)
  return PrintStatusline(finalpath)
  " return finalpath
endfunction

function! LightlineCocDiagnostics() abort
  if !get(g:, 'coc_enabled', 0)
    return ''
  endif

  " let info = get(b:, 'coc_diagnostic_info', {})
  let info = get(b:, 'coc_diagnostic_info', 0)

  " if empty(info) || get(info, a:kind, 0) == 0
  "   return "\uf42e"
  " endif

  if empty(info) | return '' | endif

  let msgs = []

  if get(info, 'error', 0)
    call add(msgs, ' ' . info['error'])
  endif

  if get(info, 'warning', 0)
    call add(msgs, ' ' . info['warning'])
  endif

  return PrintStatusline(join(msgs, ' '). ' ' . get(g:, 'coc_status', ''))
endfunction

function! LightlineCocErrors() abort
  return s:lightline_coc_diagnostic('error', 'error')
endfunction

function! LightlineCocWarnings() abort
  return s:lightline_coc_diagnostic('warning', 'warning')
endfunction

function! LightlineCocInfos() abort
  return s:lightline_coc_diagnostic('information', 'info')
endfunction

function! LightlineCocHints() abort
  return s:lightline_coc_diagnostic('hints', 'hint')
endfunction

function! LightlineCocFixes() abort
  let b:coc_line_fixes = get(get(b:, 'coc_quickfixes', {}), line('.'), 0)
  return b:coc_line_fixes > 0 ? printf('%d ', b:coc_line_fixes) : ''
endfunction

function! s:lightline_coc_diagnostic(kind, sign) abort
  if !get(g:, 'coc_enabled', 0)
    return ''
  endif
  let c = get(b:, 'coc_diagnostic_info', 0)
  if empty(c) || get(c, a:kind, 0) == 0
    return ''
  endif
  try
    let s = g:coc_user_config['diagnostic'][a:sign . 'Sign']
  catch
    " let s = ' '
    let s = ''
  endtry
  return printf('%d %s', c[a:kind], s)
endfunction

" }}}
" ░░░░░░░░░░░░░░░ coc.nvim {{{
let g:coc_force_debug = 0
let g:coc_node_path = $HOME . '/.asdf/installs/nodejs/10.15.3/bin/node'

" for showSignatureHelp
set completeopt=noinsert,menuone "https://github.com/neoclide/coc.nvim/issues/478
set shortmess+=c

" FOR COC-SNIPPETS + COC.NVIM
" ---------------------------
inoremap <silent><expr> <TAB>
      \ pumvisible() ? coc#_select_confirm() :
      \ coc#expandableOrJumpable() ? coc#rpc#request('doKeymap', ['snippets-expand-jump','']) :
      \ <SID>check_back_space() ? "\<TAB>" :
      \ coc#refresh()

function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

let g:coc_snippet_next = '<TAB>'
let g:coc_snippet_prev = '<S-TAB>'

" Use <C-e> for trigger completion.
" inoremap <silent><expr> <C-e> coc#refresh()
" imap <expr> <C-e> pumvisible() ? (<SID>isSnipsExpandable() ? "<C-R>=UltiSnips#ExpandSnippet()<CR>" : "") : "\<ESC>A"
" inoremap <expr> <C-e> pumvisible() ? (<SID>isSnipsExpandable() ? "<C-R>=UltiSnips#ExpandSnippet()<CR>" : "") : "\<ESC>A"

" Instead of coc.nvim specific things, let's just do readline things here in
" insert mode
inoremap <silent> <C-e> <ESC>A
inoremap <silent> <C-a> <ESC>I

" Use <TAB> and <S-TAB> for navigate completion list:
inoremap <expr> <Tab> pumvisible() ? "\<C-n>" : "\<Tab>"
inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"

" Use <CR> for confirm completion.
" Coc only does snippet and additional edit on confirm.
inoremap <expr> <CR> pumvisible() ? "\<C-y>" : "\<C-g>u\<CR>"

" Use <C-x><C-o> to complete 'word', 'emoji' and 'include' sources
imap <silent> <C-x><C-o> <Plug>(coc-complete-custom)

" Use K for show documentation in preview window
function! s:show_documentation()
  if &filetype ==# 'vim'
    execute 'h '.expand('<cword>')
  else
    call CocActionAsync('doHover')
  endif
endfunction

" ToggleCoc: disable coc.nvim for large file
function! ToggleCoc() abort
  let g:trigger_size = get(g:, 'trigger_size', 0.5 * 1048576)
  let size = getfsize(expand('<afile>'))
  if (size > g:trigger_size) || (size == -2)
    echohl WarningMsg
    echomsg 'Coc.nvim was disabled for this large file'
    echohl None
    exec 'CocDisable'
  else
    exec 'CocEnable'
  endif
endfunction

" ShowDoc: show document
function! ShowDoc() abort
  if (index(['vim','help'], &filetype) >= 0)
      execute 'h '.expand('<cword>')
    else
      call CocAction('jumpDefinition')
    endif
endfunction

nmap <silent> [c <Plug>(coc-diagnostic-prev)
nmap <silent> ]c <Plug>(coc-diagnostic-next)
" nmap <silent> [l <Plug>(coc-diagnostic-prev)
" nmap <silent> ]l <Plug>(coc-diagnostic-next)

" nnoremap <silent> K :call <SID>show_documentation()<CR>
nnoremap <silent> K :<C-u>call ShowDoc()<CR>
nnoremap <silent> <leader>lh :call <SID>show_documentation()<CR>
vnoremap <silent> <leader>lh :call <SID>show_documentation()<CR>

nmap <silent> <leader>lgd <Plug>(coc-definition)
nmap <silent> <leader>lgt <Plug>(coc-type-definition)
nmap <silent> <leader>lgi <Plug>(coc-implementation)

nmap <silent> <leader>lr <Plug>(coc-references)

nmap <silent> <leader>ln <Plug>(coc-rename)
nmap <silent> <leader>lR <Plug>(coc-rename)
vmap <silent> <leader>ln <Plug>(coc-rename)

nmap <silent> <leader>la <Plug>(coc-codeaction)
nmap <silent> <leader>lA <Plug>(coc-codeaction-selected)
vmap <silent> <leader>lA <Plug>(coc-codeaction-selected)

nmap <silent> <leader>lo <Plug>(coc-openlink)

" Fix autofix problem of current line
nmap <silent> <leader>lq <Plug>(coc-fix-current)

" Use `:Format` for format current buffer
command! -nargs=0 Format :call CocActionAsync('format')
" Use `:Fold` for fold current buffer
command! -nargs=? Fold :call CocActionAsync('fold', <f-args>)

 " Workspace symbols
nnoremap <silent> <leader>lS  :<C-u>CocList -I symbols<cr>
" Document symbols
nnoremap <silent> <leader>ls :<C-u>CocList outline<cr>
nnoremap <silent> <leader>lD :<C-u>CocList diagnostics<CR>
nnoremap <silent> <leader>lG :<C-u>CocList --normal --auto-preview gstatus<CR>
nnoremap <silent> <leader>lC :<C-u>CocList commands<cr>
nnoremap <silent> <leader>lO :<C-u>CocList outline<cr>
nnoremap <silent> <leader>lE :<C-u>CocList extensions<cr>
nnoremap <silent> <leader>lY :<C-u>CocList -A --normal yank<CR>

nmap [g <Plug>(coc-git-prevchunk)
nmap ]g <Plug>(coc-git-nextchunk)
nmap gs <Plug>(coc-git-chunkinfo)

" nmap <silent> ,b <Plug>(coc-bookmark-toggle)
" nmap <silent> ,a <Plug>(coc-bookmark-annotate)
" nmap <silent> gh <Plug>(coc-bookmark-prev)
" nmap <silent> gl <Plug>(coc-bookmark-next)

augroup Coc
  au!
  au BufReadPre * call ToggleCoc()
  " au CursorHold * silent call CocActionAsync('highlight')
  au CursorHoldI * silent call CocActionAsync('showSignatureHelp')
  au User CocJumpPlaceholder call CocActionAsync('showSignatureHelp')
  au User CocDiagnosticChange call lightline#update_once()
augroup END

"}}}
" ░░░░░░░░░░░░░░░ highlights/colors {{{

  hi clear SpellBad
  hi clear SpellCap

  hi htmlArg cterm=italic gui=italic
  hi xmlAttrib cterm=italic gui=italic
  hi Type cterm=italic gui=italic
  hi Comment cterm=italic term=italic gui=italic
  hi CursorLineNr guibg=#333333 guifg=#ffffff guifg=#db9c5e gui=italic

  " FIXME: IncSearch negatively affects my FZF colors
  " hi IncSearch guifg=#FFFACD

  " highlight conflicts
  match ErrorMsg '^\(<\|=\|>\)\{7\}\([^=].\+\)\?$'

  hi SpellBad gui=undercurl,underline guifg=#DF8C8C guibg=#3C4C55
  hi SpellCap gui=undercurl,underline guifg=#DF8C8C guibg=#3C4C55

  hi VertSplit guifg=#666666 guibg=NONE

  hi SignColumn guibg=NONE

  hi link Debug SpellBad
  hi link ErrorMsg SpellBad
  hi link Exception SpellBad

  hi CocCodeLens ctermfg=gray guifg=#707070 " #556873

  hi CocGitAddedSign guifg=#A8CE93
  hi CocGitRemovedSign guifg=#DF8C8C
  hi CocGitChangedSign guifg=#F2C38F

  hi CocHintSign guifg=#666666
  hi CocHintHighlight gui=underline guifg=#666666

  hi CocWarningSign guifg=#F2C38F
  hi CocWarningHighlight gui=underline guifg=#F2C38F

  hi CocErrorSign guifg=#DF8C8C
  hi CocErrorHighlight gui=underline guifg=#DF8C8C

  hi ModifiedColor guifg=#DF8C8C guibg=NONE gui=bold
  hi illuminatedWord cterm=underline gui=underline
  " hi MatchParen cterm=bold gui=bold,italic guibg=#937f6e guifg=#222222
  hi MatchWord cterm=underline gui=underline,italic
  hi MatchParen cterm=underline gui=underline,italic

  hi Visual guifg=#3C4C55 guibg=#7FC1CA
  hi Normal guifg=#C5D4DD guibg=NONE

  hi QuickScopePrimary guifg='#afff5f' guibg=#222222 gui=underline
  hi QuickScopeSecondary guifg='#5fffff' guibg=#222222 gui=underline

  hi gitCommitOverflow guibg=#DF8C8C guifg=#333333 gui=underline
  hi DiffAdd guifg=#A8CE93
  hi DiffDelete guifg=#DF8C8C
  hi DiffAdded guifg=#A8CE93
  hi DiffRemoved guifg=#DF8C8C

  hi HighlightedyankRegion term=bold ctermbg=0 guibg=#13354A

  " Header such as 'Commit:', 'Author:'
  hi link gitmessengerHeader Identifier
  " Commit hash at 'Commit:' header
  hi link gitmessengerHash Comment
  " History number at 'History:' header
  hi link gitmessengerHistory Constant
  " Normal color. This color is the most important
  hi link gitmessengerPopupNormal CursorLine
  " Color of 'end of buffer'. To hide '~' in popup window, I recommend to use the same background
  " color as gitmessengerPopupNormal.
  hi gitmessengerEndOfBuffer term=None guifg=None guibg=None ctermfg=None ctermbg=None

" }}}

" vim:ft=vim
