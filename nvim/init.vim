" =============================================================================
"
"   ┌┬┐┌─┐┌─┐┌─┐┬  ┬┌┬┐┬ ┬┬┌─┐
"   │││├┤ │ ┬├─┤│  │ │ ├─┤││   :: DOTFILES > nvim/init.vim
"   ┴ ┴└─┘└─┘┴ ┴┴─┘┴ ┴ ┴ ┴┴└─┘
"   Brought to you by: Seth Messer / @megalithic
"
" =============================================================================

" ================ Plugins ==================== {{{
call plug#begin( '~/.config/nvim/plugged')

  Plug 'tweekmonster/startuptime.vim', { 'on': [ 'StartupTime' ] } " Show slow plugins

" ## UI/Interface
  Plug 'trevordmiller/nova-vim'
  " Plug 'mhartington/oceanic-next'
  Plug 'megalithic/golden-ratio' " vertical split layout manager

" ## Syntax
  Plug 'sheerun/vim-polyglot'

" # JS
  " Plug 'othree/yajs.vim', { 'for': ['javascript', 'javascript.jsx', 'jsx'] }
  " Plug 'chemzqm/vim-jsx-improve', { 'for': ['javascript', 'javascript.jsx', 'jsx', 'js'] }
  " Plug 'mxw/vim-jsx', { 'for': ['javascript', 'javascript.jsx', 'jsx', 'js'] }
  " Plug 'elzr/vim-json', { 'for': ['json'] }
  Plug 'jparise/vim-graphql', { 'for': ['javascript', 'javascript.jsx', 'jsx', 'js'] }

" # TS
  Plug 'HerringtonDarkholme/yats.vim', { 'for': ['typescript', 'typescriptreact', 'typescript.tsx'] }
  Plug 'leafgarland/typescript-vim', { 'for': ['typescript', 'typescriptreact', 'typescript.tsx'] }
  " Plug 'ianks/vim-tsx', { 'for': ['typescript', 'typescriptreact', 'typescript.tsx'] }

" # Fn
  " Plug 'ElmCast/elm-vim', { 'for': ['elm'] }
  " Plug 'reasonml-editor/vim-reason-plus', { 'for': ['reason'] }

" # CSS
  Plug 'othree/csscomplete.vim', { 'for': ['css', 'scss', 'sass'] } " css completion
  Plug 'hail2u/vim-css3-syntax', { 'for': ['css', 'scss', 'sass'] } " css3-specific syntax
  Plug 'ap/vim-css-color', { 'for': ['css', 'scss', 'sass'] }

" # HTML
  " Plug 'othree/html5.vim', { 'for': ['html', 'haml'] }
  " Plug 'othree/xml.vim', { 'for': ['xml'] }

" # Cfg
  " Plug 'martin-svk/vim-yaml', { 'for': ['yaml'] }

" # MD
  Plug 'tpope/vim-markdown', { 'for': ['markdown', 'md', 'mdown', 'ghmarkdown'] }
  Plug 'plasticboy/vim-markdown', { 'for': ['markdown', 'md', 'mdown', 'ghmarkdown'] }
  Plug 'jtratner/vim-flavored-markdown', { 'for': ['markdown', 'ghmarkdown'] }
  Plug 'tyru/markdown-codehl-onthefly.vim', { 'for': ['markdown', 'md', 'mdown', 'ghmarkdown'] }
  Plug 'rhysd/vim-gfm-syntax', { 'for': ['markdown', 'md', 'mdown', 'ghmarkdown'] }
  " Plug 'euclio/vim-markdown-composer', { 'do': 'cargo build --release' }

" # RoR
  " Plug 'vim-ruby/vim-ruby', { 'for': ['ruby'] }
  " Plug 'tpope/vim-haml', { 'for': ['haml'] }
  Plug 'tpope/vim-rails', { 'for': ['ruby', 'eruby', 'haml', 'slim'] }
  " Plug 'tpope/vim-bundler', { 'for': ['ruby', 'eruby', 'haml', 'slim'] }
  " Plug 'thoughtbot/vim-rspec', { 'for': 'ruby' } " rspec commands and highlight

 " #Misc
  " Plug 'xolox/vim-lua-ftplugin', { 'for': ['lua'] } " all the luas
  " Plug 'tmux-plugins/vim-tmux', { 'for': ['tmux'] }
  " Plug 'vim-scripts/fish.vim',   { 'for': 'fish' }

" ## Project/Code Navigation
  Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
  Plug 'junegunn/fzf.vim'
  Plug 'ryanoasis/vim-devicons'
  Plug 'christoomey/vim-tmux-navigator' " needed for tmux/hotkey integration with vim
  Plug 'christoomey/vim-tmux-runner' " needed for tmux/hotkey integration with vim
  Plug 'tmux-plugins/vim-tmux-focus-events'
  Plug 'unblevable/quick-scope' " highlights f/t type of motions, for quick horizontal movements
  " Plug 'justinmk/vim-sneak.git' " https://github.com/justinmk/vim-sneak
  Plug 'janko-m/vim-test', {'on': ['TestFile', 'TestLast', 'TestNearest', 'TestSuite', 'TestVisit'] } " tester for js and ruby

" ## Completions
  " Plug 'neoclide/coc.nvim', { 'do': 'npm install' }
  Plug 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' }
  Plug 'Shougo/neoinclude.vim'
  " Plug 'roxma/nvim-cm-tern',  {'do': 'npm install'}
  " Plug 'calebeby/ncm-css', { 'for': ['scss', 'css', 'sass', 'less'] }
  " Plug 'Shougo/echodoc.vim'
  " Plug 'Shougo/neco-vim'
  Plug 'mhartington/nvim-typescript', { 'branch': 'feat-diagnostics', 'for': ['ts', 'tsx', 'typescript', 'typescriptreact', 'typescript.tsx'], 'do': './install.sh' }

" ## Language Servers
  Plug 'autozimu/LanguageClient-neovim', { 'branch': 'next', 'do': 'bash install.sh' }

