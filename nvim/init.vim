" =============================================================================
"
"   ┌┬┐┌─┐┌─┐┌─┐┬  ┬┌┬┐┬ ┬┬┌─┐
"   │││├┤ │ ┬├─┤│  │ │ ├─┤││   :: DOTFILES > vimrc
"   ┴ ┴└─┘└─┘┴ ┴┴─┘┴ ┴ ┴ ┴┴└─┘
"   Brought to you by: Seth Messer / @megalithic
"
" =============================================================================

" ================ Plugins ==================== {{{
call plug#begin( '~/.config/nvim/plugged')

" Plug 'tweekmonster/startuptime.vim', { 'on': [ 'StartupTime' ] } " Show slow plugins

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
  Plug 'ianks/vim-tsx', { 'for': ['typescript', 'typescriptreact', 'typescript.tsx'] }

" # Fn
  " Plug 'ElmCast/elm-vim', { 'for': ['elm'] }
  " Plug 'reasonml-editor/vim-reason-plus', { 'for': ['reason'] }

" # CSS
  Plug 'othree/csscomplete.vim', { 'for': ['css', 'scss', 'sass'] } " css completion
  Plug 'hail2u/vim-css3-syntax', { 'for': ['css', 'scss', 'sass'] } " css3-specific syntax
  Plug 'ap/vim-css-color', { 'for': ['css', 'scss', 'sass'] }
  " Plug 'chrisbra/Colorizer', { 'for': ['css', 'scss', 'sass'] }

" # HTML
  " Plug 'othree/html5.vim', { 'for': ['html', 'haml'] }
  " Plug 'othree/xml.vim', { 'for': ['xml'] }

" # Cfg
  " Plug 'martin-svk/vim-yaml', { 'for': ['yaml'] }

" # MD
  " Plug 'tpope/vim-markdown', { 'for': ['markdown', 'md', 'mdown'] }
  Plug 'jtratner/vim-flavored-markdown', { 'for': ['markdown'] }
  Plug 'tyru/markdown-codehl-onthefly.vim', { 'for': ['markdown', 'md', 'mdown'] }
  Plug 'rhysd/vim-gfm-syntax'
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
  " Plug 'scrooloose/nerdtree'
  " Plug 'Xuyuanp/nerdtree-git-plugin'
  Plug 'ryanoasis/vim-devicons'
  Plug 'christoomey/vim-tmux-navigator' " needed for tmux/hotkey integration with vim
  Plug 'christoomey/vim-tmux-runner' " needed for tmux/hotkey integration with vim
  Plug 'tmux-plugins/vim-tmux-focus-events'
  Plug 'unblevable/quick-scope' " highlights f/t type of motions, for quick horizontal movements
  " Plug 'justinmk/vim-sneak.git' " https://github.com/justinmk/vim-sneak

" ## Completions
  " Plug 'prabirshrestha/asyncomplete.vim'
  " Plug 'prabirshrestha/async.vim'
  " Plug 'prabirshrestha/vim-lsp'
  " Plug 'prabirshrestha/asyncomplete-lsp.vim'
  " Plug 'prabirshrestha/asyncomplete-buffer.vim'
  " Plug 'prabirshrestha/asyncomplete-file.vim'
  " Plug 'prabirshrestha/asyncomplete-tags.vim'
  " Plug 'prabirshrestha/asyncomplete-ultisnips.vim'
  " Plug 'prabirshrestha/asyncomplete-tscompletejob.vim'
  " Plug 'yami-beta/asyncomplete-omni.vim'

  Plug 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' }
  Plug 'Shougo/neoinclude.vim'
  " Plug 'roxma/nvim-completion-manager'
  " Plug 'roxma/nvim-cm-tern',  {'do': 'npm install'}
  " Plug 'calebeby/ncm-css', { 'for': ['scss', 'css', 'sass', 'less'] }
  " Plug 'roxma/ncm-rct-complete'
  Plug 'Shougo/echodoc.vim'
  Plug 'mhartington/nvim-typescript', { 'for': ['typescript', 'typescriptreact', 'typescript.tsx'], 'do': ':UpdateRemotePlugins' }

