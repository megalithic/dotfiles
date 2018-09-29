" ============================================================================xr=
"
"   ┌┬┐┌─┐┌─┐┌─┐┬  ┬┌┬┐┬ ┬┬┌─┐
"   │││├┤ │ ┬├─┤│  │ │ ├─┤││   :: DOTFILES > nvim/init.min.vim
"   ┴ ┴└─┘└─┘┴ ┴┴─┘┴ ┴ ┴ ┴┴└─┘
"   Brought to you by: Seth Messer / @megalithic
"
" =============================================================================

" ================ Plugins {{{

if empty(glob('~/.config/nvim/autoload/plug.vim'))
  silent !curl -fLo ~/.config/nvim/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  au VimEnter * PlugInstall --sync | source $MYVIMRC
endif
set runtimepath+=~/.config/nvim/autoload/plug.vim/

silent! if plug#begin('~/.config/nvim/plugged')

  Plug 'tweekmonster/startuptime.vim', { 'on': [ 'StartupTime' ] } " Show slow plugins

" ## UI/Interface
  Plug 'trevordmiller/nova-vim'
  Plug 'megalithic/golden-ratio' " vertical split layout manager
  Plug 'itchyny/lightline.vim'
  Plug 'maximbaz/lightline-ale'
  Plug 'ryanoasis/vim-devicons' " has to be last according to docs
  Plug 'Yggdroot/indentLine', { 'on': 'IndentLinesEnable' }
  Plug 'RRethy/vim-illuminate'

" ## Syntax
  Plug 'HerringtonDarkholme/yats.vim', { 'for': ['typescript', 'typescriptreact', 'typescript.tsx'] }
  Plug 'leafgarland/typescript-vim', { 'for': ['typescript', 'typescriptreact', 'typescript.tsx'] }
  Plug 'lilydjwg/colorizer'
  Plug 'tpope/vim-rails', { 'for': ['ruby', 'eruby', 'haml', 'slim'] }

  Plug 'ElmCast/elm-vim', { 'for': ['elm'] }
  Plug 'elixir-editors/vim-elixir', { 'for': ['elixir', 'eelixir'] }
  Plug 'mhinz/vim-mix-format'
  Plug 'mattreduce/vim-mix'

  Plug 'sheerun/vim-polyglot'

" ## Completion
  Plug 'ncm2/ncm2' | Plug 'roxma/nvim-yarp'
  Plug 'ncm2/ncm2-bufword'
  Plug 'ncm2/ncm2-tmux'
  Plug 'ncm2/ncm2-path'
  Plug 'ncm2/ncm2-html-subscope'
  Plug 'ncm2/ncm2-markdown-subscope'
  Plug 'ncm2/ncm2-cssomni'
  " Plug 'yuki-ycino/ncm2-dictionary'
  Plug 'filipekiss/ncm2-look.vim'
  Plug 'ncm2/ncm2-vim' | Plug 'Shougo/neco-vim'
  Plug 'ncm2/ncm2-syntax' | Plug 'Shougo/neco-syntax'
  Plug 'ncm2/ncm2-neoinclude' | Plug 'Shougo/neoinclude.vim'
  " Plug '~/code/plugins/ncm2-elm', { 'for': ['elm'], 'do': 'npm i -g elm-oracle' }
  Plug 'ncm2/ncm2-ultisnips' | Plug 'honza/vim-snippets' | Plug 'SirVer/ultisnips'
  Plug 'ncm2/ncm2-vim-lsp' | Plug 'prabirshrestha/vim-lsp', { 'do': 'gem install solargraph' } | Plug 'prabirshrestha/async.vim' " LanguageServer
  Plug 'othree/csscomplete.vim', { 'for': ['css', 'scss', 'sass'] } " css completion
  " Plug 'xolox/vim-lua-ftplugin', { 'for': ['lua'] } | Plug 'xolox/vim-misc'
  " Plug 'awetzel/elixir.nvim', { 'for': ['elixir', 'eelixir'], 'do': 'yes \| ./install.sh' }
  " Plug 'slashmili/alchemist.vim', { 'for': ['elixir', 'eelixir'] }
  " Plug 'mhartington/nvim-typescript', { 'for': ['typescript', 'typescriptreact', 'typescript.tsx'], 'do': './install.sh' }

" ## Project/Code Navigation
  Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
  Plug 'junegunn/fzf.vim'
  Plug 'christoomey/vim-tmux-navigator' " needed for tmux/hotkey integration with vim
  Plug 'christoomey/vim-tmux-runner' " needed for tmux/hotkey integration with vim
  Plug 'tmux-plugins/vim-tmux-focus-events'
  Plug 'unblevable/quick-scope' " highlights f/t type of motions, for quick horizontal movements
  " Plug 'justinmk/vim-sneak' " https://github.com/justinmk/vim-sneak / NOTE: need to see if you can pre-highlight possible letters
  Plug 'AndrewRadev/splitjoin.vim'
  Plug 'haya14busa/incsearch.vim'                             " Incremental search
  Plug 'haya14busa/incsearch-fuzzy.vim'                       " Fuzzy incremental search
  Plug 'osyo-manga/vim-anzu'                                  " Show search count
  Plug 'haya14busa/vim-asterisk'                              " Star * improvements
  " Plug 'jsfaint/gen_tags.vim'

" ## Utils
  Plug 'jordwalke/VimAutoMakeDirectory' " auto-makes the dir for you if it doesn't exist in the path
  Plug 'junegunn/rainbow_parentheses.vim' " nicely colors nested pairs of [], (), {}
  Plug 'docunext/closetag.vim' " will auto-close the opening tag as soon as you type </
  Plug 'tpope/vim-ragtag', { 'for': ['html', 'xml', 'erb', 'haml', 'javascript.jsx', 'typescript', 'typescriptreact', 'typescript.tsx', 'javascript'] } " a set of mappings for several langs: html, xml, erb, php, more
  " FIXME: currently, MatchTagAlways is breaking graphql queries in TS/TSX files.
  " Plug 'Valloric/MatchTagAlways', { 'for': ['haml', 'html', 'xml', 'erb', 'eruby', 'javascript.jsx'] } " highlights the opening/closing tags for the block you're in
  Plug 'jiangmiao/auto-pairs'
  Plug 'tpope/vim-endwise'
  Plug 'janko-m/vim-test', {'on': ['TestFile', 'TestLast', 'TestNearest', 'TestSuite', 'TestVisit'] } " tester for js and ruby
  " Plug 'ruanyl/coverage.vim', { 'for': ['typescript', 'typescriptreact', 'typescript.tsx', 'javascript', 'javascript.jsx', 'jsx', 'js'] }
  Plug 'tpope/vim-commentary' " (un)comment code
  Plug 'ConradIrwin/vim-bracketed-paste' " correctly paste in insert mode
  Plug 'sickill/vim-pasta' " context-aware pasting
  Plug 'zenbro/mirror.vim' " allows mirror'ed editing of files locally, to a specified ssh location via ~/.mirrors
  Plug 'keith/gist.vim', { 'do': 'chmod -HR 0600 ~/.netrc' }
  Plug 'thinca/vim-ref'
  Plug 'rhysd/devdocs.vim'
  " Plug 'Raimondi/delimitMate'
  Plug 'andymass/vim-matchup'
  Plug 'tpope/vim-surround'
  " Plug 'machakann/vim-sandwich'
  Plug 'tpope/vim-repeat'
  Plug 'tpope/vim-fugitive' | Plug 'tpope/vim-rhubarb' " required for some fugitive things
  Plug 'junegunn/gv.vim'
  Plug 'sodapopcan/vim-twiggy'
  " Plug 'christoomey/vim-conflicted'
  Plug 'rhysd/conflict-marker.vim'
  Plug 'tpope/vim-eunuch'
  " Plug 'dyng/ctrlsf.vim'
  Plug 'w0rp/ale'
  Plug 'metakirby5/codi.vim'

