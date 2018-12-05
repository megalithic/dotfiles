" ▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁
" ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
"
"   ┌┬┐┌─┐┌─┐┌─┐┬  ┬┌┬┐┬ ┬┬┌─┐
"   │││├┤ │ ┬├─┤│  │ │ ├─┤││   :: DOTFILES > nvim/init.min.vim
"   ┴ ┴└─┘└─┘┴ ┴┴─┘┴ ┴ ┴ ┴┴└─┘
"   Brought to you by: Seth Messer / @megalithic
"
" ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
" ▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔

" ░░░░░░░░░░░░░░░ Plugins {{{

if empty(glob('~/.config/nvim/autoload/plug.vim'))
  silent !curl -fLo ~/.config/nvim/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  au VimEnter * PlugInstall --sync | source $MYVIMRC
endif
set runtimepath+=~/.config/nvim/autoload/plug.vim/

silent! if plug#begin('~/.config/nvim/plugged')

  Plug 'tweekmonster/startuptime.vim',  " Show slow plugins

" ## UI/Interface
  Plug 'trevordmiller/nova-vim'
  Plug 'megalithic/golden-ratio' " vertical split layout manager
  Plug 'itchyny/lightline.vim'
  Plug 'maximbaz/lightline-ale'
  Plug 'ryanoasis/vim-devicons' " has to be last according to docs
  Plug 'tpope/vim-dispatch', { 'on': 'Dispatch' }
  Plug 'benmills/vimux'
  Plug 'Yggdroot/indentLine'
  " Plug 'kassio/neoterm'
  " Plug 'mklabs/split-term.vim'
  " Plug 'liuchengxu/vim-which-key', { 'on': ['WhichKey', 'WhichKey!'] }

" ## Syntax
  Plug 'HerringtonDarkholme/yats.vim', { 'for': ['typescript', 'typescriptreact', 'typescript.tsx'] }
  Plug 'leafgarland/typescript-vim', { 'for': ['typescript', 'typescriptreact', 'typescript.tsx'] }
  Plug 'lilydjwg/colorizer'
  Plug 'tpope/vim-rails', { 'for': ['ruby', 'eruby', 'haml', 'slim'] }

  " # elm
  Plug 'elmcast/elm-vim', { 'for': ['elm'] }
  Plug 'kbsymanz/ctags-elm', {'for': ['elm']}

  " # elixir
  Plug 'elixir-editors/vim-elixir', { 'for': ['elixir','eelixir'] }
  Plug 'mhinz/vim-mix-format', { 'for': ['elixir','eelixir'] }
  Plug 'mattreduce/vim-mix', { 'for': ['elixir','eelixir'] }
  Plug 'avdgaag/vim-phoenix', { 'for': ['elixir','eelixir'] }
  Plug 'mmorearty/elixir-ctags', { 'for': ['elixir','eelixir'] }
  " Plug 'slashmili/alchemist.vim', {'for': ['elixir', 'eelixir']}

  " # erlang
  Plug 'vim-erlang/vim-erlang-tags'
  Plug 'vim-erlang/vim-erlang-runtime'
  Plug 'vim-erlang/vim-erlang-omnicomplete'
  Plug 'vim-erlang/vim-erlang-compiler'

  " # other
  Plug 'othree/csscomplete.vim', { 'for': ['css', 'scss', 'sass'] } " css omni-completion
  Plug 'othree/html5.vim', { 'for': ['html', 'eruby', 'svg'] } " html+svg omni-completion
  Plug 'neoclide/jsonc.vim', { 'for': ['json','jsonc'] }
  Plug 'kovisoft/slimv'
  Plug 'sheerun/vim-polyglot'

" ## tags/ctags/etc
  if executable('ctags')
    Plug 'majutsushi/tagbar', { 'on': 'TagbarToggle' }
    Plug 'ludovicchabant/vim-gutentags'
    " Plug 'jsfaint/gen_tags.vim'
  "   " Plug 'craigemery/vim-autotag'
  endif

" ## Completion
  function! PlugDoCoc(info) abort
    if a:info.status ==? 'installed' || a:info.force
      !yarn install
      call coc#util#install_extension(join([
            \ 'coc-css',
            \ 'coc-emoji',
            \ 'coc-eslint',
            \ 'coc-html',
            \ 'coc-json',
            \ 'coc-pyls',
            \ 'coc-rls',
            \ 'coc-solargraph',
            \ 'coc-tag',
            \ 'coc-tsserver',
            \ 'coc-tslint',
            \ 'coc-ultisnips',
            \ 'coc-yaml',
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
    elseif a:info.status ==? 'updated'
      !yarn install
      call coc#util#update()
    endif
  endfunction
  Plug 'neoclide/coc.nvim', { 'do': function('PlugDoCoc') }
  Plug 'neoclide/coc-neco', { 'for': ['vim'] }

  if (!has('nvim'))
    Plug 'neoclide/vim-node-rpc'
  endif
  Plug 'honza/vim-snippets' | Plug 'SirVer/ultisnips'
  Plug 'Shougo/context_filetype.vim'
  Plug 'Shougo/neco-syntax'
  Plug 'Shougo/neco-vim', { 'for': ['vim'] }
  Plug 'Shougo/neoinclude.vim'

" ## Project/Code Navigation
  Plug '/usr/local/opt/fzf'
  Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
  Plug 'junegunn/fzf.vim'
  " Plug 'justinmk/vim-dirvish' " TODO: needs testing
  " Plug 'dyng/ctrlsf.vim'
  Plug 'christoomey/vim-tmux-navigator' " needed for tmux/hotkey integration with vim
  Plug 'christoomey/vim-tmux-runner' " needed for tmux/hotkey integration with vim
  Plug 'tmux-plugins/vim-tmux-focus-events'
  Plug 'AndrewRadev/splitjoin.vim'
  Plug 'haya14busa/incsearch.vim'                             " Incremental search
  Plug 'haya14busa/incsearch-fuzzy.vim'                       " Fuzzy incremental search
  " Plug 'junegunn/vim-easy-align' " TODO: needs testing / https://github.com/junegunn/vim-easy-align#quick-start-guide
  " Plug 'markonm/traces.vim' " TODO: needs testing
  Plug 'osyo-manga/vim-anzu'                                  " Show search count
  Plug 'haya14busa/vim-asterisk'                              " Star * improvements
  " Plug 'rhysd/clever-f.vim' " ; and , usage not working
  Plug 'unblevable/quick-scope' " highlights f/t type of motions, for quick horizontal movements
  " Plug 'justinmk/vim-sneak' " https://github.com/justinmk/vim-sneak / NOTE: need to see if you can pre-highlight possible letters

" ## Utils
  " Plug 'tyru/capture.vim', { 'on': ['Capture'] }
  Plug 'jordwalke/VimAutoMakeDirectory' " auto-makes the dir for you if it doesn't exist in the path
  Plug 'EinfachToll/DidYouMean' " Vim plugin which asks for the right file to open
  " Plug 'tpope/vim-characterize' " ga on a character to see special things (hex, etc)
  " Plug 'guns/xterm-color-table.vim', { 'on': ['XtermColorTable'] } " #, t, f
  Plug 'junegunn/rainbow_parentheses.vim' " nicely colors nested pairs of [], (), {}
  Plug 'docunext/closetag.vim' " will auto-close the opening tag as soon as you type </
  Plug 'tpope/vim-ragtag', { 'for': ['html', 'xml', 'erb', 'haml', 'javascript.jsx', 'typescript', 'typescriptreact', 'typescript.tsx', 'javascript'] } " a set of mappings for several langs: html, xml, erb, php, more
  Plug 'jiangmiao/auto-pairs' " or Plug 'rstacruz/vim-closer'
  Plug 'cohama/lexima.vim'
  " Plug 'tpope/vim-endwise'
  Plug 'janko-m/vim-test', {'on': ['TestFile', 'TestLast', 'TestNearest', 'TestSuite', 'TestVisit'] } " tester for js and ruby
  Plug 'tpope/vim-commentary' " (un)comment code
  Plug 'ConradIrwin/vim-bracketed-paste' " correctly paste in insert mode
  Plug 'sickill/vim-pasta' " context-aware pasting
  Plug 'zenbro/mirror.vim' " allows mirror'ed editing of files locally, to a specified ssh location via ~/.mirrors
  Plug 'keith/gist.vim', { 'do': 'chmod -HR 0600 ~/.netrc' }
  " Plug 'thinca/vim-ref' " TODO: do i need this?
  " Plug 'Raimondi/delimitMate'
  Plug 'andymass/vim-matchup'
  " Plug 'machakann/vim-sandwich' " TODO: needs testing
  Plug 'tpope/vim-surround'
  Plug 'tpope/vim-repeat'
  Plug 'tpope/vim-fugitive' | Plug 'tpope/vim-rhubarb' " required for some fugitive things
  Plug 'junegunn/gv.vim', { 'on': [ 'GV' ] }
  Plug 'rhysd/conflict-marker.vim'
  Plug 'tpope/vim-eunuch'
  Plug 'w0rp/ale'
  Plug 'metakirby5/codi.vim', { 'on': ['Codi'] }
  Plug 'svermeulen/vim-easyclip' " FIXME: figure out how to keep using dd as normal
  Plug 'iamcco/markdown-preview.nvim', { 'for': ['md, markdown, mdown'], 'do': 'cd app & yarn install' }
  Plug 'brooth/far.vim', {'do': ':UpdateRemotePlugins' }

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
  " Plug 'chaoren/vim-wordmotion'                                   " FIXME: do i really want this?  " https://github.com/chaoren/vim-wordmotion#more-useful-word-motions-for-vim
  Plug 'wellle/targets.vim'                                         " improved targets line cin) next parens)
  " ^--- https://github.com/wellle/targets.vim/blob/master/cheatsheet.md