" ## Language Servers
  Plug 'autozimu/LanguageClient-neovim', { 'branch': 'next', 'do': 'bash install.sh' }
  " Plug 'natebosch/vim-lsc' " https://github.com/natebosch/vim-lsc/blob/master/doc/lsc.txt

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
  Plug 'drmikehenry/vim-extline' " https://github.com/drmikehenry/vim-extline/blob/master/doc/extline.txt / Ctrl+L Ctrl+L to auto `=` under the visual selection
  " Plug 'Galooshi/vim-import-js' "https://github.com/Galooshi/vim-import-js#default-mappings
  Plug 'janko-m/vim-test', {'on': ['TestFile', 'TestLast', 'TestNearest', 'TestSuite', 'TestVisit'] } " tester for js and ruby

  Plug 'jordwalke/VimAutoMakeDirectory' " auto-makes the dir for you if it doesn't exist in the path
  Plug 'EinfachToll/DidYouMean'
  Plug 'wsdjeg/vim-fetch' " open files at line number
  " Plug 'nelstrom/vim-visual-star-search'
  Plug 'tpope/vim-commentary' " (un)comment code
  " Plug 'shougo/vimproc.vim', { 'do': 'make' } " for rct/rails things?
  " Plug 'xolox/vim-misc' " for lua things
  Plug 'sickill/vim-pasta' " context-aware pasting
  Plug 'zenbro/mirror.vim' " allows mirror'ed editing of files locally, to a specified ssh location via ~/.mirrors
  Plug 'keith/gist.vim', { 'do': 'chmod -HR 0600 ~/.netrc' }

  Plug 'junegunn/rainbow_parentheses.vim' " nicely colors nested pairs of [], (), {}
  Plug 'docunext/closetag.vim' " will auto-close the opening tag as soon as you type </
  Plug 'tpope/vim-ragtag', { 'for': ['html', 'xml', 'erb', 'haml', 'javascript.jsx', 'typescript', 'typescriptreact', 'typescript.tsx', 'javascript'] } " a set of mappings for several langs: html, xml, erb, php, more
  Plug 'tpope/vim-endwise'
  Plug 'Raimondi/delimitMate'
  Plug 'gregsexton/MatchTag', { 'for': ['html', 'javascript.jsx', 'javascript', 'typescript', 'typescriptreact', 'typescript.tsx'] }
  " Plug 'Valloric/MatchTagAlways', { 'for': ['haml', 'html', 'xml', 'erb', 'javascript', 'javascript.jsx', 'typescript', 'typescriptreact', 'typescript.tsx'] } " highlights the opening/closing tags for the block you're in
  Plug 'jiangmiao/auto-pairs'
  Plug 'cohama/lexima.vim' " auto-closes many delimiters and can repeat with a `.`
  Plug 'benjifisher/matchit.zip'
  Plug 'tpope/vim-rhubarb'
  Plug 'tpope/vim-surround' " soon to replace with machakann/vim-sandwich
  Plug 'tpope/vim-repeat'
  Plug 'tpope/vim-fugitive'
  Plug 'junegunn/gv.vim'
  Plug 'sodapopcan/vim-twiggy'
  Plug 'christoomey/vim-conflicted'
  Plug 'tpope/vim-eunuch'

  Plug 'w0rp/ale'
  " Plug 'mattn/emmet-vim', { 'for': ['html', 'css', 'javascript.jsx', 'typescript', 'typescriptreact', 'typescript.tsx'] }
  " Plug 'mhinz/vim-signify'
  " Plug 'airblade/vim-gitgutter'

