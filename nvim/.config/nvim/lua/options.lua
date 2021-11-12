local o, g = vim.opt, vim.g
local exec, is_macos = mega.exec, mega.is_macos

-- REFS for explaining these options
-- https://github.com/sethigeet/Dotfiles/blob/master/.config/nvim/lua/general/settings.lua

-- o.mouse = "" -- disable the mouse
o.mouse = "nva" -- Mouse support in different modes
o.mousemodel = "popup" -- Set the behaviour of mouse
o.exrc = false -- ignore '~/.exrc'
o.secure = true
o.modelines = 1 -- read a modeline at EOF
o.errorbells = false -- disable error bells (no beep/flash)
o.termguicolors = true -- enable 24bit colors

o.updatetime = 250 -- decrease update time
o.timeoutlen = 300

o.autoread = true -- auto read file if changed outside of vim
o.fileformat = "unix" -- <nl> for EOL
o.switchbuf = { "useopen", "vsplit", "split", "usetab" }
o.encoding = "utf-8"
o.fileencoding = "utf-8"
o.backspace = { "eol", "start", "indent" }
o.matchpairs = { "(:)", "{:}", "[:]", "<:>" }

-- recursive :find in current dir
vim.cmd([[set path=.,,,$PWD/**]])

-- vim clipboard copies to system clipboard
-- unnamed     = use the " register (cmd-s paste in our term)
-- unnamedplus = use the + register (cmd-v paste in our term)
o.clipboard = "unnamedplus"

o.showmode = true -- show current mode (insert, etc) under the cmdline
o.showcmd = true -- show current command under the cmd line
o.cmdheight = 2 -- cmdline height
o.laststatus = 2 -- 2 = always show status line (filename, etc)
o.lazyredraw = true -- should make scrolling faster
o.scrolloff = 3 -- min number of lines to keep between cursor and screen edge
o.sidescrolloff = 5 -- min number of cols to keep between cursor and screen edge
o.textwidth = 78 -- max inserted text width for paste operations
o.linespace = 0 -- font spacing
o.ruler = true -- show line,col at the cursor pos
o.number = true -- show absolute line no. at the cursor pos
o.relativenumber = true -- otherwise, show relative numbers in the ruler
o.cursorline = true -- Show a line where the current cursor is
o.cursorlineopt = "number" -- Show a line where the current cursor is
o.signcolumn = "yes" -- Show sign column as first column
g.colorcolumn = 81 -- global var, mark column 81
o.colorcolumn = tostring(g.colorcolumn)
o.wrap = true -- wrap long lines
o.breakindent = true -- start wrapped lines indented
o.copyindent = true
o.preserveindent = true
o.linebreak = true -- do not break words on line wrap
o.jumpoptions = "stack"

-- Characters to display on ':set list',explore glyphs using:
-- `xfd -fa "InputMonoNerdFont:style:Regular"` or
-- `xfd -fn "-misc-fixed-medium-r-semicondensed-*-13-*-*-*-*-*-iso10646-1"`
-- input special chars with the sequence <C-v-u> followed by the hex code
o.listchars = {
  tab = "→ ",
  eol = "↲",
  nbsp = "␣",
  lead = "␣",
  space = "␣",
  trail = "•",
  extends = "⟩",
  precedes = "⟨",
}
o.showbreak = "↪ "

-- show menu even for one item do not auto select/insert
o.completeopt = { "noinsert", "menuone", "noselect" }
o.wildmenu = true
o.wildmode = "longest:full,full"
o.wildoptions = "pum" -- Show completion items using the pop-up-menu (pum)
o.pumblend = 5 -- completion menu transparency
o.pumheight = 20 -- completion menu height
o.winminwidth = 15

o.joinspaces = true -- insert spaces after '.?!' when joining lines
o.autoindent = true -- copy indent from current line on newline
o.smartindent = true -- add <tab> depending on syntax (C/C++)
o.startofline = false -- keep cursor column on navigation

o.tabstop = 4 -- Tab indentation levels every two columns
o.softtabstop = 4 -- Tab indentation when mixing tabs & spaces
o.shiftwidth = 4 -- Indent/outdent by two columns
o.shiftround = true -- Always indent/outdent to nearest tabstop
o.expandtab = true -- Convert all tabs that are typed into spaces
o.smarttab = true -- Use shiftwidths at left margin, tabstops everywhere else

-- c: auto-wrap comments using textwidth
-- r: auto-insert the current comment leader after hitting <Enter>
-- o: auto-insert the current comment leader after hitting 'o' or 'O'
-- q: allow formatting comments with 'gq'
-- n: recognize numbered lists
-- 1: don't break a line after a one-letter word
-- j: remove comment leader when it makes sense
-- this gets overwritten by ftplugins (:verb set fo)
-- we use autocmd to remove 'o' in '/lua/autocmd.lua'
-- borrowed from tjdevries
o.formatoptions = o.formatoptions
  - "a" -- Auto formatting is BAD.
  - "t" -- Don't auto format my code. I got linters for that.
  + "c" -- In general, I like it when comments respect textwidth
  + "q" -- Allow formatting comments w/ gq
  - "o" -- O and o, don't continue comments
  + "r" -- But do continue when pressing enter.
  + "n" -- Indent past the formatlistpat, not underneath it.
  + "j" -- Auto-remove comments if possible.
  - "2" -- I'm not in gradeschool anymore

o.splitbelow = true -- ':new' ':split' below current
o.splitright = true -- ':vnew' ':vsplit' right of current

o.foldenable = true -- enable folding
o.foldlevelstart = 10 -- open most folds by default
o.foldnestmax = 10 -- 10 nested fold max
o.foldmethod = "indent" -- fold based on indent level

o.undofile = false -- no undo file
o.hidden = true -- do not unload buffer when abandoned
o.autochdir = false -- do not change dir when opening a file

o.magic = true --  use 'magic' chars in search patterns
o.hlsearch = true -- highlight all text matching current search pattern
o.incsearch = true -- show search matches as you type
o.ignorecase = true -- ignore case on search
o.smartcase = true -- case sensitive when search includes uppercase
o.showmatch = true -- highlight matching [{()}]
o.inccommand = "nosplit" -- show search and replace in real time
o.autoread = true -- reread a file if it's changed outside of vim
o.wrapscan = true -- begin search from top of the file when nothing is found
o.cpoptions = vim.o.cpoptions .. "x" -- stay on search item when <esc>

o.backup = false -- no backup file
o.writebackup = false -- do not backup file before write
o.swapfile = false -- no swap file

o.dictionary = "/usr/share/dict/words"
o.spellfile = "$DOTS/nvim/.config/nvim/spell/en.utf-8.add"
o.spelllang = "en"
o.spell = false -- turn off by default (ft will enable it)
o.spellsuggest:prepend({ 12 })
o.spelloptions = "camel"
o.spellcapcheck = "" -- don't check for capital letters at start of sentence
o.fileformats = { "unix", "mac", "dos" }

--[[
  ShDa (viminfo for vim): session data history
  --------------------------------------------
  ! - Save and restore global variables (their names should be without lowercase letter).
  ' - Specify the maximum number of marked files remembered. It also saves the jump list and the change list.
  < - Maximum of lines saved for each register. All the lines are saved if this is not included, <0 to disable pessistent registers.
  % - Save and restore the buffer list. You can specify the maximum number of buffer stored with a number.
  / or : - Number of search patterns and entries from the command-line history saved. o.history is used if it’s not specified.
  f - Store file (uppercase) marks, use 'f0' to disable.
  s - Specify the maximum size of an item’s content in KiB (kilobyte).
      For the viminfo file, it only applies to register.
      For the shada file, it applies to all items except for the buffer list and header.
  h - Disable the effect of 'hlsearch' when loading the shada file.
  :oldfiles - all files with a mark in the shada file
  :rshada   - read the shada file (:rviminfo for vim)
  :wshada   - write the shada file (:wrviminfo for vim)
]]
o.shada = [[!,'100,<0,s100,h]]
o.sessionoptions = "blank,buffers,curdir,folds,help,tabpages,winsize"
o.diffopt = "internal,filler,algorithm:histogram,indent-heuristic"

exec([[
  set guicursor=n-v-c:block,i-ci-ve:ver25,r-cr:hor20,o:hor50
        \,a:blinkwait700-blinkoff400-blinkon250-Cursor/lCursor
        \,sm:block-blinkwait175-blinkoff150-blinkon175

  " Set cursor shape based on mode (:h termcap-cursor-shape)
  " Vertical bar in insert mode
  let &t_SI = "\e[6 q"
  " Underline in replace mode
  let &t_SR = "\e[4 q"
  " Block in normal mode
  let &t_EI = "\e[2 q"

  " Inform vim how to enable undercurl in wezterm
  let &t_Cs = "\e[60m"
  " Inform vim how to disable undercurl in wezterm (this disables all underline modes)
  let &t_Ce = "\e[24m"

  " supposed to be undercurl things?
  let &t_Cs = "\e[4:3m"
  let &t_Ce = "\e[4:0m"
]])
--[[
-- Install neovim-nightly on mac:
❯ brew tap jason0x43/homebrew-neovim-nightly
❯ brew install --cask neovim-nightly
]]

-- MacOS clipboard
if is_macos then
  g.clipboard = {
    name = "macOS-clipboard",
    copy = {
      ["+"] = "pbcopy",
      ["*"] = "pbcopy",
    },
    paste = {
      ["+"] = "pbpaste",
      ["*"] = "pbpaste",
    },
  }
end

if is_macos then
  g.python3_host_prog = "/usr/local/bin/python3"
else
  g.python3_host_prog = "/usr/bin/python3"
end

-- use ':grep' to send resulsts to quickfix
-- use ':lgrep' to send resulsts to loclist
if vim.fn.executable("rg") == 1 then
  o.grepprg = "rg --vimgrep --no-heading --hidden --smart-case --no-ignore-vcs"
  o.grepformat = "%f:%l:%c:%m"
  o.grepformat = "%f:%l:%c:%m,%f:%l:%m"
end

-- Disable providers we do not care a about
g.loaded_python_provider = 0
g.loaded_ruby_provider = 0
g.loaded_perl_provider = 0
g.loaded_node_provider = 0

-- Disable some in built plugins completely
local disabled_built_ins = {
  "2html_plugin",
  "getscript",
  "getscriptPlugin",
  "gzip",
  "loaded_tutor_mode_plugin",
  "logipat",
  "matchit",
  "matchparen",
  "netrw",
  "netrwFileHandlers",
  "netrwPlugin",
  "netrwSettings",
  "remote_plugins",
  "rrhelper",
  "spec",
  "spellfile_plugin",
  "tar",
  "tarPlugin",
  "vimball",
  "vimballPlugin",
  "zip",
  "zipPlugin",
}

for _, plugin in pairs(disabled_built_ins) do
  g["loaded_" .. plugin] = 1
end

g.markdown_fenced_languages = {
  "vim",
  "lua",
  "cpp",
  "sql",
  "python",
  "bash=sh",
  "console=sh",
  "javascript",
  "typescript",
  "js=javascript",
  "ts=typescript",
  "yaml",
  "json",
}

-- Map leader to ,
g.mapleader = ","
g.maplocalleader = " "

-- We do this to prevent the loading of the system fzf.vim plugin. This is
-- present at least on Arch/Manjaro/Void
vim.api.nvim_command("set rtp-=/usr/share/vim/vimfiles")