" ## Movements/Text Objects, et al
  Plug 'kana/vim-operator-user'
  " -- provide ai and ii for indent blocks
  " -- provide al and il for current line
  " -- provide a_ and i_ for underscores
  " -- provide a- and i-
  Plug 'kana/vim-textobj-user', { 'on': [ '<Plug>(textobj-user' ] }                 " https://github.com/kana/vim-textobj-user/wiki
  Plug 'kana/vim-textobj-entire', { 'on': [ '<Plug>(textobj-entire' ] }             " entire buffer text object (vae)
  Plug 'kana/vim-textobj-function', { 'on': [ '<Plug>(textobj-function' ] }         " function text object (vaf)
  Plug 'kana/vim-textobj-indent', { 'on': [ '<Plug>(textobj-indent' ] }             " for indent level (vai)
  Plug 'kana/vim-textobj-line', { 'on': [ '<Plug>(textobj-line' ] }                 " for current line (val)
  Plug 'nelstrom/vim-textobj-rubyblock', { 'on': [ '<Plug>(textobj-rubyblock' ] }   " ruby block text object (vir)
  Plug 'glts/vim-textobj-comment', { 'on': [ '<Plug>(textobj-comment' ] }           " comment text object (vac)
  Plug 'michaeljsmith/vim-indent-object'
  Plug 'machakann/vim-textobj-delimited', { 'on': [ '<Plug>(textobj-delimited' ] }  " - d/D   for underscore section (e.g. `did` on foo_b|ar_baz -> foo__baz)
  Plug 'gilligan/textobj-lastpaste', { 'on': [ '<Plug>(textobj-lastpaste' ] }       " - P     for last paste
  Plug 'mattn/vim-textobj-url', { 'on': [ '<Plug>(textobj-url' ] }                  " - u     for url
  Plug 'rhysd/vim-textobj-anyblock', { 'on': [ '<Plug>(textobj-anyblock' ] }        " - '', \"\", (), {}, [], <>
  Plug 'whatyouhide/vim-textobj-xmlattr', { 'on': [ '<Plug>(textobj-xmlattr' ] }    " - x     for xml
  Plug 'arthurxavierx/vim-caser'                                                    " https://github.com/arthurxavierx/vim-caser#usage
  Plug 'wellle/targets.vim'                                                         " improved targets line cin) next parens)
  " ^--- https://github.com/wellle/targets.vim/blob/master/cheatsheet.md

call plug#end()
endif

filetype plugin indent on

"}}}
" ================ General Config/Setup {{{

let g:mapleader = ","                                                           "Change leader to a comma

set background=dark                                                             "Set background to dark

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

let g:ruby_host_prog = $HOME."/.asdf/shims/neovim-ruby-host"
" let g:node_host_prog = $HOME."/.asdf/shims/neovim-node-host" " presently installed via yarn
let g:python_host_prog = '/usr/local/bin/python2.7'
let g:python3_host_prog = '/usr/local/bin/python3'

set title                                                                       "change the terminal's title
set number                                                                      "Line numbers are good
set relativenumber                                                              "Show numbers relative to current line
set signcolumn=yes
set history=500                                                                 "Store lots of :cmdline history
set showcmd                                                                     "Show incomplete cmds down the bottom
" set cmdheight=2
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
" set textwidth=79 " will auto wrap content when set regardless of nowrap being set
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
set updatetime=500                                                              "Cursor hold timeout
set synmaxcol=300                                                               "Use syntax highlighting only for 300 columns


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
" ================ Turn Off Swap Files {{{

set noswapfile
set nobackup
set nowb
set backupcopy=yes "HMR things - https://parceljs.org/hmr.html#safe-write

" }}}
" ================ Persistent Undo {{{

" Keep undo history across sessions, by storing in file.
silent !mkdir ~/.config/nvim/undo > /dev/null 2>&1
set undodir=~/.config/nvim/undo
set undofile

" }}}
" ================ Scrolling {{{

set scrolloff=8                                                                 "Start scrolling when we're 8 lines away from margins
set sidescrolloff=15
set sidescroll=5

" }}}
" ================ Indentation {{{

set shiftwidth=2
set softtabstop=2
set tabstop=2
set expandtab
set smartindent
set nofoldenable
" set foldmethod=syntax

" }}}
" ================ Completion {{{

