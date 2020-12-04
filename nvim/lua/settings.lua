-- [ settings.. ] --------------------------------------------------------------

local utils = require "utils"


local cmd, g, go, wo, bo, exec = vim.cmd, vim.g, vim.o, vim.wo, vim.bo, vim.api.nvim_exec

cmd "runtime vimrc"

-- Activate 24 bit colors
go.termguicolors = true

go.laststatus    = 2
go.termguicolors = false
go.cursorline    = false
go.clipboard     = "unnamedplus"
go.foldlevel     = 99
go.fileencodings = "utf-8,gbk,ucs-bom,cp936,gb18030,big5,latin1"
go.modeline      = true
go.modelines     = 3
go.smartcase     = true
go.ignorecase    = true
go.mouse         = "a"
-- o.cmdheight     = 2
go.autowrite     = true
go.colorcolumn   = '+0'
go.previewheight = 8
go.splitbelow    = true
go.hidden        = true
go.updatetime    = 300
go.completeopt   = "menuone,noinsert,noselect"
go.shortmess     = "filnxtToOFc"
go.cedit         = "<C-R>"  -- open command line window
go.statusline    = "%t %h%w%m%r %=%(%l,%c%V %= %P%)"

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
g.mapleader = ","


-- [ disable some built-ins ] --------------------------------------------------

g.loaded_2html_plugin = 1
g.loaded_gzip = 1
g.loaded_matchparen = 1
g.loaded_netrwPlugin = 1
g.loaded_rrhelper = 1
g.loaded_tarPlugin = 1
g.loaded_zipPlugin = 1
g.loaded_matchit = 1
g.loaded_tutor_mode_plugin = 1

-- -- For highlighting yanked region
-- cmd('au TextYankPost * silent! lua vim.highlight.on_yank({ higroup = "HighlightedyankRegion", timeout = 120 })')