call plug#end()
endif

filetype plugin indent on

"}}}
" ░░░░░░░░░░░░░░░ General Config/Settings {{{

let g:mapleader = ","                                                           "Change leader to a comma

set background=dark                                                             "Set background to dark

let g:nova_transparent = 1
silent! colorscheme nova

set termguicolors
set guicursor=n-v-c:block,i-ci-ve:ver25,r-cr:hor20,o:hor50,a:blinkwait700-blinkoff400-blinkon250-Cursor/lCursor,sm:block-blinkwait175-blinkoff150-blinkon175
" set guicursor=n-v-c:block-Cursor/lCursor-blinkon0,i-ci:ver25-Cursor/lCursor,r-cr:hor20-Cursor/lCursor
set guifont=FuraCode\ Nerd\ Font\ Retina:h16

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

set title                                                                       "change the terminal's title
set number                                                                      "Line numbers are good
set relativenumber                                                              "Show numbers relative to current line
set signcolumn=yes
set history=500                                                                 "Store lots of :cmdline history
set showcmd                                                                     "Show incomplete cmds down the bottom
set cmdheight=1
set noshowmode                                                                  "Hide showmode because of the powerline plugin
set gdefault                                                                    "Set global flag for search and replace
set gcr=a:blinkon500-blinkwait500-blinkoff500                                   "Set cursor blinking rate
set cursorline                                                                "Highlight current line
set smartcase                                                                   "Smart case search if there is uppercase
set ignorecase                                                                  "case insensitive search
set mouse=a                                                                     "Enable mouse usage
set showmatch                                                                   "Highlight matching bracket
set nostartofline                                                               "Jump to first non-blank character
set timeoutlen=1000 ttimeoutlen=0                                               "Reduce Command timeout for faster escape and O
set fileencoding=utf-8                                                          "Set utf-8 encoding on write
set linebreak
" set textwidth=80 " will auto wrap content when set regardless of nowrap being set
set nowrap " `wrap` to turn it on
set wrapscan
set listchars=tab:▸\ ,eol:¬,extends:›,precedes:‹,trail:·,nbsp:⚋
set nolist " `list` to enable                                                     "Enable listchars
set lazyredraw                                                                  "Do not redraw on registers and macros
set ttyfast
set hidden                                                                      "Hide buffers in background
set conceallevel=2 concealcursor=i                                              "neosnippets conceal marker
set splitright                                                                  "Set up new vertical splits positions
set splitbelow                                                                  "Set up new horizontal splits positions
set path+=**                                                                    "Allow recursive search
if (has('nvim'))
  " show results of substition as they're happening but don't open a split
  set inccommand=nosplit
endif
set fillchars+=vert:\│                                                          "Make vertical split separator full line
set pumheight=30                                                                "Maximum number of entries in autocomplete popup
set exrc                                                                        "Allow using local vimrc
set secure                                                                      "Forbid autocmd in local vimrc
set tagcase=smart                                                               "Use smarcase for tags
set updatetime=300                                                              "Cursor hold timeout
set synmaxcol=300                                                               "Use syntax highlighting only for 300 columns
set showbreak=↪ "↳

" -------- dictionary and spelling
set dictionary+=/usr/share/dict/words
set nospell             " Disable spellchecking by default
set spelllang=en_us,en_gb
set spellfile=~/.config/nvim/spell/en.utf-8.add


" -------- clipboard
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

" if more than 1 files are passed to vim as arg, open them in vertical splits
if argc() > 1
  silent vertical all
endif


" -------- abbreviations/spellings
iab Connectiosn Connections
iab Cound Could
iab SOme Some
iab THat That
iab THe The
iab THere There
iab THerefore Therefore
iab THese These
iab THis This
iab THose Those
iab WHen When
iab connectiosn connections
iab cound could
iab functino function
iab indentatino indentation
iab optiosn options
iab taht that
iab teh the
iab itinirary itinerary
iab itinarary itinerary
iab acheivement achievement
iab acheivements achievements
iab acheivment achievement
iab acheivments achievements
iab dashbaord dashboard
iab Dashbaord Dashboard
iab dashbarod dashboard
iab Dashbarod Dashboard
iab canavs canvas

" }}}
" ░░░░░░░░░░░░░░░ Turn Off Swap Files {{{

set noswapfile
set nobackup
set nowb
set backupcopy=yes "HMR things - https://parceljs.org/hmr.html#safe-write

" }}}
" ░░░░░░░░░░░░░░░ Persistent Undo {{{

" Keep undo history across sessions, by storing in file.
silent !mkdir ~/.config/nvim/undo > /dev/null 2>&1
set undodir=~/.config/nvim/undo
set undofile

" }}}
" ░░░░░░░░░░░░░░░ Scrolling {{{

set scrolloff=8                                                                 "Start scrolling when we're 8 lines away from margins
set sidescrolloff=15
set sidescroll=5

" }}}
" ░░░░░░░░░░░░░░░ Indentation {{{

set shiftwidth=2
set softtabstop=2
set tabstop=2
set expandtab
set smartindent
set nofoldenable
" set foldmethod=syntax

" }}}
" ░░░░░░░░░░░░░░░ Completion {{{

