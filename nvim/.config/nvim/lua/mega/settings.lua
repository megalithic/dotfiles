-- local cache_dir = vim.fn.stdpath("cache")
local data_dir = vim.fn.stdpath("data")

local function disable_builtins()
  vim.g.loaded_2html_plugin = 1
  vim.g.loaded_getscript = 1
  vim.g.loaded_getscriptPlugin = 1
  vim.g.loaded_gzip = 1
  vim.g.loaded_logiPat = 1
  vim.g.loaded_matchit = 1
  vim.g.loaded_matchparen = 1
  vim.g.loaded_netrw = 1
  vim.g.loaded_netrwFileHandlers = 1
  vim.g.loaded_netrwPlugin = 1
  vim.g.loaded_netrwSettings = 1
  vim.g.loaded_rrhelper = 1
  vim.g.loaded_tar = 1
  vim.g.loaded_tarPlugin = 1
  vim.g.loaded_tutor_mode_plugin = 1
  vim.g.loaded_vimball = 1
  vim.g.loaded_vimballPlugin = 1
  vim.g.loaded_zip = 1
  vim.g.loaded_zipPlugin = 1
end

local function set_global_vars()
  vim.g.netrw_home = data_dir
  vim.g.netrw_banner = 0
  vim.g.netrw_liststyle = 3
  -- vim.g.fzf_command_prefix = "Fzf"
  -- vim.g.fzf_layout = {window = {width = 0.6, height = 0.5}}
  -- vim.g.fzf_action = {enter = "vsplit"}
  -- vim.g.fzf_preview_window = {"right:50%:hidden", "alt-p"}
  vim.g.polyglot_disabled = {
    "typescript",
    "typescriptreact",
    "typescript.tsx",
    "javascriptreact",
    "markdown",
    "md",
    "graphql",
    "lua",
    "tsx",
    "jsx",
    "sass",
    "scss",
    "css",
    "elm",
    "elixir",
    "eelixir",
    "ex",
    "exs"
  }
end