" ## Movements/Text Objects, et al
  Plug 'kana/vim-operator-user'
  " -- provide ai and ii for indent blocks
  " -- provide al and il for current line
  " -- provide a_ and i_ for underscores
  " -- provide a- and i-
  Plug 'kana/vim-textobj-user'                                                      " https://github.com/kana/vim-textobj-user/wiki
  Plug 'kana/vim-textobj-entire'                                                    " Entire buffer text object (vae)
  Plug 'kana/vim-textobj-function'                                                  " Function text object (vaf)
  Plug 'kana/vim-textobj-indent', { 'on': [ '<Plug>(textobj-indent' ] }             " for indent level (vai)
  Plug 'kana/vim-textobj-line', { 'on': [ '<Plug>(textobj-line' ] }                 " for current line (val)
  Plug 'nelstrom/vim-textobj-rubyblock'                                             " Ruby block text object (vir)
  Plug 'glts/vim-textobj-comment'                                                   " Comment text object (vac)
  Plug 'michaeljsmith/vim-indent-object'
  Plug 'machakann/vim-textobj-delimited', { 'on': [ '<Plug>(textobj-delimited' ] }  " - d/D   for underscore section (e.g. `did` on foo_b|ar_baz -> foo__baz)
  Plug 'gilligan/textobj-lastpaste', { 'on': [ '<Plug>(textobj-lastpaste' ] }       " - P     for last paste
  Plug 'mattn/vim-textobj-url', { 'on': [ '<Plug>(textobj-url' ] }                  " - u     for url
  Plug 'rhysd/vim-textobj-anyblock'
  Plug 'whatyouhide/vim-textobj-xmlattr', { 'on': [ '<Plug>(textobj-xmlattr' ] }    " - x     for xml
  Plug 'wellle/targets.vim'                                                         " Improved targets line cin) next parens
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
  " show results of substition as they're happening
  " but don't open a split
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
  au FileType typescript,typescriptreact,typescript.tsx,javascript,javascript.jsx,sass,scss,scss.css RainbowParentheses " consistently fails *shrug*
  au BufNewFile,BufRead .{babel,eslint,prettier,stylelint,jshint,jscs,postcss}*rc,\.tern-*,*.json set ft=json
  au BufNewFile,BufRead .tern-project set ft=json
  au BufNewFile,BufRead *.tsx set ft=typescriptreact "forces typescript.tsx -> typescriptreact

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
  au BufNewFile,BufRead,BufReadPost *.{md,mdwn,mkd,mkdn,mark*} set nolazyredraw ft=markdown
  au FileType markdown,text,html setlocal spell complete+=kspell
  au FileType markdown set tw=80

  " ----------------------------------------------------------------------------
  " ## Ruby
  au FileType ruby setl iskeyword+=_

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

  au FileType coffee setl omnifunc=javascriptcomplete#CompleteJS
  au FileType javascript,javascript.jsx,jsx setl omnifunc=javascriptcomplete#CompleteJS " default
  au FileType javascript,javascript.jsx,jsx setl completefunc=jspc#omni " jspc
  au FileType javascript,javascript.jsx,jsx setl omnifunc=tern#Complete " tern

  au FileType python setl omnifunc=pythoncomplete#Complete
  au FileType xml setl omnifunc=xmlcomplete#CompleteTags
  au FileType ruby setl omnifunc=rubycomplete#Complete

  " ----------------------------------------------------------------------------
  " ## Fixing/Linting

  " ----------------------------------------------------------------------------
  " ## Toggle certain accoutrements when entering and leaving a buffer & window
  au WinEnter,BufEnter * silent set number relativenumber syntax=on " call :RainbowParentheses  cul
  au WinLeave,BufLeave * silent set nonumber norelativenumber syntax=off " call :RainbowParentheses! nocul

  " ----------------------------------------------------------------------------
  " ## Automagically update remote homeassistant files upon editing locally
  au BufWritePost ~/.dotfiles/private/homeassistant/* silent! :MirrorPush ha

  " ----------------------------------------------------------------------------
  " ## Toggle colorcolumn when in insert mode for visual 80char indicator
  au BufEnter,FocusGained,InsertLeave * silent set relativenumber
  au BufLeave,FocusLost,InsertEnter   * silent set norelativenumber
  au InsertEnter * silent set colorcolumn=80
  au InsertLeave * silent set colorcolumn=""
  " au BufWinEnter * let w:m2=matchadd('ErrorMsg', '\%>81v.\+', -1)

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

  " " Start NERDTree automatically when vim starts up on opening a directory
  " autocmd StdinReadPre * let s:std_in=1
  " autocmd VimEnter * if argc() == 0 && !exists("s:std_in") | NERDTree | endif
  " autocmd VimEnter * if argc() == 1 && isdirectory(argv()[0]) && !exists("s:std_in") | exe 'NERDTree' argv()[0] | wincmd p | ene | endif

  " " Close vim if the only window left open is a NERDTree
  " autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif
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

" augroup language_mappings
"   autocmd!

"   " TypeScript
"   autocmd FileType typescript,typescriptreact,typescript.tsx nnoremap <leader>h :LspHover<cr>
"   autocmd FileType typescript,typescriptreact,typescript.tsx nnoremap <f2> :LspRename<cr>
"   autocmd FileType typescript,typescriptreact,typescript.tsx nnoremap <f8> :LspDocumentDiagnostics<cr>
"   autocmd FileType typescript,typescriptreact,typescript.tsx nnoremap <f10> :LspDocumentSymbol<cr>
"   autocmd FileType typescript,typescriptreact,typescript.tsx nnoremap <f11> :LspReferences<cr>
"   autocmd FileType typescript,typescriptreact,typescript.tsx nnoremap <f12> :LspDefinition<cr>
"   autocmd FileType typescript,typescriptreact,typescript.tsx command! ProjectSearch -nargs=1 vimgrep /<args>/gj ./**/*.ts<cr>

"   " Vim
"   autocmd FileType vim command! ProjectSearch -nargs=1 vimgrep /<args>/gj ./**/*.vim<cr>
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