set wildmode=list:full
set wildignore=*.o,*.obj,*~                                                     "stuff to ignore when tab completing
set wildignore+=*.git*
set wildignore+=*.meteor*
set wildignore+=*vim/backups*
set wildignore+=*sass-cache*
set wildignore+=*cache*
set wildignore+=*logs*
set wildignore+=*node_modules/**
set wildignore+=*deps/**
set wildignore+=*DS_Store*
set wildignore+=*.gem
set wildignore+=log/**
set wildignore+=tmp/**
set wildignore+=*.png,*.jpg,*.gif

set shortmess+=c

" }}}
" ░░░░░░░░░░░░░░░ Commands {{{

command! -bar -nargs=0 SudoWrite :silent exe 'write !sudo tee % >/dev/null' | silent edit!

" }}}
" ░░░░░░░░░░░░░░░ Autocommands {{{
augroup vimrc
  au!

  " automatically source vim configs
  " au BufWritePost .vimrc,.vimrc.local,init.vim source %
  " au BufWritePost .vimrc.local source %

  " save all files on focus lost, ignoring warnings about untitled buffers
  autocmd FocusLost * silent! wa

  au BufWritePre * call StripTrailingWhitespaces()                     "Auto-remove trailing spaces
  au FocusGained  * checktime "Refresh file when vim gets focus
  au BufEnter     * checktime
  au WinEnter     * checktime
  au CursorHold   * checktime
  au InsertEnter  * checktime

  " Handle window resizing
  au VimResized * execute "normal! \<c-w>="

  " No formatting on o key newlines
  au BufNewFile,BufEnter * set formatoptions-=o

  " Remember cursor position between vim sessions
  au BufReadPost *
        \ if line("'\"") > 0 && line ("'\"") <= line("$") |
        \   exe "normal! g'\"" |
        \ endif

  " Auto-close preview window when completion is done.
  au! InsertLeave,CompleteDone * if pumvisible() == 0 | pclose | endif

  " Hide status bar while using fzf commands
  if has('nvim')
    au! FileType fzf
    au  FileType fzf set laststatus=0 | au BufLeave,WinLeave <buffer> set laststatus=2
  endif

  " Auto enter insert mode in popup terminal
  autocmd BufWinEnter,WinEnter popup-term startinsert

  " When terminal buffer ends allow to close it
  autocmd TermClose * noremap <buffer><silent><CR> :bd!<CR>
  autocmd TermClose * noremap <buffer><silent><ESC> :bd!<CR>
  au! TermOpen * setlocal nonumber norelativenumber
  au! TermOpen * if &buftype == 'terminal'
        \| set nonumber norelativenumber
        \| endif

  "
  " FIXME: not sure we want these?
  " au InsertEnter,BufLeave * setl iskeyword=@,48-57,192-255,\@,\$,%,-,_
  " au InsertLeave,BufEnter * setl iskeyword=@,48-57,192-255

  " ----------------------------------------------------------------------------
  " ## JavaScript
  au FileType typescript,typescriptreact,typescript.tsx,javascript,javascript.jsx,sass,scss,scss.css,elixir,eelixir,elm RainbowParentheses
  au BufNewFile,BufRead .{babel,eslint,prettier,stylelint,jshint,jscs,postcss}*rc,\.tern-*,*.json,.tern-project set ft=json
  au BufNewFile,BufRead *.tsx,*.ts setl commentstring=//\ %s " doing this because for some reason it keeps defaulting the commentstring to `/* %s */`

  " ----------------------------------------------------------------------------
  " ## CSS/SCSS
  " make sure `complete` works as expected for CSS class names whithout
  " messing with motions (eg. '.foo-bar__baz') and we make sure all
  " delimiters (_,-,$,%,.) are treated as word separators outside insert mode
  "
  " https://github.com/rstacruz/vimfiles/blob/master/plugin/plugins/css3-syntax.vim
  au FileType css,css.scss,sass,scss setl iskeyword+=-
  au FileType css,css.scss,sass,scss setl formatoptions+=croql

  " ----------------------------------------------------------------------------
  " ## Markdown
  au BufEnter,BufNewFile,BufRead,BufReadPost *.{md,mdwn,mkd,mkdn,mark*,txt,text} set nolazyredraw conceallevel=0
  " au FileType markdown,text,html setlocal spell complete+=kspell
  au FileType markdown set tw=80

  " ----------------------------------------------------------------------------
  " ## Ruby
  au FileType ruby setl iskeyword+=_
  au BufRead,BufNewFile {Gemfile,Rakefile,Vagrantfile,Thorfile,Procfile,Guardfile,config.ru,*.rake,*.jbuilder} set ft=ruby
  au BufRead,BufNewFile .env.local,.env.development,.env.test setf sh   " Use Shell for .env files

  " ----------------------------------------------------------------------------
  " ## SSH
  au BufNewFile,BufRead */ssh/config,ssh_config,*/.dotfiles/private/ssh/config setf sshconfig

  " ----------------------------------------------------------------------------
  " ## Misc filetypes
  au FileType zsh set ts=2 sts=2 sw=2
  au FileType sh set ts=2 sts=2 sw=2
  au FileType bash set ts=2 sts=2 sw=2
  au FileType tmux set ts=2 sts=2 sw=2

  " ----------------------------------------------------------------------------
  " ## Toggle certain accoutrements when entering and leaving a buffer & window
  au WinEnter,BufEnter * silent set number relativenumber syntax=on " call RainbowParentheses
  au WinLeave,BufLeave * silent set nonumber norelativenumber syntax=off " call RainbowParentheses!
  au BufEnter,FocusGained,InsertLeave * silent set relativenumber cursorline
  au BufLeave,FocusLost,InsertEnter   * silent set norelativenumber nocursorline
  au InsertEnter * silent set colorcolumn=80
  au InsertLeave * silent set colorcolumn=""

  " ----------------------------------------------------------------------------
  " ## Automagically update remote homeassistant files upon editing locally
  au BufWritePost ~/.dotfiles/private/homeassistant/* silent! :MirrorPush ha

  " ----------------------------------------------------------------------------
  " ## Manage GIT related scenarios
  au FileType gitcommit,gitrebase setl nospell textwidth=72
  au BufNewFile,BufRead .git/index setlocal nolist
  au BufReadPost fugitive://* set bufhidden=delete
  au BufReadCmd *.git/index exe BufReadIndex()
  au BufEnter *.git/index silent normal gg0j
  au BufEnter *.git/COMMIT_EDITMSG exe BufEnterCommit()
  au FileType gitcommit,gitrebase exe BufEnterCommit()
  " au FileType gitcommit,gitrebase let g:gutentags_enabled=0

  " set up default omnifunc
  autocmd FileType *
        \ if &omnifunc == "" |
        \    setlocal omnifunc=syntaxcomplete#Complete |
        \ endif
augroup END

augroup elm
  au!
  au FileType elm let g:VimuxOrientation = "h"
  au FileType elm nn <buffer> K :ElmShowDocs<CR>

  au FileType elm nn <silent> <leader>ei :VimuxInspectRunner<CR>
  " TODO: want to automatically do this if all normal buffers are closed:
  au FileType elm nn <silent> <leader>ec :VimuxCloseRunner<CR>

  " au FileType elm nn <buffer> <localleader>m :ElmMakeMain<CR>
  " au FileType elm nn <buffer> <localleader>r :ElmRepl<CR>

  " Check and see if we are we in the root of vpp or in vpp/ui?
  if filereadable("./ui/bin/start")
    " au FileType elm nn <leader>em :Dispatch ui/bin/start<CR>
    au FileType elm nn <leader>em :call VimuxRunCommand("ui/bin/start")<CR>
    au FileType elm nn <leader>et :Dispatch ui/bin/test<CR>
    au FileType elm nn <leader>ef :Dispatch ui/bin/format<CR>
  else
    " au FileType elm nn <leader>em :Dispatch bin/start<CR>
    au FileType elm nn <leader>em :call VimuxRunCommand("bin/start")<CR>
    au FileType elm nn <leader>et :Dispatch bin/test<CR>
    au FileType elm nn <leader>ef :Dispatch bin/format<CR>
  endif

  au FileType elm setl iskeyword+=_
  " au FileType elm nn <C-c> :bd!<CR>
  " au FileType elm setlocal omnifunc=lsp#complete
  " au FileType elm setlocal omnifunc=LanguageClient#complete
augroup END

augroup elixir
  au!
  au FileType elixir,eelixir setl matchpairs=(:),{:},[:]
  au FileType elixir,eelixir setl iskeyword+=_

  " Enable html syntax highlighting in all .eex files
  " autocmd BufReadPost *.html.eex set syntax=html

  " ways-to-debug:
  " au FileType elixir,eelixir nnoremap <leader>er :Dispatch !iex -r % -S mix<CR>
  au FileType elixir,eelixir nnoremap <leader>er :TREPLSendFile<CR>
  au FileType elixir,eelixir nnoremap <leader>ed orequire IEx; IEx.pry<ESC>:w<CR>
  au FileType elixir,eelixir nnoremap <leader>ep orequire IEx; IEx.pry<ESC>:w<CR>
  au FileType elixir,eelixir nnoremap <leader>ei o\|>IO.inspect<ESC>:w<CR>
  au FileType elixir,eelixir nnoremap <leader>ew :call VimuxRunCommand("mix test.watch")<CR>
  au FileType elixir,eelixir nnoremap <leader>ex :call VimuxRunCommand("iex -S mix")<CR>

  " :Eix => open iex with current file compiled
  command! Iex :!iex -S mix %<cr>
  " au FileType elixir,eelixir nnoremap <leader>e :!elixir %<CR>

  " disable endwise for anonymous fn in elixir
  au BufNewFile,BufRead *.{ex,exs}
        \ let b:endwise_addition = '\=submatch(0)=="fn" ? "end)" : "end"'
augroup END

" Automatically close vim if only the quickfix window is open
" http://stackoverflow.com/a/7477056/3720597
augroup QuickFixClose
  au!
  au WinEnter * if winnr('$') == 1 &&
        \getbufvar(winbufnr(winnr()), "&buftype") == "quickfix"
        \| q
        \| endif
augroup END

augroup MakeQuickFixPrettier
  au!
  au BufRead * if &buftype == 'quickfix'
        \| setlocal colorcolumn=
        \| setlocal nolist
        \| endif
augroup END

" }}}
" ░░░░░░░░░░░░░░░ Functions {{{

" Scratch buffer
function! ScratchOpen()
  let scr_bufnr = bufnr('__scratch__')
  if scr_bufnr == -1
    vnew
    setlocal filetype=ghmarkdown
    setlocal bufhidden=hide
    setlocal nobuflisted
    setlocal buftype=nofile
    setlocal noswapfile
    file __scratch__
  else
    execute 'buffer ' . scr_bufnr
  endif
endfunction

" Open persistant scratch buffer
function! OpenScratch() abort
  edit ~/.local/share/nvim/scratch.md
  setlocal bufhidden=delete autowriteall
endfunction

" Make current window golden ratio sized
function! GoldenRatio() abort
  wincmd =
  execute 'resize' . (winheight(0) * 5/4)
  execute 'vertical resize' . (winwidth(0) * 5/4)
endfunction

" Call another command if one failed
function! ExeWithFallback(command, fallback) abort
  try
    exe a:command
  catch
    try | exe a:fallback | catch | endtry
  endtry
endfunction

function! StripTrailingWhitespaces()
  if &modifiable
    let l:l = line(".")
    let l:c = col(".")
    %s/\s\+$//e
    call cursor(l:l, l:c)
  endif
endfunction

function! Search(...)
  let default = a:0 > 0 ? expand('<cword>') : ''
  let term = input('Search for: ', default)
  if term != ''
    let path = input('Path: ', '', 'file')
    execute 'CtrlSF "'.term.'" '.path
  endif
endfunction

function! CloseBuffer() abort
  if &buftype ==? 'quickfix'
    bd
    return 1
  endif
  let l:windowCount = winnr('$')
  let l:command = 'bd'
  let l:totalBuffers = len(getbufinfo({ 'buflisted': 1 }))
  silent exe l:command
endfunction

" Used by Fugitive
function! BufReadIndex()
  " Use j/k in status
  setl nohlsearch
  nnoremap <buffer> <silent> j :call search('^#\t.*','W')<Bar>.<CR>
  nnoremap <buffer> <silent> k :call search('^#\t.*','Wbe')<Bar>.<CR>
endfunction

" Used by Fugitive
function! BufEnterCommit()
  " Start in insert mode for commit
  normal gg0
  if getline('.') == ''
    start
  end

  " disable completion for gitcommit messages
  " call ncm2#disable_for_buffer()
  " au InsertEnter * call ncm2#disable_for_buffer()

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

" quick-scope, used in conjunction with keybinding overrides
function! Quick_scope_selective(movement)
  let needs_disabling = 0
  if !g:qs_enable
    QuickScopeToggle
    redraw
    let needs_disabling = 1
  endif

  let letter = nr2char(getchar())

  if needs_disabling
    QuickScopeToggle
  endif

  return a:movement . letter
endfunction

" vim-vertical-move replacement
" credit: cherryberryterry: https://www.reddit.com/r/vim/comments/4j4duz/a/d33s213
function! s:vjump(dir) abort
  let c = '%'.virtcol('.').'v'
  let flags = a:dir ? 'bnW' : 'nW'
  let bot = search('\v'.c.'.*\n^(.*'.c.'.)@!.*$', flags)
  let top = search('\v^(.*'.c.'.)@!.*$\n.*\zs'.c, flags)

  " norm! m`
  return a:dir ? (line('.') - (bot > top ? bot : top)).'k'
    \        : ((bot < top ? bot : top) - line('.')).'j'
