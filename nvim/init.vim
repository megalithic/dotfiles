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
  au VimEnter * PlugInstall --sync | source $MYVIMRC
endif
set runtimepath+=~/.config/nvim/autoload/plug.vim/

silent! if plug#begin('~/.config/nvim/plugins')

function! PostInstallCoc(info) abort
  if a:info.status ==? 'installed' || a:info.force
    !yarn install
    call coc#util#install_extension(join([
          \ 'coc-css',
          \ 'coc-emoji',
          \ 'coc-eslint',
          \ 'coc-html',
          \ 'coc-json',
          \ 'coc-lists',
          \ 'coc-pyls',
          \ 'coc-rls',
          \ 'coc-solargraph',
          \ 'coc-tag',
          \ 'coc-tailwindcss',
          \ 'coc-tsserver',
          \ 'coc-tslint',
          \ 'coc-ultisnips',
          \ 'coc-yaml',
          \ 'coc-yank',
          \ ]))

    " -- disabled coc.nvim extensions:
    " \ 'coc-omni',
    " \ 'coc-dictionary',
    " \ 'coc-java',
    " \ 'coc-vetur',
    " \ 'coc-wxml',
    " \ 'coc-prettier',
    " \ 'coc-stylelint',
    " \ 'coc-highlight',
    " \ 'coc-word',
    " \ 'coc-snippets',
  elseif a:info.status ==? 'updated'
    !yarn install
    call coc#util#update()
  endif
endfunction

Plug 'SirVer/ultisnips'
Plug 'andymass/vim-matchup'
Plug 'antew/vim-elm-analyse', { 'for': ['elm'] }
Plug 'avdgaag/vim-phoenix', { 'for': ['elixir','eelixir'] }
Plug 'christoomey/vim-tmux-navigator' " needed for tmux/hotkey integration with vim
Plug 'christoomey/vim-tmux-runner' " needed for tmux/hotkey integration with vim
Plug 'cohama/lexima.vim'
Plug 'ConradIrwin/vim-bracketed-paste' " correctly paste in insert mode
Plug 'docunext/closetag.vim' " will auto-close the opening tag as soon as you type </
Plug 'editorconfig/editorconfig-vim'
Plug 'EinfachToll/DidYouMean' " Vim plugin which asks for the right file to open
Plug 'elixir-lang/vim-elixir', { 'for': 'elixir' }
Plug 'hail2u/vim-css3-syntax', { 'for': 'css' }
" Plug 'honza/vim-snippets'
" Plug 'iamcco/sran.nvim', { 'do': { -> sran#util#install() } }
" Plug 'iamcco/git-p.nvim'
Plug 'iamcco/markdown-preview.nvim', { 'for': ['md', 'markdown', 'mdown'], 'do': 'cd app & yarn install' } " https://github.com/iamcco/markdown-preview.nvim#install--usage
Plug 'itchyny/lightline.vim'
Plug 'janko-m/vim-test', {'on': ['TestFile', 'TestLast', 'TestNearest', 'TestSuite', 'TestVisit'] } " tester for js and ruby
Plug 'jordwalke/VimAutoMakeDirectory' " auto-makes the dir for you if it doesn't exist in the path
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': 'yes \| ./install --all' }
Plug 'junegunn/fzf.vim'
Plug 'junegunn/goyo.vim', { 'on': 'Goyo' }
Plug 'junegunn/limelight.vim', { 'on': 'Limelight' }
Plug 'junegunn/rainbow_parentheses.vim' " nicely colors nested pairs of [], (), {}
Plug 'junegunn/vim-plug'
Plug 'keith/gist.vim', { 'do': 'chmod -HR 0600 ~/.netrc' }
Plug 'KKPMW/distilled-vim'
Plug 'kopischke/vim-fetch'
Plug 'lilydjwg/colorizer' " or 'chrisbra/Colorizer'
" Plug 'markonm/traces.vim'
" if executable('ctags')
"   Plug 'majutsushi/tagbar', { 'on': 'TagbarToggle' }
"   Plug 'ludovicchabant/vim-gutentags'
"   Plug 'skywind3000/gutentags_plus'
"   " Plug 'jsfaint/gen_tags.vim'
"   " Plug 'craigemery/vim-autotag'
" endif
Plug 'mattn/emmet-vim', { 'for': 'html,erb,eruby,markdown' }
Plug 'mattn/webapi-vim'
Plug 'maximbaz/lightline-ale'
Plug 'megalithic/golden-ratio' " vertical split layout manager
Plug 'neoclide/jsonc.vim', { 'for': ['json','jsonc'] }
Plug 'neoclide/coc-neco'
Plug 'neoclide/coc.nvim', { 'do': function('PostInstallCoc') }
Plug 'othree/csscomplete.vim', { 'for': 'css' }
Plug 'pangloss/vim-javascript', { 'for': 'javascript' }
Plug 'pbrisbin/vim-colors-off'
Plug 'powerman/vim-plugin-AnsiEsc' " supports ansi escape codes for documentation from lc/lsp/etc
Plug 'rizzatti/dash.vim'
Plug 'Shougo/neco-vim'
Plug 'sickill/vim-pasta' " context-aware pasting
Plug 'TaDaa/vimade'
Plug 'tmux-plugins/vim-tmux-focus-events'
Plug 'tpope/vim-abolish'
Plug 'tpope/vim-commentary'
Plug 'tpope/vim-eunuch'
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-git'
Plug 'tpope/vim-markdown'
Plug 'tpope/vim-ragtag'
Plug 'tpope/vim-rails', {'for': 'ruby,erb,yaml,ru,haml'}
Plug 'tpope/vim-repeat'
Plug 'tpope/vim-rhubarb'
Plug 'tpope/vim-speeddating'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-unimpaired'
Plug 'tpope/vim-vinegar'
Plug 'trevordmiller/nova-vim'
Plug 'unblevable/quick-scope' " highlights f/t type of motions, for quick horizontal movements
Plug 'vim-ruby/vim-ruby', { 'for': 'ruby' }
Plug 'w0rp/ale'
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
  set icm=nosplit