set wildmode=list:full
set wildignore=*.o,*.obj,*~                                                     "stuff to ignore when tab completing
set wildignore+=*.git*
set wildignore+=*.meteor*
set wildignore+=*vim/backups*
set wildignore+=*sass-cache*
set wildignore+=*cache*
set wildignore+=*logs*
set wildignore+=*node_modules/**
set wildignore+=*DS_Store*
set wildignore+=*.gem
set wildignore+=log/**
set wildignore+=tmp/**
set wildignore+=*.png,*.jpg,*.gif

set shortmess+=c

" }}}
" ================ Autocommands {{{
augroup vimrc
  au!

  " identLine coloring things
  au! User indentLine doautocmd indentLine Syntax

  " automatically source vim configs
  au BufWritePost .vimrc,.vimrc.local,init.vim source %
  au BufWritePost .vimrc.local source %

  " save all files on focus lost, ignoring warnings about untitled buffers
  " autocmd FocusLost * silent! wa

  au BufWritePre * call StripTrailingWhitespaces()                     "Auto-remove trailing spaces
  au FocusGained,BufEnter * checktime                                  "Refresh file when vim gets focus

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
    autocmd! FileType fzf
    autocmd  FileType fzf set laststatus=0 | autocmd BufLeave,WinLeave <buffer> set laststatus=2
  endif

  " ----------------------------------------------------------------------------
  " ## JavaScript
  au FileType typescript,typescriptreact,typescript.tsx,javascript,javascript.jsx,sass,scss,scss.css RainbowParentheses
  " au FileType typescript,typescriptreact,typescript.tsx,javascript,javascript.jsx set ts=2 sts=2 sw=2
  au BufNewFile,BufRead .{babel,eslint,prettier,stylelint,jshint,jscs,postcss}*rc,\.tern-*,*.json,.tern-project set ft=json
  au BufNewFile,BufRead *.tsx,*.ts setl commentstring=//\ %s " doing this because for some reason it keeps defaulting the commentstring to `/* %s */`

  " ----------------------------------------------------------------------------
  " ## CSS/SCSS
  " make sure `complete` works as expected for CSS class names whithout
  " messing with motions (eg. '.foo-bar__baz') and we make sure all
  " delimiters (_,-,$,%,.) are treated as word separators outside insert mode
  au InsertEnter,BufLeave * setl iskeyword=@,48-57,192-255,\@,\$,%,-,_
  au InsertLeave,BufEnter * setl iskeyword=@,48-57,192-255
  " https://github.com/rstacruz/vimfiles/blob/master/plugin/plugins/css3-syntax.vim
  au FileType css,css.scss,sass,scss setl iskeyword+=-
  " au FileType scss set iskeyword+=-
  au FileType css,css.scss,sass,scss setl formatoptions+=croql

  " ----------------------------------------------------------------------------
  " ## Markdown
  au BufEnter,BufNewFile,BufRead,BufReadPost *.{md,mdwn,mkd,mkdn,mark*,txt,text} set nolazyredraw conceallevel=0
  au FileType markdown,text,html setlocal spell complete+=kspell
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
  au Filetype gitcommit setl nospell textwidth=72
  au BufNewFile,BufRead .git/index setlocal nolist
  au BufReadPost fugitive://* set bufhidden=delete
  au BufReadCmd *.git/index exe BufReadIndex()
  au BufEnter *.git/index silent normal gg0j
  au BufEnter *.git/COMMIT_EDITMSG exe BufEnterCommit()
  au Filetype gitcommit exe BufEnterCommit()

  autocmd! TermOpen * setlocal nonumber norelativenumber
  autocmd! TermOpen * if &buftype == 'terminal'
        \| set nonumber norelativenumber
        \| endif
augroup END

" # vim-lsp
augroup LspMappings
  au!
  " ruby/javascript (using nvim-typescript for typescript-specific mappings)
  au FileType eruby,ruby,javascript,javascript.jsx nnoremap <leader>h :LspHover<CR>
  au FileType eruby,ruby,javascript,javascript.jsx nnoremap <F2> :LspRename<CR>
  au FileType eruby,ruby,javascript,javascript.jsx nnoremap <F7> :LspDocumentDiagnostics<CR>
  au FileType eruby,ruby,javascript,javascript.jsx nnoremap <F8> :LspReferences<CR>
  au FileType eruby,ruby,javascript,javascript.jsx nnoremap <F9> :LspDefinition<CR>
  au FileType eruby,ruby,javascript,javascript.jsx nnoremap <F10> :LspDocumentSymbol<CR>

  nnoremap <leader>ld :LspDefinition<CR>
  nnoremap <leader>lf :LspDocumentFormat<CR>
  nnoremap <leader>lh :LspHover<CR>
  nnoremap <leader>lr :LspReferences<CR>
augroup END
augroup TSMappings
  au!
  " au FileType typescript,typescriptreact,typescript.tsx nnoremap <F2> :TSRename<CR>
  au FileType typescript,typescriptreact,typescript.tsx nnoremap <F2> :LspRename<CR>
  " au FileType typescript,typescriptreact,typescript.tsx nnoremap <F3> :TSImport<CR>
  " au FileType typescript,typescriptreact,typescript.tsx nnoremap <F6> :TSTypeDef<CR>
  au FileType typescript,typescriptreact,typescript.tsx nnoremap <F6> :LspDefinition<CR>
  " au FileType typescript,typescriptreact,typescript.tsx nnoremap <F7> :TSRefs<CR>
  au FileType typescript,typescriptreact,typescript.tsx nnoremap <F7> :LspReferences<CR>
  " au FileType typescript,typescriptreact,typescript.tsx nnoremap <F8> :TSDefPreview<CR>
  " au FileType typescript,typescriptreact,typescript.tsx nnoremap <F9> :TSDoc<CR>
  " au FileType typescript,typescriptreact,typescript.tsx nnoremap <F10> :TSType<CR>
augroup END

augroup elm
  au!
  au FileType elm nn <buffer> K :ElmShowDocs<CR>
  au FileType elm nn <buffer> <localleader>m :ElmMakeMain<CR>
  au FileType elm nn <buffer> <localleader>r :ElmRepl<CR>

  au FileType elm setlocal omnifunc=lsp#complete
augroup END

augroup elixir
  autocmd!
  autocmd FileType elixir nnoremap <buffer> <leader>h :call alchemist#exdoc()<CR>
  autocmd FileType elixir nnoremap <buffer> <leader>d :call alchemist#exdef()<CR>
  autocmd FileType elixir setlocal matchpairs=(:),{:},[:]

  " Enable html syntax highlighting in all .eex files
  " autocmd BufReadPost *.html.eex set syntax=html

  autocmd FileType elixir nnoremap <leader>d orequire IEx; IEx.pry<ESC>:w<CR>
  autocmd FileType elixir nnoremap <leader>i i\|>IO.inspect<ESC>:w<CR>

  " :Eix => open iex with current file compiled
  command! Iex :!iex %<cr>
  autocmd FileType elixir nnoremap <leader>e :!elixir %<CR>
  autocmd FileType elixir nnoremap <leader>ee :!iex -r % -S mix<CR>
augroup END

" Automatically close vim if only the quickfix window is open
" http://stackoverflow.com/a/7477056/3720597
augroup QuickFixClose
    autocmd!
    autocmd WinEnter * if winnr('$') == 1 &&
                \getbufvar(winbufnr(winnr()), "&buftype") == "quickfix"
                \| q
                \| endif
augroup END

augroup MakeQuickFixPrettier
    autocmd!
    autocmd BufRead * if &buftype == 'quickfix'
                \| setlocal colorcolumn=
                \| setlocal nolist
                \| endif
augroup END

" }}}
" ================ Functions {{{

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
  call ncm2#disable_for_buffer()
  au InsertEnter * call ncm2#disable_for_buffer()

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
function! SnipComplete()
  let line = getline('.')
  let start = col('.') - 1
  while start > 0 && line[start - 1] =~# '\k'
    let start -= 1
  endwhile
  let suggestions = []
  let snips =  UltiSnips#SnippetsInCurrentScope(0)
  for item in keys(snips)
    let entry = {'word': item, 'menu': snips[item]}
    call add(suggestions, entry)
  endfor
  if empty(suggestions)
    echohl Error | echon 'no match' | echohl None
  elseif len(suggestions) == 1
    let pos = getcurpos()
    if start == 0
      let str = trigger
    else
      let str = line[0:start - 1] . trigger
    endif
    call setline('.', str)
    let pos[2] = len(str) + 1
    call setpos('.', pos)
    call UltiSnips#ExpandSnippet()
  else
    call complete(start + 1, suggestions)
  endif
  return ''
endfunction

function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~ '\s'
endfunction

" }}}
" ================ Plugin Config/Settings {{{

" ## polyglot
  let g:polyglot_disabled = ['typescript', 'typescriptreact', 'typescript.tsx', 'graphql', 'jsx', 'sass', 'scss', 'css', 'markdown', 'elm', 'elixir', 'eelixir']

" ## devdocs.vim
  let g:devdocs_filetype_map = {
      \   'ruby': 'rails',
      \   'javascript.jsx': 'react',
      \   'typescript.tsx': 'react',
      \   'javascript.test': 'jest',
      \ }

" ## vim-matchup
  let g:matchup_matchparen_status_offscreen = 0 " prevents statusline from disappearing

" ## codi
  let g:codi#rightalign=0

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
        \       ['linter_checking', 'linter_warnings', 'linter_errors', 'linter_ok'],
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

  let g:lightline#ale#indicator_ok = "✔"
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
          \ '[⦿]' : '')
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

" ## golden-ratio
  let g:golden_ratio_exclude_nonmodifiable = 1
  let g:golden_ratio_wrap_ignored = 0
  let g:golden_ratio_ignore_horizontal_splits = 1

" ## vim-sneak
  let g:sneak#label = 1
  let g:sneak#use_ic_scs = 1
  let g:sneak#absolute_dir = 1

" ## quick-scope
  let g:qs_enable = 0

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
  " let g:lexima_enable_endwise_rules = 1

" # indentLine
  let g:indentLine_color_term = 239
  let g:indentLine_color_gui = '#616161'

" ## ALE
  let g:ale_enabled = 1
  let g:ale_lint_delay = 1000
  let g:ale_sign_column_always = 1
  let g:ale_echo_msg_format = '[%linter%] %s'
  let g:ale_linter_aliases = {'tsx': ['ts', 'typescript'], 'typescriptreact': ['ts', 'typescript']}
  let g:ale_linters = {
        \   'javascript': ['prettier', 'eslint', 'prettier_eslint'],
        \   'javascript.jsx': ['prettier', 'eslint', 'prettier_eslint'],
        \   'typescript': ['prettier', 'eslint', 'prettier_eslint', 'tsserver', 'tslint', 'typecheck'],
        \   'typescriptreact': ['prettier', 'eslint', 'prettier_eslint', 'tsserver', 'tslint', 'typecheck'],
        \   'typescript.tsx': ['prettier', 'eslint', 'prettier_eslint', 'tsserver', 'tslint', 'typecheck'],
        \   'css': ['prettier'],
        \   'scss': ['prettier'],
        \   'json': ['prettier'],
        \   'python': ['pyls'],
        \   'ruby': [],
        \   'elixir': ['mix', 'credo', 'dogma'],
        \ }                                                                       "Lint js with eslint
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
        \ }                                                                       "Fix eslint errors
  let g:ale_sign_error = '✖'                                                      "Lint error sign ⤫ ✖⨉
  let g:ale_sign_warning = '⬥'                                                    "Lint warning sign ⬥⚠
  let g:ale_javascript_eslint_use_local_config = 1
  let g:ale_javascript_prettier_use_local_config = 1
  let g:ale_javascript_prettier_eslint_use_local_config = 1
  let g:ale_lint_on_text_changed = 'always'
  let g:ale_lint_on_enter = 1
  let g:ale_fix_on_save = 1
  let g:ale_lint_on_save = 1

" ## vim-jsx
  let g:jsx_ext_required = 0
  let g:jsx_pragma_required = 0
  let g:javascript_plugin_jsdoc = 1                                               "Enable syntax highlighting for js doc blocks

" ## vim-markdown
  let g:vim_markdown_frontmatter = 1
  let g:vim_markdown_toc_autofit = 1
  let g:vim_markdown_new_list_item_indent = 2
  let g:vim_markdown_conceal = 0
  let g:vim_markdown_folding_disabled = 1
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

" ## nvim-typescript
  let g:nvim_typescript#completion_mark=''
  let g:nvim_typescript#default_mappings=0
  let g:nvim_typescript#type_info_on_hold=0
  let g:nvim_typescript#max_completion_detail=50
  let g:nvim_typescript#javascript_support=1
  let g:nvim_typescript#signature_complete=0
  let g:nvim_typescript#diagnosticsEnable=0
  let $NVIM_NODE_LOG_FILE='~/.config/nvim/nvim-node.log'
  let $NVIM_NODE_LOG_LEVEL='warn'
  let g:nvim_typescript#kind_symbols = {
      \ 'keyword': 'keyword',
      \ 'class': '',
      \ 'interface': '',
      \ 'script': 'script',
      \ 'module': '',
      \ 'local class': 'local class',
      \ 'type': '',
      \ 'enum': '',
      \ 'enum member': '',
      \ 'alias': '',
      \ 'type parameter': 'type param',
      \ 'primitive type': 'primitive type',
      \ 'var': '',
      \ 'local var': '',
      \ 'property': '',
      \ 'let': '',
      \ 'const': '',
      \ 'label': 'label',
      \ 'parameter': 'param',
      \ 'index': 'index',
      \ 'function': '',
      \ 'local function': 'local function',
      \ 'method': '',
      \ 'getter': '',
      \ 'setter': '',
      \ 'call': 'call',
      \ 'constructor': '',
      \}

" ## elm.nvim
  " let g:elm_jump_to_error = 0
  let g:elm_make_output_file = "elm.js"
  let g:elm_make_show_warnings = 1
  let g:elm_syntastic_show_warnings = 1
  " let g:elm_browser_command = ""
  let g:elm_detailed_complete = 1
  let g:elm_format_autosave = 1
  let g:elm_format_fail_silently = 0
  let g:elm_setup_keybindings = 1

" ## elixir.nvim
  " let g:elixir_autobuild = 1
  " let g:elixir_showerror = 1
  let g:elixir_maxpreviews = 20
  let g:elixir_docpreview = 1

" ## alchemist.vim
  let g:alchemist_tag_disable       = 1 "Use Universal ctags instead
  let g:alchemist_iex_term_size     = 10
  let g:alchemist_tag_map           = '<C-]>'
  let g:alchemist_tag_stack_map     = '<C-T>'

" ## colorizer
  let g:colorizer_auto_filetype='css,scss'
  let g:colorizer_colornames = 1

" ## rainbow_parentheses.vim
  let g:rainbow#max_level = 10
  let g:rainbow#pairs = [['(', ')'], ['[', ']'], ['{', '}']]

" ## vim-surround
  let g:surround_indent = 0
  " let g:surround_no_insert_mappings = 1

" ## vim-sandwich
  runtime macros/sandwich/keymap/surround.vim " loads vim-surround keymaps

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

  let g:fzf_colors = {
        \ 'fg':      ['fg', 'Normal'],
        \ 'bg':      ['bg', 'Normal'],
        \ 'hl':      ['fg', 'SpellBad'],
        \ 'fg+':     ['fg', 'CursorLine', 'CursorColumn', 'Normal'],
        \ 'bg+':     ['bg', 'CursorLine', 'CursorColumn'],
        \ 'hl+':     ['fg', 'CursorLineNr'],
        \ 'info':    ['fg', 'PreProc'],
        \ 'border':  ['fg', 'Ignore'],
        \ 'prompt':  ['fg', 'Conditional'],
        \ 'pointer': ['fg', 'Exception'],
        \ 'marker':  ['fg', 'Keyword'],
        \ 'spinner': ['fg', 'Label'],
        \ 'header':  ['fg', 'Comment']
        \ }

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
          \   'rg --column --line-number --no-heading --color=always --fixed-strings --ignore-case --hidden --follow --glob "!{.git,node_modules}/*" '.shellescape(<q-args>).'| tr -d "\017"', 1,
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

" " ## gen_tags
"   let g:gen_tags#use_cache_dir  = 0
"   let g:gen_tags#ctags_auto_gen = 1
"   let g:gen_tags#gtags_auto_gen = 1

" ## ultisnips
  let g:UltiSnipsExpandTrigger = "<c-e>"
  let g:UltiSnipsExpandTrigger = "<Plug>(ultisnips_expand)"
  let g:UltiSnipsJumpForwardTrigger	= "<tab>"
  let g:UltiSnipsJumpBackwardTrigger	= "<s-tab>"
  let g:UltiSnipsRemoveSelectModeMappings = 0
  let g:UltiSnipsSnippetDirectories=['UltiSnips']

" ## async/vim-lsp
  let g:lsp_auto_enable = 1
  let g:lsp_signs_enabled = 0             " enable diagnostic signs / we use ALE for now
  let g:lsp_diagnostics_echo_cursor = 0   " enable echo under cursor when in normal mode
  let g:lsp_signs_error = {'text': '⤫'}
  let g:lsp_signs_warning = {'text': '~'}
  let g:lsp_signs_hint = {'text': '?'}
  let g:lsp_signs_information = {'text': '!!'}
  let g:lsp_log_verbose = 0
  let g:lsp_log_file = expand('~/.config/nvim/vim-lsp.log')
  if executable('typescript-language-server')
    au User lsp_setup call lsp#register_server({
          \ 'name': 'typescript',
          \ 'cmd': {server_info->[&shell, &shellcmdflag, 'typescript-language-server --stdio']},
          \ 'root_uri':{server_info->lsp#utils#path_to_uri(lsp#utils#find_nearest_parent_file_directory(lsp#utils#get_buffer_path(), 'tsconfig.json'))},
          \ 'whitelist': ['typescript', 'typescriptreact', 'typescript.tsx'],
          \ })
  endif
  if executable('javascript-typescript-langserver')
    au User lsp_setup call lsp#register_server({
          \ 'name': 'javascript',
          \ 'cmd': {server_info->[&shell, &shellcmdflag, 'javascript-typescript-stdio']},
          \ 'whitelist': ['javascript', 'javascript.jsx'],
          \ })
  endif
  if executable('css-languageserver')
    au User lsp_setup call lsp#register_server({
          \ 'name': 'css',
          \ 'cmd': {server_info->[&shell, &shellcmdflag, 'css-languageserver --stdio']},
          \ 'whitelist': ['css', 'less', 'sass', 'scss'],
          \ })
  endif
  if executable('solargraph')
    au User lsp_setup call lsp#register_server({
        \ 'name': 'solargraph',
        \ 'cmd': {server_info->[&shell, &shellcmdflag, 'solargraph stdio']},
        \ 'initialization_options': {"diagnostics": "true"},
        \ 'whitelist': ['ruby', 'eruby'],
        \ })
  endif
  if executable($HOME.'/.elixir-ls/language_server.sh')
    au User lsp_setup call lsp#register_server({
          \ 'name': 'elixir',
          \ 'cmd': {server_info->[&shell, &shellcmdflag, '~/.dotfiles/elixir/elixir-ls.symlink/language_server.sh']},
          \ 'whitelist': ['elixir', 'eelixir'],
          \ 'workspace_config': {'elixirLS': { 'dialyzerEnabled': v:true }},
          \ })
  endif

" ## ncm2
  " NOTE: source changes must happen before the source is loaded
  let g:ncm2_ultisnips#source = {'priority': 10, 'mark': ''}
  let g:ncm2_nvim_typescript#source = {'priority': 9, 'mark': ''}
  let g:ncm2_alchemist#source = {'priority': 9, 'mark': "\ue62d"} " unicode for the elixir logo for nerdfonts
  " let g:ncm2_elm#source = {'priority': 9, 'mark': "\ue62c"} " unicode for the elixir logo for nerdfonts
  " let g:ncm2_tags#source = {'priority': 7, 'mark': "\uf9fa"}
  " let g:ncm2_tags#source = {'priority': 7, 'mark': "\uf9fa"}
  " let g:ncm2_tag#source = {'priority': 7, 'mark': "\uf9fa"}
  let g:ncm2_dictionary#source = {'priority': 2, 'popup_limit': 5}
  let g:ncm2_dict#source = {'priority': 2, 'popup_limit': 5}
  let g:ncm2_look#source = {'priority': 2, 'popup_limit': 5}
  call ncm2#override_source('ncm2_vim_lsp_solargraph', { 'priority': 9, 'mark': "\ue23e"})
  call ncm2#override_source('ncm2_vim_lsp_typescript', { 'priority': 9, 'mark': "\ue628"})
  call ncm2#override_source('ncm2_vim_lsp_javascript', { 'priority': 9, 'mark': "\ue74e"})
  call ncm2#override_source('ncm2_vim_lsp_elixir', { 'priority': 9, 'mark': "\ue62d"})

  " " == elm support
  " au User Ncm2Plugin call ncm2#register_source({
  "       \ 'name' : 'elm',
  "       \ 'priority': 9,
  "       \ 'subscope_enable': 1,
  "       \ 'scope': ['elm'],
  "       \ 'mark': "\ue62c",
  "       \ 'word_pattern': '[\w\-]+',
  "       \ 'complete_pattern': ':\s*',
  "       \ 'on_complete': ['ncm2#on_complete#omni', 'elm#Complete'],
  "       \ })

  au InsertEnter * call ncm2#enable_for_buffer() " or on BufEnter
  set completeopt=noinsert,menuone,noselect
  set shortmess+=c
  au TextChangedI * call ncm2#auto_trigger()
  let g:ncm2#complete_length = 2
  let g:ncm2#matcher = {
                  \ 'name': 'combine',
                  \ 'matchers': ['substrfuzzy', 'abbrfuzzy']
                  \ }
  let g:ncm2#sorter = 'abbrfuzzy'
  let g:ncm2#popup_limit = 25
  let $NVIM_PYTHON_LOG_FILE=expand('~/.config/nvim/nvim-python.log')
  let $NVIM_PYTHON_LOG_LEVEL="DEBUG"

" }}}
" ================ Custom Mappings {{{

" - ncm2 + ultisnips
inoremap <expr> <Tab> pumvisible() ? "\<C-n>" : "\<Tab>"
inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"
inoremap <expr> <CR> pumvisible() ? "\<C-y>" : "\<CR>"
inoremap <c-c> <ESC>
inoremap <silent> <expr> <CR> ((pumvisible() && empty(v:completed_item)) ?  "\<c-y>\<cr>" : (!empty(v:completed_item) ? ncm2_ultisnips#expand_or("", 'n') : "\<CR>\<C-R>=EndwiseDiscretionary()\<CR>" ))
imap <silent> <expr> <c-e> ncm2_ultisnips#expand_or("\<Plug>(ultisnips_expand)", 'm')
smap <silent> <expr> <c-e> ncm2_ultisnips#expand_or("\<Plug>(ultisnips_expand)", 'm')
inoremap <silent> <expr> <c-e> ncm2_ultisnips#expand_or("\<Plug>(ultisnips_expand)", 'm')
"
" Down is really the next line
nnoremap j gj
nnoremap k gk

" Yank to the end of the line
nnoremap Y y$

" Copy to system clipboard
vnoremap <C-c> "+y
" Paste from system clipboard with Ctrl + v
inoremap <C-v> <Esc>"+p
nnoremap <Leader>p "0p
vnoremap <Leader>p "0p
nnoremap <Leader>h viw"0p

" Move to the end of yanked text after yank and paste
nnoremap p p`]
vnoremap y y`]
vnoremap p p`]