endfunction

" improved ultisnips complete
function! ExpandLspSnippet()
  call UltiSnips#ExpandSnippetOrJump()
  if !pumvisible() || empty(v:completed_item)
    return ''
  endif

  " only expand Lsp if UltiSnips#ExpandSnippetOrJump not effect.
  let l:value = v:completed_item['word']
  let l:matched = len(l:value)
  if l:matched <= 0
    return ''
  endif

  " remove inserted chars before expand snippet
  if col('.') == col('$')
    let l:matched -= 1
    exec 'normal! ' . l:matched . 'Xx'
  else
    exec 'normal! ' . l:matched . 'X'
  endif

  if col('.') == col('$') - 1
    " move to $ if at the end of line.
    call cursor(line('.'), col('$'))
  endif

  " expand snippet now.
  call UltiSnips#Anon(l:value)
  return ''
endfunction

function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~ '\s'
endfunction

function! ToggleTerminal() abort
  let l:buffer_name = 'popup-term'
  let l:win_number = bufwinnr(l:buffer_name)

  " check if window already open
  if l:win_number > 0
    exe l:win_number . 'wincmd c'
  else
    botright split | exe 'resize' . &previewheight

    " check if buffer exists
    if bufexists(l:buffer_name)
      exe 'buffer ' . l:buffer_name
    else
      terminal
      exe 'file ' . l:buffer_name

      " Disable line numbers
      setlocal nonumber norelativenumber

      " Close terminal window when leaving insert mode
      tnoremap <buffer><silent><C-[> <C-\><C-n>:call ToggleTerminal()<CR>
    endif

    startinsert
  endif
endfunction

" }}}
" ░░░░░░░░░░░░░░░ Plugin Config/Settings {{{

" ## polyglot
  let g:polyglot_disabled = ['typescript', 'typescriptreact', 'typescript.tsx', 'graphql', 'jsx', 'sass', 'scss', 'css', 'markdown', 'elm', 'elixir']

" ## vim-matchup
  let g:matchup_matchparen_status_offscreen = 0 " prevents statusline from disappearing

" ## vim-easyclip
  let g:EasyClipAutoFormat = 1
  let g:EasyClipUseYankDefaults = 0
  let g:EasyClipUseCutDefaults = 0
  let g:EasyClipUsePasteDefaults = 0
  let g:EasyClipEnableBlackHoleRedirect = 0
  let g:EasyClipUsePasteToggleDefaults = 0
  let g:EasyClipEnableBlackHoleRedirectForDeleteOperator = 0
  let g:EasyClipUseSubstituteDefaults = 1
  "m[motion] or mm to cut
  "s[motion] or ss to substitute
  "d[motion] or dd does not yank
  "c[motion] or cc does not yank
  "Ctrl+p and Ctrl+n cycles through next and previous yanks

" ## codi
  let g:codi#rightalign=0

" vim-dirvish
  let g:dirvish_mode = ':sort | sort ,^.*[\/],'

" ## netrw
  " netrw cheatsheet: https://gist.github.com/t-mart/610795fcf7998559ea80
  " let g:loaded_netrw = 1
  " let g:loaded_netrwPlugin = 1
  " let g:netrw_banner = 0
  " let g:netrw_liststyle = 3
  " let g:netrw_browse_split = 4
  " let g:netrw_altv = 1
  " let g:netrw_winsize = 25

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

" ## indentLine
  let g:indentLine_enabled = 1
  let g:indentLine_color_gui = '#556874'
  let g:indentLine_char = '│'
  " let g:indentLine_bgcolor_gui = '#3C4C55'

" ## golden-ratio
  let g:golden_ratio_exclude_nonmodifiable = 1
  let g:golden_ratio_wrap_ignored = 0
  let g:golden_ratio_ignore_horizontal_splits = 1

" ## vim-sneak
  let g:sneak#label = 1
  let g:sneak#use_ic_scs = 1
  let g:sneak#absolute_dir = 1

" " ## clever-f
  " let g:clever_f_across_no_line = 1
  " let g:clever_f_timeout_ms = 3000

" ## quick-scope
  let g:qs_enable = 1
  let g:qs_highlight_on_keys = ['f', 'F', 't', 'T']

" ## vim-asterisk
  map *  <Plug>(incsearch-nohl0)<Plug>(asterisk-z*)
  map #  <Plug>(incsearch-nohl0)<Plug>(asterisk-z#)
  map g* <Plug>(incsearch-nohl0)<Plug>(asterisk-gz*)
  map g# <Plug>(incsearch-nohl0)<Plug>(asterisk-gz#)

" ## incsearch.vim
  let g:incsearch#auto_nohlsearch = 1
  let g:incsearch#consistent_n_direction = 1
  let g:incsearch#do_not_save_error_message_history = 1
  let g:incsearch#separate_highlight = 1
  map / <Plug>(incsearch-forward)
  map ? <Plug>(incsearch-backward)
  map g/ <Plug>(incsearch-stay)
  map z/ <Plug>(incsearch-fuzzy-/)
  map z? <Plug>(incsearch-fuzzy-?)
  map zg/ <Plug>(incsearch-fuzzy-stay)
  map n <Plug>(incsearch-nohl)<Plug>(anzu-n-with-echo)zMzv
  map N <Plug>(incsearch-nohl)<Plug>(anzu-N-with-echo)zMzv

" ## auto-pairs
  let g:AutoPairsShortcutToggle = ''
  let g:AutoPairsMapCR = 0 " https://www.reddit.com/r/neovim/comments/4st4i6/making_ultisnips_and_deoplete_work_together_nicely/d6m73rh/

" # delimitMate
  let delimitMate_expand_cr = 2
  let delimitMate_expand_space = 1
  let delimitMate_nesting_quotes = ['"', '`']
  let delimitMate_excluded_regions = ""
  let delimitMate_balance_matchpairs = 1

" # endwise
  let g:endwise_no_mappings = 1

" # lexima
  let g:lexima_enable_endwise_rules = 1

" ## ALE
  let g:ale_enabled = 1
  let g:ale_completion_enabled = 0
  let g:ale_lint_delay = 500
  let g:ale_sign_column_always = 1
  let g:ale_echo_msg_format = '[%linter%] %s'
  let g:ale_linter_aliases = {'tsx': ['ts', 'typescript'], 'typescriptreact': ['ts', 'typescript']}
  let g:ale_linters = {
        \   'elixir': ['elixir-ls'],
        \   'eelixir': ['elixir-ls'],
        \ }
  let g:ale_fixers = {
        \   'javascript': ['prettier_eslint'],
        \   'javascript.jsx': ['prettier_eslint'],
        \   'typescript': ['prettier_eslint'],
        \   'typescriptreact': ['prettier_eslint'],
        \   'typescript.tsx': ['prettier_eslint'],
        \   'css': ['prettier'],
        \   'scss': ['prettier'],
        \   'json': ['prettier'],
        \   'python': ['black'],
        \   'elm': ['elm-format'],
        \   'eelixir': ['mix_format'],
        \   'elixir': ['mix_format'],
        \ }                                                                       "Fix eslint errors
  let g:ale_sign_error = '✖'                                                      "Lint error sign ⤫ ✖⨉
  let g:ale_sign_warning = '⬥'                                                    "Lint warning sign ⬥⚠
  let g:ale_sign_info = '‣'
  let g:ale_javascript_eslint_use_local_config = 1
  let g:ale_javascript_prettier_use_local_config = 1
  let g:ale_javascript_prettier_eslint_use_local_config = 1
  let g:ale_elixir_elixir_ls_release = expand($PWD."/.elixir_ls/rel")
  let g:ale_elm_format_options = '--yes --elm-version=0.18'
  let g:ale_lint_on_text_changed = 'always'
  let g:ale_lint_on_insert_leave = 1
  let g:ale_lint_on_enter = 1
  let g:ale_lint_on_save = 1
  let g:ale_fix_on_save = 1
  let g:ale_virtualtext_cursor = 1
  let g:ale_virtualtext_prefix = "❯❯ "

" ## vim-jsx
  let g:jsx_ext_required = 0
  let g:jsx_pragma_required = 0
  let g:javascript_plugin_jsdoc = 1                                               "Enable syntax highlighting for js doc blocks

" ## vim-markdown
  " let g:vim_markdown_frontmatter = 1
  " let g:vim_markdown_toc_autofit = 1
  " let g:vim_markdown_new_list_item_indent = 2
  " let g:vim_markdown_conceal = 0
  " let g:vim_markdown_folding_disabled = 1
  let g:markdown_fenced_languages = [
        \ 'javascript', 'js=javascript', 'json=javascript',
        \ 'typescript', 'typescriptreact=typescript',
        \ 'css', 'scss', 'sass',
        \ 'ruby', 'erb=eruby',
        \ 'python',
        \ 'haml', 'html',
        \ 'bash=sh', 'zsh', 'elm', 'elixir']

" ## vim-json
  let g:vim_json_syntax_conceal = 0

" ## vim-better-javascript-completion
  let g:vimjs#casesensistive = 1
  " Enabled by default. flip the value to make completion matches case insensitive
  let g:vimjs#smartcomplete = 0
  " Disabled by default. Enabling this will let vim complete matches at any location
  " e.g. typing 'ocument' will suggest 'document' if enabled.
  let g:vimjs#chromeapis = 0
  " Disabled by default. Toggling this will enable completion for a number of Chrome's JavaScript extension APIs

" ## vim-javascript-syntax
  let g:JSHintHighlightErrorLine = 1
  let javascript_enable_domhtmlcss = 1
  let loaded_matchit = 1
  let g:js_indent_log = 1
  let g:used_javascript_libs = 'underscore,chai,react,flux,mocha,redux,lodash,angularjs,angularui,enzyme,ramda,d3'

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

" ## colorizer
  " let g:colorizer_auto_filetype='css,scss'
  " let g:colorizer_colornames = 1

" ## rainbow_parentheses.vim
  let g:rainbow#max_level = 10
  let g:rainbow#pairs = [['(', ')'], ['[', ']'], ['{', '}']]

" ## vim-surround
  let g:surround_indent = 0
  " let g:surround_no_insert_mappings = 1

" ## vim-test
  function! SplitStrategy(cmd)
    vert new | call termopen(a:cmd) | startinsert
  endfunction
  let g:test#custom_strategies = {'terminal_split': function('SplitStrategy')}
  let g:test#strategy = 'terminal_split'
  let test#ruby#rspec#options = '-f d'
  " let test#ruby#bundle_exec = 1
  let test#ruby#use_binstubs = 1
  let g:test#runner_commands = ['Jest', 'RSpec', 'Cypress']

" ## FZF
  let g:fzf_buffers_jump = 1
  let g:fzf_filemru_bufwrite = 1
  let g:fzf_layout = { 'down': '~15%' }
  " let g:fzf_files_options =
  "       \ '--preview "(~/dev/termpix/bin/termpix --width 50 --true-color {} || cat {}) 2> /dev/null "'
  let g:fzf_action = {
        \ 'ctrl-t': 'tab split',
        \ 'ctrl-x': 'split',
        \ 'ctrl-v': 'vsplit',
        \ 'enter': 'vsplit'
        \ }

  " nova-vim
  let g:fzf_colors = {
        \ "fg":      ["fg", "Normal"],
        \ "bg":      ["bg", "Normal"],
        \ "hl":      ["fg", "ALEWarning"],
        \ "fg+":     ["fg", "CursorLine", "CursorColumn", "Normal"],
        \ "bg+":     ["bg", "CursorLine", "CursorColumn"],
        \ "hl+":     ["fg", "CocWarning"],
        \ "info":    ["fg", "Comment"],
        \ "border":  ["fg", "Ignore"],
        \ "prompt":  ["fg", "Comment"],
        \ "pointer": ["fg", "IncSearch"],
        \ "marker":  ["fg", "IncSearch"],
        \ "spinner": ["fg", "IncSearch"],
        \ "header":  ["fg", "IncSearch"]
        \}

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

" ## gist.vim
  let g:gist_open_url = 1
  let g:gist_default_private = 1

" ## gen_tags
"   let g:gen_tags#use_cache_dir  = 1
"   let g:gen_tags#ctags_auto_gen = 1
"   let g:gen_tags#gtags_auto_gen = 1


" ## vim-gutentags
  " let g:gutentags_project_root = ['.git']
  " let g:gutentags_cache_dir = expand('~/.tags_cache')
  " " let g:gutentags_ctags_exclude = ['*.css', '*.html', '*.js', '*.json', '*.xml', '*.ini', '*.rst', '*.md', '*/vendor/*', '*vendor/*/test*', '*vendor/*/Test*', '*vendor/*/fixture*', '*vendor/*/Fixture*', '*var/cache*', '*var/log*']
  " let g:gutentags_ctags_tagfile = '.tags'
  " let g:gutentags_trace = 1

" ## vim-autotag
  " let g:autotagTagsFile="tags"
  " let g:autotagmaxTagsFileSize=100000000
  " let g:autotagExcludeSuffixes='xml.html.css.scss.sass.md.rst.ini.json.js.log.txt'

" ## far.vim
  if has('nvim')
    let g:far#source = 'rgnvim'
  else
    let g:far#source = 'rg'
  endif
  let g:far#window_layout = 'current'
  let g:far#preview_window_layout = 'right'
  let g:far#file_mask_favorites = ['%', 'elm', 'elixir', 'html', 'json', 'js', 'jsx', 'ts', 'tsx']

" ## tagbar
  set tags+=tags,tags.vendors
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

" ## ultisnips
  let g:UltiSnipsExpandTrigger = "<C-e>"
  let g:UltiSnipsExpandTrigger = "<Plug>(ultisnips_expand)"
  let g:UltiSnipsJumpForwardTrigger	= "<Tab>"
  let g:UltiSnipsJumpBackwardTrigger	= "<S-Tab>"
  let g:UltiSnipsRemoveSelectModeMappings = 0
  let g:UltiSnipsSnippetDirectories=['UltiSnips']

" ## alchemist.vim
  " let g:alchemist_mappings_disable = 1
  " let g:alchemist_tag_disable = 1

" }}}
" ░░░░░░░░░░░░░░░ lightline/statusbar {{{

" ## lightline.vim
let status_timer = timer_start(1000, 'UpdateStatusBar', { 'repeat': -1 })
let g:lightline = {
      \   'colorscheme': 'wombat',
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
      \     'gutentags': 'LightlineGutentags',
      \     'coc': 'LightlineCocStatus',
      \   },
      \   'component_expand': {
      \     'linter_checking': 'lightline#ale#checking',
      \     'linter_warnings': 'lightline#ale#warnings',
      \     'linter_errors': 'lightline#ale#errors',
      \     'linter_ok': 'lightline#ale#ok',
      \   },
      \   'component_type': {
      \     'readonly': 'error',
      \     'modified': 'raw',
      \     'linter_checking': 'left',
      \     'linter_warnings': 'warning',
      \     'linter_errors': 'error',
      \     'linter_ok': 'left',
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
      \       ['linter_checking', 'linter_warnings', 'linter_errors', 'linter_ok', 'gutentags'],
      \       ['lineinfo', 'percent'],
      \       ['fileformat'],
      \       ['filetype'],
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

" right section for ALE things:
" \       ['coc', 'gutentags'],
" \       ['linter_checking', 'linter_warnings', 'linter_errors', 'linter_ok'],

let g:lightline#ale#indicator_ok = "\uf42e "
let g:lightline#ale#indicator_warnings = ' '
let g:lightline#ale#indicator_errors = ' '
let g:lightline#ale#indicator_checking = " "

function! UpdateStatusBar(timer)
  " call lightline#update()
endfunction

function! PrintStatusline(v)
  return &buftype == 'nofile' ? '' : a:v
endfunction

function! LightlineFileType()
  return winwidth(0) > 70 ? (strlen(&filetype) ? WebDevIconsGetFileTypeSymbol() . ' '. &filetype : 'no ft') : ''
endfunction

function! LightlineFileFormat()
  return winwidth(0) > 70 ? (WebDevIconsGetFileFormatSymbol() . ' ' . &fileformat) : ''
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

function! LightlineScrollbar()
  let top_line = str2nr(line('w0'))
  let bottom_line = str2nr(line('w$'))
  let lines_count = str2nr(line('$'))

  if bottom_line - top_line + 1 >= lines_count
    return ''
  endif

  let window_width = winwidth(0)
  if window_width < 90
    let scrollbar_width = 6
  elseif window_width < 120
    let scrollbar_width = 9
  else
    let scrollbar_width = 12
  endif

  return noscrollbar#statusline(scrollbar_width, '-', '#')
endfunction

function! s:get_gutentags_status(mods) abort
  let l:msg = ''
  if index(a:mods, 'ctags') > 0
     let l:msg .= '♨'
   endif
   if index(a:mods, 'cscope') > 0
     let l:msg .= '♺'
   endif
   return l:msg
endfunction

function! LightlineGutentags()
  if !exists('g:loaded_gutentags')
    return ''
  endif
  return gutentags#statusline_cb(function('<SID>get_gutentags_status'))
endfunction

function! LightlineCocStatus()
  let info = get(b:, 'coc_diagnostic_info', {})
  if empty(info) | return "\uf42e " | endif
  let msgs = []
  if get(info, 'error', 0)
    call add(msgs, ' ' . info['error'])
  endif
  if get(info, 'warning', 0)
    call add(msgs, ' ' . info['warning'])
  endif
  " return 'coc: ' . join(msgs, ' ')
  return join(msgs, ' ')
endfunction

" }}}
" ░░░░░░░░░░░░░░░ coc.nvim {{{
" for showSignatureHelp
set completeopt=noinsert,menuone,noselect
set shortmess+=c

" Or use formatexpr for range format
set formatexpr=CocActionAsync('formatSelected')

" use <tab> for trigger completion and navigate next complete item
function! s:check_back_space() abort
  let l:col = col('.') - 1
  return !l:col || getline('.')[l:col - 1]  =~# '\s'
endfunction

" if exists snippets
function s:isSnipsExpandable()
  try
    let l:line = getline('.')
    let l:start = col('.') - 1
    while l:start > 0 && l:line[l:start - 1] =~# '\k'
      let l:start -= 1
    endwhile
    let l:trigger = l:line[l:start : col('.')-2]
    " get user input str
    if s:input_word ==# ''
      let s:input_word = l:trigger
    endif
    if s:input_word !=# l:trigger
      return v:false
    endif
    " get snippets
    let l:snippets = UltiSnips#SnippetsInCurrentScope()
    let l:has_snips = !(
          \ col('.') <= 1
          \ || !empty(matchstr(getline('.'), '\%' . (col('.') - 1) . 'c\s'))
          \ || empty(l:snippets)
          \ || get(l:snippets, l:trigger, 'notExists') ==# 'notExists'
          \ )
    " has snippets and snippets is input str
    return l:has_snips
  catch /.*/
    return v:false
  endtry
endfunction

" press enter when pumvisible
function! s:press_enter() abort
  if s:input_word ==# ''
    return "\<C-g>u\<CR>\<C-g>u"
  endif
  return "\<C-y>"
endfunction

" tab:
"   1. trigger snippets
"   2. select autocomplete
"   3. trigger autocomplete
" inoremap <silent><expr> <TAB>
"       \ <SID>isSnipsExpandable() ? "<C-R>=UltiSnips#ExpandSnippet()<CR>" :
"       \ pumvisible() ? "\<C-n>" :
"       \ <SID>check_back_space() ? "\<TAB>" : coc#refresh()
" inoremap <expr> <S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"

inoremap <silent><expr> <TAB> pumvisible() ? "\<C-n>" : (<SID>check_back_space() ? "\<TAB>" : coc#refresh())
inoremap <silent><expr> <S-TAB> pumvisible() ? "\<C-p>" : "\<S-TAB>"
inoremap <expr> <C-e> pumvisible() ? (<SID>isSnipsExpandable() ? "<C-R>=UltiSnips#ExpandSnippet()<CR>" : "") : "\<ESC>A"

" Use <C-x></C-u> to complete custom sources, including emoji, include and words
imap <silent> <C-x><C-o> <Plug>(coc-complete-custom)

" Use <CR> for confirm completion.
inoremap <expr> <CR> pumvisible() ? <SID>press_enter() : "\<C-g>u\<CR>"
"inoremap <expr> <CR> (pumvisible() ? "\<c-y>" : "\<CR>")

" Use K for show documentation in preview window
function! s:show_documentation()
  if &filetype ==# 'vim'
    execute 'h '.expand('<cword>')
  else
    call CocActionAsync('doHover')
  endif
endfunction

nnoremap <silent> K :call <SID>show_documentation()<CR>

" Remap for rename current word
nmap <leader>rn <Plug>(coc-rename)
nmap <F2> <Plug>(coc-rename)

" Use `[c` and `]c` for navigate diagnostics
nmap <silent> [c <Plug>(coc-diagnostic-prev)
nmap <silent> ]c <Plug>(coc-diagnostic-next)
" nmap <silent> <C-[> <Plug>(coc-diagnostic-prev)
" nmap <silent> <C-]> <Plug>(coc-diagnostic-next)

" Remap keys for gotos
nmap <silent> <leader>ld <Plug>(coc-definition)
nmap <silent> <leader>lt <Plug>(coc-type-definition)
nmap <silent> <leader>li <Plug>(coc-implementation)
nmap <silent> <leader>lr <Plug>(coc-references)

" Remap for format selected region
vmap <leader>lf <Plug>(coc-format-selected)
nmap <leader>lf <Plug>(coc-format-selected)

" Remap for do codeAction of selected region, ex: `<leader>aap` for current paragraph
vmap <leader>la <Plug>(coc-codeaction-selected)
nmap <leader>la <Plug>(coc-codeaction-selected)

" Use `:Format` for format current buffer
command! -nargs=0 Format :call CocActionAsync('format')

" Use `:Fold` for fold current buffer
command! -nargs=? Fold :call CocActionAsync('fold', <f-args>)

augroup coc_au
  au!
  " Show signature help while editing
  " au CursorHoldI * silent! call CocActionAsync('showSignatureHelp')
  au User CocJumpPlaceholder call CocActionAsync('showSignatureHelp')

  " Highlight symbol under cursor on CursorHold
  " au CursorHold * silent call CocActionAsync('highlight')
augroup END

function! s:clear_input() abort
  let s:input_word = ''
endfunction

function! s:snippet() abort
  let l:start_line = line('.')
  let l:is_position = search('\v%x0')
  if l:is_position !=# 0
    silent! s/\v\t/    /g
    silent! s/\v%x0\n//g
    silent! s/\v%x0/\r/g
    let l:end_line = line('.')
    call cursor(l:start_line, 0)
    let l:pos = searchpos('\v\$\{\d+\}', 'n', l:end_line)
    if l:pos[0] !=# 0 && l:pos[1] !=# 0
      call cursor(l:pos[0], l:pos[1])
      normal! df}
    endif
  endif
endfunction

augroup CocSnippet
  au!
  au CompleteDone *.exs,*.ex,*.elm call <SID>snippet()
  au CursorMovedI * call <SID>clear_input()
  " highlight text color
  au ColorScheme * highlight! CocHighlightText  guibg=#707e0a
augroup END
"}}}
" ░░░░░░░░░░░░░░░ codi {{{

" since it is fullscreen, I'd like a 50/50 split
let g:codi#width = 50.0

" instead of destroying buffers, hide them and
" index them by filetype into this dictionary
let s:codi_filetype_tabs = {}

fun! s:FullscreenScratch()
  " store filetype and bufnr of current buffer
  " for later reference
  let current_buf_ft  = &ft
  let current_buf_num = bufnr('%')

  " check if a scratch buffer for this filetype already exists
  let saved_scratch = get(s:codi_filetype_tabs, current_buf_ft, -1)

  " if a tabpage exists for current_buf_ft, go to it instead of
  " creating a new scratch buffer
  if saved_scratch != -1
    if index(map(gettabinfo(), 'v:val.tabnr'), saved_scratch) == -1
      unlet s:codi_filetype_tabs[current_buf_ft]
    else
      exe 'tabn' saved_scratch
      return
    endif
  endif

  " create a new empty tab, set scratch options and give it a name
  tabe
  setlocal buftype=nofile noswapfile modifiable buflisted bufhidden=hide
  let b:ale_enabled = 0
  exe ':file scratch::' . current_buf_ft

  " set filetype to that of original source file
  " e.g. ruby / python / w/e Codi supports
  let &filetype = current_buf_ft

  " store the tabpagenr per filetype so we can return
  " to it later when re-opening from the same filetype
  let s:codi_filetype_tabs[&filetype] = tabpagenr()

  " create a buffer local mapping that overrides the
  " outer one to delete the current scratch buffer instead
  " when the buffer is destroyed, this mapping will be
  " destroyed with it and the next <Leader><Leader>
  " will spawn a new fullscreen scratch window again
  nmap <silent><buffer> <Leader>r :tabprevious<Cr>

  " everything is setup, filetype is set
  " let Codi do the rest :)
  Codi
endfun

" create a mapping to call the fullscreen scratch wrapper
nmap <silent> <Leader>r :call <SID>FullscreenScratch()<Cr>

"}}}
" ░░░░░░░░░░░░░░░ Custom Mappings {{{

" # ncm2 + ultisnips
  " for details around ultisnips and lsp snippets: https://github.com/ncm2/ncm2-ultisnips/issues/6#issuecomment-410186456
  inoremap <expr> <Tab> pumvisible() ? "\<C-n>" : "\<Tab>"
  inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"
  inoremap <expr> <CR> pumvisible() ? "\<C-y>" : "\<CR>"
  " " details about endwise + ncm2 here: https://github.com/roxma/nvim-completion-manager/issues/49#issuecomment-285923119
  " imap <C-X><CR>   <CR><Plug>AlwaysEnd
  " inoremap <silent> <expr> <CR> ((pumvisible() && empty(v:completed_item)) ?  "\<C-y>\<CR>" : (!empty(v:completed_item) ? ncm2_ultisnips#expand_or("", 'n') : "\<CR>\<C-R>=EndwiseDiscretionary()\<CR>" ))
  " imap <silent> <expr> <C-e> ncm2_ultisnips#expand_or("\<Plug>(ultisnips_expand)", 'm')
  " smap <silent> <expr> <C-e> ncm2_ultisnips#expand_or("\<Plug>(ultisnips_expand)", 'm')
  " inoremap <silent> <expr> <C-e> ncm2_ultisnips#expand_or("\<Plug>(ultisnips_expand)", 'm')
  " inoremap <C-e> <C-R>=ExpandLspSnippet()<CR>

" # ALE
  " nmap <silent> <C-[> <Plug>(ale_previous_wrap)
  " nmap <silent> <C-]> <Plug>(ale_next_wrap)

" # netrw
  " nnoremap - :Vexplore<CR>
  " nnoremap <F3> :Vexplore<CR>

" # vim-dirvish
  nnoremap <silent> - :Dirvish %:p:h<CR>
  " nnoremap <silent> <leader>d :Dirvish %:p:h<CR>
  " nnoremap <silent> <leader>D :Dirvish<CR>

" Down is really the next line
nnoremap j gj
nnoremap k gk

" Yank to the end of the line
nnoremap Y y$

" Copy to system clipboard
vnoremap <C-c> "+y
" Paste from system clipboard with Ctrl + v
inoremap <C-v> <ESC>"+p
nnoremap <Leader>p "0p
vnoremap <Leader>p "0p
nnoremap <Leader>h viw"0p

" Insert mode mappings (beginning of line, end of line, and word movement)
" -- FIXME: interferes with ultisnips/ncm2/vim-lsp things
" move to front of line:
map <C-a> <ESC>^
imap <C-a> <ESC>I
" move to end of line:
map <C-e> <ESC>$
imap <expr> <C-e> pumvisible() ? ncm2_ultisnips#expand_or("\<Plug>(ultisnips_expand)", 'm') : "\<ESC>A"
inoremap <expr> <C-e> pumvisible() ? ncm2_ultisnips#expand_or("\<Plug>(ultisnips_expand)", 'm') : "\<ESC>A"

" move by word forward and back:
inoremap <M-f> <ESC><Space>Wi
inoremap <M-b> <Esc>Bi
inoremap <M-d> <ESC>cW

" Move to the end of yanked text after yank and paste
nnoremap p p`]
vnoremap y y`]
vnoremap p p`]

" " # clever-f
" nmap ; <Plug>(clever-f-repeat-forward)
" nmap , <Plug>(clever-f-repeat-back)

" # tagbar
nnoremap <F4> :TagbarToggle<CR>

" Filesearch plugin map for searching in whole folder
nnoremap <Leader>f :call Search()<CR>
nnoremap <Leader>F :call Search(1)<CR>

" Toggle buffer list
" nnoremap <C-p> :Files<CR>
" nnoremap <Leader>b :Buffers<CR>
" nnoremap <Leader>t :BTags<CR>
" nnoremap <Leader>m :History<CR>

" Indenting in visual mode
xnoremap <S-Tab> <gv
xnoremap <Tab> >gv

" Center highlighted search
nnoremap n nzz
nnoremap N Nzz

"Disable ex mode mapping
map Q <Nop>

" Jump to definition in vertical split
nnoremap <leader>] <C-W>v<C-]>

map <leader>ev :vnew! ~/.dotfiles/nvim/init.vim<CR>
map <leader>ek :vnew! ~/.dotfiles/kitty/kitty.conf<CR>
map <leader>eg :vnew! ~/.gitconfig<CR>
map <leader>et :vnew! ~/.dotfiles/tmux/tmux.conf.symlink<CR>
map <leader>ez :vnew! ~/.dotfiles/zsh/zshrc.symlink<CR>

" open scratch buffer
nnoremap <C-s> :call ScratchOpen()<CR>
nnoremap <leader>bs :call ScratchOpen()<CR>

nnoremap <silent><leader>' :call ToggleTerminal()<CR>

" vim-vertical-move replacement
" nnoremap <expr> <C-j> <SID>vjump(0)
" nnoremap <expr> <C-k> <SID>vjump(1)
" xnoremap <expr> <C-j> <SID>vjump(0)
" xnoremap <expr> <C-k> <SID>vjump(1)
" onoremap <expr> <C-j> <SID>vjump(0)
" onoremap <expr> <C-k> <SID>vjump(1)

" folding toggle
nnoremap <leader><space> za

" ## vim-commentary
nmap <leader>c :Commentary<CR>
vmap <leader>c :Commentary<CR>

" ## FZF
nnoremap <silent><leader>m <ESC>:FZF<CR>
nnoremap <silent><C-p> <ESC>:FZF<CR>
nnoremap <leader>a <ESC>:Rg<space>
nnoremap <silent><leader>A  <ESC>:exe('Rg '.expand('<cword>'))<CR>
" Backslash as shortcut to ag
nnoremap \ :Rg<SPACE>

" ## vim-plug
noremap <F5> :PlugUpdate<CR>
map <F5> :PlugUpdate<CR>
noremap <S-F5> :PlugClean!<CR>
map <S-F5> :PlugClean!<CR>

" ## vim-sneak
" nmap f <Plug>Sneak_f
" nmap F <Plug>Sneak_F
" xmap f <Plug>Sneak_f
" xmap F <Plug>Sneak_F
" omap f <Plug>Sneak_f
" omap F <Plug>Sneak_F

" nmap t <Plug>Sneak_t
" nmap T <Plug>Sneak_T
" xmap t <Plug>Sneak_t
" xmap T <Plug>Sneak_T
" omap t <Plug>Sneak_t
" omap T <Plug>Sneak_T

" ## vim-js-file-import
" nmap <C-i> <Plug>(JsFileImport)
" nmap <C-u> <Plug>(PromptJsFileImport)

" ## quick-scope
" nnoremap <expr> <silent> f Quick_scope_selective('f')
" nnoremap <expr> <silent> F Quick_scope_selective('F')
" nnoremap <expr> <silent> t Quick_scope_selective('t')
" nnoremap <expr> <silent> T Quick_scope_selective('T')
" vnoremap <expr> <silent> f Quick_scope_selective('f')
" vnoremap <expr> <silent> F Quick_scope_selective('F')
" vnoremap <expr> <silent> t Quick_scope_selective('t')
" vnoremap <expr> <silent> T Quick_scope_selective('T')

" ## Fugitive
nnoremap <leader>H :Gbrowse<CR>
vnoremap <leader>H :Gbrowse<CR>
nnoremap <leader>gb :Gblame<CR>

" ## Testing vim-test
nmap <silent> <leader>t :TestFile<CR>
nmap <silent> <leader>T :TestNearest<CR>
nmap <silent> <leader>l :TestLast<CR>
nnoremap <Leader>u :Jest <C-r>=escape(expand("%"), ' ') . ' ' . '--updateSnapshot'<CR><CR>
" nmap <silent> <leader>a :TestSuite<CR>
" nmap <silent> <leader>g :TestVisit<CR>
" ref: https://github.com/Dkendal/dot-files/blob/master/nvim/.config/nvim/init.vim

" ## Gist/Github
" Send visual selection to gist.github.com as a private, filetyped Gist
" Requires the gist command line too (brew install gist)
vnoremap <leader>G :Gist -po<CR>

" ## Surround
vmap [ S]
vmap ( S)
vmap { S}
vmap ' S'
vmap " S"
vmap ` S`

" ## vim-sandwich
" ref: https://github.com/machakann/vim-sandwich/wiki/Introduce-vim-surround-keymappings#textobjects
xmap is <Plug>(textobj-sandwich-query-i)
xmap as <Plug>(textobj-sandwich-query-a)
omap is <Plug>(textobj-sandwich-query-i)
omap as <Plug>(textobj-sandwich-query-a)
xmap iss <Plug>(textobj-sandwich-auto-i)
xmap ass <Plug>(textobj-sandwich-auto-a)
omap iss <Plug>(textobj-sandwich-auto-i)
omap ass <Plug>(textobj-sandwich-auto-a)
xmap im <Plug>(textobj-sandwich-literal-query-i)
xmap am <Plug>(textobj-sandwich-literal-query-a)
omap im <Plug>(textobj-sandwich-literal-query-i)
omap am <Plug>(textobj-sandwich-literal-query-a)
" in middle (of) {'_'  '.' ',' '/' '-')
xmap i_ im_
xmap a_ im_
omap i_ im_
omap a_ am_

" ## Splits with vim-tmux-navigator
let g:tmux_navigator_no_mappings = 1
let g:tmux_navigator_save_on_switch = 1
nnoremap <silent> <C-h> :TmuxNavigateLeft<CR>
nnoremap <silent> <C-j> :TmuxNavigateDown<CR>
nnoremap <silent> <C-k> :TmuxNavigateUp<CR>
nnoremap <silent> <C-l> :TmuxNavigateRight<CR>
nnoremap <silent> <C-\> :TmuxNavigatePrevious<CR>
" nnoremap <C-o> :vsp <c-d> " this was overwrting default behaviors
nnoremap <silent><leader>o :vnew<cr>:e<space><c-d>
nnoremap <C-t> :tabe <c-d>

if(has('nvim'))
  tnoremap <C-w>h <C-\><C-n><C-w><C-h>
  tnoremap <C-w>j <C-\><C-n><C-w><C-j>
  tnoremap <C-w>k <C-\><C-n><C-w><C-k>
  tnoremap <C-w>l <C-\><C-n><C-w><C-l>
endif

inoremap <C-w>h <ESC><C-w><C-h>
inoremap <C-w>j <ESC><C-w><C-j>
inoremap <C-w>k <ESC><C-w><C-k>
inoremap <C-w>l <ESC><C-w><C-l>

" ## Writing / quitting
nnoremap <silent> <leader>w :w<CR>
nnoremap <leader>q :q<CR>
" Sudo write (,W)
noremap <silent><leader>W :w !sudo tee %<CR>

" ## Vim process management
" background VIM
vnoremap <c-z> <ESC>zv`<ztgv

nnoremap / /\v
vnoremap / /\v

" clear incsearch term
nnoremap  <silent><ESC> :syntax sync fromstart<CR>:nohlsearch<CR>:redrawstatus!<CR><ESC>

" Start substitute on current word under the cursor
nnoremap ,s :%s///gc<Left><Left><Left>

" Start search on current word under the cursor
nnoremap ,/ /<CR>

" Start reverse search on current word under the cursor
nnoremap ,? ?<CR>

" Keep search matches in the middle of the window.
nnoremap <silent> n nzzzv
nnoremap <silent> N Nzzzv
vnoremap <silent> n nzzzv
vnoremap <silent> N Nzzzv

" Keep search matches jumping around
nnoremap g; g;zz
nnoremap g, g,zz

" Faster sort
vnoremap ,s :!sort<CR>

" ## Yank/Paste
" More logical Y (default was alias for yy)
nnoremap Y y$

" Don't yank to default register when changing something
nnoremap c "xc
xnoremap c "xc

" After block yank and paste, move cursor to the end of operated text and don't override register
vnoremap y y`]
vnoremap p "_dP`]
nnoremap p p`]

" Yank and paste from clipboard
nnoremap ,y "+y
vnoremap ,y "+y
nnoremap ,yy "+yy
nnoremap ,p "+p

" Don't copy the contents of an overwritten selection.
vnoremap p "_dP

" Fix the cw at the end of line bug default vim has special treatment (:help cw)
nmap cw ce
nmap dw de

" ## Convenience rebindings
noremap <leader>; :!
noremap <leader>: :<Up>

" remap q for recording to Q
nnoremap Q q
nnoremap q <Nop>

" switch between current and last buffer
nmap <leader>. <c-^>
nmap <leader><leader> <c-^>

" allow deleting selection without updating the clipboard (yank buffer)
vnoremap x "_x
vnoremap X "_X

" Easier to type, however, i hurt my muscle memory when on remote vim (disabled) for now
noremap H ^
noremap L $
vnoremap L g_

" make the tab key match bracket pairs
silent! unmap [%
silent! unmap ]%
map <Tab> %
noremap <Tab> %
nnoremap <Tab> %
vnoremap <Tab> %
" Better mark jumping (line + col)
nnoremap ' <nop>
" Remap VIM 0 to first non-blank character
map 0 ^

" ## Selections
" reselect pasted content:
nnoremap gV `[v`]
" select all text in the file
nnoremap <leader>v ggVG
" Easier linewise reselection of what you just pasted.
nnoremap <leader>V V`]