" ## Tags
  " if executable('ctags')
  "   Plug 'ludovicchabant/vim-gutentags'
  "   Plug 'majutsushi/tagbar'
  "   " Plug 'kristijanhusak/vim-js-file-import'
  " endif

" ## Snippets
  if has('python3')
    " Plug 'Shougo/neosnippet.vim'
    " Plug 'Shougo/neosnippet-snippets'
    Plug 'SirVer/ultisnips'
    " Plug 'honza/vim-snippets'
    " Plug 'epilande/vim-es2015-snippets'
    " Plug 'epilande/vim-react-snippets'
  endif

" ## Random/Misc/Docs
  Plug 'junegunn/limelight.vim'
  Plug 'junegunn/goyo.vim'
  " Plug 'raghur/vim-ghost', {'do': ':GhostInstall'} " just run :GhostStart in nvim and click the vim-ghost icon in Chrome/Firefox
  Plug 'drmikehenry/vim-extline' " https://github.com/drmikehenry/vim-extline/blob/master/doc/extline.txt / Ctrl+L Ctrl+L to auto underline with `=` under the visual selection
  " Plug 'Galooshi/vim-import-js' "https://github.com/Galooshi/vim-import-js#default-mappings

  Plug 'brooth/far.vim' " find and replace
  Plug 'jordwalke/VimAutoMakeDirectory' " auto-makes the dir for you if it doesn't exist in the path
  Plug 'EinfachToll/DidYouMean'
  Plug 'wsdjeg/vim-fetch' " open files at line number
  " Plug 'nelstrom/vim-visual-star-search'
  Plug 'tpope/vim-commentary' " (un)comment code
  Plug 'shougo/vimproc.vim', { 'do': 'make' } " for rct/rails things?
  Plug 'xolox/vim-misc' " for lua things
  Plug 'sickill/vim-pasta' " context-aware pasting
  Plug 'zenbro/mirror.vim' " allows mirror'ed editing of files locally, to a specified ssh location via ~/.mirrors
  Plug 'keith/gist.vim', { 'do': 'chmod -HR 0600 ~/.netrc' }

  Plug 'junegunn/rainbow_parentheses.vim' " nicely colors nested pairs of [], (), {}
  Plug 'docunext/closetag.vim' " will auto-close the opening tag as soon as you type </
  Plug 'tpope/vim-ragtag', { 'for': ['html', 'xml', 'erb', 'haml', 'javascript.jsx', 'typescript', 'typescriptreact', 'typescript.tsx', 'javascript'] } " a set of mappings for several langs: html, xml, erb, php, more
  Plug 'Valloric/MatchTagAlways', { 'for': ['haml', 'html', 'xml', 'erb', 'eruby', 'javascript.jsx', 'typescriptreact', 'typescript.tsx'] } " highlights the opening/closing tags for the block you're in
  Plug 'cohama/lexima.vim' " auto-closes many delimiters and can repeat with a `.`
  Plug 'andymass/vim-matchup'
  Plug 'tpope/vim-rhubarb'
  Plug 'tpope/vim-surround' " soon to replace with machakann/vim-sandwich
  Plug 'tpope/vim-repeat'
  Plug 'tpope/vim-fugitive'
  Plug 'junegunn/gv.vim'
  Plug 'sodapopcan/vim-twiggy'
  Plug 'christoomey/vim-conflicted'
  Plug 'tpope/vim-eunuch'
  Plug 'dyng/ctrlsf.vim'
  Plug 'metakirby5/codi.vim'
  " Plug 'BurningEther/iron.nvim'
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
  Plug 'wellle/targets.vim'                                                         " improved targets line cin) next parens
  " ^--- https://github.com/wellle/targets.vim/blob/master/cheatsheet.md


call plug#end()

"}}}
" ================ General Config/Setup ==================== {{{

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

" let g:ruby_host_prog = '$RUBY_ROOT/bin/ruby'
let g:python_host_prog = '/usr/local/bin/python2.7'
let g:python3_host_prog = '/usr/local/bin/python3'
let g:node_host_prog = $HOME."/.n/bin/neovim-node-host"

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
set cursorline                                                                  "Highlight current line
set smartcase                                                                   "Smart case search if there is uppercase
set ignorecase                                                                  "case insensitive search
set mouse=a                                                                     "Enable mouse usage
set showmatch                                                                   "Highlight matching bracket
set nostartofline                                                               "Jump to first non-blank character
set timeoutlen=1000 ttimeoutlen=0                                               "Reduce Command timeout for faster escape and O
set fileencoding=utf-8                                                          "Set utf-8 encoding on write
set linebreak
set textwidth=79 " will auto wrap content when set
set nowrap " `on` is 'wrap'
set wrapscan
set listchars=tab:▸\ ,eol:¬,extends:›,precedes:‹,trail:·,nbsp:⚋
set nolist " list to enable                                                                        "Enable listchars
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
" ================ Turn Off Swap Files ============== {{{

set noswapfile
set nobackup
set nowb
set backupcopy=yes "HMR things - https://parceljs.org/hmr.html#safe-write

" }}}
" ================ Persistent Undo ================== {{{

" Keep undo history across sessions, by storing in file.
silent !mkdir ~/.config/nvim/undo > /dev/null 2>&1
set undodir=~/.config/nvim/undo
set undofile

" }}}
" ================ Indentation ====================== {{{

set shiftwidth=2
set softtabstop=2
set tabstop=2
set expandtab
set smartindent
set nofoldenable
" set foldmethod=syntax

" }}}
" ================ Autocommands ====================== {{{

