" =============================================================================
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
  Plug 'vim-airline/vim-airline'
  Plug 'vim-airline/vim-airline-themes'
  Plug 'ryanoasis/vim-devicons' " has to be last according to docs
  Plug 'Yggdroot/indentLine', { 'on': 'IndentLinesEnable' }

" ## Syntax
  Plug 'sheerun/vim-polyglot'
  Plug 'HerringtonDarkholme/yats.vim', { 'for': ['typescript', 'typescriptreact', 'typescript.tsx'] }
  Plug 'leafgarland/typescript-vim', { 'for': ['typescript', 'typescriptreact', 'typescript.tsx'] }
  Plug 'lilydjwg/colorizer'
  Plug 'tpope/vim-rails', { 'for': ['ruby', 'eruby', 'haml', 'slim'] }

" ## Completion
  Plug 'ncm2/ncm2' | Plug 'roxma/nvim-yarp'
  Plug 'othree/csscomplete.vim', { 'for': ['css', 'scss', 'sass'] } " css completion
  Plug 'xolox/vim-lua-ftplugin', { 'for': ['lua'] } | Plug 'xolox/vim-misc'
  Plug 'ncm2/ncm2-ultisnips' | Plug 'SirVer/ultisnips'
  Plug 'ncm2/ncm2-bufword'
  Plug 'ncm2/ncm2-tmux'
  Plug 'ncm2/ncm2-path'
  " Plug 'ncm2/ncm2-match-highlight' " the fonts used are wonky
  Plug 'ncm2/ncm2-html-subscope'
  Plug 'ncm2/ncm2-markdown-subscope'
  Plug 'ncm2/ncm2-tern'
  Plug 'ncm2/ncm2-cssomni'
  " Plug 'mhartington/nvim-typescript', { 'for': ['typescript', 'typescriptreact', 'typescript.tsx'], 'do': './install.sh' }
  " Plug 'ncm2/nvim-typescript', {'for': ['typescript', 'typescriptreact', 'typescript.tsx'], 'do': './install.sh'}
  " Plug 'ncm2/ncm2-jedi'
  " Plug 'ncm2/ncm2-pyclang'
  " Plug 'ncm2/ncm2-vim' | Plug 'Shougo/neco-vim'
  " Plug 'ncm2/ncm2-syntax' | Plug 'Shougo/neco-syntax'
  " Plug 'ncm2/ncm2-neoinclude' | Plug 'Shougo/neoinclude.vim'
  Plug 'ncm2/ncm2-vim-lsp' | Plug 'prabirshrestha/vim-lsp' | Plug 'prabirshrestha/async.vim' " LanguageServer

" ## Project/Code Navigation
  Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
  Plug 'junegunn/fzf.vim'
  Plug 'christoomey/vim-tmux-navigator' " needed for tmux/hotkey integration with vim
  Plug 'christoomey/vim-tmux-runner' " needed for tmux/hotkey integration with vim
  Plug 'tmux-plugins/vim-tmux-focus-events'
  Plug 'unblevable/quick-scope' " highlights f/t type of motions, for quick horizontal movements
  " Plug 'justinmk/vim-sneak.git' " https://github.com/justinmk/vim-sneak
  Plug 'AndrewRadev/splitjoin.vim'