" ## Indentions
" Indent/dedent/autoindent what you just pasted.
nnoremap <lt>> V`]<
nnoremap ><lt> V`]>
nnoremap =- V`]=

" ## Misc (organize this please!)
" Insert newline below
nnoremap <CR><CR> o<ESC>

" push newline
nnoremap <S-CR>   mzO<ESC>j`z
nnoremap <C-CR>   mzo<ESC>k`z
" spawn newline
inoremap <S-CR>     <C-O>O
inoremap <C-CR>     <C-O>o
"
" gi already moves to 'last place you exited insert mode', so we'll map gI to
" something similar: move to last change
nnoremap gI `.

" Make D behave
nnoremap D d$

" Delete a line and not keep it in a register
nnoremap X Vx

" Redraw my screen
nnoremap U :syntax sync fromstart<CR>:redraw!<CR>

" Select (charwise) the contents of the current line, excluding indentation.
" Great for pasting Python lines into REPLs.
nnoremap vv ^vg_

" ## Join and Split Lines
" Keep the cursor in place while joining lines
nnoremap J mzJ`z
" Split line (sister to [J]oin lines above)
" The normal use of S is covered by cc, so don't worry about shadowing it.
nnoremap S i<CR><ESC>^mwgk:silent! s/\v +$//<CR>:noh<CR>`w