hi User1 guifg=#FF0000 guibg=#504945 gui=bold
hi User2 guifg=#FFFFFF guibg=#FF1111 gui=bold
hi User3 guifg=#2C323C guibg=#E5C07B gui=bold
" Override statusline as you like
hi fzf1 ctermfg=161 ctermbg=251
hi fzf2 ctermfg=23 ctermbg=251
hi fzf3 ctermfg=237 ctermbg=251
set statusline=\ %{toupper(mode())}                                             "Mode
set statusline+=\ \│\ %{fugitive#head()!=''?'\ \ '.fugitive#head().'\ ':''}    "Git branch
" set statusline+=\ \│\ %{fugitive#head()}                                      "Git branch
set statusline+=%{GitFileStatus()}                                              "Git file status
" set statusline+=\ \│\ %<%{pathshorten(getcwd())}\                             "File path
" set statusline+=\ \│\ %4F                                                     "File path
set statusline+=\ \│\ %{FilepathStatusline()}                                   "File path
set statusline+=\%{FilenameStatusline()}                                        "File name
set statusline+=\ %1*%m%*                                                       "Modified indicator
set statusline+=\ %w                                                            "Preview indicator
set statusline+=%{&readonly?'\ ':''}                                           "Read only indicator
" set statusline+=\ %r                                                          "Read only indicator
set statusline+=\ %q                                                            "Quickfix list indicator
set statusline+=\ %=                                                            "Start right side layout
set statusline+=\ %{&enc}                                                       "Encoding
set statusline+=\ \│\ %{WebDevIconsGetFileTypeSymbol()}                         "DevIcon/Filetype
" set statusline+=\ \│\ %{WebDevIconsGetFileTypeSymbol()}\ %{&filetype}         "Filetype
" set statusline+=\ \│\ %y                                                      "Filetype
set statusline+=\ \│\ %p%%                                                      "Percentage
set statusline+=\ \│\ %c                                                        "Column number
set statusline+=\ \│\ %l/%L                                                     "Current line number/Total line numbers
" set statusline+=\ \│\ %#fzf1#\ >\ %#fzf2#fz%#fzf3#f                              "FZF
" set statusline+=\ %{gutentags#statusline('\│\ ')}                               "Tags status
set statusline+=\ %2*%{AleStatusline('error')}%*                                "Errors count
set statusline+=%3*%{AleStatusline('warning')}%*                                "Warning count

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

" }}}
" ================ Functions ======================== {{{

" Keybinding for visiting the GitHub page of the plugin defined on the current line
autocmd FileType vim nnoremap <silent> <leader>op :call OpenPluginHomepage()<CR>
function! OpenPluginHomepage()
  " Get line under cursor
  let line = getline(".")

  " Matches for instance Plug 'tpope/surround' -> tpope/surround
  " Greedy match in order to not capture trailing comments
  let plugin_name = '\w\+ \([''"]\)\(.\{-}\)\1'
  let repository = matchlist(line, plugin_name)[2]

  " Open the corresponding GitHub homepage with $BROWSER
  " You need to set the BROWSER environment variable in order for this to work
  " For MacOS, you can set the following for opening it in your default
  " browser: 'export BROWSER=open'
  silent exec "!$BROWSER https://github.com/".repository
endfunction

" Scratch buffer
function! ScratchOpen()
  let scr_bufnr = bufnr('__scratch__')
  if scr_bufnr == -1
    vnew
    setlocal filetype=markdown
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
endfun

function! FilenameStatusline() abort
  let fn = !empty(expand('%:t'))
        \ ? expand('%:p:t')
        \ : '[No Name]'
  return fn . (&readonly ? ' ' : '')
endfun

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

function! CloseBuffer() abort
  if &buftype ==? 'quickfix'
    bd
    return 1
  endif
  " let l:nerdtreeOpen = g:NERDTree.IsOpen()
  let l:windowCount = winnr('$')
  let l:command = 'bd'
  let l:totalBuffers = len(getbufinfo({ 'buflisted': 1 }))
  " let l:isNerdtreeLast = l:nerdtreeOpen && l:windowCount ==? 2
  " let l:noSplits = !l:nerdtreeOpen && l:windowCount ==? 1
  " if l:totalBuffers > 1 && (l:isNerdtreeLast || l:noSplits)
  "   let l:command = 'bp|bd#'
  " endif
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


" }}}
" ================ Plugin Config/Settings ======================== {{{

" ## polyglot
  let g:polyglot_disabled = ['typescript', 'graphql', 'jsx']

" ## vim-devicons
  " let g:NERDTreeGitStatusNodeColorization = 1
  " 
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

" ## goyo
  " let g:goyo_width = 80
  " let g:goyo_height = '100%'
  " let g:goyo_margin_top = 3
  " let g:goyo_margin_bottom = 3
  " Writing in vim {{{{
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

" " ## NERDtree
"   let g:NERDTreeChDirMode = 2                                                     "Always change the root directory
"   let g:NERDTreeMinimalUI = 1                                                     "Disable help text and bookmark title
"   let g:NERDTreeShowHidden = 1                                                    "Show hidden files in NERDTree
"   let g:NERDTreeUpdateOnCursorHold = 0                                            "Disable nerdtree git plugin updating on cursor hold

" ## vim-sneak
  let g:sneak#label = 1
  let g:sneak#use_ic_scs = 1
  let g:sneak#absolute_dir = 1

" ## quickscope
  let g:qs_enable = 0

" ## emmet
  " let g:user_emmet_leader_key = '<c-e>'                                           "Change trigger emmet key
  " let g:user_emmet_leader_key='<Tab>'
  " let g:user_emmet_settings = {
  "       \  'javascript.jsx' : {
  "       \      'extends' : 'jsx',
  "       \  },
  "       \}

" # delimitMate
  let g:delimitMate_expand_cr = 2                                                 "Auto indent on enter

" ## ALE
  let g:ale_enabled = 1
  let g:ale_lint_delay = 100
  let g:ale_sign_column_always = 1
  let g:ale_echo_msg_format = '[%linter%] %s'
  let g:ale_linters = {
        \   'javascript': ['prettier', 'eslint', 'prettier_eslint'],
        \   'javascript.jsx': ['prettier', 'eslint', 'prettier_eslint'],
        \   'typescript': ['prettier', 'eslint', 'prettier_eslint'],
        \   'typescriptreact': ['prettier', 'eslint', 'prettier_eslint'],
        \   'typescript.tsx': ['prettier', 'eslint', 'prettier_eslint'],
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

" ## vim-js-file-import
  " let g:js_file_import_no_mappings = 1

" ## vim-markdown
  let g:vim_markdown_frontmatter = 1
  let g:vim_markdown_toc_autofit = 1
  let g:markdown_fenced_languages = [
                          \ 'javascript',
                          \ 'typescript',
                          \ 'json',
                          \ 'python',
                          \ 'html',
                          \ 'bash=sh']

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
  autocmd FileType typescript,typescriptreact,typescript.tsx nnoremap <f2> :TSRename<cr>
  autocmd FileType typescript,typescriptreact,typescript.tsx nnoremap <f3> :TSDefPreview<cr>
  autocmd FileType typescript,typescriptreact,typescript.tsx nnoremap <f8> :TSDef<cr>
  autocmd FileType typescript,typescriptreact,typescript.tsx nnoremap <f9> :TSDoc<cr>
  autocmd FileType typescript,typescriptreact,typescript.tsx nnoremap <f10> :TSType<cr>
  autocmd FileType typescript,typescriptreact,typescript.tsx nnoremap <leader>K :TSType<cr>
  " autocmd FileType typescript,typescriptreact,typescript.tsx nnoremap <f11> :TSRefs<cr>
  " autocmd FileType typescript,typescriptreact,typescript.tsx nnoremap <f12> :TSTypeDef<cr>
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
  let g:colorizer_colornames = 0

" ## rainbow_parentheses.vim
  let g:rainbow#max_level = 16
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
  let test#ruby#bundle_exec = 1

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
    " command! -bang -nargs=* Rg
    "       \ call fzf#vim#grep(
    "       \   'rg --column --line-number --no-heading --color=always --glob "!.git/*" '.shellescape(<q-args>), 1,
    "       \   <bang>0 ? fzf#vim#with_preview('up:60%')
    "       \           : fzf#vim#with_preview('right:50%:hidden', '?'),
    "       \   <bang>0)
    " command! -bang -nargs=* Rg
    "       \ call fzf#vim#grep(
    "       \   'rg --column --line-number --ignore-case --no-heading --no-messages --hidden --color=always '
    "       \   . <q-args>, 1,
    "       \   <bang>0 ? fzf#vim#with_preview('up:60%')
    "       \           : fzf#vim#with_preview('right:50%:hidden', '?'),
    "       \   <bang>0)
    command! -bang -nargs=? -complete=dir Files
          \ call fzf#vim#files(<q-args>,
          \   <bang>0 ? fzf#vim#with_preview('up:60%')
          \           : fzf#vim#with_preview('right:50%', '?'),
          \   <bang>0)
    " command! -bang -nargs=* Find
    "       \ call fzf#vim#grep('rg --column --line-number --no-heading --fixed-strings --ignore-case --no-ignore --hidden --follow --glob "!.git/*" --color "always" '.shellescape(<q-args>).'| tr -d "\017"',
    "       \   1,
    "       \   <bang>0)

    " command! -bang -nargs=* F
    "       \ call fzf#vim#grep(
    "       \   'rg --column --line-number --no-heading --glob "!.git/*" --color=always '.shellescape(<q-args>), 1,
    "       \   <bang>0 ? fzf#vim#with_preview('up:60%')
    "       \           : fzf#vim#with_preview('right:50%:hidden', '?'),
    "       \   <bang>0)
  endif

" ## ag
  if executable("ag")
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


" ## neosnippet
  " let g:neosnippet#enable_completed_snippet = 1
  " let g:neosnippet#enable_snipmate_compatibility = 1
  " " let g:neosnippet#snippets_directory='~/GitHub/ionic-snippets'
  " let g:neosnippet#expand_word_boundary = 1


" ## LanguageClient
  let g:LanguageClient_diagnosticsList = v:null
  let g:LanguageClient_autoStart = 1 " Automatically start language servers.
  let g:LanguageClient_loadSettings = 0
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
    " autocmd FileType javascript,javascript.jsx,python,json,css,less,html nnoremap <silent> <leader>ld :call LanguageClient_textDocument_definition()<cr>
    " " <leader>lf to autoformat document
    " autocmd FileType javascript,javascript.jsx,python,json,css,less,html nnoremap <silent> <leader>lf :call LanguageClient_textDocument_formatting()<cr>
    " " <leader>lh for type info under cursor
    " autocmd FileType javascript,javascript.jsx,python,json,css,less,html nnoremap <silent> <leader>lh :call LanguageClient_textDocument_hover()<cr>
    " " <leader>lr to rename variable under cursor
    " autocmd FileType javascript,javascript.jsx,python,json,css,less,html nnoremap <silent> <leader>lr :call LanguageClient_textDocument_rename()<cr>
    " autocmd FileType javascript,javascript.jsx,python,json,css,less,html nnoremap <silent> <F2> :call LanguageClient_textDocument_rename()<cr>
    " " <leader>lc to switch omnifunc to LanguageClient
    " autocmd FileType javascript,javascript.jsx,python,json,css,less,html nnoremap <silent> <leader>lc :setlocal omnifunc=LanguageClient#complete<cr>
    " " <leader>ls to fuzzy find the symbols in the current document
    " autocmd FileType javascript,javascript.jsx,python,json,css,less,html nnoremap <silent> <leader>ls :call LanguageClient_textDocument_documentSymbol()<cr>
    " autocmd FileType javascript,javascript.jsx,python,json,css,less,html nnoremap <silent> <leader>@ :call LanguageClient_textDocument_documentSymbol()<cr>
    " autocmd FileType javascript,javascript.jsx,python,json,css,less,html nnoremap <silent> <leader># :call LanguageClient_workspace_symbol()<cr>
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
    let g:LanguageClient_serverCommands.typescript = ['javascript-typescript-stdio']
    let g:LanguageClient_serverCommands.typescriptreact = ['javascript-typescript-stdio']
    let g:LanguageClient_serverCommands['typescript.tsx'] = ['javascript-typescript-stdio']
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


" ## vim-lsc
  " let g:lsc_enable_autocomplete = v:true
  " let g:lsc_auto_map = v:true
  " let g:lsc_preview_split_direction = 'below'
  " let g:lsc_enable_apply_edit = v:true
  " let g:lsc_enable_incremental_sync = v:true
  " let g:lsc_server_commands = {}
  " if executable('pyls')
  "   let g:lsc_server_commands.python = 'pyls'
  " endif
  " if executable('go-langserver')
  "   let g:lsc_server_commands.go = 'go-langserver'
  " endif
  " if executable('lua-lsp')
  "   let g:lsc_server_commands.lua = 'lua-lsp'
  " endif
  " if executable('dart_language_server')
  "   let g:lsc_server_commands.dart = 'dart_language_server'
  " endif
  " if executable('javascript-typescript-stdio')
  "   let g:lsc_server_commands.javascript = 'javascript-typescript-stdio'
  "   let g:lsc_server_commands['javascript.jsx'] = 'javascript-typescript-stdio'
  "   let g:lsc_server_commands.typescript = 'javascript-typescript-stdio'
  "   let g:lsc_server_commands.typescriptreact = 'javascript-typescript-stdio'
  "   let g:lsc_server_commands['typescript.tsx'] = 'javascript-typescript-stdio'
  " endif
  " if executable('css-languageserver')
  "   let g:lsc_server_commands.css = 'css-languageserver --stdio'
  "   let g:lsc_server_commands.less = 'css-languageserver --stdio'
  "   let g:lsc_server_commands.scss = 'css-languageserver --stdio'
  "   let g:lsc_server_commands.sass = 'css-languageserver --stdio'
  " endif
  " if executable('html-languageserver')
  "   let g:lsc_server_commands.html = 'html-languageserver --stdio'
  " endif
  " if executable('json-languageserver')
  "   let g:lsc_server_commands.json = 'json-languageserver --stdio'
  " endif
  " if executable('language_server-ruby')
  "   let g:lsc_server_commands.ruby = 'language_server-ruby'
  " endif
  " autocmd FileType javascript,javascript.jsx,python,typescript,typescriptreact,typescript.tsx,json,css,less,html setlocal omnifunc=lsc#complete

" ## asyncomplete.vim/asynccomplete/vim-lsp
  " let g:asyncomplete_auto_popup = 1
  " let g:asyncomplete_remove_duplicates = 0
  " let g:asyncomplete_smart_completion = 1
  " let g:asyncomplete_min_chars = 2
  " let g:lsp_signs_enabled = 1         " enable signs
  " let g:lsp_diagnostics_echo_cursor = 1 " enable echo under cursor when in normal mode
  " let g:lsp_signs_error = {'text': '⤫'}
  " let g:lsp_signs_warning = {'text': '~'}
  " let g:lsp_signs_hint = {'text': '?'}
  " " let g:lsp_signs_warning = {'text': '~', 'icon': '/path/to/some/icon'} " icons require GUI
  " " let g:lsp_signs_hint = {'icon': '/path/to/some/other/icon'} " icons require GUI
  " " let g:lsp_log_verbose = 0
  " " let g:lsp_log_file = expand('~/.config/nvim/vim-lsp.log')
  " let g:asyncomplete_log_file = expand('~/.config/nvim/asyncomplete.log')
  " set completeopt+=preview
  " if has('python3')
  "   let g:UltiSnipsExpandTrigger="<c-e>"
  "   au User asyncomplete_setup call asyncomplete#register_source(asyncomplete#sources#ultisnips#get_source_options({
  "         \ 'name': 'ultisnips',
  "         \ 'whitelist': ['*'],
  "         \ 'completor': function('asyncomplete#sources#ultisnips#completor'),
  "         \ }))
  " endif
  " au User asyncomplete_setup call asyncomplete#register_source(asyncomplete#sources#buffer#get_source_options({
  "       \ 'name': 'buffer',
  "       \ 'whitelist': ['*'],
  "       \ 'blacklist': ['go'],
  "       \ 'completor': function('asyncomplete#sources#buffer#completor'),
  "       \ }))
  " au User asyncomplete_setup call asyncomplete#register_source(asyncomplete#sources#file#get_source_options({
  "       \ 'name': 'file',
  "       \ 'whitelist': ['*'],
  "       \ 'blacklist': ['typescript', 'javascript', 'javascript.js'],
  "       \ 'priority': 10,
  "       \ 'completor': function('asyncomplete#sources#file#completor')
  "       \ }))
  " if executable('ctags')
  "   au User asyncomplete_setup call asyncomplete#register_source(asyncomplete#sources#tags#get_source_options({
  "       \ 'name': 'tags',
  "       \ 'whitelist': ['typescript', 'javascript', 'javascript.jsx'],
  "       \ 'completor': function('asyncomplete#sources#tags#completor'),
  "       \ 'config': {
  "       \    'max_file_size': 150000000,
  "       \  },
  "       \ }))
  " endif
  " au User asyncomplete_setup call asyncomplete#register_source(asyncomplete#sources#omni#get_source_options({
  "       \ 'name': 'omni',
  "       \ 'whitelist': ['*'],
  "       \ 'blacklist': ['c', 'cpp', 'html'],
  "       \ 'completor': function('asyncomplete#sources#omni#completor')
  "       \  }))
  " au User asynccomplete_setup call asyncomplete#register_source(asyncomplete#sources#tscompletejob#get_source_options({
  "       \ 'name': 'tscompletejob',
  "       \ 'whitelist': ['typescript', 'typescriptreact', 'typescript.tsx'],
  "       \ 'completor': function('asyncomplete#sources#tscompletejob#completor'),
  "       \ }))
  " if executable('typescript-language-server')
  "   au User lsp_setup call lsp#register_server({
  "         \ 'name': 'typescript-language-server',
  "         \ 'cmd': {server_info->[&shell, &shellcmdflag, 'typescript-language-server', '--stdio']},
  "         \ 'root_uri':{server_info->lsp#utils#path_to_uri(lsp#utils#find_nearest_parent_file_directory(lsp#utils#get_buffer_path(), 'tsconfig.json'))},
  "         \ 'whitelist': ['typescript', 'typescriptreact', 'typescript.tsx'],
  "         \ })
  " endif
  " if executable('css-languageserver')
  "   au User lsp_setup call lsp#register_server({
  "         \ 'name': 'css-languageserver',
  "         \ 'cmd': {server_info->[&shell, &shellcmdflag, 'css-languageserver --stdio']},
  "         \ 'whitelist': ['css', 'less', 'sass', 'scss'],
  "         \ })
  " endif
  " if executable('ocaml-language-server')
  "   au User lsp_setup call lsp#register_server({
  "         \ 'name': 'ocaml-language-server',
  "         \ 'cmd': {server_info->[&shell, &shellcmdflag, 'ocaml-language-server --stdio']},
  "         \ 'whitelist': ['reason', 'ocaml'],
  "         \ })
  " endif
  " if executable('pyls')
  "   " pip install python-language-server
  "   au User lsp_setup call lsp#register_server({
  "         \ 'name': 'pyls',
  "         \ 'cmd': {server_info->['pyls']},
  "         \ 'whitelist': ['python'],
  "         \ })
  " endif

" ## deoplete
  " call deoplete#enable() " which of these startups are needed?
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
  call deoplete#custom#source('tern', 'mark', '')
  call deoplete#custom#source('omni', 'mark', '⌾')
  call deoplete#custom#source('file', 'mark', '')
  " call deoplete#custom#source('jedi', 'mark', '')
  call deoplete#custom#source('ultisnips', 'mark', '')
  call deoplete#custom#source('typescript', 'mark', '')
  " call deoplete#custom#source('neosnippet', 'mark', '')
  call deoplete#custom#source('LanguageClient', 'mark', 'LC')
  call deoplete#custom#source('typescript', 'rank', 630)
  call deoplete#custom#source('ultisnips', 'rank', 999)
  call deoplete#custom#source('LanguageClient', 'rank', 629)
  call deoplete#custom#source('ultisnips', 'matchers', ['matcher_fuzzy'])
  " let g:deoplete#sources = {}
  let g:deoplete#omni_patterns = {}
  let g:deoplete#omni_patterns.html = ''
  let g:deoplete#omni_patterns.css = ''
  function! Preview_func()
    if &pvw
      setlocal nonumber norelativenumber
     endif
  endfunction
  autocmd WinEnter * call Preview_func()
  let g:deoplete#ignore_sources = {}
  let g:deoplete#ignore_sources._ = ['around']

  " let g:deoplete#enable_debug = 1
  " let g:deoplete#enable_profile = 1
  " let g:deoplete#enable_logging = {'level': 'DEBUG','logfile': 'deoplete.log'}
  " call deoplete#enable_logging('DEBUG', 'deoplete.log')
  " call deoplete#custom#source('typescript', 'debug_enabled', 1)
  " call deoplete#custom#source('typescriptreact', 'debug_enabled', 1)

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
inoremap <expr> <Tab> pumvisible() ? "\<C-n>" : "\<Tab>"
inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"
inoremap <expr> <cr> pumvisible() ? "\<C-y>" : "\<cr>"

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

" Handle syntastic error window
nnoremap <Leader>e :lopen<CR>
nnoremap <silent><Leader>q :call CloseBuffer()<CR>

" " Find current file in NERDTree
" nnoremap <Leader>hf :NERDTreeFind<CR>
" " Open NERDTree
" " nnoremap <Leader>n :NERDTreeToggle<CR>
" nnoremap <f3> :NERDTreeToggle<CR>

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

map <leader>ev :vnew! ~/.dotfiles/nvim/init.vim<cr>
map <leader>eg :vnew! ~/.gitconfig<cr>
map <leader>et :vnew! ~/.dotfiles/tmux/tmux.conf.symlink<cr>
map <leader>ez :vnew! ~/.dotfiles/zsh/zshrc.symlink<cr>

nnoremap <C-s> :call ScratchOpen()<cr>

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
nmap <leader>c :Commentary<cr>
vmap <leader>c :Commentary<cr>

" ## FZF
nnoremap <silent> <leader>m <esc>:FZF<cr>
nnoremap <leader>a <esc>:Rg<space>
nnoremap <silent> <leader>A  <esc>:exe('Rg '.expand('<cword>'))<cr>
" Backslash as shortcut to ag
nnoremap \ :Rg<SPACE>

" ## vim-plug
noremap <F5> :PlugUpdate<cr>
map <F5> :PlugUpdate<cr>
noremap <S-F5> :PlugClean!<cr>
map <S-F5> :PlugClean!<cr>

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
nnoremap <leader>H :Gbrowse<cr>
vnoremap <leader>H :Gbrowse<cr>
nnoremap <leader>gb :Gblame<cr>

" ## Testing vim-test
nmap <silent> <leader>t :TestFile<CR>
nmap <silent> <leader>T :TestNearest<CR>
nmap <silent> <leader>l :TestLast<CR>
" nmap <silent> <leader>a :TestSuite<CR>
" nmap <silent> <leader>g :TestVisit<CR>
" ref: https://github.com/Dkendal/dot-files/blob/master/nvim/.config/nvim/init.vim

" ## Gist/Github
" Send visual selection to gist.github.com as a private, filetyped Gist
" Requires the gist command line too (brew install gist)
vnoremap <leader>G :Gist -po<cr>

" ## Surround
vmap [ S]
vmap ( S)
vmap { S}
vmap ' S'
vmap " S"

" ## Splits with vim-tmux-navigator
let g:tmux_navigator_no_mappings = 1
let g:tmux_navigator_save_on_switch = 1
" nnoremap <silent> <BS>  :TmuxNavigateLeft<cr>
nnoremap <silent> <C-h> :TmuxNavigateLeft<cr>
nnoremap <silent> <C-j> :TmuxNavigateDown<cr>
nnoremap <silent> <C-k> :TmuxNavigateUp<cr>
nnoremap <silent> <C-l> :TmuxNavigateRight<cr>
nnoremap <silent> <C-\> :TmuxNavigatePrevious<cr>
nnoremap <C-o> :vnew<cr>:e<space><c-d>
nnoremap <C-t> :tabe<cr>:e<space><c-d>

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
nnoremap <silent> <leader>w :w<cr>
nnoremap <leader>q :q<cr>
" Sudo write (,W)
noremap <silent><leader>W :w !sudo tee %<CR>

" ## Vim process management
" background VIM
vnoremap <c-z> <esc>zv`<ztgv

nnoremap / /\v
vnoremap / /\v

" clear incsearch term
nnoremap  <silent><ESC> :syntax sync fromstart<cr>:nohlsearch<cr>:redrawstatus!<cr><ESC>

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
nnoremap <cr><cr> o<ESC>
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
nnoremap U :syntax sync fromstart<cr>:redraw!<cr>

" Select (charwise) the contents of the current line, excluding indentation.
" Great for pasting Python lines into REPLs.
nnoremap vv ^vg_

" ## Join and Split Lines
" Keep the cursor in place while joining lines
nnoremap J mzJ`z
" Split line (sister to [J]oin lines above)
" The normal use of S is covered by cc, so don't worry about shadowing it.
nnoremap S i<cr><esc>^mwgk:silent! s/\v +$//<cr>:noh<cr>`w

" Insert mode movements
" Ctrl-e: Go to end of line
" inoremap <c-e> <esc>A
" Ctrl-a: Go to begin of line
" inoremap <c-a> <esc>I


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
  highlight clear SpellBad

  " highlight conflicts
  match ErrorMsg '^\(<\|=\|>\)\{7\}\([^=].\+\)\?$'

  highlight SpellBad   term=underline cterm=underline gui=underline ctermfg=red guifg=#ff2929 guibg=NONE
  highlight SpellCap   term=underline cterm=underline gui=underline ctermbg=NONE ctermfg=33
  highlight SpellRare  term=underline cterm=underline gui=underline ctermbg=NONE ctermfg=217
  highlight SpellLocal term=underline cterm=underline gui=underline ctermbg=NONE ctermfg=72

  " Markdown could be more fruit salady
  highlight link markdownH1 PreProc
  highlight link markdownH2 PreProc
  highlight link markdownLink Character
  highlight link markdownBold String
  highlight link markdownItalic Statement
  highlight link markdownCode Delimiter
  highlight link markdownCodeBlock Delimiter
  highlight link markdownListMarker Todo

  " Configure how vim-lsc highlights errors.
  hi lscDiagnosticError term=none ctermbg=none cterm=undercurl ctermfg=red gui=undercurl guisp=#ff2929
  hi lscDiagnosticWarning term=none ctermbg=none cterm=undercurl ctermfg=magenta gui=undercurl guisp=magenta
  hi lscDiagnosticHint term=none ctermbg=none cterm=undercurl ctermfg=cyan gui=undercurl guisp=cyan
  hi lscDiagnosticInfo term=none ctermbg=none cterm=undercurl ctermfg=grey gui=undercurl guisp=grey

  " hi DiffChange guibg=#444444 ctermbg=238
  " hi DiffText guibg=#777777 ctermbg=244
  " hi DiffAdd guibg=#4f8867 ctermbg=29
  " hi DiffDelete guibg=#870000 ctermbg=88

  highlight ALEErrorSign ctermfg=9 ctermbg=15 guifg=#cc6666 guibg=NONE
  highlight ALEWarningSign ctermfg=11 ctermbg=15 guifg=#f0c674 guibg=NONE

  highlight GitGutterAdd guibg=NONE
  highlight GitGutterChange guibg=NONE
  highlight GitGutterDelete guibg=NONE
  highlight GitGutterChangeDelete guibg=NONE
" }}}

" vim:foldenable:foldmethod=marker:ft=vim