endif

" ---- Tab completion
set wildmode=list:longest,full
set wildignore=*.swp,*.o,*.so,*.exe,*.dll

" ---- Scroll
set scrolloff=5                                                                 "Start scrolling when we're 8 lines away from margins
set sidescrolloff=15
set sidescroll=5

" ---- Tab settings
set ts=2
set sw=2
set expandtab

" ---- Hud
set ruler
set number
set nowrap
set fillchars=vert:\│
" set colorcolumn=80
set cursorline                                                                  "Highlight current line
set pumheight=30                                                                "Maximum number of entries in autocomplete popup
set cmdheight=1
set signcolumn=yes
" set cpoptions+=$              " dollar sign while changing
set synmaxcol=250             " set max syntax highlighting column to sane level
set visualbell t_vb=          " no visual bell
set t_ut=                     " fix 256 colors in tmux http://sunaku.github.io/vim-256color-bce.html

" ---- Show
set noshowmode                                                                  "Hide showmode because of the powerline plugin
set noshowcmd                                                                   "Hide incomplete cmds down the bottom
set showmatch                                                                   "Highlight matching bracket

" ---- Buffers
set hidden
set autoread                  " auto read external file changes

" ---- Backup directories
set backupdir=~/.config/nvim/backups,.
set directory=~/.config/nvim/swaps,.
if exists('&undodir')
  set undodir=~/.config/nvim/undo,.
endif

" ---- Swap and backups
set noswapfile
set nobackup
set nowb
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
set timeoutlen=1000 ttimeoutlen=0                                               "Reduce Command timeout for faster escape and O
set updatetime=300

" ---- Split behaviors
set splitright                                                                  "Set up new vertical splits positions
set splitbelow                                                                  "Set up new horizontal splits positions

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
set gcr=a:blinkon500-blinkwait500-blinkoff500                                   "Set cursor blinking rate

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