-- TODO: please..... get ahold of these options.. all over the place
local function set_global_options()
  local opt = require("mega.tj_opts").opt
  vim.o.termguicolors = true
  vim.o.showcmd = false
  vim.o.laststatus = 2
  vim.o.ruler = true
  vim.o.rulerformat = [[%-14.(%l,%c   %o%)]]
  -- vim.o.statusline = "%t %h%w%m%r %=%(%l,%c%V %= %P%)"
  -- vim.o.statusline="%<%f\ %h%m%r%=%-14.(%l,%c\ \ \ %o%)"
  -- vim.o.rulerformat="%-14.(%l,%c\ \ \ %o%)"
  vim.o.guicursor =
    "n:block-Cursor,a:block-blinkon0,i:ver25-blinkwait200-blinkoff150-blinkon200-CursorInsert,r:blinkwait200-blinkoff150-blinkon200-CursorReplace,v:CursorVisual,c:ver25-blinkon300-CursorInsert"
  vim.o.mouse = ""
  vim.o.shortmess = "filnxtToOFIc"
  vim.o.completeopt = "menuone,noinsert,noselect"
  vim.o.hidden = true
  vim.o.backspace = "indent,eol,start"
  vim.o.hlsearch = true
  vim.o.incsearch = true
  vim.o.smartcase = true
  vim.o.wildmenu = true
  vim.o.wildmode = "list:longest"
  vim.o.autoindent = true
  vim.o.smartindent = true
  vim.o.smarttab = true
  vim.o.errorbells = false
  vim.o.backup = false
  vim.o.swapfile = false
  vim.o.inccommand = "split"
  vim.o.jumpoptions = "stack"
  vim.wo.signcolumn = "yes:2" -- always showsigncolumn

  -- from tj_opts -> thanks TJ Devries!
  -- opt.autowrite = true
  -- opt.cedit = "<C-R>" -- open command line window
  -- opt.clipboard = "unnamedplus"
  -- opt.cmdheight = 1
  -- opt.colorcolumn = "+0"
  -- opt.completeopt = "menuone,noinsert,noselect"
  -- opt.cursorline = false
  -- opt.fileencodings = "utf-8,gbk,ucs-bom,cp936,gb18030,big5,latin1"
  -- opt.foldlevel = 99
  -- opt.hidden = true
  -- opt.ignorecase = true
  -- opt.laststatus = 2
  -- opt.modeline = true
  -- opt.modelines = 3
  -- opt.mouse = "a"
  -- opt.previewheight = 8
  -- opt.shortmess = "filnxtToOFc"
  -- opt.smartcase = true
  -- opt.splitbelow = true
  -- opt.statusline = "%t %h%w%m%r %=%(%l,%c%V %= %P%)"
  -- opt.termguicolors = false
  -- opt.termguicolors = true
  -- opt.updatetime = 300

  -- Ignore compiled files
  opt.wildignore = "__pycache__"
  opt.wildignore = opt.wildignore + {"*.o", "*~", "*.pyc", "*pycache*"}
  opt.wildignore = opt.wildignore + {"*.obj", "*.bin", "*.dll", "*.exe", "*.DS_Store"}
  opt.wildignore = opt.wildignore + {"*/.git/*", "*/.svn/*", "*/__pycache__/*", "*/build/**", "*/undo/*"}
  opt.wildignore = opt.wildignore + {"*.aux", "*.bbl", "*.blg", "*.brf", "*.fls", "*.fdb_latexmk", "*.synctex.gz"}

  -- Cool floating window popup menu for completion on command line
  opt.pumblend = 17

  opt.wildmode = {"longest", "list", "full"}
  opt.wildmode = opt.wildmode - "list"
  opt.wildmode = opt.wildmode + {"longest", "full"}

  opt.wildoptions = "pum"

  opt.showmode = false
  opt.showcmd = true
  opt.cmdheight = 1 -- Height of the command bar
  opt.incsearch = true -- Makes search act like search in modern browsers
  opt.showmatch = true -- show matching brackets when text indicator is over them
  opt.relativenumber = true -- Show line numbers
  opt.number = true -- But show the actual number for the line we're on
  opt.ignorecase = true -- Ignore case when searching...
  opt.smartcase = true -- ... unless there is a capital letter in the query
  opt.hidden = true -- I like having buffers stay around
  opt.cursorline = false -- Highlight the current line
  opt.equalalways = false -- I don't like my windows changing all the time
  opt.splitright = true -- Prefer windows splitting to the right
  opt.splitbelow = true -- Prefer windows splitting to the bottom
  opt.updatetime = 1000 -- Make updates happen faster
  opt.hlsearch = true -- I wouldn't use this without my DoNoHL function
  opt.scrolloff = 10 -- Make it so there are always ten lines below my cursor

  -- Tabs
  opt.autoindent = true
  opt.cindent = true
  opt.wrap = true

  opt.tabstop = 4
  opt.shiftwidth = 4
  opt.softtabstop = 4
  opt.expandtab = true

  opt.breakindent = true
  opt.showbreak = string.rep(" ", 3) -- Make it so that long lines wrap smartly
  opt.linebreak = true

  opt.foldmethod = "marker"
  opt.foldlevel = 0
  opt.modelines = 1

  opt.belloff = "all" -- Just turn the dang bell off

  opt.clipboard = "unnamedplus"

  opt.inccommand = "split"
  opt.swapfile = false -- Living on the edge
  opt.shada = {"!", "'1000", "<50", "s10", "h"}

  opt.mouse = "n"
  -- Helpful related items:
  --   1. :center, :left, :right
  --   2. gw{motion} - Put cursor back after formatting motion.
  --
  -- TODO: w, {v, b, l}
  opt.formatoptions =
    opt.formatoptions - "a" - -- Auto formatting is BAD.
    "t" + -- Don't auto format my code. I got linters for that.
    "c" + -- In general, I like it when comments respect textwidth
    "q" - -- Allow formatting comments w/ gq
    "o" + -- O and o, don't continue comments
    "r" + -- But do continue when pressing enter.
    "n" + -- Indent past the formatlistpat, not underneath it.
    "j" - -- Auto-remove comments if possible.
    "2" -- I'm not in gradeschool anymore

  -- set joinspaces
  opt.joinspaces = false -- Two spaces and grade school, we're done

  -- set fillchars=eob:~
  opt.fillchars = {eob = "~"}