" ## Utils
  Plug 'jordwalke/VimAutoMakeDirectory' " auto-makes the dir for you if it doesn't exist in the path
  Plug 'EinfachToll/DidYouMean'
  Plug 'junegunn/rainbow_parentheses.vim' " nicely colors nested pairs of [], (), {}
  Plug 'docunext/closetag.vim' " will auto-close the opening tag as soon as you type </
  Plug 'tpope/vim-ragtag', { 'for': ['html', 'xml', 'erb', 'haml', 'javascript.jsx', 'typescript', 'typescriptreact', 'typescript.tsx', 'javascript'] } " a set of mappings for several langs: html, xml, erb, php, more
  Plug 'Valloric/MatchTagAlways', { 'for': ['haml', 'html', 'xml', 'erb', 'eruby', 'javascript.jsx', 'typescriptreact', 'typescript.tsx'] } " highlights the opening/closing tags for the block you're in
  Plug 'jiangmiao/auto-pairs'
  " Plug 'tpope/vim-endwise'
  Plug 'janko-m/vim-test', {'on': ['TestFile', 'TestLast', 'TestNearest', 'TestSuite', 'TestVisit'] } " tester for js and ruby
  " Plug 'ruanyl/coverage.vim', { 'for': ['typescript', 'typescriptreact', 'typescript.tsx', 'javascript', 'javascript.jsx', 'jsx', 'js'] }
  Plug 'tpope/vim-commentary' " (un)comment code
  Plug 'ConradIrwin/vim-bracketed-paste' " correctly paste in insert mode
  Plug 'sickill/vim-pasta' " context-aware pasting
  Plug 'zenbro/mirror.vim' " allows mirror'ed editing of files locally, to a specified ssh location via ~/.mirrors
  Plug 'keith/gist.vim', { 'do': 'chmod -HR 0600 ~/.netrc' }
  " Plug 'Raimondi/delimitMate'
  Plug 'andymass/vim-matchup'
  Plug 'tpope/vim-surround' " soon to replace with machakann/vim-sandwich
  Plug 'tpope/vim-repeat'
  Plug 'tpope/vim-fugitive' | Plug 'tpope/vim-rhubarb' " required for some fugitive things
  Plug 'junegunn/gv.vim'
  Plug 'sodapopcan/vim-twiggy'
  Plug 'christoomey/vim-conflicted'
  Plug 'tpope/vim-eunuch'
  " Plug 'dyng/ctrlsf.vim'
  Plug 'w0rp/ale'

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
  Plug 'rhysd/vim-textobj-anyblock', { 'on': [ '<Plug>(textobj-anyblock' ] }
  Plug 'whatyouhide/vim-textobj-xmlattr', { 'on': [ '<Plug>(textobj-xmlattr' ] }    " - x     for xml
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
set cmdheight=2
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
" ================ Statusline {{{

" TODO: change statusline based on focus:
" https://github.com/VagabondAzulien/dotfiles/blob/master/vim/vimrc#L88
" or:
" https://www.reddit.com/r/vim/comments/6b7b08/my_custom_statusline/
" or:
" https://kadekillary.work/post/statusline/
" or:
" https://github.com/KabbAmine/myVimFiles/blob/master/config/statusline.vim
" definitely:
" https://gabri.me/blog/diy-vim-statusline/

"let g:currentmode={
"      \ 'n'  : 'N ',
"      \ 'no' : 'N·Operator Pending ',
"      \ 'v'  : 'V ',
"      \ 'V'  : 'V·Line ',
"      \ '' : 'V·Block ',
"      \ 's'  : 'Select ',
"      \ 'S'  : 'S·Line ',
"      \ '' : 'S·Block ',
"      \ 'i'  : 'I ',
"      \ 'R'  : 'R ',
"      \ 'Rv' : 'V·Replace ',
"      \ 'c'  : 'Command ',
"      \ 'cv' : 'Vim Ex ',
"      \ 'ce' : 'Ex ',
"      \ 'r'  : 'Prompt ',
"      \ 'rm' : 'More ',
"      \ 'r?' : 'Confirm ',
"      \ '!'  : 'Shell ',
"      \ 't'  : 'Terminal '
"      \}
"let fgcolor=synIDattr(synIDtrans(hlID("Normal")), "fg", "gui")
"let bgcolor=synIDattr(synIDtrans(hlID("Normal")), "bg", "gui")

"hi User1 guifg=#DF8C8C guibg=#504945 gui=bold
"hi User2 guifg=#FFFFFF guibg=#FF1111 gui=bold
"hi User3 guifg=#2C323C guibg=#E5C07B gui=bold

