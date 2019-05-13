scriptencoding utf-8
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
if executable('ctags')
  Plug 'craigemery/vim-autotag', { 'for': ['elm','elixir','eelixir'] }
  Plug 'liuchengxu/vista.vim', { 'on': ['Vista', 'Vista!!'] }
endif
Plug 'docunext/closetag.vim' " will auto-close the opening tag as soon as you type </
Plug 'editorconfig/editorconfig-vim'
Plug 'EinfachToll/DidYouMean' " Vim plugin which asks for the right file to open
Plug 'elixir-lang/vim-elixir', { 'for': ['elixir', 'eelixir'] }
Plug 'hail2u/vim-css3-syntax', { 'for': 'css' }
Plug 'HerringtonDarkholme/yats.vim', { 'for': ['typescript','typescriptreact','typescript.tsx'] }
Plug 'honza/vim-snippets'
Plug 'iamcco/markdown-preview.nvim', { 'for': ['md', 'markdown', 'mdown'], 'do': 'cd app & yarn install' } " https://github.com/iamcco/markdown-preview.nvim#install--usage
Plug 'itchyny/lightline.vim'

" Plug 'vim-airline/vim-airline'
" Plug 'vim-airline/vim-airline-themes'
" let g:airline_theme='nova'

Plug 'janko-m/vim-test', {'on': ['TestFile', 'TestLast', 'TestNearest', 'TestSuite', 'TestVisit'] } " tester for js and ruby
Plug 'jordwalke/VimAutoMakeDirectory' " auto-makes the dir for you if it doesn't exist in the path
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': 'yes \| ./install --all' }
Plug 'junegunn/fzf.vim'
Plug 'junegunn/goyo.vim', { 'on': 'Goyo' }
Plug 'junegunn/limelight.vim', { 'on': 'Limelight' }
Plug 'junegunn/rainbow_parentheses.vim' " nicely colors nested pairs of [], (), {}
" Plug 'junegunn/vim-slash'
Plug 'junegunn/vim-plug'
" Plug 'justinmk/vim-sneak'
Plug 'keith/gist.vim', { 'do': 'chmod -HR 0600 ~/.netrc' }
Plug 'KKPMW/distilled-vim' " colorscheme used for goyo
Plug 'wsdjeg/vim-fetch'
Plug 'liuchengxu/vim-which-key'
" Plug 'lilydjwg/colorizer' " or 'chrisbra/Colorizer'
Plug 'mattn/webapi-vim'
Plug 'mbbill/undotree', { 'on': 'UndotreeToggle' }
Plug 'megalithic/golden-ratio' " vertical split layout manager
" Plug 'mhinz/vim-mix-format'
Plug 'neoclide/jsonc.vim', { 'for': ['json','jsonc'] }
Plug 'neoclide/coc-neco'
if executable('yarn') && executable('node')
  function! PostInstallCoc(info)
    echo 'PostInstallCoc Status: ' . a:info.status
    if a:info.status ==# 'installed' || a:info.force
      let extensions = [
            \ 'coc-css',
            \ 'coc-diagnostic',
            \ 'coc-dictionary',
            \ 'coc-eslint',
            \ 'coc-git',
            \ 'coc-highlight',
            \ 'coc-html',
            \ 'coc-json',
            \ 'coc-lists',
            \ 'coc-prettier',
            \ 'coc-python',
            \ 'coc-rls',
            \ 'coc-snippets',
            \ 'coc-solargraph',
            \ 'coc-svg',
            \ 'coc-syntax',
            \ 'coc-tag',
            \ 'coc-tailwindcss',
            \ 'coc-tsserver',
            \ 'coc-tslint-plugin',
            \ 'coc-vimlsp',
            \ 'coc-word',
            \ 'coc-yaml',
            \ 'coc-yank',
            \ ]

      " -- disabled coc.nvim extensions:
      "
      " \ 'coc-emmet',
      " \ 'coc-emoji',
      " \ 'coc-highlight',
      " \ 'coc-omni',
      " \ 'coc-java',
      " \ 'coc-vetur',
      " \ 'coc-wxml',
      " \ 'coc-stylelint',
      " \ 'coc-ultisnips',
      " \ 'coc-snippets',
      " \ 'https://github.com/xabikos/vscode-react',
      " \ 'https://github.com/xabikos/vscode-javascript',
      " \ 'https://github.com/arubertoson/vscode-snippets',

      call coc#util#install()
      for l:ext in extensions
        if !(finddir(l:ext, coc#util#extension_root()))
          call coc#util#install_extension(['-sync', l:ext])
        endif
      endfor
    elseif a:info.status ==# 'updated'
			call coc#util#update_extensions(1)
    endif
  endfunction
  Plug 'neoclide/coc.nvim', {'do': function('PostInstallCoc')}
endif
Plug 'othree/csscomplete.vim', { 'for': 'css' }
Plug 'pangloss/vim-javascript', { 'for': 'javascript' }
Plug 'pbrisbin/vim-colors-off' " colorscheme used for goyo
Plug 'peitalin/vim-jsx-typescript', { 'for': ['javascript', 'typescript'] }
Plug 'powerman/vim-plugin-AnsiEsc' " supports ansi escape codes for documentation from lc/lsp/etc
Plug 'rizzatti/dash.vim'
Plug 'RRethy/vim-hexokinase'
" Plug 'rhysd/clever-f.vim'
Plug 'rhysd/git-messenger.vim'
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
Plug 'tpope/vim-markdown'
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
Plug 'Yggdroot/indentLine'
Plug 'zaptic/elm-vim', { 'for': ['elm'] }
Plug 'zenbro/mirror.vim' " allows mirror'ed editing of files locally, to a specified ssh location via ~/.mirrors
Plug 'sheerun/vim-polyglot'
Plug 'ryanoasis/vim-devicons' " has to be last according to docs

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

filetype plugin indent on

"}}}
" ░░░░░░░░░░░░░░░ options {{{

" ---- Color
set termguicolors

syntax on

" ---- Search
set ignorecase
set smartcase
if has('nvim')
  set inccommand=nosplit
endif

" ---- Tab completion
set wildmode=list:longest,full
set wildignore=*.swp,*.o,*.so,*.exe,*.dll
set wildoptions=pum

" ---- Scroll
set scrolloff=5                                                                 "Start scrolling when we're 8 lines away from margins
set sidescrolloff=15
set sidescroll=5

" ---- Tab settings
set tabstop=2
set shiftwidth=2
set expandtab

" ---- Hud
set ruler
set number
set nowrap
set fillchars=vert:\│,fold:·
" set colorcolumn=80
set nocursorline                                                                  "Highlight current line
if exists('+pumheight')
  set pumheight=30
endif
set cmdheight=1
set signcolumn=yes
" set cpoptions+=$              " dollar sign while changing
set synmaxcol=250             " set max syntax highlighting column to sane level
set visualbell t_vb=          " no visual bell
set t_ut=                     " fix 256 colors in tmux http://sunaku.github.io/vim-256color-bce.html
set laststatus=2

" ---- Show
set noshowmode                                                                  "Hide showmode because of the powerline plugin
set noshowcmd                                                                   "Hide incomplete cmds down the bottom
set showmatch                                                                 "Highlight matching bracket

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
set timeoutlen=500 ttimeoutlen=0                                               "Reduce Command timeout for faster escape and O
set updatetime=300

" ---- Split behaviors
set splitright                                                                  "Set up new vertical splits positions
set splitbelow                                                                  "Set up new horizontal splits positions

" ---- Diff opts
set diffopt-=internal
set diffopt+=indent-heuristic,algorithm:patience

" ---- Cursor
set guicursor=n-v-c:block,i-ci-ve:ver25,r-cr:hor20,o:hor50,a:blinkwait700-blinkoff400-blinkon250-Cursor/lCursor,sm:block-blinkwait175-blinkoff150-blinkon175
" set guicursor=n-v-c:block-Cursor/lCursor-blinkon0,i-ci:ver25-Cursor/lCursor,r-cr:hor20-Cursor/lCursor
if has('termguicolors')
  " Don't need this in xterm-256color, but do need it inside tmux.
  " (See `:h xterm-true-color`.)
  if &term =~# 'tmux-256color'
    let &t_8f="\e[38;2;%ld;%ld;%ldm"
    let &t_8b="\e[48;2;%ld;%ld;%ldm"
    " deus
    let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"
    let &t_8b = "\<Esc>[48;2;%lu;%lu;%lum"
  endif
endif
set guicursor=a:blinkon500-blinkwait500-blinkoff500                                   "Set cursor blinking rate

"}}}
" ░░░░░░░░░░░░░░░ mappings/remaps {{{

let mapleader=','
let maplocalleader=','

" Fancy macros
nnoremap q <Nop>
nnoremap Q @q
vnoremap Q :norm @q<cr>

" No arrow keys
map <Left>  :echo "ಠ_ಠ"<cr>
map <Right> :echo "ಠ_ಠ"<cr>
map <Up>    :echo "ಠ_ಠ"<cr>
map <Down>  :echo "ಠ_ಠ"<cr>

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

  " save all files on focus lost, ignoring warnings about untitled buffers
  autocmd FocusLost * silent! wa

  au FocusGained  * checktime "Refresh file when vim gets focus
  au BufEnter     * checktime
  au WinEnter     * checktime
  au CursorHold   * checktime
  au InsertEnter  * checktime

  " TODO: handle turning toggling the tmux status bar, if we're in $TMUX and Goyo is active
  " au FocusGained  * :echo "focus gained"
  " au FocusLost  * :echo "focus lost"

  " Refresh lightline when certain things happen
  " au TextChanged,InsertLeave,BufWritePost * call lightline#update()
  au BufWritePost * call lightline#update()

  " Handle window resizing
  au VimResized * execute "normal! \<c-w>="

  " No formatting on o key newlines
  au BufNewFile,BufEnter * set formatoptions-=o

  " Trim trailing whitespace
  function! <SID>TrimWhitespace()
    let l = line(".")
    let c = col(".")
    keeppatterns %s/\v\s+$//e
    call cursor(l, c)
  endfunction
  au FileType * au BufWritePre <buffer> :call <SID>TrimWhitespace()

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
    autocmd TermClose * noremap <buffer><silent><CR> :bd!<CR>
    autocmd TermClose * noremap <buffer><silent><ESC> :bd!<CR>
    au! TermOpen * setlocal nonumber norelativenumber
    au! TermOpen * if &buftype == 'terminal'
          \| set nonumber norelativenumber
          \| endif
  endif

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

    " setl spell
    " setl spelllang=en
    " setl nolist
    " setl nonumber
  endfunction

  au FileType gitcommit,gitrebase setl spell textwidth=72
  au BufNewFile,BufRead .git/index setlocal nolist
  au BufReadPost fugitive://* set bufhidden=delete
  au BufReadCmd *.git/index exe BufReadIndex()
  au BufEnter *.git/index silent normal gg0j
  au BufEnter *.git/COMMIT_EDITMSG exe BufEnterCommit()
  au FileType gitcommit,gitrebase exe BufEnterCommit()

  " co-authored-by abbreviations
  autocmd FileType gitcommit,gitrebase :iabbrev <buffer> cabjj Co-authored-by: Joe Jobes <jmrjobes@gmail.com>
  autocmd FileType gitcommit,gitrebase :iabbrev <buffer> cabtw Co-authored-by: Tony Winn <hi@tonywinn.me>
augroup END

augroup elixir
  au!
  au FileType elixir,eelixir nnoremap <leader>ed orequire IEx; IEx.pry<ESC>:w<CR>
  au FileType elixir,eelixir nnoremap <leader>ep o\|><ESC>i
  au FileType elixir,eelixir nnoremap <leader>ei o\|> IO.inspect()<ESC>i
  au FileType elixir,eelixir nnoremap <leader>eil o\|> IO.inspect(label: "")<ESC>hi

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

augroup ft_formatting
  au!
  au BufWrite *.json :call CocAction('format')
  au BufWrite *.ex,*.exs :call CocAction('format')
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

" ## polyglot
let g:polyglot_disabled = ['typescript', 'typescriptreact', 'typescript.tsx', 'javascriptreact', 'graphql', 'tsx', 'jsx', 'sass', 'scss', 'css', 'elm', 'elixir', 'eelixir', 'ex', 'exs']

" ## indentLine
let g:indentLine_enabled = 1
let g:indentLine_color_gui = '#556874'
let g:indentLine_char = '│'
" let g:indentLine_bgcolor_gui = '#3C4C55'

" rhysd/git-messenger
let g:git_messenger_no_default_mappings = 1
nmap <leader>gm <Plug>(git-messenger)

" ## andymass/vim-matchup
" let g:matchup_matchparen_deferred = 1
" let g:matchup_matchparen_hi_surround_always = 1
let g:matchup_matchparen_status_offscreen = 0

" ## liuchengxu/vim-which-key
" ref: https://github.com/sinecodes/dotfiles/blob/master/.vim/settings/rich/whichkey.vim
let g:which_key_use_floating_win = 1
let g:which_key_hspace = 15
let g:which_key_map = {
      \   'a': 'search-project-for',
      \   'A': 'search-project-for-cursor-word',
      \   'c': 'comment-line',
      \   'G': 'goyo-enter',
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
      \ 'a' : 'code-action',
      \ 'A' : 'code-action-selected',
      \ 'r' : 'references',
      \ 'R' : 'rename',
      \ 'n' : 'rename',
      \ 'c' : 'context-menu',
      \ 'b' : 'toggle-tagbar',
      \ 'o' : 'open-link',
      \ 'h' : 'hover',
      \ 'f' : 'format',
      \ 'F' : 'format-selected',
      \ 'l' : 'highlight',
      \ 'L' : 'unmark-highlight',
      \ 's' : 'document-symbol',
      \ 'i' : 'toggle-indent-lines',
      \ 'S' : 'workspace-symbol',
      \ 'g' : {
      \   'name': '+goto',
      \   'd' : 'definition',
      \   'D' : 'dash-search',
      \   't' : 'type-definition',
      \   'i' : 'implementation',
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
let g:netrw_browse_split = 4 " use the previous window to open file
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
let $FZF_DEFAULT_COMMAND = 'rg --files --hidden --follow --glob "!.git/*"'
" let $FZF_DEFAULT_OPTS='--layout=reverse'
let g:fzf_action = {
      \ 'ctrl-s': 'split',
      \ 'ctrl-v': 'vsplit',
      \ 'enter': 'vsplit'
      \ }
let g:fzf_layout = { 'down': '~15%' }

if executable('rg')
  " ## rg
  set grepprg=rg\ --vimgrep                                                       "Use ripgrep for grepping
  function! s:CompleteRg(arg_lead, line, pos)
    let l:args = join(split(a:line)[1:])
    return systemlist('get_completions rg ' . l:args)
  endfunction

  " Add support for ripgrep
  " https://github.com/dsifford/.dotfiles/blob/master/vim/.vimrc#L130
  command! -bang -complete=customlist,s:CompleteRg -nargs=* Rg
        \ call fzf#vim#grep(
        \   'rg --column --line-number --no-heading --color=always --fixed-strings --smart-case --hidden --follow --glob "!{.git,deps,node_modules}/*" '.shellescape(<q-args>).'| tr -d "\017"', 1,
        \   <bang>0 ? fzf#vim#with_preview('up:60%')
        \           : fzf#vim#with_preview('right:50%', '?'),
        \   <bang>0)
  command! -bang -nargs=? -complete=dir Files
        \ call fzf#vim#files(<q-args>,
        \   <bang>0 ? fzf#vim#with_preview('up:60%')
        \           : fzf#vim#with_preview('right:50%', '?'),
        \   <bang>0)
endif

nnoremap <silent><leader>m <ESC>:FZF --tiebreak=begin,length,index<CR>
nnoremap <leader>a <ESC>:Rg<SPACE>
nnoremap <silent><leader>A  <ESC>:exe('Rg '.expand('<cword>'))<CR>
" Backslash as shortcut to ag
nnoremap \ :Rg<SPACE>

" ## junegunn/limelight.vim
let g:limelight_conceal_guifg = 'DarkGray'
let g:limelight_conceal_guifg = '#777777'

" ## junegunn/goyo.vim
" ref: https://github.com/ydhamija96/config/blob/master/.vimrc#L137
" function! s:goyo_enter()
"   silent !tmux set status off
"   silent !tmux list-panes -F '\#F' | grep -q Z || tmux resize-pane -Z
"   set textwidth=78
"   set wrap
"   set noshowmode
"   set noshowcmd
"   set scrolloff=999
"   Limelight
"   color off
" endfunction
" function! s:goyo_leave()
"   silent !tmux set status on
"   silent !tmux list-panes -F '\#F' | grep -q Z && tmux resize-pane -Z
"   set textwidth=0
"   set nowrap
"   set showmode
"   set showcmd
"   set scrolloff=8
"   Limelight!
"   color nova
" endfunction
function! s:goyo_enter()
  silent !tmux set status off
  silent !tmux list-panes -F '\#F' | grep -q Z || tmux resize-pane -Z
  setlocal spell
  setlocal noshowmode
  setlocal nocursorline
  setlocal noshowcmd
  setlocal nolist
  setlocal signcolumn=no
  setlocal showbreak=
  " Fix Airline showing up bug
  setlocal eventignore=FocusGained
  call css_color#disable()
  let b:coc_suggest_disable = 1
  IndentLinesDisable
  color off
  Limelight
  " Set up ability to :q from within WritingMode
  let b:quitting = 0
  let b:quitting_bang = 0
  autocmd QuitPre <buffer> let b:quitting = 1
  cabbrev <buffer> q! let b:quitting_bang = 1 <bar> q!
endfunction

function! s:goyo_leave()
  silent !tmux set status on
  silent !tmux list-panes -F '\#F' | grep -q Z && tmux resize-pane -Z
  set spell<
  set showmode<
  set showcmd<
  set list<
  set cursorline<
  set signcolumn<
  set eventignore<
  set showbreak=>>>\
  call css_color#enable()
  let b:coc_suggest_disable = 0
  IndentLinesEnable
  color nova
  Limelight!
  AirlineRefresh " Airline starts up weird sometimes...
  AirlineToggle
  AirlineToggle
  AirlineRefresh
  " Quit Vim if this is the only remaining buffer
  if b:quitting && len(filter(range(1, bufnr('$')), 'buflisted(v:val)')) == 1
    if b:quitting_bang
      qa!
    else
      qa
    endif
  endif
endfunction
autocmd! User GoyoEnter nested call <SID>goyo_enter()
autocmd! User GoyoLeave nested call <SID>goyo_leave()
nnoremap <silent><Leader>G :Goyo<CR>

" ## trevordmiller/nova-vim
set background=dark
let g:nova_transparent = 1
silent! colorscheme nova

" morhetz/gruvbox
" let g:gruvbox_italic=1
" let g:gruvbox_improved_strings=1
" let g:gruvbox_improved_warnings=1
" let g:gruvbox_guisp_fallback='fg'
" let g:gruvbox_contrast_light='hard'
" let g:gruvbox_contrast_dark='medium'
" set background=dark
" colorscheme gruvbox

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

" ## liuchengxu/vista.vim
nmap <silent> <F4> :Vista!!<CR>
let g:vista_echo_cursor_strategy = 'floating_win'
" Position to open the vista sidebar. On the right by default.
" Change to 'vertical topleft' to open on the left.
let g:vista_sidebar_position = 'vertical botright'
" Width of vista sidebar.
let g:vista_sidebar_width = 30
" Set this flag to 0 to disable echoing when the cursor moves.
let g:vista_echo_cursor = 1
" Time delay for showing detailed symbol info at current cursor.
let g:vista_cursor_delay = 400
" Close the vista window automatically close when you jump to a symbol.
let g:vista_close_on_jump = 0
" Move to the vista window when it is opened.
let g:vista_stay_on_open = 1
" Blinking cursor 2 times with 100ms interval after jumping to the tag.
let g:vista_blink = [2, 100]
" How each level is indented and what to prepend.
" This could make the display more compact or more spacious.
" e.g., more compact: ["▸ ", ""]
let g:vista_icon_indent = ['╰─▸ ', '├─▸ ']
" Executive used when opening vista sidebar without specifying it.
" See all the avaliable executives via `:echo g:vista#executives`.
let g:vista_default_executive = 'ctags'
" Declare the command including the executable and options used to generate ctags output
" for some certain filetypes.The file path will be appened to your custom command.
" For example:
let g:vista_ctags_cmd = {
      \ 'haskell': 'hasktags -o - -c',
      \ }
" To enable fzf's preview window set g:vista_fzf_preview.
" The elements of g:vista_fzf_preview will be passed as arguments to fzf#vim#with_preview()
" For example:
let g:vista_fzf_preview = ['right:50%']
" Fall back to other executives if the specified one gives empty data.
" By default it's all the provided executives excluding the tried one.
let g:vista_finder_alternative_executives = ['coc']

" ## craigemery/vim-autotag
let g:autotagTagsFile='.tags'

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
      \    }
      \  }
      \}


