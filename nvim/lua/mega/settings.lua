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
  -- vim.g.loaded_netrw = 1
  -- vim.g.loaded_netrwFileHandlers = 1
  -- vim.g.loaded_netrwPlugin = 1
  -- vim.g.loaded_netrwSettings = 1
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
    -- disable_builtins()
    -- set_global_options()
    -- set_global_vars()
    -- set_iabbrevs()
  end
}
