local fn = vim.fn
local fmt = string.format

-----------------------------------------------------------------------------//
-- Message output on vim actions {{{1
-----------------------------------------------------------------------------//
vim.opt.shortmess = {
  t = true, -- truncate file messages at start
  A = true, -- ignore annoying swap file messages
  o = true, -- file-read message overwrites previous
  O = true, -- file-read message overwrites previous
  T = true, -- truncate non-file messages in middle
  f = true, -- (file x of x) instead of just (x of x
  F = true, -- Don't give file info when editing a file, NOTE: this breaks autocommand messages
  s = true,
  c = true,
  W = true, -- Don't show [w] or written when writing
}
-----------------------------------------------------------------------------//
-- Timings {{{1
-----------------------------------------------------------------------------//
vim.opt.updatetime = 300
vim.opt.timeout = true
vim.opt.timeoutlen = 500
vim.opt.ttimeoutlen = 10
-----------------------------------------------------------------------------//
-- Window splitting and buffers {{{1
-----------------------------------------------------------------------------//
vim.opt.splitbelow = true
vim.opt.splitright = true
vim.opt.eadirection = "hor"
-- exclude usetab as we do not want to jump to buffers in already open tabs
-- do not use split or vsplit to ensure we don't open any new windows
vim.o.switchbuf = "useopen,uselast"
vim.opt.fillchars = {
  vert = "▕", -- alternatives │
  horiz = "━",
  --   horizup   = '┻',
  --   horizdown = '┳',
  --   vert      = '┃',
  --   vertleft  = '┫',
  --   vertright = '┣',
  --   verthoriz = '╋',
  fold = " ",
  eob = " ", -- suppress ~ at EndOfBuffer
  diff = "╱", -- alts: = ⣿ ░ ─
  msgsep = " ", -- alts: ‾ ─
  foldopen = mega.icons.misc.fold_open, -- alts: ▾
  foldsep = "│",
  foldclose = mega.icons.misc.fold_close, -- alts: ▸
}

-----------------------------------------------------------------------------//
-- Diff {{{1
-----------------------------------------------------------------------------//
-- Use in vertical diff mode, blank lines to keep sides aligned, Ignore whitespace changes
vim.opt.diffopt = vim.opt.diffopt
  + {
    "vertical",
    "iwhite",
    "hiddenoff",
    "foldcolumn:0",
    "context:4",
    "algorithm:histogram",
    "indent-heuristic",
  }
-----------------------------------------------------------------------------//
-- Format Options {{{1
-----------------------------------------------------------------------------//
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
--
-- - "a" -- Auto formatting is BAD.
-- - "t" -- Don't auto format my code. I got linters for that.
-- + "c" -- In general, I like it when comments respect textwidth
-- + "q" -- Allow formatting comments w/ gq
-- - "o" -- O and o, don't continue comments
-- + "r" -- But do continue when pressing enter.
-- + "n" -- Indent past the formatlistpat, not underneath it.
-- + "j" -- Auto-remove comments if possible.
-- - "2" -- I'm not in gradeschool anymore

-- original; FIXME: are these right?
vim.opt.formatoptions = {
  ["1"] = true,
  ["2"] = true, -- Use indent from 2nd line of a paragraph
  q = true, -- continue comments with gq"
  c = true, -- Auto-wrap comments using textwidth
  r = true, -- Continue comments when pressing Enter
  n = true, -- Recognize numbered lists
  t = false, -- autowrap lines using text width value
  j = true, -- remove a comment leader when joining lines.
  -- Only break if the line was not longer than 'textwidth' when the insert
  -- started and only at a white character that has been entered during the
  -- current insert command.
  l = true,
  v = true,
}

-- from tj: FIXME: validate these!
vim.opt.formatoptions = vim.opt.formatoptions
  - "a" -- Auto formatting is BAD.
  - "t" -- Don't auto format my code. I got linters for that.
  + "c" -- In general, I like it when comments respect textwidth
  + "q" -- Allow formatting comments w/ gq
  - "o" -- O and o, don't continue comments
  + "r" -- But do continue when pressing enter.
  + "n" -- Indent past the formatlistpat, not underneath it.
  + "j" -- Auto-remove comments if possible.
  - "2" -- I'm not in gradeschool anymore

-----------------------------------------------------------------------------//
-- Folds {{{1
-----------------------------------------------------------------------------//
vim.opt.foldenable = false -- enable folding
vim.opt.foldcolumn = "0" -- presently disabled until we can use foldcolumndigits
-- vim.wo.foldcolumndigits = false
-- vim.opt.foldtext = "v:lua.mega.folds()"
vim.opt.foldopen = vim.opt.foldopen + "search"
vim.opt.foldlevel = 99 -- feel free to decrease the value
vim.opt.foldlevelstart = 10 -- open most folds by default
vim.opt.foldnestmax = 10 -- 10 nested fold max
vim.opt.foldexpr = "nvim_treesitter#foldexpr()"
vim.opt.foldmethod = "expr"
-- vim.wo.foldcolumndigits = false -- if disabled, 'foldsep' from 'fillchars' used.
-- or --
vim.opt.foldmethod = "indent" -- fold based on indent level
-----------------------------------------------------------------------------//
-- Quickfix {{{1
-----------------------------------------------------------------------------//
--- @see config/nvim/plugin/quickfix.lua
-- vim.o.qftf (quickfixtextfunc) is set there 👆
-----------------------------------------------------------------------------//
-- Grepprg {{{1
-----------------------------------------------------------------------------//
-- Use faster grep alternatives if possible
if mega.executable("rg") then
  vim.o.grepprg = [[rg --glob "!.git" --no-heading --vimgrep --follow $*]]
  vim.opt.grepformat = vim.opt.grepformat ^ { "%f:%l:%c:%m" }
elseif mega.executable("ag") then
  vim.o.grepprg = [[ag --nogroup --nocolor --vimgrep]]
  vim.opt.grepformat = vim.opt.grepformat ^ { "%f:%l:%c:%m" }
end
-----------------------------------------------------------------------------//
-- Wild and file globbing stuff in command mode {{{1
-----------------------------------------------------------------------------//
vim.opt.wildcharm = fn.char2nr(mega.replace_termcodes([[<Tab>]]))
vim.opt.wildmode = "longest:full,full" -- Shows a menu bar as opposed to an enormous list
vim.opt.wildignorecase = true -- Ignore case when completing file names and directories
-- Binary
vim.opt.wildignore = {
  "*.aux",
  "*.out",
  "*.toc",
  "*.o",
  "*.obj",
  "*.dll",
  "*.jar",
  "*.pyc",
  "*.rbc",
  "*.class",
  "*.gif",
  "*.ico",
  "*.jpg",
  "*.jpeg",
  "*.png",
  "*.avi",
  "*.wav",
  -- Temp/System
  "*.*~",
  "*~ ",
  "*.swp",
  ".lock",
  ".DS_Store",
  "tags.lock",
}
vim.opt.wildoptions = "pum"
vim.opt.pumblend = 3 -- Make popup window translucent
vim.opt.pumheight = 20 -- completion menu height
-----------------------------------------------------------------------------//
-- Display {{{1
-----------------------------------------------------------------------------//
vim.opt.conceallevel = 2
vim.opt.wrap = true
-- vim.opt.wrapmargin = 2
vim.opt.textwidth = 79
vim.opt.textwidth = 0 --  0 disables
vim.opt.linebreak = true -- lines wrap at words rather than random characters
vim.opt.synmaxcol = 1024 -- don't syntax highlight long lines
-- FIXME: use 'auto:2-4' when the ability to set only a single lsp sign is restored
--@see: https://github.com/neovim/neovim/issues?q=set_signs
vim.opt.signcolumn = "auto:2-5"
-- vim.opt.signcolumn = "auto:2-4"
vim.opt.ruler = false
vim.opt.cmdheight = 1 -- Set command line height to two lines
vim.opt.showbreak = [[↪ ]] -- Options include -> '…', '↳ ', '→','↪ '
vim.opt.showbreak = string.rep(" ", 3) -- Make it so that long lines wrap smartly
vim.opt.lazyredraw = true -- should make scrolling faster
vim.opt.ttyfast = true -- more faster scrolling (thanks @morganick!)
--- This is used to handle markdown code blocks where the language might
--- be set to a value that isn't equivalent to a vim filetype
vim.g.markdown_fenced_languages = {
  "shell=sh",
  "bash=sh",
  "zsh=sh",
  "console=sh",
  "vim",
  "lua",
  "cpp",
  "sql",
  "elixir",
  "python",
  "javascript",
  "typescript",
  "js=javascript",
  "ts=typescript",
  "yaml",
  "json",
}
vim.opt.winminwidth = 20
-----------------------------------------------------------------------------//
-- Jumplist
-----------------------------------------------------------------------------//
-- TODO: vim.opt.jumpoptions = { 'stack' } -- make the jumplist behave like a browser stack
-----------------------------------------------------------------------------//
-- List chars {{{1
-----------------------------------------------------------------------------//
vim.opt.list = true -- invisible chars
vim.opt.listchars = {
  eol = nil,
  tab = "│ ",
  extends = "›", -- Alternatives: … »
  precedes = "‹", -- Alternatives: … «
  trail = "•", -- BULLET (U+2022, UTF-8: E2 80 A2)
}
-----------------------------------------------------------------------------//
-- Indentation
-----------------------------------------------------------------------------//
vim.opt.breakindentopt = "sbr"
vim.opt.autoindent = true
vim.opt.shiftround = true
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
-----------------------------------------------------------------------------//
-- vim.o.debug = "msg"
vim.opt.gdefault = true
vim.opt.confirm = true -- make vim prompt me to save before doing destructive things
vim.opt.completeopt = { "menuone", "noselect" }
vim.opt.hlsearch = true
vim.opt.autowriteall = true -- will automatically :write before running commands and changing files
vim.opt.clipboard = { "unnamedplus" }

-- statusline:
-- 2 = statusline in each window;
-- 3 = global statusline
vim.opt.laststatus = 2
vim.opt.statusline = ""
-- fallback in the event our statusline plugins fail to load
-- vim.opt.statusline = table.concat({
--   "%2{toupper(mode())} ",
--   "f", -- relative path
--   "m", -- modified flag
--   "r",
--   "=",
--   "{&spelllang}",
--   "%{get(b:,'gitsigns_status','')}",
--   "y", -- filetype
--   "8(%l,%c%)", -- line, column
--   "8p%% ", -- file percentage
-- }, " %")
-----------------------------------------------------------------------------//
-- Emoji {{{1
-----------------------------------------------------------------------------//
-- emoji is true by default but makes (n)vim treat all emoji as double width
-- which breaks rendering so we turn this off.
-- CREDIT: https://www.youtube.com/watch?v=F91VWOelFNE
vim.opt.emoji = false
-----------------------------------------------------------------------------//
-- Cursor {{{1
-----------------------------------------------------------------------------//
-- This is from the help docs, it enables mode shapes, "Cursor" highlight, and blinking :h guicursor
vim.opt.guicursor = {
  [[n-v-c:block,i-ci-ve:ver25,r-cr:hor20,o:hor50]],
  [[a:blinkwait700-blinkoff400-blinkon250-Cursor/lCursor]],
  [[sm:block-blinkwait175-blinkoff150-blinkon175]],
}
-- ]])

-- NOTE: plugin/cursorline.lua has more...
vim.opt.cursorline = true -- Show a line where the current cursor is
vim.opt.cursorlineopt = "number" -- optionally -> "screenline,number"
-----------------------------------------------------------------------------//
-- Utilities {{{1
-----------------------------------------------------------------------------//
vim.opt.showmode = false -- show current mode (insert, etc) under the cmdline
vim.opt.showcmd = true -- show current mode (insert, etc) under the cmdline
-- NOTE: Don't remember
-- * help files since that will error if they are from a lazy loaded plugin
-- * folds since they are created dynamically and might be missing on startup
vim.opt.sessionoptions = {
  "blank",
  "globals",
  "buffers",
  "curdir",
  "folds",
  -- "help",
  "winpos",
  "winsize",
  -- "tabpages",
}
-- vim.opt.sessionoptions = "blank,buffers,curdir,folds,help,tabpages,winsize"
vim.opt.viewoptions = { "cursor", "folds" } -- save/restore just these (with `:{mk,load}view`)
vim.opt.virtualedit = "block" -- allow cursor to move where there is no text in visual block mode
-----------------------------------------------------------------------------//
-- ShaDa (viminfo for vim): session data history
-----------------------------------------------------------------------------//
--[[
   NOTE: don't store marks as they are currently broke i.e.
   are incorrectly resurrected after deletion
   replace '100 with '0 the default which stores 100 marks
   add f0 so file marks aren't stored
   @credit: wincent

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
-- vim.opt.shada = [[!,'0,f0,<50,s10,h]]
vim.opt.shada = [[!,'100,<0,s100,h]]
-------------------------------------------------------------------------------
-- BACKUP AND SWAPS {{{
-------------------------------------------------------------------------------
vim.opt.backup = false
vim.opt.writebackup = false
if fn.isdirectory(vim.o.undodir) == 0 then
  fn.mkdir(vim.o.undodir, "p")
end
vim.opt.undofile = true
vim.opt.swapfile = false
vim.opt.directory = fn.stdpath("state") .. "/swap//"
if fn.isdirectory(vim.o.directory) == 0 then
  fn.mkdir(vim.o.directory, "p")
end
--}}}
-----------------------------------------------------------------------------//
-- Match and search {{{1
-----------------------------------------------------------------------------//
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.wrapscan = true -- Searches wrap around the end of the file
vim.opt.scrolloff = 9 -- for typerwritering (HT: @evantravers), see https://randomdeterminism.wordpress.com/2011/08/15/typewriter-scroll-mode-in-vim/
vim.opt.sidescrolloff = 10
vim.opt.sidescroll = 1
-----------------------------------------------------------------------------//
-- Spelling {{{1
-----------------------------------------------------------------------------//
vim.opt.spellsuggest:prepend({ 12 })
vim.opt.spelloptions = "camel"
vim.opt.spellcapcheck = "" -- don't check for capital letters at start of sentence
vim.opt.dictionary = "/usr/share/dict/words"

vim.opt.spellfile = fn.expand("$DOTS/config/nvim/spell/en.utf-8.add")
vim.opt.spelllang = "en"
vim.opt.fileformats = { "unix", "mac", "dos" }
-----------------------------------------------------------------------------//
-- Mouse {{{1
-----------------------------------------------------------------------------//
vim.opt.mouse = "a"
vim.opt.mousefocus = true
-----------------------------------------------------------------------------//
-- these only read ".vim" files
vim.opt.secure = true -- Disable autocmd etc for project local vimrc files.
vim.opt.exrc = true -- Allow project local vimrc files example .nvimrc see :h exrc
-----------------------------------------------------------------------------//
-- Git editor
-----------------------------------------------------------------------------//
if mega.executable("nvr") then
  vim.env.GIT_EDITOR = "nvr -cc split --remote-wait +'set bufhidden=wipe'"
  vim.env.EDITOR = "nvr -cc split --remote-wait +'set bufhidden=wipe'"
end
-----------------------------------------------------------------------------//
-- Disable built-ins
-----------------------------------------------------------------------------//
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
  vim.g["loaded_" .. plugin] = 1
end

mega.exec([[
  " Set cursor shape based on mode (:h termcap-cursor-shape)
  " Vertical bar in insert mode
  let &t_SI = "\e[6 q"
  " underline in replace mode
  let &t_SR = "\e[4 q"
  " block in normal mode
  let &t_EI = "\e[2 q"

  " inform vim how to enable undercurl in wezterm
  let &t_Cs = "\e[60m"
  " inform vim how to disable undercurl in wezterm (this disables all underline modes)
  let &t_Ce = "\e[24m"

  " supposed to be undercurl things?
  let &t_Cs = "\e[4:3m"
  let &t_Ce = "\e[4:0m"

  " for kitty background things:
  " https://sw.kovidgoyal.net/kitty/faq/?highlight=send_text#using-a-color-theme-with-a-background-color-does-not-work-well-in-vim
  let &t_ut=''
]])
-----------------------------------------------------------------------------//
-- Random Other Things
-----------------------------------------------------------------------------//
-- vim.opt.shortmess = "IToOlxfitnw" -- https://neovim.io/doc/user/options.html#'shortmess'
vim.g.no_man_maps = true
vim.g.vim_json_syntax_conceal = false
vim.g.vim_json_conceal = false

-- vim.opt.shell = "/usr/local/bin/zsh --login" -- fix this for cross-platform
-- vim.opt.concealcursor = "n" -- Hide * markup for bold and italic
-- # git editor
if vim.fn.executable("nvr") then
  vim.env.GIT_EDITOR = "nvr -cc split --remote-wait +'set bufhidden=wipe'"
  vim.env.EDITOR = "nvr -cc split --remote-wait +'set bufhidden=wipe'"
end
-- # registers
vim.g.registers_return_symbol = " ﬋ " -- "'⏎' by default
vim.g.registers_tab_symbol = "." -- "'·' by default
vim.g.registers_space_symbol = " " -- "' ' by default
vim.g.registers_register_key_sleep = 0 -- "0 by default, seconds to wait before closing the window when a register key is pressed
vim.g.registers_show_empty_registers = 0 -- "1 by default, an additional line with the registers without content

-----------------------------------------------------------------------------//
-- Abbreviations/Cabbreviations
-----------------------------------------------------------------------------//
-- REF: https://github.com/lukas-reineke/lsp-format.nvim#wq-will-not-format
vim.cmd([[cabbrev wq execute "lua vim.lsp.buf.formatting_sync()" <bar> wq]])

-- [ colorscheme ] -------------------------------------------------------------
do
  vim.opt.termguicolors = true
  pcall(vim.cmd, fmt("colorscheme %s", vim.g.colorscheme))
end

-- vim:foldmethod=marker