"" highlight User1 cterm=None gui=None ctermfg=007 guifg=fgcolor
"" highlight User2 cterm=None gui=None ctermfg=008 guifg=bgcolor
"" highlight User3 cterm=None gui=None ctermfg=008 guifg=bgcolor
"highlight User4 cterm=None gui=None ctermfg=008 guifg=bgcolor
"highlight User5 cterm=None gui=None ctermfg=008 guifg=bgcolor
"highlight User7 cterm=None gui=None ctermfg=008 guifg=bgcolor
"highlight User8 cterm=None gui=None ctermfg=008 guifg=bgcolor
"highlight User9 cterm=None gui=None ctermfg=007 guifg=fgcolor

"set statusline=%{ChangeStatuslineColor()}                                       "Changing the statusline color
"set statusline+=\ %0*\ %{toupper(g:currentmode[mode()])}                        "Current mode
"set statusline+=\│\ %{fugitive#head()!=''?'\ \ '.fugitive#head().'\ ':''}      "Git branch
"set statusline+=%{GitFileStatus()}                                              "Git file status
"set statusline+=\ \│\ %{FilepathStatusline()}                                   "File path
"set statusline+=\%{FilenameStatusline()}                                        "File name
"set statusline+=\ %1*%m%*                                                       "Modified indicator
"set statusline+=\ %w                                                            "Preview indicator
"set statusline+=%{ReadOnly()}                                                   "Read only indicator
"set statusline+=\ %q                                                            "Quickfix list indicator
"set statusline+=\ %=                                                            "Start right side layout
"set statusline+=\ %{&enc}                                                       "Encoding
"set statusline+=\ \│\ %{WebDevIconsGetFileTypeSymbol()}\                        "DevIcon/Filetype
"set statusline+=\ \│\ %{FileSize()}                                             "File size
"set statusline+=\ \│\ %p%%                                                      "Percentage
"set statusline+=\ \│\ %c                                                        "Column number
"set statusline+=\ \│\\ %l/%L                                                   "Current line number/Total line numbers
"set statusline+=\ %2*%{AleStatusline('error')}%*                                "Errors count
"set statusline+=%3*%{AleStatusline('warning')}%*                                "Warning count

"function! ReadOnly()
"  if &readonly || !&modifiable
"    return ''
"  else
"    return ''
"endfunction

"" Automatically change the statusline color depending on mode
"function! ChangeStatuslineColor()
"  if (mode() =~# '\v(n|no)')
"    exe 'hi! StatusLine ctermfg=008 guifg=fgcolor gui=None cterm=None'
"  elseif (mode() =~# '\v(v|V)' || g:currentmode[mode()] ==# 'V·Block' || get(g:currentmode, mode(), '') ==# 't')
"    exe 'hi! StatusLine ctermfg=005 guifg=#00ff00 gui=None cterm=None'
"  elseif (mode() ==# 'i')
"    exe 'hi! StatusLine ctermfg=004 guifg=#6CBCE8 gui=None cterm=None'
"  else
"    exe 'hi! StatusLine ctermfg=006 guifg=orange gui=None cterm=None'
"  endif

"  return ''
"endfunction

"function! FilepathStatusline() abort
"  if !empty(expand('%:t'))
"    let fn = winwidth(0) <# 55
"          \ ? '../'
"          \ : winwidth(0) ># 85
"          \ ? expand('%:~:.:h') . '/'
"          \ : pathshorten(expand('%:~:.:h')) . '/'
"  else
"    let fn = ''
"  endif
"  return fn
"endfunction

"function! FilenameStatusline() abort
"  let fn = !empty(expand('%:t'))
"        \ ? expand('%:p:t')
"        \ : '[No Name]'
"  return fn . (&readonly ? ' ' : '')
"endfunction
""
"" Find out current buffer's size and output it.
"function! FileSize()
"  let bytes = getfsize(expand('%:p'))
"  if (bytes >= 1024)
"    let kbytes = bytes / 1024
"  endif
"  if (exists('kbytes') && kbytes >= 1000)
"    let mbytes = kbytes / 1000
"  endif

"  if bytes <= 0
"    return '0'
"  endif