" ## splitjoin.vim
" let g:splitjoin_split_mapping = ''
" let g:splitjoin_join_mapping = ''
" nmap J :SplitjoinJoin<cr>
" nmap S :SplitjoinSplit<cr>
" nmap sS :SplitjoinSplit<cr>
" nmap sJ :SplitjoinJoin<cr>

" Insert mode movements
" Ctrl-e: Go to end of line
" inoremap <c-e> <ESC>A
" Ctrl-a: Go to begin of line
" inoremap <c-a> <ESC>I

cnoremap <C-a> <Home>
cnoremap <C-e> <End>

" get the syntax group under the cursor
nmap <F10> :echo "hi<" . synIDattr(synID(line("."),col("."),1),"name") . '> trans<' . synIDattr(synID(line("."),col("."),0),"name") . "> lo<" . synIDattr(synIDtrans(synID(line("."),col("."),1)),"name") . ">" . " FG:" . synIDattr(synIDtrans(synID(line("."),col("."),1)),"fg#")<CR>

" Recall command-line history.
cnoremap <C-p> <Up>
cnoremap <C-n> <Down>

" handy escapes; folks that i pair with uese these
inoremap <C-c> <ESC>
" inoremap jj <ESC>
" inoremap jk <ESC>
" inoremap kj <ESC>