" ## elm-vim
let g:elm_jump_to_error = 0
let g:elm_make_output_file = '/dev/null'
let g:elm_make_show_warnings = 1
let g:elm_syntastic_show_warnings = 1
let g:elm_browser_command = 'open'
let g:elm_detailed_complete = 1
let g:elm_format_autosave = 1
let g:elm_format_fail_silently = 0
let g:elm_setup_keybindings = 0

" ## vim-elixir
let g:elixir_autobuild = 1
let g:elixir_showerror = 1
let g:elixir_maxpreviews = 20
let g:elixir_docpreview = 1

" " ## mhinz/vim-mix-format
" let g:mix_format_on_save = 1
" let g:mix_format_silent_errors = 1

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
let g:markdown_fenced_languages = [
      \ 'javascript', 'js=javascript', 'json=javascript',
      \ 'css', 'scss', 'sass',
      \ 'ruby', 'erb=eruby',
      \ 'python',
      \ 'haml', 'html',
      \ 'bash=sh', 'zsh', 'elm', 'elixir']

" # markdown-preview.nvim
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
" let g:indentLine_bgcolor_gui = '#3C4C55'

" ## golden-ratio
let g:golden_ratio_exclude_nonmodifiable = 1
let g:golden_ratio_wrap_ignored = 0
let g:golden_ratio_ignore_horizontal_splits = 1