augroup vimrc
  autocmd!

  " automatically source vim configs
  autocmd BufWritePost .vimrc,.vimrc.local,init.vim source %
  autocmd BufWritePost .vimrc.local source %

  " save all files on focus lost, ignoring warnings about untitled buffers
  autocmd FocusLost * silent! wa

  au BufWritePre * call StripTrailingWhitespaces()                     "Auto-remove trailing spaces
  au FocusGained,BufEnter * checktime                                  "Refresh file when vim gets focus

  " Handle window resizing
  au VimResized * execute "normal! \<c-w>="

  " No formatting on o key newlines
  au BufNewFile,BufEnter * set formatoptions-=o

  " Remember cursor position between vim sessions
  autocmd BufReadPost *
        \ if line("'\"") > 0 && line ("'\"") <= line("$") |
        \   exe "normal! g'\"" |
        \ endif

  " Auto-close preview window when completion is done.
  autocmd! InsertLeave,CompleteDone * if pumvisible() == 0 | pclose | endif

  " ----------------------------------------------------------------------------
  " ## JavaScript
  au FileType typescript,typescriptreact,typescript.tsx,javascript,javascript.jsx,sass,scss,scss.css RainbowParentheses
  au FileType typescript,typescriptreact,typescript.tsx,javascript,javascript.jsx set sw=2 ts=2 sts=2 et
  au BufNewFile,BufRead .{babel,eslint,prettier,stylelint,jshint,jscs,postcss}*rc,\.tern-*,*.json set ft=json
  au BufNewFile,BufRead .tern-project set ft=json
  au BufNewFile,BufRead *.tsx set ft=typescriptreact " forces typescript.tsx -> typescriptreact
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
  au BufNewFile,BufRead */ssh/config  setf sshconfig
  au BufNewFile,BufRead ssh_config,*/.dotfiles/private/ssh/config  setf sshconfig

  " ----------------------------------------------------------------------------
  " ## Misc filetypes
  au FileType zsh set ts=2 sts=2 sw=2
  au FileType sh set ts=2 sts=2 sw=2
  au FileType bash set ts=2 sts=2 sw=2
  au FileType tmux set ts=2 sts=2 sw=2

  " ----------------------------------------------------------------------------
  " ## Completions
  au FileType * setl omnifunc=syntaxcomplete#Complete
  au FileType html,markdown setl omnifunc=htmlcomplete#CompleteTags
  au FileType css,scss,sass,less,scss.css,sass.css setl omnifunc=csscomplete#CompleteCSS noci

  " au FileType javascript,javascript.jsx,jsx setl omnifunc=javascriptcomplete#CompleteJS " default
  " au FileType javascript,javascript.jsx,jsx setl completefunc=jspc#omni " jspc
  " au FileType javascript,javascript.jsx,jsx setl omnifunc=tern#Complete " tern

  au FileType python setl omnifunc=pythoncomplete#Complete
  au FileType xml setl omnifunc=xmlcomplete#CompleteTags
  " au FileType ruby setl omnifunc=rubycomplete#Complete
  au FileType ruby setl omnifunc=LanguageClient#complete

  " ----------------------------------------------------------------------------
  " ## Toggle certain accoutrements when entering and leaving a buffer & window
  au WinEnter,BufEnter * silent set number relativenumber syntax=on " exec RainbowParentheses
  au WinLeave,BufLeave * silent set nonumber norelativenumber syntax=off " exec RainbowParentheses!
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

" # vim-lsp
" augroup language_mappings
"   autocmd!

"   " TypeScript
"   autocmd FileType typescript,typescriptreact,typescript.tsx nnoremap <leader>h :LspHover<CR>
"   autocmd FileType typescript,typescriptreact,typescript.tsx nnoremap <f2> :LspRename<CR>
"   autocmd FileType typescript,typescriptreact,typescript.tsx nnoremap <f8> :LspDocumentDiagnostics<CR>
"   autocmd FileType typescript,typescriptreact,typescript.tsx nnoremap <f10> :LspDocumentSymbol<CR>
"   autocmd FileType typescript,typescriptreact,typescript.tsx nnoremap <f11> :LspReferences<CR>
"   autocmd FileType typescript,typescriptreact,typescript.tsx nnoremap <f12> :LspDefinition<CR>
"   autocmd FileType typescript,typescriptreact,typescript.tsx command! ProjectSearch -nargs=1 vimgrep /<args>/gj ./**/*.ts<CR>

"   " Vim
"   autocmd FileType vim command! ProjectSearch -nargs=1 vimgrep /<args>/gj ./**/*.vim<CR>
" augroup END

" }}}
" ================ Completion ======================= {{{

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
" ================ Scrolling ======================== {{{

set scrolloff=8                                                                 "Start scrolling when we're 8 lines away from margins
set sidescrolloff=15
set sidescroll=5

" }}}
" ================ Statusline ======================== {{{

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

let g:currentmode={
      \ 'n'  : 'N ',
      \ 'no' : 'N·Operator Pending ',
      \ 'v'  : 'V ',
      \ 'V'  : 'V·Line ',
      \ '' : 'V·Block ',
      \ 's'  : 'Select ',
      \ 'S'  : 'S·Line ',
      \ '' : 'S·Block ',
      \ 'i'  : 'I ',
      \ 'R'  : 'R ',
      \ 'Rv' : 'V·Replace ',
      \ 'c'  : 'Command ',
      \ 'cv' : 'Vim Ex ',
      \ 'ce' : 'Ex ',
      \ 'r'  : 'Prompt ',
      \ 'rm' : 'More ',
      \ 'r?' : 'Confirm ',
      \ '!'  : 'Shell ',
      \ 't'  : 'Terminal '
      \}
let fgcolor=synIDattr(synIDtrans(hlID("Normal")), "fg", "gui")
let bgcolor=synIDattr(synIDtrans(hlID("Normal")), "bg", "gui")

hi User1 guifg=#FF0000 guibg=#504945 gui=bold
hi User2 guifg=#FFFFFF guibg=#FF1111 gui=bold
hi User3 guifg=#2C323C guibg=#E5C07B gui=bold