"  if (exists('mbytes'))
"    return mbytes . 'MB '
"  elseif (exists('kbytes'))
"    return kbytes . 'KB '
"  else
"    return bytes . 'B '
"  endif
"endfunction

"function! AleStatusline(type)
"  let count = ale#statusline#Count(bufnr(''))
"  if a:type == 'error' && count['error']
"    return printf(' %d E ', count['error'])
"  endif

"  if a:type == 'warning' && count['warning']
"    let l:space = count['error'] ? ' ': ''
"    return printf('%s %d W ', l:space, count['warning'])
"  endif

"  return ''
"endfunction

"function! GitFileStatus()
"  if !exists('b:gitgutter')
"    return ''
"  endif
"  let l:summary = get(b:gitgutter, 'summary', [0, 0, 0])
"  let l:result = l:summary[0] == 0 ? '' : ' +'.l:summary[0]
"  let l:result .= l:summary[1] == 0 ? '' : ' ~'.l:summary[1]
"  let l:result .= l:summary[2] == 0 ? '' : ' -'.l:summary[2]
"  if l:result != ''
"    return ' '.l:result
"  endif
"  return l:result
"endfunction

"}}}
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
  au Filetype gitcommit setl spell textwidth=72
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
  " TypeScript
  au FileType eruby,ruby,typescript,typescriptreact,typescript.tsx,javascript,javascript.jsx nnoremap <leader>h :LspHover<CR>
  au FileType eruby,ruby,typescript,typescriptreact,typescript.tsx,javascript,javascript.jsx nnoremap <F2> :LspRename<CR>
  au FileType eruby,ruby,typescript,typescriptreact,typescript.tsx,javascript,javascript.jsx nnoremap <F7> :LspDocumentDiagnostics<CR>
  au FileType eruby,ruby,typescript,typescriptreact,typescript.tsx,javascript,javascript.jsx nnoremap <F8> :LspReferences<CR>
  au FileType eruby,ruby,typescript,typescriptreact,typescript.tsx,javascript,javascript.jsx nnoremap <F9> :LspDefinition<CR>
  au FileType eruby,ruby,typescript,typescriptreact,typescript.tsx,javascript,javascript.jsx nnoremap <F10> :LspDocumentSymbol<CR>
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

" QuickScope, used in conjunction with keybinding overrides
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
  let g:polyglot_disabled = ['typescript', 'typescriptreact', 'typescript.tsx', 'graphql', 'jsx', 'sass', 'scss', 'css', 'markdown']

" ## vim-matchup
  let g:matchup_matchparen_status_offscreen = 0 " prevents statusline from disappearing

" ## vim-devicons
  " let g:WebDevIconsUnicodeDecorateFileNodesExtensionSymbols['vim'] = ''
  let g:WebDevIconsUnicodeDecorateFolderNodesDefaultSymbol = ''
  let g:WebDevIconsOS = 'Darwin'
  let g:WebDevIconsUnicodeDecorateFolderNodes = 1
  let g:WebDevIconsUnicodeDecorateFileNodesDefaultSymbol = ''
  let g:WebDevIconsUnicodeDecorateFolderNodes = 1
  let g:WebDevIconsUnicodeDecorateFolderNodesDefaultSymbol = ''
  let g:WebDevIconsUnicodeDecorateFileNodesExtensionSymbols = {} " needed
  let g:WebDevIconsUnicodeDecorateFileNodesExtensionSymbols['js'] = ''
  let g:WebDevIconsUnicodeDecorateFileNodesExtensionSymbols['tsx'] = ''
  let g:WebDevIconsUnicodeDecorateFileNodesExtensionSymbols['css'] = ''
  let g:WebDevIconsUnicodeDecorateFileNodesExtensionSymbols['html'] = ''
  let g:WebDevIconsUnicodeDecorateFileNodesExtensionSymbols['json'] = ''
  let g:WebDevIconsUnicodeDecorateFileNodesExtensionSymbols['md'] = ''
  let g:WebDevIconsUnicodeDecorateFileNodesExtensionSymbols['sql'] = ''