end

local function set_iabbrevs()
  vim.cmd([[iabbrev cabbb Co-authored-by: Bijan Boustani <bijanbwb@gmail.com>]])
  vim.cmd([[iabbrev cabpi Co-authored-by: Patrick Isaac <pisaac@enbala.com>]])
  vim.cmd([[iabbrev cabtw Co-authored-by: Tony Winn <hi@tonywinn.me>]])
end

return {
  activate = function()
    disable_builtins()
    set_global_options()
    set_global_vars()
    set_iabbrevs()
  end
}

-- vim.cmd('filetype plugin indent on')
-- vim.cmd('syntax on')

-- vim.cmd("runtime vimrc")

-- vim.g.mapleader = ","
-- vim.g.maplocalleader = ","

-- -- presently working ->
-- vim.o.autowrite     = true
-- vim.o.cedit         = "<C-R>"  -- open command line window
-- vim.o.clipboard     = "unnamedplus"
-- vim.o.cmdheight     = 1
-- vim.o.colorcolumn   = '+0'
-- vim.o.completeopt   = "menuone,noinsert,noselect"
-- vim.o.cursorline    = false
-- vim.o.fileencodings = "utf-8,gbk,ucs-bom,cp936,gb18030,big5,latin1"
-- vim.o.foldlevel     = 99
-- vim.o.hidden        = true
-- vim.o.ignorecase    = true
-- vim.o.laststatus    = 2
-- vim.o.modeline      = true
-- vim.o.modelines     = 3
-- vim.o.mouse         = "a"
-- vim.o.previewheight = 8
-- vim.o.shortmess     = "filnxtToOFc"
-- vim.o.smartcase     = true
-- vim.o.splitbelow    = true
-- vim.o.statusline    = "%t %h%w%m%r %=%(%l,%c%V %= %P%)"
-- vim.o.termguicolors = false
-- vim.o.termguicolors = true
-- -- vim.o.updatetime    = 300