" tagbar
" nnoremap <f4> :TagbarToggle<CR>

" Filesearch plugin map for searching in whole folder
nnoremap <Leader>f :call Search()<CR>
nnoremap <Leader>F :call Search(1)<CR>

" Toggle buffer list
" nnoremap <C-p> :Files<CR>
" nnoremap <Leader>b :Buffers<CR>
" nnoremap <Leader>t :BTags<CR>
" nnoremap <Leader>m :History<CR>

" Indenting in visual mode
xnoremap <s-tab> <gv
xnoremap <tab> >gv

" Center highlighted search
nnoremap n nzz
nnoremap N Nzz

"Disable ex mode mapping
map Q <Nop>

" Jump to definition in vertical split
nnoremap <Leader>] <C-W>v<C-]>

map <leader>ev :vnew! ~/.dotfiles/nvim/init.vim<CR>
map <leader>ek :vnew! ~/.dotfiles/kitty/kitty.conf<CR>
map <leader>eg :vnew! ~/.gitconfig<CR>
map <leader>et :vnew! ~/.dotfiles/tmux/tmux.conf.symlink<CR>
map <leader>ez :vnew! ~/.dotfiles/zsh/zshrc.symlink<CR>

" open scratch buffer
nnoremap <C-s> :call ScratchOpen()<CR>