" ## justinmk/vim-sneak
" let g:sneak#label = 1
" let g:qs_highlight_on_keys = ['f', 'F', 't', 'T']

" ## rhysd/clever-f
" let g:clever_f_mark_char_color='#ff0000'
" map ; <Plug>(clever-f-repeat-forward)
" map , <Plug>(clever-f-repeat-back)

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

" ref: https://github.com/hourliert/dotfiles/blob/7049f2cb46f840ce242d44825f1f1963fe34a054/vimrc#L340
let g:test#custom_strategies = {'terminal_split': function('TerminalSplit')}
let g:test#strategy = 'terminal_split'
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
      \       ['cocstatus'],
      \       ['linter_checking', 'linter_warnings', 'linter_errors', 'linter_ok'],
      \       ['filetype', 'fileformat', 'lineinfo', 'percent'],
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

" for showSignatureHelp
set completeopt=noinsert,menuone "https://github.com/neoclide/coc.nvim/issues/478
set shortmess+=c

" Or use formatexpr for range format
set formatexpr=CocActionAsync('formatSelected')

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
inoremap <silent><expr> <C-e> coc#refresh()

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

nmap <silent> [c <Plug>(coc-diagnostic-prev)
nmap <silent> ]c <Plug>(coc-diagnostic-next)
" nmap <silent> [l <Plug>(coc-diagnostic-prev)
" nmap <silent> ]l <Plug>(coc-diagnostic-next)