" previous/next modification
" nmap ]c <Plug>GitGutterNextHunk
" nmap [c <Plug>GitGutterPrevHunk

" previous/next location
nnoremap <silent> ]l :call ExeWithFallback('lnext', 'lfirst')<CR>
nnoremap <silent> [l :call ExeWithFallback('lprev', 'lfirst')<CR>

" previous/next quickfix
nnoremap <silent> ]q :call ExeWithFallback('cnext', 'cfirst')<CR>
nnoremap <silent> [q :call ExeWithFallback('cprev', 'cfirst')<CR>

" }}}
" ░░░░░░░░░░░░░░░ Blink {{{

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
" ░░░░░░░░░░░░░░░ Highlights and Colors {{{
  hi clear SpellBad
  hi htmlArg cterm=italic gui=italic
  hi xmlAttrib cterm=italic gui=italic
  hi Type cterm=italic gui=italic
  hi Comment cterm=italic term=italic gui=italic
  hi LineNr guibg=#3C4C55 guifg=#937f6e gui=NONE
  hi CursorLineNr ctermbg=black ctermfg=223 cterm=NONE guibg=#333333 guifg=#db9c5e gui=bold
  hi CursorLine guibg=#333333
  hi qfLineNr ctermbg=black ctermfg=95 cterm=NONE guibg=black guifg=#875f5f gui=NONE
  hi QuickFixLine term=bold,underline cterm=bold,underline gui=bold,underline
  hi Search term=underline cterm=underline ctermfg=232 ctermbg=230 guibg=#db9c5e guifg=#343d46 gui=underline
  hi IncSearch ctermfg=red ctermbg=0 guibg=#FFFACD guifg=#000000 gui=bold

  " highlight conflicts
  match ErrorMsg '^\(<\|=\|>\)\{7\}\([^=].\+\)\?$'

  " hi SpellBad   term=underline cterm=underline gui=undercurl ctermfg=red guifg=#cc6666 guibg=NONE
  " hi SpellCap   term=underline cterm=underline gui=undercurl ctermbg=NONE ctermfg=33 guifg=#cc6666 guibg=NONE
  " hi SpellRare  term=underline cterm=underline gui=undercurl ctermbg=NONE ctermfg=217 guifg=#cc6666 guibg=NONE
  " hi SpellLocal term=underline cterm=underline gui=undercurl ctermbg=NONE ctermfg=72 guifg=#cc6666 guibg=NONE
  " Standardize spelling error highlighting across all color schemes.
  hi clear SpellBad
  hi clear SpellCap
  hi SpellBad gui=undercurl
  hi SpellCap gui=undercurl
  hi VertSplit guibg=NONE

  " " Markdown could be more fruit salady
  " hi link markdownH1 PreProc
  " hi link markdownH2 PreProc
  " hi link markdownLink Character
  " hi link markdownBold String
  " hi link markdownItalic Statement
  " hi link markdownCode Delimiter
  " hi link markdownCodeBlock Delimiter
  " hi link markdownListMarker Todo

  hi link Debug SpellBad
  hi link ErrorMsg SpellBad
  hi link Exception SpellBad

  hi ALEErrorSign gui=NONE guifg=#cc6666 guibg=NONE
  hi ALEWarningSign guifg=#f0c674 guibg=NONE
  hi ALEError guibg=#DF8C8C guifg=#333333
  hi ALEWarning guibg=#F2C38F guifg=#333333
  hi ALEVirtualTextWarning guibg=#F2C38F guifg=#333333
  hi ALEVirtualTextError guibg=#DF8C8C guifg=#333333

  hi CocErrorSign guibg=#DF8C8C guifg=#333333 gui=underline
  hi CocWarningSign guibg=#F2C38F guifg=#333333 gui=underline
  hi CocErrorHighlight guibg=#DF8C8C guifg=#333333
  " hi CocWarningHighlight guibg=#F2C38F guifg=#333333
  " hi CocErrorLine guibg=#DF8C8C guifg=#333333
  " hi CocWarningLine guibg=#F2C38F guifg=#333333
  hi ALEVirtualTextWarning guibg=#F2C38F guifg=#333333
  hi ALEVirtualTextError guibg=#DF8C8C guifg=#333333

  hi link LspErrorText ALEErrorSign
  hi link LspWarningText ALEWarningSign
  hi link LspError ALEError
  hi link LspWarning ALEWarning

  hi ModifiedColor ctermfg=196 ctermbg=NONE guifg=#cc6666 guibg=NONE term=bold cterm=bold gui=bold
  hi illuminatedWord cterm=underline gui=underline
  hi MatchParen cterm=bold gui=bold,italic guibg=#937f6e guifg=#222222

  hi Visual ctermbg=242 guifg=#3C4C55 guibg=#7FC1CA
  hi Normal ctermbg=none guibg=NONE guifg=#C5D4DD

  hi QuickScopePrimary guifg=#DF8C8C gui=underline ctermfg=155 cterm=underline
  hi QuickScopeSecondary guifg=#F2C38F gui=underline ctermfg=81 cterm=underline

  hi gitCommitOverflow term=NONE guibg=#cc6666 guifg=#333333 ctermbg=210
  hi DiffAdd guifg=#A8CE93
  hi DiffDelete guifg=#DF8C8C
  hi DiffAdded guifg=#A8CE93
  hi DiffRemoved guifg=#DF8C8C
  " hi ErrorMsg guifg=#DF8C8C
  " hi DiffChange guifg=#F2C38F
  " hi DiffText guifg=#F2C38F
" }}}

" vim:foldenable:foldmethod=marker:ft=vim