" browse devdocs
nnoremap <leader>d :DevDocs
nnoremap <leader>dd :DevDocsAll
nmap K <Plug>(devdocs-under-cursor)

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
nnoremap <silent> <leader>m <esc>:FZF<CR>
nnoremap <leader>a <esc>:Rg<space>
nnoremap <silent> <leader>A  <esc>:exe('Rg '.expand('<cword>'))<CR>
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
nnoremap <C-o> :vsp <c-d>
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
vnoremap <c-z> <esc>zv`<ztgv

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
noremap  <Leader>; :!
noremap  <Leader>: :<Up>

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
map <tab> %
noremap <tab> %
nnoremap <tab> %
vnoremap <tab> %
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
nnoremap <S-CR>   mzO<Esc>j`z
nnoremap <C-CR>   mzo<Esc>k`z
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
nnoremap S i<CR><esc>^mwgk:silent! s/\v +$//<CR>:noh<CR>`w

" ## splitjoin.vim
" let g:splitjoin_split_mapping = ''
" let g:splitjoin_join_mapping = ''
" nmap J :SplitjoinJoin<cr>
" nmap S :SplitjoinSplit<cr>
" nmap sS :SplitjoinSplit<cr>
" nmap sJ :SplitjoinJoin<cr>

" Insert mode movements
" Ctrl-e: Go to end of line
" inoremap <c-e> <esc>A
" Ctrl-a: Go to begin of line
" inoremap <c-a> <esc>I