" ## vim-airline
  let g:webdevicons_enable_airline_statusline = 1
  if !exists('g:airline_symbols')
    let g:airline_symbols = {}
  endif

  let g:airline_powerline_fonts = 0
  let g:airline_symbols.branch = ''
  let g:airline_theme='nova'
  let g:airline_section_x = ''
  let g:airline_mode_map = {
    \ '__' : '-',
    \ 'n'  : 'N',
    \ 'i'  : 'I',
    \ 'R'  : 'R',
    \ 'c'  : 'C',
    \ 'v'  : 'V',
    \ 'V'  : 'V',
    \ '' : 'V',
    \ 's'  : 'S',
    \ 'S'  : 'S',
    \ '' : 'S',
    \ }

" ## golden-ratio
  let g:golden_ratio_exclude_nonmodifiable = 1
  let g:golden_ratio_wrap_ignored = 0
  let g:golden_ratio_ignore_horizontal_splits = 1

" ## vim-sneak
  let g:sneak#label = 1
  let g:sneak#use_ic_scs = 1
  let g:sneak#absolute_dir = 1

" ## quickscope
  let g:qs_enable = 0

" ## auto-pairs
  let g:AutoPairsShortcutToggle = ''
  let g:AutoPairsMapCR = 0 " https://www.reddit.com/r/neovim/comments/4st4i6/making_ultisnips_and_deoplete_work_together_nicely/d6m73rh/

" # delimitMate
  let g:delimitMate_expand_cr = 2                                                 "Auto indent on enter

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
        \   'typescript': ['prettier', 'eslint', 'prettier_eslint', 'tslint', 'typecheck'],
        \   'typescriptreact': ['prettier', 'eslint', 'prettier_eslint', 'tslint', 'typecheck'],
        \   'typescript.tsx': ['prettier', 'eslint', 'prettier_eslint', 'tslint', 'typecheck'],
        \   'css': ['prettier'],
        \   'scss': ['prettier'],
        \   'json': ['prettier'],
        \   'ruby': []
        \ }                                                                       "Lint js with eslint
  let g:ale_fixers = {
        \   'javascript': ['prettier_eslint'],
        \   'javascript.jsx': ['prettier_eslint'],
        \   'typescript': ['prettier_eslint'],
        \   'typescriptreact': ['prettier_eslint'],
        \   'typescript.tsx': ['prettier_eslint'],
        \   'css': ['prettier'],
        \   'scss': ['prettier'],
        \   'json': ['prettier']
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
        \ 'bash=sh', 'zsh']

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
  let g:nvim_typescript#max_completion_detail=100
  let g:nvim_typescript#javascript_support=0
  let g:nvim_typescript#signature_complete=0
  let g:nvim_typescript#diagnosticsEnable=0
  autocmd FileType typescript,typescriptreact,typescript.tsx nnoremap <F2> :TSRename<CR>
  autocmd FileType typescript,typescriptreact,typescript.tsx nnoremap <F3> :TSImport<CR>
  autocmd FileType typescript,typescriptreact,typescript.tsx nnoremap <F6> :TSTypeDef<CR>
  autocmd FileType typescript,typescriptreact,typescript.tsx nnoremap <F7> :TSRefs<CR>
  autocmd FileType typescript,typescriptreact,typescript.tsx nnoremap <F8> :TSDefPreview<CR>
  autocmd FileType typescript,typescriptreact,typescript.tsx nnoremap <F9> :TSDoc<CR>
  autocmd FileType typescript,typescriptreact,typescript.tsx nnoremap <F10> :TSType<CR>
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