nnoremap <silent> K :call <SID>show_documentation()<CR>
nnoremap <silent> <leader>lh :call <SID>show_documentation()<CR>
vnoremap <silent> <leader>lh :call <SID>show_documentation()<CR>

nmap <silent> <leader>lgd <Plug>(coc-definition)
nmap <silent> <leader>lgt <Plug>(coc-type-definition)
nmap <silent> <leader>lgi <Plug>(coc-implementation)

nmap <silent> <leader>lr <Plug>(coc-references)

nmap <silent> <leader>ln <Plug>(coc-rename)
nmap <silent> <leader>lR <Plug>(coc-rename)
vmap <silent> <leader>ln <Plug>(coc-rename)

nmap <silent> <leader>lf <Plug>(coc-format)
vmap <silent> <leader>lF <Plug>(coc-format-selected)
nmap <silent> <leader>lF <Plug>(coc-format-selected)

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

nnoremap <silent> <leader>lS  :<C-u>CocList -I symbols<cr> " Workspace symbols
nnoremap <silent> <leader>ls  :<C-u>CocList outline<cr> " Document symbols

nnoremap <silent> <leader>lD :<C-u>CocList diagnostics<CR>
nnoremap <silent> <leader>lG :<C-u>CocList --normal --auto-preview gstatus<CR>
nnoremap <silent> <leader>lC :<C-u>CocList commands<cr>
nnoremap <silent> <leader>lO :<C-u>CocList outline<cr>
nnoremap <silent> <leader>lE :<C-u>CocList extensions<cr>
nnoremap <silent> <leader>lY :<C-u>CocList -A --normal yank<CR>