cnoremap <C-a> <Home>
cnoremap <C-e> <End>

map <leader>hi :echo "hi<" . synIDattr(synID(line("."),col("."),1),"name") . '> trans<' . synIDattr(synID(line("."),col("."),0),"name") . "> lo<" . synIDattr(synIDtrans(synID(line("."),col("."),1)),"name") . ">" . " FG:" . synIDattr(synIDtrans(synID(line("."),col("."),1)),"fg#")<CR>


" }}}
" ================ Highlights and Colors {{{
  hi clear SpellBad
  hi htmlArg cterm=italic gui=italic
  hi xmlAttrib cterm=italic gui=italic
  hi Type cterm=italic gui=italic
  hi Comment cterm=italic term=italic gui=italic
  hi LineNr guibg=#3C4C55 guifg=#937f6e gui=NONE
  hi CursorLineNr ctermbg=black ctermfg=223 cterm=NONE guibg=#333333 guifg=#db9c5e gui=bold
  hi CursorLine guibg=#333333
  hi qfLineNr ctermbg=black ctermfg=95 cterm=NONE guibg=black guifg=#875f5f gui=NONE
  hi QuickFixLine term=bold,underline cterm=bold,underline gui=bold,underline guifg=#cc6666 guibg=red
  hi Search term=underline cterm=underline ctermfg=232 ctermbg=230 guibg=#db9c5e guifg=#343d46 gui=underline
  hi IncSearch ctermfg=red ctermbg=0 guibg=#FFFACD guifg=#000000 gui=bold

  " highlight conflicts
  match ErrorMsg '^\(<\|=\|>\)\{7\}\([^=].\+\)\?$'

  hi SpellBad   term=underline cterm=underline gui=undercurl ctermfg=red guifg=#cc6666 guibg=NONE
  hi SpellCap   term=underline cterm=underline gui=undercurl ctermbg=NONE ctermfg=33 guifg=#cc6666 guibg=NONE
  hi SpellRare  term=underline cterm=underline gui=undercurl ctermbg=NONE ctermfg=217 guifg=#cc6666 guibg=NONE
  hi SpellLocal term=underline cterm=underline gui=undercurl ctermbg=NONE ctermfg=72 guifg=#cc6666 guibg=NONE

  " Markdown could be more fruit salady
  hi link markdownH1 PreProc
  hi link markdownH2 PreProc
  hi link markdownLink Character
  hi link markdownBold String
  hi link markdownItalic Statement
  hi link markdownCode Delimiter
  hi link markdownCodeBlock Delimiter
  hi link markdownListMarker Todo

  hi ALEErrorSign term=NONE cterm=NONE gui=NONE ctermfg=red guifg=#cc6666 guibg=NONE
  hi ALEWarningSign ctermfg=11 ctermbg=15 guifg=#f0c674 guibg=NONE

  hi link ALEError SpellBad
  hi link ALEWarning SpellBad
  hi link Debug SpellBad
  hi link ErrorMsg SpellBad
  hi link Exception SpellBad

  hi link LspErrorText ALEErrorSign
  hi link LspWarningText ALEWarningSign
  hi link LspError ALEError
  hi link LspWarning ALEWarning

  hi ModifiedColor ctermfg=196 ctermbg=NONE guifg=#cc6666 guibg=NONE term=bold cterm=bold gui=bold
  hi illuminatedWord cterm=underline gui=underline
  hi MatchParen cterm=bold gui=bold,italic guibg=#937f6e guifg=#222222

  hi Visual ctermbg=242 guifg=#3C4C55 guibg=#7FC1CA
  hi Normal ctermbg=none guibg=NONE guifg=#C5D4DD
  hi gitCommitOverflow term=NONE guibg=#cc6666 guifg=#333333 ctermbg=210
  hi ALEError term=NONE guibg=#cc6666 guifg=#C5D4DD ctermbg=167

  " ## -----------------------------------------------------------------------
  " COLLECTION OF ALL THE COLORS USED IN SPRING-NIGHT:
  " ## -----------------------------------------------------------------------
  " hi Boolean term=NONE guifg=#fd8489 ctermfg=210
  " hi Character term=NONE guifg=#a9dd9d ctermfg=150
  " hi ColorColumn term=NONE guibg=#536273 ctermbg=238
  " exe 'hi' 'Comment' 'term=NONE' 'guifg=#8d9eb2' 'ctermfg=103' g:spring_night_italic_comments ? s:italic_attr : ''
  " exe 'hi' 'Conceal' 'term=NONE' 'guifg=#fb8965' 'ctermfg=209' 'guibg='.s:bg_gui 'ctermbg=233'
  " hi Conditional term=NONE guifg=#a8d2eb ctermfg=153
  " hi Constant term=NONE guifg=#fd8489 ctermfg=210
  " exe 'hi' 'Cursor' 'term=NONE' 'guifg='.s:bg_gui 'ctermfg=233' 'guibg=#fffeeb' 'ctermbg='.s:fg_cterm
  " hi CursorColumn term=NONE guibg=#3a4b5c ctermbg=235
  " hi CursorLine term=NONE guibg=#3a4b5c ctermbg=235 gui=NONE cterm=NONE
  " hi CursorLineNr term=NONE guifg=#e7d5ff ctermfg=189 guibg=#536273 ctermbg=238
  " hi Define term=NONE guifg=#f0aa8a ctermfg=216
  " hi Directory term=NONE guifg=#a9dd9d ctermfg=150
  " hi EndOfBuffer term=NONE guifg=#536273 ctermfg=238
  " exe 'hi' 'Error' 'term=NONE' 'guifg=#fd8489' 'ctermfg=210' 'guibg=#3a4b5c' 'ctermbg=235' s:bold_attr
  " exe 'hi' 'ErrorMsg' 'term=NONE' 'guifg=#fd8489' 'ctermfg=210' 'guibg='.s:bg_gui 'ctermbg=233' s:bold_attr
  " hi Float term=NONE guifg=#fd8489 ctermfg=210
  " hi FoldColumn term=NONE guifg=#e7d5ff ctermfg=189 guibg=#3a4b5c ctermbg=235
  " hi Folded term=NONE guifg=#e7d5ff ctermfg=189 guibg=#646f7c ctermbg=60
  " hi Function term=NONE guifg=#f0aa8a ctermfg=216
  " exe 'hi' 'Identifier' 'term=NONE' 'guifg=#fedf81' 'ctermfg=222' s:italic_attr
  " hi IncSearch term=NONE guifg=NONE ctermfg=NONE guibg=#a9667a ctermbg=132 gui=underline cterm=underline
  " exe 'hi' 'Keyword' 'term=NONE' 'guifg=#f0eaaa' 'ctermfg=229' s:bold_attr
  " hi Label term=NONE guifg=#a8d2eb ctermfg=153
  " hi LineNr term=NONE guifg=#788898 ctermfg=102 guibg=#3a4b5c ctermbg=235
  " exe 'hi' 'MatchParen' 'term=NONE' 'guifg='.s:bg_gui 'ctermfg=233' 'guibg=#a9667a' 'ctermbg=132' 'gui=underline cterm=underline'
  " hi ModeMsg term=NONE guifg=#fedf81 ctermfg=222
  " hi MoreMsg term=NONE guifg=#a9dd9d ctermfg=150
  " hi NonText term=NONE guifg=#646f7c ctermfg=60
  " exe 'hi' 'Normal' 'term=NONE' 'guifg=#fffeeb' 'ctermfg='.s:fg_cterm 'guibg='.s:bg_gui 'ctermbg=233'
  " hi Number term=NONE guifg=#fd8489 ctermfg=210
  " hi Operater term=NONE guifg=#f0aa8a ctermfg=216
  " hi Pmenu term=NONE guifg=#e7d5ff ctermfg=189 guibg=#3a4b5c ctermbg=235
  " hi PmenuSbar term=NONE guifg=#fedf81 ctermfg=222 guibg=#536273 ctermbg=238
  " hi PmenuSel term=NONE guifg=#fedf81 ctermfg=222 guibg=#536273 ctermbg=238
  " hi PmenuThumb term=NONE guifg=#fedf81 ctermfg=222 guibg=#8d9eb2 ctermbg=103
  " hi PreProc term=NONE guifg=#f0aa8a ctermfg=216
  " hi Question term=NONE guifg=#a8d2eb ctermfg=153
  " hi Search term=NONE guifg=NONE ctermfg=NONE guibg=#70495d ctermbg=95 gui=underline cterm=underline
  " hi SignColumn term=NONE guibg=#3a4b5c ctermbg=235
  " exe 'hi' 'Special' 'term=NONE' 'guifg=#f0eaaa' 'ctermfg=229' s:bold_attr
  " hi SpecialKey term=NONE guifg=#607080 ctermfg=60
  " exe 'hi' 'SpellBad' 'term=NONE' 'guifg=#fd8489' 'ctermfg=210' 'guisp=#fd8489' s:undercurl_attr
  " exe 'hi' 'SpellCap' 'term=NONE' 'guifg=#e7d5ff' 'ctermfg=189' 'guisp=#e7d5ff' s:undercurl_attr
  " exe 'hi' 'SpellLocal' 'term=NONE' 'guifg=#fd8489' 'ctermfg=210' 'guisp=#fd8489' s:undercurl_attr
  " exe 'hi' 'SpellRare' 'term=NONE' 'guifg=#f0eaaa' 'ctermfg=229' 'guisp=#f0eaaa' s:undercurl_attr
  " hi Statement term=NONE guifg=#a8d2eb ctermfg=153
  " exe 'hi' 'StatusLine' 'term=NONE' 'guifg=#fffeeb' 'ctermfg='.s:fg_cterm 'guibg=#536273' 'ctermbg=238' s:bold_attr
  " hi StatusLineNC term=NONE guifg=#8d9eb2 ctermfg=103 guibg=#3a4b5c ctermbg=235 gui=NONE cterm=NONE
  " exe 'hi' 'StatusLineTerm' 'term=NONE' 'guifg=#fffeeb' 'ctermfg='.s:fg_cterm 'guibg=#536273' 'ctermbg=238' s:bold_attr
  " hi StatusLineTermNC term=NONE guifg=#8d9eb2 ctermfg=103 guibg=#3a4b5c ctermbg=235 gui=NONE cterm=NONE
  " exe 'hi' 'StorageClass' 'term=NONE' 'guifg=#fedf81' 'ctermfg=222' s:italic_attr
  " hi String term=NONE guifg=#a9dd9d ctermfg=150
  " hi TabLine term=NONE guifg=#8d9eb2 ctermfg=103 guibg=#536273 ctermbg=238
  " hi TabLineFill term=NONE guifg=#3a4b5c ctermfg=235
  " exe 'hi' 'TabLineSel' 'term=NONE' 'guifg=#fedf81' 'ctermfg=222' 'guibg='.s:bg_gui 'ctermbg=233' s:bold_attr
  " hi Tag term=NONE guifg=#f0aa8a ctermfg=216
  " exe 'hi' 'Title' 'term=NONE' 'guifg=#fedf81' 'ctermfg=222' s:bold_attr
  " exe 'hi' 'Todo' 'term=NONE' 'guifg='.s:bg_gui 'ctermfg=233' 'guibg=#fd8489' 'ctermbg=210' s:bold_attr
  " exe 'hi' 'ToolbarButton' 'term=NONE' 'guifg=#fedf81' 'ctermfg=222' 'guibg='.s:bg_gui 'ctermbg=233' s:bold_attr
  " hi ToolbarLine term=NONE guifg=#8d9eb2 ctermfg=103 guibg=#536273 ctermbg=238
  " hi Type term=NONE guifg=#fedf81 ctermfg=222
  " hi Underlined term=NONE guifg=#a8d2eb ctermfg=153 gui=underline cterm=underline
  " exe 'hi' 'VertSplit' 'term=NONE' 'guifg=#3a4b5c' 'ctermfg=235' 'guibg='.s:bg_gui 'ctermbg=233'
  " hi Visual term=NONE guibg=#70495d ctermbg=95
  " hi WarningMsg term=NONE guifg=#fb8965 ctermfg=209 guibg=#3a4b5c ctermbg=235
  " hi WildMenu term=NONE guibg=#fedf81 ctermbg=222
  " hi cmakeArguments term=NONE guifg=#f0eaaa ctermfg=229
  " hi cmakeOperators term=NONE guifg=#fd8489 ctermfg=210
  " exe 'hi' 'DiffAdd' 'term=NONE' 'guibg=#5f8770' 'ctermbg=65' s:bold_attr
  " exe 'hi' 'DiffChange' 'term=NONE' 'guibg=#685800' 'ctermbg=58' s:bold_attr
  " exe 'hi' 'DiffDelete' 'term=NONE' 'guifg=#fffeeb' 'ctermfg='.s:fg_cterm 'guibg=#ab6560' 'ctermbg=167' s:bold_attr
  " exe 'hi' 'DiffText' 'term=NONE' 'guibg='.s:bg_gui 'ctermbg=233'
  " hi diffAdded term=NONE guifg=#a9dd9d ctermfg=150
  " hi diffFile term=NONE guifg=#f0eaaa ctermfg=229
  " hi diffIndexLine term=NONE guifg=#fedf81 ctermfg=222
  " hi diffNewFile term=NONE guifg=#f0eaaa ctermfg=229
  " hi diffRemoved term=NONE guifg=#fd8489 ctermfg=210
  " hi gitCommitOverflow term=NONE guibg=#fd8489 ctermbg=210
  " hi gitCommitSummary term=NONE guifg=#f0eaaa ctermfg=229
  " hi gitCommitSelectedFile term=NONE guifg=#a8d2eb ctermfg=153
  " exe 'hi' 'gitconfigSection' 'term=NONE' 'guifg=#a8d2eb' 'ctermfg=153' s:bold_attr
  " hi goBuiltins term=NONE guifg=#fd8489 ctermfg=210
  " hi helpExample term=NONE guifg=#a8d2eb ctermfg=153
  " hi htmlBold term=NONE guibg=#3a4b5c ctermbg=235
  " hi htmlLinkText term=NONE guifg=#a8d2eb ctermfg=153
  " hi htmlTagName term=NONE guifg=#f0aa8a ctermfg=216
  " exe 'hi' 'javaScriptBraces' 'term=NONE' 'guifg=#fffeeb' 'ctermfg='.s:fg_cterm
  " hi makeCommands term=NONE guifg=#f0eaaa ctermfg=229
  " hi markdownCode term=NONE guifg=#f0eaaa ctermfg=229
  " hi markdownUrl term=NONE guifg=#8d9eb2 ctermfg=103
  " hi ocamlConstructor term=NONE guifg=#fedf81 ctermfg=222
  " hi ocamlKeyChar term=NONE guifg=#a8d2eb ctermfg=153
  " hi ocamlKeyword term=NONE guifg=#fedf81 ctermfg=222
  " hi ocamlFunDef term=NONE guifg=#a8d2eb ctermfg=153
  " hi plantumlColonLine term=NONE guifg=#a8d2eb ctermfg=153
  " hi pythonBuiltin term=NONE guifg=#fd8489 ctermfg=210
  " hi qfFileName term=NONE guifg=#fedf81 ctermfg=222
  " hi qfLineNr term=NONE guifg=#a8d2eb ctermfg=153
  " exe 'hi' 'rstEmphasis' 'term=NONE' 'guibg=#3a4b5c' 'ctermbg=235' s:italic_attr
  " exe 'hi' 'rstStrongEmphasis' 'term=NONE' 'guibg=#536273' 'ctermbg=238' s:bold_attr
  " hi rubyFunction term=NONE guifg=#f0eaaa ctermfg=229
  " hi rubyIdentifier term=NONE guifg=#f0eaaa ctermfg=229
  " hi rustEnumVariant term=NONE guifg=#fedf81 ctermfg=222
  " exe 'hi' 'rustFuncCall' 'term=NONE' 'guifg=#fffeeb' 'ctermfg='.s:fg_cterm
  " hi rustCommentLineDoc term=NONE guifg=#e7c6b7 ctermfg=181
  " exe 'hi' 'typescriptBraces' 'term=NONE' 'guifg=#fffeeb' 'ctermfg='.s:fg_cterm
  " hi vimfilerColumn__SizeLine term=NONE guifg=#8d9eb2 ctermfg=103
  " hi vimfilerClosedFile term=NONE guifg=#a9dd9d ctermfg=150
  " hi vimCommand term=NONE guifg=#a8d2eb ctermfg=153
  " exe 'hi' 'wastListDelimiter' 'term=NONE' 'guifg=#fffeeb' 'ctermfg='.s:fg_cterm
  " hi wastInstGeneral term=NONE guifg=#f0eaaa ctermfg=229
  " hi wastInstWithType term=NONE guifg=#f0eaaa ctermfg=229
  " hi wastUnnamedVar term=NONE guifg=#e7d5ff ctermfg=189
  " hi zshDelimiter term=NONE guifg=#a8d2eb ctermfg=153
  " hi zshPrecommand term=NONE guifg=#fd8489 ctermfg=210
  " exe 'hi' 'ALEWarningSign' 'term=NONE' 'guifg=#f0aa8a' 'ctermfg=216' 'guibg=#3a4b5c' 'ctermbg=235' s:bold_attr
  " exe 'hi' 'ALEErrorSign' 'term=NONE' 'guifg=#3a4b5c' 'ctermfg=235' 'guibg=#ab6560' 'ctermbg=167' s:bold_attr
  " hi ALEInfoSign term=NONE guibg=#646f7c ctermbg=60
  " hi ALEError term=NONE guibg=#ab6560 ctermbg=167
  " hi ALEWarning term=NONE guibg=#685800 ctermbg=58
  " exe 'hi' 'CleverFChar' 'term=NONE' 'guifg='.s:bg_gui 'ctermfg=233' 'guibg=#fd8489' 'ctermbg=210'
  " exe 'hi' 'DirvishArg' 'term=NONE' 'guifg=#f0eaaa' 'ctermfg=229' s:bold_attr
  " exe 'hi' 'EasyMotionTarget' 'term=NONE' 'guifg=#fd8489' 'ctermfg=210' s:bold_attr
  " exe 'hi' 'EasyMotionShade' 'term=NONE' 'guifg=#8d9eb2' 'ctermfg=103' 'guibg='.s:bg_gui 'ctermbg=233'
  " hi GitGutterAdd term=NONE guifg=#a9dd9d ctermfg=150 guibg=#3a4b5c ctermbg=235
  " hi GitGutterChange term=NONE guifg=#f0eaaa ctermfg=229 guibg=#3a4b5c ctermbg=235
  " hi GitGutterChangeDelete term=NONE guifg=#fedf81 ctermfg=222 guibg=#3a4b5c ctermbg=235
  " hi GitGutterDelete term=NONE guifg=#fd8489 ctermfg=210 guibg=#3a4b5c ctermbg=235
  " hi HighlightedyankRegion term=NONE guibg=#3a4b5c ctermbg=235
" }}}

" vim:foldenable:foldmethod=marker:ft=vim