" ## colorizer
  let g:colorizer_auto_filetype='css,scss'
  let g:colorizer_colornames = 1

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
  let g:fzf_action = {
        \ 'ctrl-t': 'tab split',
        \ 'ctrl-x': 'split',
        \ 'ctrl-v': 'vsplit',
        \ 'enter': 'vsplit'
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
          \   'rg --column --line-number --no-heading --color=always --glob "!.git/*" '.shellescape(<q-args>), 1,
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

" ## ultisnips
  let g:UltiSnipsExpandTrigger		= "<c-e>"
  let g:UltiSnipsExpandTrigger		= "<Plug>(ultisnips_expand)"
  let g:UltiSnipsJumpForwardTrigger	= "<tab>"
  let g:UltiSnipsJumpBackwardTrigger	= "<s-tab>"
  let g:UltiSnipsRemoveSelectModeMappings = 0
  let g:UltiSnipsSnippetDirectories=['UltiSnips']

" ## async/vim-lsp
  let g:lsp_auto_enable = 1
  let g:lsp_signs_enabled = 1         " enable diagnostic signs / we use ALE for now
  let g:lsp_diagnostics_echo_cursor = 1 " enable echo under cursor when in normal mode
  let g:lsp_signs_error = {'text': '✖'}
  let g:lsp_signs_warning = {'text': '~'}
  let g:lsp_signs_hint = {'text': '?'}
  let g:lsp_signs_information = {'text': '!!'}
  let g:lsp_log_verbose = 0
  let g:lsp_log_file = expand('~/.config/nvim/vim-lsp.log')
  if executable('typescript-language-server')
    au User lsp_setup call lsp#register_server({
          \ 'name': 'typescript-language-server',
          \ 'cmd': {server_info->[&shell, &shellcmdflag, 'typescript-language-server --stdio']},
          \ 'root_uri':{server_info->lsp#utils#path_to_uri(lsp#utils#find_nearest_parent_file_directory(lsp#utils#get_buffer_path(), 'tsconfig.json'))},
          \ 'whitelist': ['typescript', 'typescriptreact', 'typescript.tsx'],
          \ })
  endif
  if executable('css-languageserver')
    au User lsp_setup call lsp#register_server({
          \ 'name': 'css-languageserver',
          \ 'cmd': {server_info->[&shell, &shellcmdflag, 'css-languageserver --stdio']},
          \ 'whitelist': ['css', 'less', 'sass', 'scss'],
          \ })
  endif
  if executable('solargraph')
    au User lsp_setup call lsp#register_server({
        \ 'name': 'solargraph',
        \ 'cmd': {server_info->[&shell, &shellcmdflag, 'solargraph stdio']},
        \ 'initialization_options': {"diagnostics": "true"},
        \ 'root_uri':{server_info->lsp#utils#path_to_uri(lsp#utils#find_nearest_parent_file_directory(lsp#utils#get_buffer_path(), 'Gemfile'))},
        \ 'whitelist': ['ruby', 'eruby'],
        \ })
  endif
  if executable('pyls')
    " pip install python-language-server
    au User lsp_setup call lsp#register_server({
          \ 'name': 'pyls',
          \ 'cmd': {server_info->['pyls']},
          \ 'whitelist': ['python'],
          \ })
  endif

" ## ncm2
  " NOTE: source changes must happen before the source is loaded
  let g:ncm2_ultisnips#source = {'priority': 10, 'mark': ''}
  " let g:ncm2_vim_lsp#source = {'priority': 9, 'mark': ''} " not working as a source

  au InsertEnter * call ncm2#enable_for_buffer() " or on BufEnter
  set completeopt=noinsert,menuone,noselect
  set shortmess+=c
  au TextChangedI * call ncm2#auto_trigger()
  let g:ncm2#matcher = 'abbrfuzzy'
  let g:ncm2#sorter = 'abbrfuzzy'
  " let g:ncm2#match_highlight = 'sans-serif-bold'

" }}}
" ================ Custom Mappings {{{