" Trim trailing whitespace
nnoremap <localleader>tw m`:%s/\s\+$//e<CR>``

" ## Writing / quitting
nnoremap <silent><leader>w :w<CR>
nnoremap <silent><leader>W :w !sudo tee %<CR>
nnoremap <leader>q :q<CR>

" open a (new)file in a new vsplit
nnoremap <silent><leader>o :vnew<cr>:e<space><c-d>

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
noremap <leader>; :!
noremap <leader>: :<Up>

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
  au TextChanged,InsertLeave,BufWritePost * call lightline#update()

  " Handle window resizing
  au VimResized * execute "normal! \<c-w>="

  " No formatting on o key newlines
  au BufNewFile,BufEnter * set formatoptions-=o

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
  " au InsertLeave * silent set colorcolumn=""
  au InsertLeave * if &filetype != "markdown"
                            \ | silent set colorcolumn=""
                            \ | endif

  " Open QuickFix horizontally with line wrap
  au FileType qf wincmd J | setlocal wrap

  " Preview window with line wrap
  au WinEnter * if &previewwindow | setlocal wrap | endif
augroup END

augroup mirrors
  au!
  " ## Automagically update remote files via scp
  au BufWritePost ~/.dotfiles/private/homeassistant/* silent! :MirrorPush ha
  au BufWritePost ~/.dotfiles/private/domains/nginx/* silent! :MirrorPush nginx
  au BufWritePost ~/.dotfiles/private/domains/fathom/* silent! :MirrorPush fathom
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
    if getline('.') == ''
      start
    end

    " disable coc.nvim for gitcommit
    " autocmd BufNew,BufEnter *.json,*.vim,*.lua execute "silent! CocEnable"
    autocmd InsertEnter * execute "silent! CocDisable"

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

  au FileType gitcommit,gitrebase setl nospell textwidth=72
  au BufNewFile,BufRead .git/index setlocal nolist
  au BufReadPost fugitive://* set bufhidden=delete
  au BufReadCmd *.git/index exe BufReadIndex()
  au BufEnter *.git/index silent normal gg0j
  au BufEnter *.git/COMMIT_EDITMSG exe BufEnterCommit()
  au FileType gitcommit,gitrebase exe BufEnterCommit()
augroup END

augroup ale
  au!
  au User ALEJobStarted call lightline#update()
  au User ALELintPost   call lightline#update()
  au User ALEFixPost    call lightline#update()
augroup END

"}}}
" ░░░░░░░░░░░░░░░ other settings {{{

" Use relative line numbers
set relativenumber

" Toggle paste mode
set pastetoggle=<leader>z

" Fancy tag lookup
set tags=./tags;/,tags;/

" Visible whitespace
set listchars=tab:»·,trail:·
set listchars=tab:▸\ ,eol:¬,extends:›,precedes:‹,trail:·,nbsp:⚋
set nolist

" Soft-wrap for prose
command! -nargs=* Wrap set wrap linebreak nolist spell
let &showbreak='↪ '

"}}}
" ░░░░░░░░░░░░░░░ plugin settings {{{

" ## polyglot
  let g:polyglot_disabled = ['typescript', 'typescriptreact', 'typescript.tsx', 'graphql', 'jsx', 'sass', 'scss', 'css', 'elm', 'elixir', 'eelixir', 'ex', 'exs']

" ## indentLine
let g:indentLine_enabled = 1
let g:indentLine_color_gui = '#556874'
let g:indentLine_char = '│'
" let g:indentLine_bgcolor_gui = '#3C4C55'

" ## junegunn/fzf
let $FZF_DEFAULT_COMMAND = 'rg --files --hidden --follow --glob "!.git/*"'
let g:fzf_action = {
      \ 'ctrl-s': 'split',
      \ 'ctrl-v': 'vsplit',
      \ 'enter': 'vsplit'
      \ }
let g:fzf_layout = { 'down': '~15%' }
if executable("rg")
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
        \   'rg --column --line-number --no-heading --color=always --fixed-strings --ignore-case --hidden --follow --glob "!{.git,deps,node_modules}/*" '.shellescape(<q-args>).'| tr -d "\017"', 1,
        \   <bang>0 ? fzf#vim#with_preview('up:60%')
        \           : fzf#vim#with_preview('right:50%', '?'),
        \   <bang>0)
  command! -bang -nargs=? -complete=dir Files
        \ call fzf#vim#files(<q-args>,
        \   <bang>0 ? fzf#vim#with_preview('up:60%')
        \           : fzf#vim#with_preview('right:50%', '?'),
        \   <bang>0)
endif

nnoremap <silent><leader>m <ESC>:FZF<CR>
nnoremap <leader>a <ESC>:Rg<SPACE>
nnoremap <silent><leader>A  <ESC>:exe('Rg '.expand('<cword>'))<CR>
" nnoremap <localleader><space> :Buffers<cr> nnoremap <leader>a <ESC>:Rg<SPACE> nnoremap <silent><leader>A  <ESC>:exe('Rg '.expand('<cword>'))<CR> vnoremap <silent><leader>A  <ESC>:exe('Rg '.expand('<cword>'))<CR>
" Backslash as shortcut to ag
nnoremap \ :Rg<SPACE>

" ## junegunn/limelight.vim
let g:limelight_conceal_guifg = 'DarkGray'
let g:limelight_conceal_guifg = '#777777'

" ## junegunn/goyo.vim
function! s:goyo_enter()
  silent !tmux set status off
  silent !tmux list-panes -F '\#F' | grep -q Z || tmux resize-pane -Z
  set tw=78
  set wrap
  set noshowmode
  set noshowcmd
  set scrolloff=999
  Limelight
  color off
endfunction
function! s:goyo_leave()
  silent !tmux set status on
  silent !tmux list-panes -F '\#F' | grep -q Z && tmux resize-pane -Z
  set tw=0
  set nowrap
  set showmode
  set showcmd
  set scrolloff=8
  Limelight!
  color nova
endfunction
autocmd! User GoyoEnter nested call <SID>goyo_enter()
autocmd! User GoyoLeave nested call <SID>goyo_leave()
nnoremap <silent><Leader>G :Goyo<CR>

" ## trevordmiller/nova-vim
set background=dark
let g:nova_transparent = 1
silent! colorscheme nova

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

" " ## vim-gutentags
" let g:gutentags_modules = ['ctags', 'gtags_cscope']
" let g:gutentags_project_root = ['.root']
" let g:gutentags_ctags_tagfile = '.tags'
" let g:gutentags_cache_dir = expand('~/.cache/tags')
" let g:gutentags_ctags_extra_args = []
" let g:gutentags_ctags_extra_args = ['--fields=+niazS', '--extra=+q']
" let g:gutentags_ctags_extra_args += ['--c++-kinds=+px']
" let g:gutentags_ctags_extra_args += ['--c-kinds=+px']

" let g:gutentags_trace = 1
" let g:gutentags_modules = ['ctags', 'gtags_cscope']
" let g:gutentags_cache_dir = expand('~/.cache/tags')
" let g:gutentags_ctags_tagfile = '.tags'
" let g:gutentags_plus_switch = 1
" let g:gutentags_auto_add_gtags_cscope = 0
" let g:gutentags_define_advanced_commands = 1

" ## tagbar
set tags+=tags,tags.vendors,.tags
let g:tagbar_autofocus = 1
let g:tagbar_type_elm = {
      \   'ctagstype':'elm'
      \ , 'kinds' : [
      \ 'h:header:0:0',
      \ 'e:exposing:0:0',
      \ 'f:function:0:0',
      \ 'm:modules:0:0',
      \ 'i:imports:1:0',
      \ 't:types:1:0',
      \ 'a:type aliases:0:0',
      \ 'c:type constructors:0:0',
      \ 'p:ports:0:0',
      \ 's:functions:0:0',
      \ ]
      \ , 'sro':'&&&'
      \ , 'kind2scope':{ 'h':'header', 'i':'import'}
      \ , 'sort':0
      \ , 'ctagsargs': ''
      \ , 'ctagsbin':'~/.config/nvim/pythonx/elmtags.py'
      \ }
let g:tagbar_type_elixir = {
      \ 'ctagstype' : 'elixir',
      \ 'kinds' : [
      \ 'f:functions',
      \ 'functions:functions',
      \ 'c:callbacks',
      \ 'd:delegates',
      \ 'e:exceptions',
      \ 'i:implementations',
      \ 'a:macros',
      \ 'o:operators',
      \ 'm:modules',
      \ 'p:protocols',
      \ 'r:records',
      \ 't:tests'
      \ ]
      \ }

" ## elm-vim
let g:elm_jump_to_error = 0
let g:elm_make_output_file = "/dev/null"
let g:elm_make_show_warnings = 1
let g:elm_syntastic_show_warnings = 1
let g:elm_browser_command = "open"
let g:elm_detailed_complete = 1
let g:elm_format_autosave = 1
let g:elm_format_fail_silently = 0
let g:elm_setup_keybindings = 0

" ## elixir.nvim
let g:elixir_autobuild = 1
let g:elixir_showerror = 1
let g:elixir_maxpreviews = 20
let g:elixir_docpreview = 1

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
let g:vimade.fadelevel = 0.7

" ## tpope/vim-markdown
let g:markdown_fenced_languages = [
      \ 'javascript', 'js=javascript', 'json=javascript',
      \ 'css', 'scss', 'sass',
      \ 'ruby', 'erb=eruby',
      \ 'python',
      \ 'haml', 'html',
      \ 'bash=sh', 'zsh', 'elm', 'elixir']

" ## w0rp/ale
let g:ale_javascript_eslint_use_global = 1
let g:ale_enabled = 1
let g:ale_completion_enabled = 0
let g:ale_lint_delay = 1000
let g:ale_echo_msg_format = '[%linter%] %s'
" disabling linters where language servers are installed/available..
let g:ale_linters = {
      \   'elixir': [],
      \   'eelixir': [],
      \   'elm': [],
      \   'lua': [],
      \   'javascript': [],
      \   'typescript': [],
      \ }
" let g:ale_linters = {
"       \   'elixir': ['elixir-ls'],
"       \   'eelixir': ['elixir-ls'],
"       \   'ex': ['elixir-ls'],
"       \   'exs': ['elixir-ls'],
"       \ }
let g:ale_fixers = {
      \   '*': ['remove_trailing_lines', 'trim_whitespace'],
      \   'javascript': ['prettier_eslint'],
      \   'javascript.jsx': ['prettier_eslint'],
      \   'css': ['prettier'],
      \   'scss': ['prettier'],
      \   'json': ['prettier'],
      \   'elm': ['elm-format'],
      \   'elixir': ['mix_format'],
      \   'eelixir': ['mix_format'],
      \ }                                                                       "Fix eslint errors
let g:ale_sign_error = '✖'                                                      "Lint error sign ⤫ ✖⨉
let g:ale_sign_warning = '⬥'                                                    "Lint warning sign ⬥⚠
let g:ale_sign_info = '‣'
let g:ale_elixir_elixir_ls_release = expand($PWD."/.elixir_ls/rel")
let b:ale_elixir_elixir_ls_config = {'elixirLS': {'dialyzerEnabled': v:true, 'projectDir': expand($PWD)}}
let g:ale_elm_format_options = '--yes --elm-version=0.18'
let g:ale_lint_on_text_changed = 'always' " 'normal'
let g:ale_lint_on_insert_leave = 1
let g:ale_lint_on_enter = 1
let g:ale_lint_on_save = 1
let g:ale_fix_on_save = 1
let g:ale_virtualtext_cursor = 1
let g:ale_virtualtext_prefix = "❯❯ "
" let g:ale_set_balloons = 0
" let g:ale_set_highlights = 0
" let g:ale_sign_column_always = 1 " handled in autocommands per filetype

" # markdown-preview.nvim
nnoremap <Leader>M :MarkdownPreview<CR>

" # sran.nvim/git-p.nvim
let g:gitp_blame_virtual_text = 1
" use custom highlight for blame virtual text
" change GitPBlameLineHi to your highlight group
highlight link GitPBlameLine GitPBlameLineHi
" format blame virtual text
" hash: commit hash
" account: commit account name
" date: YYYY-MM-DD
" time: HH:mm:ss
" ago: xxx ago
" zone: +xxxx
" commit: commit message
" lineNum: line number
let g:gitp_blame_format = '    %{account} * %{ago}'
" show blame on statusline git-p.nvim will udpate b:gitp_blame variable
" and trigger GitPDiffAndBlameUpdate event when blame update
" so you can use this info to display on statusline
" b:gitp_blame = {
"    hash: string
"    account: string
"    date: string
"    time: string
"    ago: string
"    zone: string
"    lineNum: string
"    lineString: string
"    commit: string
"    rawString: string
" }
" use custom highlight for diff sign
" change the GitPAddHi GitPModifyHi GitPDeleteHi to your highlight group
highlight link GitPAdd                GitPAddHi
highlight link GitPModify             GitPModifyHi
highlight link GitPDeleteTop          GitPDeleteHi
highlight link GitPDeleteBottom       GitPDeleteHi
highlight link GitPDeleteTopAndBottom GitPDeleteHi
" use custom diff sign
let g:gitp_add_sign = '■'
let g:gitp_modify_sign = '▣'
let g:gitp_delete_top_sign = '▤'
let g:gitp_delete_bottom_sign = '▤'
let g:gitp_delete_top_and_bottom_sign = '▤'
" let your sign column background same as line number column
" highlight! link SignColumn LineNr

" ## vim-plug
noremap <F5> :PlugUpdate<CR>
map <F5> :PlugUpdate<CR>
noremap <S-F5> :PlugClean!<CR>
map <S-F5> :PlugClean!<CR>

" ## fugitive
nnoremap <leader>H :Gbrowse<CR>
vnoremap <leader>H :Gbrowse<CR>
nnoremap <leader>B :Gblame<CR>

" ## vim-test / testing
nmap <silent> <leader>t :TestFile<CR>
nmap <silent> <leader>T :TestNearest<CR>
nmap <silent> <leader>l :TestLast<CR>
" nmap <silent> <leader>a :TestSuite<CR>
" nmap <silent> <leader>g :TestVisit<CR>
" ref: https://github.com/Dkendal/dot-files/blob/master/nvim/.config/nvim/init.vim

" ## gist/github
let g:gist_open_url = 1
let g:gist_default_private = 1
" Send visual selection to gist.github.com as a private, filetyped Gist
" Requires the gist command line too (brew install gist)
vnoremap <leader>G :Gist -po<CR>

" ## dash.vim
nmap <silent> <leader>d <Plug>DashSearch

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

" ## quick-scope
let g:qs_enable = 1
let g:qs_highlight_on_keys = ['f', 'F', 't', 'T']

" ## vim-test
function! SplitStrategy(cmd)
  vert new | call termopen(a:cmd) | startinsert
endfunction
let g:test#custom_strategies = {'terminal_split': function('SplitStrategy')}
let g:test#strategy = 'terminal_split'
let test#ruby#rspec#options = '-f d'
" let test#ruby#bundle_exec = 1
let test#ruby#use_binstubs = 1

" ## mattn/emmet-vim
" Remap for expand with Tab
let g:user_emmet_leader_key = '<C-e>'
" let g:user_emmet_expandabbr_key = '<A-x><A-e>'

" ## ultisnips
" Not conflict with Coc
let g:UltiSnipsExpandTrigger = "<C-e>"
" let g:UltiSnipsExpandTrigger = "<Plug>(ultisnips_expand)"
let g:UltiSnipsJumpForwardTrigger	= "<Tab>"
let g:UltiSnipsJumpBackwardTrigger	= "<S-Tab>"
let g:UltiSnipsRemoveSelectModeMappings = 0
let g:UltiSnipsSnippetDirectories=['UltiSnips']

"}}}
" ░░░░░░░░░░░░░░░ blink {{{

" REF: https://github.com/sedm0784/vimconfig/blob/master/_vimrc#L173
" Modified version of Damian Conway's Die Blinkënmatchen: highlight matches
"
" This is how long you want the blinking to last in milliseconds. If you're
" using an earlier Vim without the `+timers` feature, you need a much shorter
" blink time because Vim blocks while it waits for the blink to complete.
let s:blink_length = has("timers") ? 500 : 100

if has("timers")
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

  augroup die_blinkmatchen
    autocmd!
    autocmd CursorMoved * call BlinkStop(0)
    autocmd InsertEnter * call BlinkStop(0)
  augroup END
endif

function! HLNext(blink_length, blink_freq)
  let target_pat = '\c\%#'.@/
  if has("timers")
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
execute printf("nnoremap <silent> n n:call HLNext(%d, %d)<cr>", s:blink_length, has("timers") ? s:blink_freq : s:blink_length)
execute printf("nnoremap <silent> N N:call HLNext(%d, %d)<cr>", s:blink_length, has("timers") ? s:blink_freq : s:blink_length)

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
      \     'ale_error'        : 'LightlineAleErrors',
      \     'ale_warning'      : 'LightlineAleWarnings',
      \     'ale_info'         : 'LightlineAleInfos',
      \     'ale_style_error'  : 'LightlineAleStyleErrors',
      \     'ale_style_warning': 'LightlineAleStyleWarnings',
      \   },
      \   'component_type': {
      \     'readonly': 'error',
      \     'modified': 'raw',
      \     'coc_error'        : 'error',
      \     'coc_warning'      : 'warning',
      \     'coc_info'         : 'tabsel',
      \     'coc_hint'         : 'middle',
      \     'coc_fix'          : 'middle',
      \     'ale_error'        : 'error',
      \     'ale_warning'      : 'warning',
      \     'ale_info'         : 'tabsel',
      \     'ale_style_error'  : 'error',
      \     'ale_style_warning': 'warning',
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
      \       ['paste', 'readonly', 'modified'],
      \       ['spell'],
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
let g:lightline#ale#indicator_warnings = "  "
let g:lightline#ale#indicator_errors = "  "
let g:lightline#ale#indicator_checking = "  "

let g:coc_status_warning_sign = "  "
let g:coc_status_error_sign = "  "

function! UpdateStatusBar(timer)
  call lightline#update()
endfunction

function! PrintStatusline(v)
  return &buftype == 'nofile' ? '' : a:v
endfunction

function! LightlineFileType()
  return winwidth(0) > 70 ? (strlen(&filetype) ? WebDevIconsGetFileTypeSymbol() . ' '. &filetype : 'no ft') : ''
  " return &filetype
endfunction

function! LightlineFileFormat()
  return winwidth(0) > 70 ? (WebDevIconsGetFileFormatSymbol() . ' ' . &fileformat) : ''
  " return &fileformat
endfunction

function! LightlineBranch()
  if exists('*fugitive#head')
    let l:branch = fugitive#head()
    return PrintStatusline(branch !=# '' ? " " . l:branch : '')
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
        \ "" : '')
endfunction

function! LightlineFileName()
  " Get the full path of the current file.
  let filepath =  expand('%:p')

  " If the filename is empty, then display nothing as appropriate.
  if empty(filepath)
    return '[No Name]'
  endif

  " Find the correct expansion depending on whether Vim has autochdir.
  let mod = (exists('+acd') && &acd) ? ':~' : ':~:.'

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
  if !get(g:, 'coc_enabled', 0) | return '' endif

  " let info = get(b:, 'coc_diagnostic_info', {})
  let info = get(b:, 'coc_diagnostic_info', 0)

  " if empty(info) || get(info, a:kind, 0) == 0
  "   return "\uf42e"
  " endif

  if empty(info) | return '' | endif

  let msgs = []

  if get(info, 'error', 0)
    call add(msgs, " " . info['error'])
  endif

  if get(info, 'warning', 0)
    call add(msgs, " " . info['warning'])
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

function! LightlineAleErrors() abort
  return s:lightline_ale_diagnostic('error')
endfunction

function! LightlineAleWarnings() abort
  return s:lightline_ale_diagnostic('warning')
endfunction

function! LightlineAleInfos() abort
  return s:lightline_ale_diagnostic('info')
endfunction

function! LightlineAleStyleErrors() abort
  return s:lightline_ale_diagnostic('style_error')
endfunction

function! LightlineAleStyleWarnings() abort
  return s:lightline_ale_diagnostic('style_warning')
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

function! s:lightline_ale_diagnostic(kind) abort
  if !get(g:, 'ale_enabled', 0)
    return ''
  endif
  if !get(b:, 'ale_linted', 0)
    return ''
  endif
  if ale#engine#IsCheckingBuffer(bufnr(''))
    return '  '
  endif
  let c = ale#statusline#Count(bufnr(''))
  if empty(c) || get(c, a:kind, 0) == 0
    return ''
  endif
  return printf('%d %s', c[a:kind], get(g:, 'ale_sign_' . a:kind, '!!'))
endfunction

" }}}
" ░░░░░░░░░░░░░░░ coc.nvim {{{
let g:coc_force_debug = 1

" for showSignatureHelp
set completeopt=noinsert,menuone "https://github.com/neoclide/coc.nvim/issues/478
set shortmess+=c

" Or use formatexpr for range format
set formatexpr=CocActionAsync('formatSelected')

" Use tab for trigger completion with characters ahead and navigate.
" Use command ':verbose imap <tab>' to make sure tab is not mapped by other plugin.
inoremap <silent><expr> <TAB>
      \ pumvisible() ? "\<C-n>" :
      \ <SID>check_back_space() ? "\<TAB>" :
      \ coc#refresh()
inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"

function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

" Use <c-space> for trigger completion.
inoremap <silent><expr> <C-e> coc#refresh()

" Use <Tab> and <S-Tab> for navigate completion list:
inoremap <expr> <Tab> pumvisible() ? "\<C-n>" : "\<Tab>"
inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"

let g:coc_snippet_next = '<TAB>'
let g:coc_snippet_prev = '<S-TAB>'

" Use <cr> for confirm completion.
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

" Use `[c` and `]c` for navigate diagnostics
" nmap <silent> [c <Plug>(coc-diagnostic-prev)
" nmap <silent> ]c <Plug>(coc-diagnostic-next)
" nmap <silent> <C-[> <Plug>(coc-diagnostic-prev)
" nmap <silent> <C-]> <Plug>(coc-diagnostic-next)

nnoremap <silent> <leader>lh :call <SID>show_documentation()<CR>

nmap <silent> <leader>ld <Plug>(coc-definition)
nmap <silent> <leader>lt <Plug>(coc-type-definition)
nmap <silent> <leader>li <Plug>(coc-implementation)
nmap <silent> <leader>lr <Plug>(coc-references)
nmap <silent> <leader>ln <Plug>(coc-rename)

" Remap for format selected region
vmap <silent> <leader>lf <Plug>(coc-format-selected)

" Remap for do codeAction of selected region, ex: `<leader>aap` for current paragraph
vmap <silent> <leader>la <Plug>(coc-codeaction-selected)

" Remap for do codeAction of current line
nmap <silent> <leader>la <Plug>(coc-codeaction)

" Fix autofix problem of current line
nmap <silent> <leader>lq <Plug>(coc-fix-current)

" Use `:Format` for format current buffer
command! -nargs=0 Format :call CocActionAsync('format')

" Use `:Fold` for fold current buffer
command! -nargs=? Fold :call CocActionAsync('fold', <f-args>)

augroup coc
  au!

  au! User CocJumpPlaceholder call CocActionAsync('showSignatureHelp')

  function! CocUpdateQuickFixes(error, actions) abort
    let coc_quickfixes = {}
    try
      for action in a:actions
        if action.kind ==? 'quickfix'
          for change in action.edit.documentChanges
            for edit in change.edits
              let start_line = edit.range.start.line + 1
              let end_line = edit.range.end.line + 1
              let coc_quickfixes[start_line] = get(coc_quickfixes, start_line, 0) + 1
              if start_line != end_line
                let coc_quickfixes[end_line] = get(coc_quickfixes, end_line, 0) + 1
              endif
            endfor
          endfor
        endif
      endfor
    catch
    endtry
    if coc_quickfixes != get(b:, 'coc_quickfixes', {})
      let b:coc_quickfixes = coc_quickfixes
      call lightline#update()
    endif
  endfunction

  au User CocDiagnosticChange
        \   call lightline#update()
        \|  call CocActionAsync('quickfixes', function('CocUpdateQuickFixes'))

  function! s:coc_fix_on_cursor_moved() abort
    let current_line = line('.')
    if current_line != get(b:, 'last_line', 0)
      let b:last_line = current_line
      if has_key(get(b:, 'coc_quickfixes', {}), current_line)
        call lightline#update()
      else
        if get(b:, 'coc_line_fixes', 0) > 0
          call lightline#update()
        endif
      endif
    endif
  endfunction

  au CursorMoved * call s:coc_fix_on_cursor_moved()
augroup END

" augroup coc_au
"   au!
"   " Show signature help while editing
"   " au CursorHoldI * silent! call CocActionAsync('showSignatureHelp')
"   au User CocJumpPlaceholder call CocActionAsync('showSignatureHelp')

"   " Highlight symbol under cursor on CursorHold
"   " au CursorHold * silent call CocActionAsync('highlight')
" augroup END

" function! s:clear_input() abort
"   let s:input_word = ''
" endfunction

" function! s:snippet() abort
"   let l:start_line = line('.')
"   let l:is_position = search('\v%x0')
"   if l:is_position !=# 0
"     silent! s/\v\t/    /g
"     silent! s/\v%x0\n//g
"     silent! s/\v%x0/\r/g
"     let l:end_line = line('.')
"     call cursor(l:start_line, 0)
"     let l:pos = searchpos('\v\$\{\d+\}', 'n', l:end_line)
"     if l:pos[0] !=# 0 && l:pos[1] !=# 0
"       call cursor(l:pos[0], l:pos[1])
"       normal! df}
"     endif
"   endif
" endfunction

" augroup CocSnippet
"   au!
"   au CompleteDone *.exs,*.ex,*.elm call <SID>snippet()
"   au CursorMovedI * call <SID>clear_input()
"   " highlight text color
"   au ColorScheme * highlight! CocHighlightText  guibg=#707e0a
" augroup END
"}}}
" ░░░░░░░░░░░░░░░ highlights/colors {{{

  hi clear SpellBad
  hi clear SpellCap

  hi htmlArg cterm=italic gui=italic
  hi xmlAttrib cterm=italic gui=italic
  hi Type cterm=italic gui=italic
  hi Comment cterm=italic term=italic gui=italic
  " hi LineNr guibg=#3C4C55 guifg=#937f6e gui=NONE
  " hi CursorLineNr ctermbg=black ctermfg=223 cterm=NONE guibg=#333333 guifg=#db9c5e gui=bold
  " hi CursorLine guibg=#333333
  " hi qfLineNr ctermbg=black ctermfg=95 cterm=NONE guibg=black guifg=#875f5f gui=NONE
  " hi QuickFixLine term=bold,underline cterm=bold,underline gui=bold,underline
  " hi Search term=underline cterm=underline ctermfg=232 ctermbg=230 guibg=#db9c5e guifg=#343d46 gui=underline

  " FIXME: IncSearch negatively affects my FZF colors
  " hi IncSearch guifg=#FFFACD

  " highlight conflicts
  match ErrorMsg '^\(<\|=\|>\)\{7\}\([^=].\+\)\?$'

  hi SpellBad gui=undercurl,underline
  hi SpellCap gui=undercurl,underline
  hi VertSplit guibg=NONE

  hi link Debug SpellBad
  hi link ErrorMsg SpellBad
  hi link Exception SpellBad

  " hi ALEErrorSign guifg=#DF8C8C guibg=NONE gui=NONE
  " hi ALEWarningSign guifg=#F2C38F guibg=NONE gui=NONE
  " hi ALEInfoSign guifg=#F2C38F guibg=NONE gui=NONE
  " hi ALEError guibg=#DF8C8C guifg=#333333 gui=NONE
  " hi ALEWarning guibg=#F2C38F guifg=#333333 gui=NONE
  " hi ALEInfo guibg=#F2C38F guifg=#333333 gui=NONE
  " hi ALEVirtualTextWarning guibg=#F2C38F guifg=#333333 gui=NONE
  " hi ALEVirtualTextError guibg=#DF8C8C guifg=#333333 gui=NONE

  hi CocErrorSign guifg=#333333 guifg=#DF8C8C
  hi CocErrorHighlight gui=underline guifg=#DF8C8C
  " hi CocErrorLine gui=underline
  hi CocWarningSign guifg=#333333 guifg=#F2C38F
  hi CocWarningHighlight gui=underline guifg=#F2C38F
  " hi CocWarningLine gui=underline
  hi CocHintSign guifg=#333333 guifg=#999999
  hi CocCodeLens ctermfg=gray guifg=#999999

  " hi link CocPumFloating Pmenu
  " hi link CocPumFloatingDetail Pmenu

  hi ModifiedColor guifg=#DF8C8C guibg=NONE gui=bold
  hi illuminatedWord cterm=underline gui=underline
  hi MatchParen cterm=bold gui=bold,italic guibg=#937f6e guifg=#222222

  hi Visual guifg=#3C4C55 guibg=#7FC1CA
  hi Normal guifg=#C5D4DD guibg=NONE

  hi QuickScopePrimary guifg=#DF8C8C guibg=#222222 gui=underline
  hi QuickScopeSecondary guifg=#F2C38F guibg=#222222 gui=underline

  hi gitCommitOverflow guibg=#DF8C8C guifg=#333333 gui=underline
  hi DiffAdd guifg=#A8CE93
  hi DiffDelete guifg=#DF8C8C
  hi DiffAdded guifg=#A8CE93
  hi DiffRemoved guifg=#DF8C8C

  hi HighlightedyankRegion term=bold ctermbg=0 guibg=#13354A
  hi Floating guibg=#000044

" }}}

" vim:foldenable:foldmethod=marker:ft=vim