" highlight User1 cterm=None gui=None ctermfg=007 guifg=fgcolor
" highlight User2 cterm=None gui=None ctermfg=008 guifg=bgcolor
" highlight User3 cterm=None gui=None ctermfg=008 guifg=bgcolor
highlight User4 cterm=None gui=None ctermfg=008 guifg=bgcolor
highlight User5 cterm=None gui=None ctermfg=008 guifg=bgcolor
highlight User7 cterm=None gui=None ctermfg=008 guifg=bgcolor
highlight User8 cterm=None gui=None ctermfg=008 guifg=bgcolor
highlight User9 cterm=None gui=None ctermfg=007 guifg=fgcolor

set statusline=%{ChangeStatuslineColor()}                                       "Changing the statusline color
set statusline+=\ %0*\ %{toupper(g:currentmode[mode()])}                        "Current mode
set statusline+=\│\ %{fugitive#head()!=''?'\ \ '.fugitive#head().'\ ':''}      "Git branch
set statusline+=%{GitFileStatus()}                                              "Git file status
set statusline+=\ \│\ %{FilepathStatusline()}                                   "File path
set statusline+=\%{FilenameStatusline()}                                        "File name
set statusline+=\ %1*%m%*                                                       "Modified indicator
set statusline+=\ %w                                                            "Preview indicator
set statusline+=%{ReadOnly()}                                                   "Read only indicator
set statusline+=\ %q                                                            "Quickfix list indicator
set statusline+=\ %=                                                            "Start right side layout
set statusline+=\ %{&enc}                                                       "Encoding
set statusline+=\ \│\ %{WebDevIconsGetFileTypeSymbol()}\                        "DevIcon/Filetype
set statusline+=\ \│\ %{FileSize()}                                             "File size
set statusline+=\ \│\ %p%%                                                      "Percentage
set statusline+=\ \│\ %c                                                        "Column number
set statusline+=\ \│\\ %l/%L                                                   "Current line number/Total line numbers
set statusline+=\ %2*%{AleStatusline('error')}%*                                "Errors count
set statusline+=%3*%{AleStatusline('warning')}%*                                "Warning count

function! ReadOnly()
  if &readonly || !&modifiable
    return ''
  else
    return ''
endfunction

" Automatically change the statusline color depending on mode
function! ChangeStatuslineColor()
  if (mode() =~# '\v(n|no)')
    exe 'hi! StatusLine ctermfg=008 guifg=fgcolor gui=None cterm=None'
  elseif (mode() =~# '\v(v|V)' || g:currentmode[mode()] ==# 'V·Block' || get(g:currentmode, mode(), '') ==# 't')
    exe 'hi! StatusLine ctermfg=005 guifg=#00ff00 gui=None cterm=None'
  elseif (mode() ==# 'i')
    exe 'hi! StatusLine ctermfg=004 guifg=#6CBCE8 gui=None cterm=None'
  else
    exe 'hi! StatusLine ctermfg=006 guifg=orange gui=None cterm=None'
  endif

  return ''
endfunction

function! FilepathStatusline() abort
  if !empty(expand('%:t'))
    let fn = winwidth(0) <# 55
          \ ? '../'
          \ : winwidth(0) ># 85
          \ ? expand('%:~:.:h') . '/'
          \ : pathshorten(expand('%:~:.:h')) . '/'
  else
    let fn = ''
  endif
  return fn
endfunction

function! FilenameStatusline() abort
  let fn = !empty(expand('%:t'))
        \ ? expand('%:p:t')
        \ : '[No Name]'
  return fn . (&readonly ? ' ' : '')
endfunction
"
" Find out current buffer's size and output it.
function! FileSize()
  let bytes = getfsize(expand('%:p'))
  if (bytes >= 1024)
    let kbytes = bytes / 1024
  endif
  if (exists('kbytes') && kbytes >= 1000)
    let mbytes = kbytes / 1000
  endif

  if bytes <= 0
    return '0'
  endif

  if (exists('mbytes'))
    return mbytes . 'MB '
  elseif (exists('kbytes'))
    return kbytes . 'KB '
  else
    return bytes . 'B '
  endif
endfunction

function! AleStatusline(type)
  let count = ale#statusline#Count(bufnr(''))
  if a:type == 'error' && count['error']
    return printf(' %d E ', count['error'])
  endif

  if a:type == 'warning' && count['warning']
    let l:space = count['error'] ? ' ': ''
    return printf('%s %d W ', l:space, count['warning'])
  endif

  return ''
endfunction

function! GitFileStatus()
  if !exists('b:gitgutter')
    return ''
  endif
  let l:summary = get(b:gitgutter, 'summary', [0, 0, 0])
  let l:result = l:summary[0] == 0 ? '' : ' +'.l:summary[0]
  let l:result .= l:summary[1] == 0 ? '' : ' ~'.l:summary[1]
  let l:result .= l:summary[2] == 0 ? '' : ' -'.l:summary[2]
  if l:result != ''
    return ' '.l:result
  endif
  return l:result
endfunction

"}}}
" ================ Abbreviations ==================== {{{

cnoreabbrev Wq wq
cnoreabbrev WQ wq
cnoreabbrev W w
cnoreabbrev Q q
cnoreabbrev Qa qa
cnoreabbrev Bd bd
cnoreabbrev bD bd
cnoreabbrev wrap set wrap
cnoreabbrev nowrap set nowrap
cnoreabbrev ft set ft

" }}}
" ================ Functions ======================== {{{

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

  " disable for gitcommit messages
  " call deoplete#disable()

  " let g:cm_smart_enable = 0
  let b:deoplete_disable_auto_complete=1
  let g:deoplete_disable_auto_complete=1
  call deoplete#custom#buffer_option('auto_complete', v:false)
  " let g:lsc_enable_autocomplete = v:false

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

" }}}
" ================ Plugin Config/Settings ======================== {{{

" ## polyglot
  let g:polyglot_disabled = ['typescript', 'graphql', 'jsx', 'sass', 'scss', 'css', 'markdown']

" ## vim-devicons
  " let g:webdevicons_enable_denite = 0
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


" ## codi
  let g:codi#rightalign=0

" ## iron.nvim
  let g:iron_map_defaults=0

" ## goyo
  " let g:goyo_width = 80
  " let g:goyo_height = '100%'
  " let g:goyo_margin_top = 3
  " let g:goyo_margin_bottom = 3
  " Writing in vim
    let g:limelight_conceal_ctermfg = 240
    let g:goyo_entered = 0
    function! s:goyo_enter()
      silent !tmux set status off
      let g:goyo_entered = 1
      set noshowmode
      set noshowcmd
      set scrolloff=999
      Limelight
    endfunction

    function! s:goyo_leave()
      silent !tmux set status on
      let g:goyo_entered = 0
      set showmode
      set showcmd
      set scrolloff=5
      Limelight!
    endfunction
    autocmd! User GoyoEnter nested call <SID>goyo_enter()
    autocmd! User GoyoLeave nested call <SID>goyo_leave()
    " " Activate goyo with Markdown files
    " function! s:auto_goyo()
    "   if &ft == 'markdown'
    "     Goyo 120
    "   elseif exists('#goyo')
    "     let bufnr = bufnr('%')
    "     Goyo!
    "     execute 'b '.bufnr
    "   endif
    " endfunction

" ## vim-qf
  " nmap qp <Plug>qf_qf_previous
  " nmap qn <Plug>qf_qf_next
  " nmap qc <Plug>qf_qf_stay_toggle

" ## golden-ratio
  let g:golden_ratio_exclude_nonmodifiable = 1
  let g:golden_ratio_wrap_ignored = 0
  let g:golden_ratio_ignore_horizontal_splits = 1

" ## auto-pairs
  let g:AutoPairsShortcutToggle = ''
  let g:AutoPairsMapCR = 0 " https://www.reddit.com/r/neovim/comments/4st4i6/making_ultisnips_and_deoplete_work_together_nicely/d6m73rh/

" ## vim-sneak
  let g:sneak#label = 1
  let g:sneak#use_ic_scs = 1
  let g:sneak#absolute_dir = 1

" ## quickscope
  let g:qs_enable = 0

" # lexima
  let g:lexima_enable_endwise_rules = 1

" ## ALE
  let g:ale_enabled = 1
  let g:ale_lint_delay = 1000
  let g:ale_sign_column_always = 1
  let g:ale_echo_msg_format = '[%linter%] %s'
  let g:ale_linters = {
        \   'javascript': ['prettier', 'eslint', 'prettier_eslint'],
        \   'javascript.jsx': ['prettier', 'eslint', 'prettier_eslint'],
        \   'css': ['prettier'],
        \   'scss': ['prettier'],
        \   'json': ['prettier'],
        \   'ruby': []
        \ }                                                                       "Lint js with eslint
  "   'typescript': ['prettier', 'eslint', 'prettier_eslint', 'tsserver', 'tslint', 'typecheck'],
  "   'typescriptreact': ['prettier', 'eslint', 'prettier_eslint', 'tsserver', 'tslint', 'typecheck'],
  "   'typescript.tsx': ['prettier', 'eslint', 'prettier_eslint', 'tsserver', 'tslint', 'typecheck'],
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

" ## vim-js-file-import
  " let g:js_file_import_no_mappings = 1

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
  " let g:nvim_typescript#max_completion_detail=100
  let g:nvim_typescript#completion_mark=''
  let g:nvim_typescript#default_mappings=0
  " " let g:nvim_typescript#type_info_on_hold=1
  let g:nvim_typescript#javascript_support=1
  " let g:nvim_typescript#vue_support=1
  autocmd FileType typescript,typescriptreact,typescript.tsx nnoremap <f2> :TSRename<CR>
  autocmd FileType typescript,typescriptreact,typescript.tsx nnoremap <f3> :TSDefPreview<CR>
  autocmd FileType typescript,typescriptreact,typescript.tsx nnoremap <f8> :TSDef<CR>
  autocmd FileType typescript,typescriptreact,typescript.tsx nnoremap <f9> :TSDoc<CR>
  autocmd FileType typescript,typescriptreact,typescript.tsx nnoremap <f10> :TSType<CR>
  autocmd FileType typescript,typescriptreact,typescript.tsx nnoremap <leader>K :TSType<CR>
  " autocmd FileType typescript,typescriptreact,typescript.tsx nnoremap <f11> :TSRefs<CR>
  " autocmd FileType typescript,typescriptreact,typescript.tsx nnoremap <f12> :TSTypeDef<CR>
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

" ## JSDoc
" https://github.com/heavenshell/vim-jsdoc#configuration
  let g:jsdoc_allow_input_prompt=1
  let g:jsdoc_input_description=1
  let g:jsdoc_enable_es6 = 1
  let g:jsdoc_access_descriptions=2
  let g:jsdoc_additional_descriptions=1

" ## colorizer
  let g:colorizer_auto_filetype='css,scss'
  let g:colorizer_colornames = 1

" ## rainbow_parentheses.vim
  let g:rainbow#max_level = 8
  let g:rainbow#pairs = [['(', ')'], ['[', ']'], ['{', '}']]
  let g:rainbow_levels = [
      \{'ctermfg': 84,  'guifg': '#50fa7b'},
      \{'ctermfg': 117, 'guifg': '#8be9fd'},
      \{'ctermfg': 61,  'guifg': '#6272a4'},
      \{'ctermfg': 212, 'guifg': '#ff79c6'},
      \{'ctermfg': 203, 'guifg': '#ffb86c'},
      \{'ctermfg': 228, 'guifg': '#f1fa8c'},
      \{'ctermfg': 15,  'guifg': '#f8f8f2'},
      \{'ctermfg': 231, 'guifg': '#525563'}]

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
  let test#ruby#rspec#executable = 'bin/rspec --format doc --no-color'
  let g:test#runner_commands = ['Jest', 'RSpec', 'Cypress']

" ## FZF
  let g:fzf_buffers_jump = 1
  let g:fzf_filemru_bufwrite = 1
  let g:fzf_layout = { 'down': '~25%' }
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
  elseif executable("ag")
    " ## ag
    " Note we extract the column as well as the file and line number
    set grepprg=ag\ --nogroup\ --nocolor\ --column
    set grepformat=%f:%l:%c%m
    " Have the silver searcher ignore all the same things as wilgignore
    let b:ag_command = 'ag %s -i --nogroup'
    let g:ag_prg = 'ag %s -i --nogroup'
    for i in split(&wildignore, ",")
      let i = substitute(i, '\*/\(.*\)/\*', '\1', 'g')
      let b:ag_command = b:ag_command . ' --ignore "' . substitute(i, '\*/\(.*\)/\*', '\1', 'g') . '"'
    endfor
    let b:ag_command = b:ag_command . ' --hidden -g ""'
    let g:ctrlp_user_command = b:ag_command
  endif

" ## gist.vim
  let g:gist_open_url = 1
  let g:gist_default_private = 1

" ## ultisnips
  let g:UltiSnipsExpandTrigger		= "<c-e>"
  " let g:UltiSnipsExpandTrigger		= "<Plug>(ultisnips_expand)"
  let g:UltiSnipsJumpForwardTrigger	= "<tab>"
  let g:UltiSnipsJumpBackwardTrigger	= "<s-tab>"
  let g:UltiSnipsRemoveSelectModeMappings = 0
  let g:UltiSnipsSnippetDirectories=['UltiSnips']

" ## LanguageClient
  let g:LanguageClient_diagnosticsList = v:null
  let g:LanguageClient_diagnosticsEnable = 1
  let g:LanguageClient_autoStart = 1 " Automatically start language servers.
  let g:LanguageClient_autoStop = 0
  let g:LanguageClient_loadSettings = 1
  let g:LanguageClient_loggingLevel = 'INFO'
  " Don't populate lists since it overrides Neomake lists
  " try
  "   let g:LanguageClient_diagnosticsList = v:null
  " catch
  "   let g:LanguageClient_diagnosticsList = ''
  " endtry

  " PREFER nvim-typescript for most things, as it's faster
  augroup LanguageClientConfig
    autocmd!
    " " <leader>ld to go to definition
    " autocmd FileType javascript,javascript.jsx,python,json,css,less,html nnoremap <silent> <leader>ld :call LanguageClient_textDocument_definition()<CR>
    " " <leader>lf to autoformat document
    " autocmd FileType javascript,javascript.jsx,python,json,css,less,html nnoremap <silent> <leader>lf :call LanguageClient_textDocument_formatting()<CR>
    " " <leader>lh for type info under cursor
    " autocmd FileType javascript,javascript.jsx,python,json,css,less,html nnoremap <silent> <leader>lh :call LanguageClient_textDocument_hover()<CR>
    " " <leader>lr to rename variable under cursor
    " autocmd FileType javascript,javascript.jsx,python,json,css,less,html nnoremap <silent> <leader>lr :call LanguageClient_textDocument_rename()<CR>
    " autocmd FileType javascript,javascript.jsx,python,json,css,less,html nnoremap <silent> <F2> :call LanguageClient_textDocument_rename()<CR>
    " " <leader>lc to switch omnifunc to LanguageClient
    " autocmd FileType javascript,javascript.jsx,python,json,css,less,html nnoremap <silent> <leader>lc :setlocal omnifunc=LanguageClient#complete<CR>
    " " <leader>ls to fuzzy find the symbols in the current document
    " autocmd FileType javascript,javascript.jsx,python,json,css,less,html nnoremap <silent> <leader>ls :call LanguageClient_textDocument_documentSymbol()<CR>
    " autocmd FileType javascript,javascript.jsx,python,json,css,less,html nnoremap <silent> <leader>@ :call LanguageClient_textDocument_documentSymbol()<CR>
    " autocmd FileType javascript,javascript.jsx,python,json,css,less,html nnoremap <silent> <leader># :call LanguageClient_workspace_symbol()<CR>
    " " Use as omnifunc by default
    autocmd FileType javascript,javascript.jsx,python,json,css,less,html setlocal omnifunc=LanguageClient#complete
  augroup END
  let g:LanguageClient_serverCommands = {}
  if executable('pyls')
    let g:LanguageClient_serverCommands.python = ['pyls']
  endif
  if executable('javascript-typescript-stdio')
    let g:LanguageClient_serverCommands.javascript = ['javascript-typescript-stdio']
    let g:LanguageClient_serverCommands['javascript.jsx'] = ['javascript-typescript-stdio']
    " let g:LanguageClient_serverCommands.typescript = ['javascript-typescript-stdio']
    " let g:LanguageClient_serverCommands.typescriptreact = ['javascript-typescript-stdio']
    " let g:LanguageClient_serverCommands['typescript.tsx'] = ['javascript-typescript-stdio']
  endif
  if executable('css-languageserver')
    let g:LanguageClient_serverCommands.css = ['css-languageserver', '--stdio']
    let g:LanguageClient_serverCommands.less = ['css-languageserver', '--stdio']
    let g:LanguageClient_serverCommands.scss = ['css-languageserver', '--stdio']
    let g:LanguageClient_serverCommands.sass = ['css-languageserver', '--stdio']
  endif
  if executable('html-languageserver')
    let g:LanguageClient_serverCommands.html = ['html-languageserver', '--stdio']
  endif
  if executable('json-languageserver')
    let g:LanguageClient_serverCommands.json = ['json-languageserver', '--stdio']
  endif
  if executable('language_server-ruby')
    let g:LanguageClient_serverCommands.ruby = ['language_server-ruby']
  endif
  if executable('solargraph')
    let g:LanguageClient_serverCommands.ruby = ['tcp://localhost:7658']
  endif
  " Signs and highlighting for errors, etc. TODO: move this elsewhere and fix
  " up. ref: https://github.com/euclio/vimrc/blob/master/plugins.vim
  let s:error_sign = '⨉'
  let s:error_sign_hl = 'DiagnosticErrorSign'
  let s:error_hl = 'DiagnosticError'
  let s:warning_sign = '♦'
  let s:warning_sign_hl = 'DiagnosticWarningSign'
  let s:warning_hl = 'DiagnosticWarning'
  let s:message_sign = '→'
  let s:message_sign_hl = 'DiagnosticMessageSign'
  let s:message_hl = 'DiagnosticMessage'
  let s:info_sign = '…'
  let s:info_sign_hl = s:message_sign_hl
  let s:info_hl = s:message_hl
  " let g:LanguageClient_diagnosticsDisplay = v:null
  " let g:LanguageClient_diagnosticsDisplay = {
  "       \  1: {
  "       \    'name': 'Error',
  "       \    'texthl': s:error_hl,
  "       \    'signText': s:error_sign,
  "       \    'signTexthl': s:error_sign_hl,
  "       \  },
  "       \  2: {
  "       \    'name': 'Warning',
  "       \    'texthl': s:warning_hl,
  "       \    'signText': s:warning_sign,
  "       \    'signTexthl': s:warning_sign_hl,
  "       \  },
  "       \  3: {
  "       \    'name': 'Information',
  "       \    'texthl': s:info_hl,
  "       \    'signText': s:info_sign,
  "       \    'signTexthl': s:info_sign_hl,
  "       \  },
  "       \  4: {
  "       \    'name': 'Hint',
  "       \    'texthl': s:message_hl,
  "       \    'signText': s:message_sign,
  "       \    'signTexthl': s:message_sign_hl,
  "       \  },
  "       \ }


" ## deoplete
  " REFS:
  " https://github.com/roflcopter4/PersonalDotFiles/blob/master/.Vim/deoplete.vim
  " https://github.com/CameronDiver/dotfiles/blob/master/.SpaceVim/config/plugins/deoplete.vim
  let g:deoplete#enable_at_startup = 1
  let g:deoplete#auto_complete_delay = 0
  let g:echodoc_enable_at_startup=1
  set splitbelow
  set completeopt+=noselect,menuone
  set completeopt-=preview

  function! Multiple_cursors_before()
    let b:deoplete_disable_auto_complete=2
  endfunction
  function! Multiple_cursors_after()
    let b:deoplete_disable_auto_complete=0
  endfunction
  let g:deoplete#file#enable_buffer_path=1
  call deoplete#custom#source('buffer', 'mark', 'B')
  " call deoplete#custom#source('tern', 'mark', '')
  " call deoplete#custom#source('ternjs', 'mark', '')
  call deoplete#custom#source('omni', 'mark', '⌾')
  call deoplete#custom#source('file', 'mark', '')
  call deoplete#custom#source('ultisnips', 'mark', '')
  call deoplete#custom#source('typescript', 'mark', '')
  call deoplete#custom#source('LanguageClient', 'mark', 'LC')
  call deoplete#custom#source('ultisnips', 'rank', 9999)
  call deoplete#custom#source('typescript', 'rank', 1000)
  " call deoplete#custom#source('tern', 'rank', 1000)
  " call deoplete#custom#source('ternjs', 'rank', 1000)
  call deoplete#custom#source('LanguageClient', 'rank', 750)
  call deoplete#custom#source('ultisnips', 'matchers', ['matcher_fuzzy'])
  let g:deoplete#omni_patterns = {}
  let g:deoplete#omni_patterns.html = ''
  let g:deoplete#omni_patterns.css = ''
  let g:deoplete#omni_patterns.lua = get(g:deoplete#omni_patterns, 'lua', '.')
  let g:deoplete#omni#input_patterns = {}
  let g:deoplete#omni#input_patterns.gitcommit = get(g:deoplete#omni#input_patterns, 'gitcommit', [
        \'[ ]#[ 0-9a-zA-Z]*',
        \])
  function! Preview_func()
    if &pvw
      setlocal nonumber norelativenumber
     endif
  endfunction
  autocmd WinEnter * call Preview_func()
  let g:deoplete#ignore_sources = {}
  let g:deoplete#ignore_sources._ = ['around']
  " let g:deoplete#ignore_sources.typescript = get(g:deoplete#ignore_sources, 'typescript', ['LanguageClient'])
  " let g:deoplete#ignore_sources.typescriptreact = get(g:deoplete#ignore_sources, 'typescriptreact', ['LanguageClient'])
  " let g:deoplete#ignore_sources.gitcommit = get(g:deoplete#ignore_sources, 'gitcommit', ['ultisnips'])

  " let g:deoplete#enable_debug = 1
  " let g:deoplete#enable_profile = 1
  " let g:deoplete#enable_logging = {'level': 'DEBUG','logfile': 'deoplete.log'}
  " call deoplete#enable_logging('DEBUG', 'deoplete.log')
  " call deoplete#custom#source('typescript', 'debug_enabled', 1)
  " call deoplete#custom#source('typescriptreact', 'debug_enabled', 1)

" coc.nvim
  let g:coc_timeout = 300
  let g:coc_ignore_git_ignore = 0
  let g:coc_use_noselect = 1
  let g:coc_chars_guifg = '#ffffff'
  let g:coc_chars_guibg = '#b180a4'
  let g:coc_increment_highlight = 1
  let g:coc_source_config = {
        \  'languageclient': {
        \    'filetypes': ['wxml', 'vue'],
        \    'disabled': 0,
        \  },
        \  'omni': {
        \    'filetypes': ['css', 'html', 'wxss'],
        \  },
        \  'file': {
        \    'ignorePatterns': ['*.bundle.js'],
        \  },
        \  'tern': {
        \    'ternRoot': expand('~/lib/tern'),
        \  },
        \  'jedi': {
        \    'settings': {
        \       'dynamic_params': v:true,
        \       'dynamic_params_for_other_modules': v:true
        \    },
        \  },
        \}

" ## tagbar
  let g:tagbar_sort = 0
  let g:tagbar_compact = 1
  let tagbar_type_css = {
      \ 'ctagsbin' : 'ctags',
      \ 'ctagsargs' : '--file-scope=yes -o - ',
      \ 'kinds' : [
          \ 'c:classes:1:0',
          \ 'i:ids:1:0',
          \ 't:tags:1:0',
          \ 's:selectors:1:0',
      \ ],
  \ }

  let tagbar_type_scss = {
      \ 'ctagsbin' : 'ctags',
      \ 'ctagsargs' : '--file-scope=yes -o - ',
      \ 'kinds' : [
          \ 'v:variables:1:0',
          \ 'm:mixins:1:0',
          \ 'c:classes:1:0',
          \ 'i:ids:1:0',
          \ 't:tags:1:0',
      \ ],
  \ }

  let g:tagbar_type_typescript = {
    \ 'ctagstype': 'typescript',
    \ 'kinds': [
      \ 'c:classes',
      \ 'n:modules',
      \ 'f:functions',
      \ 'v:variables',
      \ 'v:varlambdas',
      \ 'a:abstract classes',
      \ 'm:members',
      \ 'i:interfaces',
      \ 'e:enums',
    \ 'p:properties',
    \ ]
  \ }

" }}}
" ================ Custom Mappings ======================== {{{

" - deoplete + ultisnips
function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~ '\s'
endfunction

inoremap <expr> <Tab> pumvisible() ? "\<C-n>" : "\<Tab>"
inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"
inoremap <expr> <CR> pumvisible() ? "\<C-y>" : "\<CR>"
" ultisnips
inoremap <C-e> <C-R>=SnipComplete()<CR>

" - coc
" inoremap <silent><expr> <TAB>
"       \ pumvisible() ? "\<C-n>" :
"       \ <SID>check_back_space() ? "\<TAB>" :
"       \ coc#refresh()

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

nnoremap <C-s> :call SCRatchOpen()<CR>

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

" Insert mode movements
" Ctrl-e: Go to end of line
" inoremap <c-e> <esc>A
" Ctrl-a: Go to begin of line
" inoremap <c-a> <esc>I

cnoremap <C-a> <Home>
cnoremap <C-e> <End>


" }}}
" ================ Highlights and Colors ======================== {{{
  hi htmlArg cterm=italic gui=italic
  hi xmlAttrib cterm=italic gui=italic
  hi Type cterm=italic gui=italic
  hi Normal ctermbg=none guibg=NONE
  hi Comment cterm=italic term=italic gui=italic
  hi LineNr guibg=#3C4C55 guifg=#937f6e gui=NONE
  hi CursorLineNr ctermbg=black ctermfg=223 cterm=NONE guibg=#333333 guifg=#db9c5e gui=bold
  hi qfLineNr ctermbg=black ctermfg=95 cterm=NONE guibg=black guifg=#875f5f gui=NONE
  hi Search gui=underline term=underline cterm=underline ctermfg=232 ctermbg=230 guibg=#afaf87 guifg=#333333
  hi QuickFixLine term=bold,underline cterm=bold,underline gui=bold,underline

  " Some custom spell-checking colors
  "highlight SpellBad   term=underline cterm=underline ctermbg=NONE ctermfg=205
  hi clear SpellBad

  " highlight conflicts
  match ErrorMsg '^\(<\|=\|>\)\{7\}\([^=].\+\)\?$'

  hi SpellBad   term=underline cterm=underline gui=underline ctermfg=red guifg=#ff2929 guibg=NONE
  hi SpellCap   term=underline cterm=underline gui=underline ctermbg=NONE ctermfg=33
  hi SpellRare  term=underline cterm=underline gui=underline ctermbg=NONE ctermfg=217
  hi SpellLocal term=underline cterm=underline gui=underline ctermbg=NONE ctermfg=72

  " Markdown could be more fruit salady
  hi link markdownH1 PreProc
  hi link markdownH2 PreProc
  hi link markdownLink Character
  hi link markdownBold String
  hi link markdownItalic Statement
  hi link markdownCode Delimiter
  hi link markdownCodeBlock Delimiter
  hi link markdownListMarker Todo

  " Configure how vim-lsc highlights errors.
  hi lscDiagnosticError term=none ctermbg=none cterm=undercurl ctermfg=red gui=undercurl guisp=#ff2929
  hi lscDiagnosticWarning term=none ctermbg=none cterm=undercurl ctermfg=magenta gui=undercurl guisp=magenta
  hi lscDiagnosticHint term=none ctermbg=none cterm=undercurl ctermfg=cyan gui=undercurl guisp=cyan
  hi lscDiagnosticInfo term=none ctermbg=none cterm=undercurl ctermfg=grey gui=undercurl guisp=grey

  " hi DiffChange guibg=#444444 ctermbg=238
  " hi DiffText guibg=#777777 ctermbg=244
  " hi DiffAdd guibg=#4f8867 ctermbg=29
  " hi DiffDelete guibg=#870000 ctermbg=88

  hi ALEErrorSign ctermfg=9 ctermbg=15 guifg=#cc6666 guibg=NONE
  hi ALEWarningSign ctermfg=11 ctermbg=15 guifg=#f0c674 guibg=NONE

  hi link ALEError SpellBad
  hi link ALEWarning SpellBad

  hi GitGutterAdd guibg=NONE
  hi GitGutterChange guibg=NONE
  hi GitGutterDelete guibg=NONE
  hi GitGutterChangeDelete guibg=NONE

  " Nord
  hi! RainbowLevel0 ctermbg=240 guibg=#2C3441
  hi! RainbowLevel1 ctermbg=240 guibg=#2E3440
  hi! RainbowLevel2 ctermbg=239 guibg=#252d3d
  hi! RainbowLevel3 ctermbg=238 guibg=#1f293d
  hi! RainbowLevel4 ctermbg=237 guibg=#18243d
  hi! RainbowLevel5 ctermbg=236 guibg=#131f38
  hi! RainbowLevel6 ctermbg=235 guibg=#0f1c38
  hi! RainbowLevel7 ctermbg=234 guibg=#09193a
  hi! RainbowLevel8 ctermbg=233 guibg=#041538
  hi! RainbowLevel9 ctermbg=232 guibg=#001030
" }}}

" vim:foldenable:foldmethod=marker:ft=vim