" - ncm2 + ultisnips
inoremap <expr> <Tab> pumvisible() ? "\<C-n>" : "\<Tab>"
inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"
inoremap <expr> <CR> pumvisible() ? "\<C-y>" : "\<CR>"
inoremap <c-c> <ESC>
inoremap <silent> <expr> <CR> ((pumvisible() && empty(v:completed_item)) ?  "\<c-y>\<cr>" : (!empty(v:completed_item) ? ncm2_ultisnips#expand_or("", 'n') : "\<CR>" ))
imap <silent> <expr> <c-e> ncm2_ultisnips#expand_or("\<Plug>(ultisnips_expand)", 'm')
smap <silent> <expr> <c-e> ncm2_ultisnips#expand_or("\<Plug>(ultisnips_expand)", 'm')
inoremap <silent> <expr> <c-e> ncm2_ultisnips#expand_or("\<Plug>(ultisnips_expand)", 'm')
" smap <silent> <c-u> <Plug>(ultisnips_expand)
" inoremap <C-e> <C-R>=SnipComplete()<CR>
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
nnoremap <f4> :TagbarToggle<CR>

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

nnoremap <C-s> :call ScratchOpen()<CR>

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
" map f <Plug>Sneak_f
" map F <Plug>Sneak_F
" map t <Plug>Sneak_t
" map T <Plug>Sneak_T
" map <M-;> <Plug>Sneak_,

" ## vim-js-file-import
" nmap <C-i> <Plug>(JsFileImport)
" nmap <C-u> <Plug>(PromptJsFileImport)

" ## QuickScope
nnoremap <expr> <silent> f Quick_scope_selective('f')
nnoremap <expr> <silent> F Quick_scope_selective('F')
nnoremap <expr> <silent> t Quick_scope_selective('t')
nnoremap <expr> <silent> T Quick_scope_selective('T')
vnoremap <expr> <silent> f Quick_scope_selective('f')
vnoremap <expr> <silent> F Quick_scope_selective('F')
vnoremap <expr> <silent> t Quick_scope_selective('t')
vnoremap <expr> <silent> T Quick_scope_selective('T')

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
  hi Normal ctermbg=none guibg=NONE
  hi Comment cterm=italic term=italic gui=italic
  hi LineNr guibg=#3C4C55 guifg=#937f6e gui=NONE
  hi CursorLineNr ctermbg=black ctermfg=223 cterm=NONE guibg=#333333 guifg=#db9c5e gui=bold
  hi CursorLine guibg=#333333
  hi qfLineNr ctermbg=black ctermfg=95 cterm=NONE guibg=black guifg=#875f5f gui=NONE
  hi QuickFixLine term=bold,underline cterm=bold,underline gui=bold,underline guifg=#cc6666 guibg=red
  hi Search gui=underline term=underline cterm=underline ctermfg=232 ctermbg=230 guibg=#db9c5e guifg=#333333 gui=bold

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

  " hi DiffChange guibg=#444444 ctermbg=238
  " hi DiffText guibg=#777777 ctermbg=244
  " hi DiffAdd guibg=#4f8867 ctermbg=29
  " hi DiffDelete guibg=#870000 ctermbg=88

  hi ALEErrorSign term=NONE cterm=NONE gui=NONE ctermfg=red guifg=#cc6666 guibg=NONE
  hi ALEWarningSign ctermfg=11 ctermbg=15 guifg=#f0c674 guibg=NONE
  hi link ALEError SpellBad
  hi link ALEWarning SpellBad
  hi link Debug SpellBad
  hi link ErrorMsg SpellBad
  hi link Exception SpellBad


  hi MatchParen cterm=italic gui=italic guibg=#937f6e

  " Nord
  " hi! RainbowLevel0 ctermbg=240 guibg=#2C3441
  " hi! RainbowLevel1 ctermbg=240 guibg=#2E3440
  " hi! RainbowLevel2 ctermbg=239 guibg=#252d3d
  " hi! RainbowLevel3 ctermbg=238 guibg=#1f293d
  " hi! RainbowLevel4 ctermbg=237 guibg=#18243d
  " hi! RainbowLevel5 ctermbg=236 guibg=#131f38
  " hi! RainbowLevel6 ctermbg=235 guibg=#0f1c38
  " hi! RainbowLevel7 ctermbg=234 guibg=#09193a
  " hi! RainbowLevel8 ctermbg=233 guibg=#041538
  " hi! RainbowLevel9 ctermbg=232 guibg=#001030

" }}}

" vim:foldenable:foldmethod=marker:ft=vim