nmap [g <Plug>(coc-git-prevchunk)
nmap ]g <Plug>(coc-git-nextchunk)
nmap gs <Plug>(coc-git-chunkinfo)
"}}}
" ░░░░░░░░░░░░░░░ highlights/colors {{{

  hi clear SpellBad
  hi clear SpellCap
  " hi clear Floating
  " hi clear NormalFloat
  " hi clear CocFloating
  " hi clear CocPumFloating
  " hi clear CocPumFloatingDetail

  hi htmlArg cterm=italic gui=italic
  hi xmlAttrib cterm=italic gui=italic
  hi Type cterm=italic gui=italic
  hi Comment cterm=italic term=italic gui=italic
  " hi LineNr guibg=#3C4C55 guifg=#937f6e gui=NONE

  hi CursorLineNr guibg=#333333 guifg=#ffffff guifg=#db9c5e gui=italic

  " hi CursorLine guibg=#333333
  " hi qfLineNr ctermbg=black ctermfg=95 cterm=NONE guibg=black guifg=#875f5f gui=NONE
  " hi QuickFixLine term=bold,underline cterm=bold,underline gui=bold,underline
  " hi Search term=underline cterm=underline ctermfg=232 ctermbg=230 guibg=#db9c5e guifg=#343d46 gui=underline

  " FIXME: IncSearch negatively affects my FZF colors
  " hi IncSearch guifg=#FFFACD

  " highlight conflicts
  match ErrorMsg '^\(<\|=\|>\)\{7\}\([^=].\+\)\?$'

  hi SpellBad gui=undercurl,underline guifg=#DF8C8C guibg=#3C4C55
  hi SpellCap gui=undercurl,underline guifg=#DF8C8C guibg=#3C4C55
  hi VertSplit guibg=NONE

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

" vim:foldenable:foldmethod=marker:ft=vim