-- mine.. converted from my init.vim ===========================================
-- presently untested ->
-- vim.o.autoindent=true        -- Indented text
-- vim.o.autoread=true          -- Pick up external changes to files
-- vim.o.autowrite=true         -- Write files when navigating with :next/:previous
-- vim.o.backspace="indent,eol,start"
-- vim.o.belloff="all"       -- Bells are annoying
-- vim.o.breakindent=true       -- Wrap long lines *with* indentation
-- vim.o.breakindentopt="shift:2"
-- vim.o.clipboard="unnamedplus"
-- vim.o.colorcolumn=81 -- Highlight 81 and 82 columns
-- vim.o.conceallevel=2
-- vim.o.complete=".,w,b"    -- Sources for term and line completions
-- vim.o.completeopt="menuone,noinsert,noselect" -- Don't auto select first one
-- vim.o.dictionary="/usr/share/dict/words"
-- vim.o.spellfile="$HOME/.dotfiles/nvim/spell/en.utf-8.add"
-- vim.o.spelllang="en"
-- vim.o.expandtab = true        -- Use spaces instead of tabs
-- vim.o.foldlevelstart=20
-- vim.o.foldmethod="indent" -- Simple and fast
-- vim.o.foldtext=""
-- vim.o.formatoptions="cqj" -- Default format options
-- vim.o.gdefault=true          -- Always do global substitutes
-- vim.o.history=200       -- Keep 200 changes of undo history
-- vim.o.infercase=true         -- Smart casing when completing
-- vim.o.ignorecase=true        -- Search in case-insensitively
-- vim.o.incsearch=true         -- Go to search results immediately
-- vim.o.laststatus=2      -- We want a statusline
-- vim.o.linespace=0       -- Line height of things like, the statusline
-- vim.o.cmdheight=1
-- vim.o.lazyredraw=true        -- should make scrolling faster
-- vim.o.matchpairs="(:),{:},[:],<:>"
-- vim.o.mouse="nva"         -- Mouse support in different modes
-- vim.o.mousemodel="popup"  -- Set the behaviour of mouse
-- vim.o.mousehide=true         -- Hide mouse when typing text
-- vim.o.nobackup=true          -- No backup files
-- vim.o.nocompatible=true      -- No Vi support
-- vim.o.noemoji=true           -- don't assume all emoji are double width (@wincent)
-- vim.o.noexrc=true            -- Disable reading of working directory vimrc files
-- vim.o.nohlsearch=true        -- Don't highlight search results by default
-- vim.o.nojoinspaces=true      -- No to double-spaces when joining lines
-- vim.o.noshowcmd=true         -- No to showing command in bottom-right corner
-- vim.o.noshowmatch=true       -- No jumping jumping cursors when matching pairs
-- vim.o.noshowmode=true        -- No to showing mode in bottom-left corner
-- vim.o.noswapfile=true        -- No backup files
-- -- vim.o.nowrapscan        -- Don't wrap searches around
-- -- vim.o.number            -- Show line numbers
-- vim.o.nrformats="alpha,hex,octal"        -- No to oct/hex support when doing CTRL-a/x
-- -- vim.o.path=**
-- -- vim.o.relativenumber    -- Show relative numbers
-- vim.o.ruler=true
-- -- vim.o.scrolloff=5       -- Start scrolling when we're 5 lines away from margins
-- vim.o.shiftwidth=2
-- -- vim.o.shortmess+=c                          -- Don't show insert mode completion messages
-- vim.o.sidescrolloff=15
-- vim.o.sidescroll=5
-- vim.o.showbreak="↳"      -- Use this to wrap long lines
-- vim.o.smartcase  =true       -- Case-smart searching
-- vim.o.smarttab=true
-- vim.o.splitbelow=true        -- Split below current window
-- vim.o.splitright =true       -- Split window to the right
-- vim.o.synmaxcol=500     -- Syntax highlight first 500 chars, for performance
-- vim.o.t_Co=256          -- 256 color support
-- vim.o.tabstop=2
-- -- if has("termguicolors")
-- --   vim.o.termguicolors -- Enable 24-bit color support if available
-- -- endif
-- vim.o.textwidth=80
-- vim.o.timeoutlen=1500   -- Give some time for multi-key mappings
-- -- Don't set ttimeoutlen to zero otherwise it will break terminal cursor block
-- -- to I-beam and back functionality set by the t_SI and t_EI variables.
-- vim.o.ttimeoutlen=10
-- vim.o.ttyfast=true
-- -- Set the persistent undo directory on temporary private fast storage.
-- -- let s:undoDir="/tmp/.undodir_" . $USER
-- -- if !isdirectory(s:undoDir)
-- --   call mkdir(s:undoDir, "", 0700)
-- -- endif
-- -- let &undodir=s:undoDir
-- vim.o.undofile=true          -- Maintain undo history
-- vim.o.updatetime=100    -- Make async plugin more responsive
-- vim.o.viminfo=false          -- No backups
-- vim.o.wildcharm="<Tab>"   -- Defines the trigger for 'wildmenu' in mappings
-- vim.o.wildmenu =true         -- Nice command completions
-- vim.o.wildmode="full"
-- -- vim.o.wildignore+=*.o,*.obj,*.bin,*.dll,*.exe
-- -- vim.o.wildignore+=*/.git/*,*/.svn/*,*/__pycache__/*,*/build/**
-- -- vim.o.wildignore+=*.pyc
-- -- vim.o.wildignore+=*.DS_Store
-- -- vim.o.wildignore+=*.aux,*.bbl,*.blg,*.brf,*.fls,*.fdb_latexmk,*.synctex.gz
-- vim.o.wrap =true             -- Wrap long lines

-- vim.o.diffopt="filler,internal,algorithm:histogram,indent-heuristic"
-- vim.o.inccommand="nosplit"
-- vim.o.list=true
-- -- vim.o.listchars=tab:\ \ ,trail:-
-- vim.o.listchars="tab:\ \ ,trail:·"
-- -- vim.o.listchars=tab:»·,trail:·
-- -- vim.o.listchars=tab:▸\ ,eol:¬,extends:›,precedes:‹,trail:·,nbsp:⚋
-- -- vim.o.listchars=tab:»\ ,eol:¬,extends:›,precedes:‹,trail:·,nbsp:⚋
-- -- vim.o.listchars=tab:»\ ,extends:›,precedes:‹,trail:·,nbsp:⚋
-- -- vim.o.pumblend=10
-- vim.o.pumheight=20      -- Height of complete list
-- vim.o.signcolumn="yes:2"  -- always showsigncolumn
-- vim.o.switchbuf="useopen,vsplit,split,usetab"
-- -- vim.o.wildoptions+=pum
-- vim.o.wildoptions="pum"
-- -- vim.o.winblend=10
-- vim.o.jumpoptions="stack"

-- vim.o.guicursor=
--       \n:block-Cursor,
--       \a:block-blinkon0,
--       \i:ver25-blinkwait200-blinkoff150-blinkon200-CursorInsert,
--       \r:blinkwait200-blinkoff150-blinkon200-CursorReplace,
--       \v:CursorVisual,
--       \c:ver25-blinkon300-CursorInsert

-- -- Set cursor shape based on mode (:h termcap-cursor-shape)
-- -- Vertical bar in insert mode
-- let &t_SI = "\e[6 q"
-- -- Underline in replace mode
-- let &t_SR = "\e[4 q"
-- -- Block in normal mode
-- let &t_EI = "\e[2 q"

-- let $VISUAL      = 'nvr -cc split --remote-wait +"setlocal bufhidden=delete"'
-- let $GIT_EDITOR  = 'nvr -cc split --remote-wait +"setlocal bufhidden=delete"'
-- let $EDITOR      = 'nvr -l'
-- let $ECTO_EDITOR = 'nvr -l'

-- let g:python_host_prog = '~/.asdf/shims/python'
-- let g:python3_host_prog = '~/.asdf/shims/python3'

-- share data between nvim instances (registers etc)
-- augroup SHADA
--   autocmd!
--   autocmd CursorHold,TextYankPost,FocusGained,FocusLost *
--         \ if exists(':rshada') | rshada | wshada | endif
-- augroup END

-- cmd("scriptencoding utf-16")
-- cmd("syntax on")
-- cmd("filetype plugin indent on")

-- go.compatible = false
-- go.encoding = 'UTF-8'
-- go.termguicolors = true
-- go.background = 'dark'

-- go.hidden = true
-- go.timeoutlen = 500
-- go.updatetime = 100
-- go.ttyfast = true
-- go.scrolloff = 8

-- go.showcmd = true
-- go.wildmenu = true

-- wo.number = true
-- wo.numberwidth = 6
-- wo.relativenumber = true
-- wo.signcolumn = "yes"
-- wo.cursorline = true

-- go.expandtab = true
-- go.smarttab = true
-- go.tabstop = 4
-- go.cindent = true
-- go.shiftwidth = 4
-- go.softtabstop = 4
-- go.autoindent = true
-- go.clipboard = "unnamedplus"

-- wo.wrap = true
-- bo.textwidth = 300
-- bo.formatoptions = "qrn1"

-- go.hlsearch = true
-- go.ignorecase = true
-- go.smartcase = true

-- go.backup = false
-- go.writebackup = false
-- go.undofile = true
-- go.backupdir = "/tmp/"
-- go.directory = "/tmp/"
-- go.undodir = "/tmp/"

-- -- Map <leader> to space
-- U.map("n", "<SPACE>", "<Nop>")
-- g.mapleader = ","

-- -- For highlighting yanked region
-- cmd('au TextYankPost * silent! lua vim.highlight.on_yank({ higroup = "HighlightedyankRegion", timeout = 120 })')
