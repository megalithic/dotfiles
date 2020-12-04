-- ┌───────────────────────────────────────────────────────────────────────────┐
-- │                                                                           │
-- │ Setup for Lua-based plugins                                               │
-- │ --> REF: https://github.com/nanotee/nvim-lua-guide                        │
-- │                                                                           │
-- └───────────────────────────────────────────────────────────────────────────┘

local utils = require "utils"
local cmd, g, go, wo, bo, execute, exec, fn = vim.cmd, vim.g, vim.o, vim.wo, vim.bo, vim.api.nvim_command, vim.api.nvim_exec, vim.fn


-- [ settings.. ] --------------------------------------------------------------
--
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


-- [ plugins.. ] ---------------------------------------------------------------

-- paq-nvim --
local install_path = fn.stdpath('data')..'/site/pack/paqs/opt/paq-nvim'
if fn.empty(fn.glob(install_path)) > 0 then
    print "paq-nvim is NOT installed.."
    execute('!git clone https://github.com/savq/paq-nvim.git '..install_path)
    -- execute 'packadd paq-nvim'
else
    -- print "paq-nvim is installed.."
end

local Paq = require 'paq-nvim'
local paq = Paq.paq

vim.cmd [[ packadd paq-nvim ]]
vim.cmd [[ autocmd BufWritePost plugins.lua PaqInstall ]]
vim.cmd [[ autocmd BufWritePost plugins.lua PaqUpdate ]]
vim.cmd [[ autocmd BufWritePost plugins.lua PaqClean ]]
paq{'savq/paq-nvim', opt=true}

paq 'neovim/nvim-lspconfig'

paq 'nvim-lua/completion-nvim'
paq 'nvim-lua/popup.nvim'
paq 'nvim-lua/plenary.nvim'
-- paq 'nvim-lua/telescope.nvim'
paq 'nvim-lua/lsp-status.nvim'
paq 'nvim-lua/lsp_extensions.nvim'

-- paq 'nvim-treesitter/nvim-treesitter'
-- paq 'nvim-treesitter/nvim-treesitter-textobjects'
-- paq 'nvim-treesitter/completion-treesitter'
-- paq 'nvim-treesitter/nvim-treesitter-refactor'
-- paq 'nvim-treesitter/playground'

--paq 'lervag/vimtex'
--paq 'lervag/wiki.vim'
--paq 'vim-pandoc/vim-pandoc'
-- paq 'vim-pandoc/vim-pandoc-syntax'

paq 'trevordmiller/nova-vim'
paq 'norcalli/nvim-colorizer.lua'

paq 'dm1try/golden_size'

-- paq 'junegunn/vim-easy-align'
paq 'junegunn/fzf' -- must run -> `:call fzf#install()`
paq 'junegunn/fzf.vim'

--vim.g.fzf_action = { 'ctrl-s' = 'split', 'ctrl-v' = 'vsplit', 'enter' = 'vsplit' }
vim.g.fzf_layout = { window = { width= 0.6, height= 0.5 } }
vim.g.fzf_preview_window = {'right:50%:hidden', 'alt-p'}

-- utils.gmap("n", "<Leader>m", '<cmd>Files<CR>')

paq 'Raimondi/delimitMate'
--      let delimitMate_expand_cr = 0
paq 'rstacruz/vim-closer'
paq 'tpope/vim-endwise'
paq 'tpope/vim-eunuch' --"eunuch.vim
paq 'tpope/vim-abolish'
--" https://github.com/tpope/vim-abolish/blob/master/doc/abolish.txt#L146-L162
paq 'tpope/vim-rhubarb'
paq 'tpope/vim-repeat'
paq 'tpope/vim-surround'
--" paq 'machakann/vim-sandwich'
paq 'tpope/vim-commentary'
--paq '907th/vim-auto-save'-- "auto-save.vim
paq 'rhysd/clever-f.vim' --"clever-f.vim
--" paq 'justinmk/vim-sneak'
paq 'tpope/vim-unimpaired'-- "unimpaired.vim
paq 'EinfachToll/DidYouMean' --" Vim plugin which asks for the right file to open
paq 'jordwalke/VimAutoMakeDirectory' --" auto-makes the dir for you if it doesn't exist in the path
paq 'ConradIrwin/vim-bracketed-paste' --" correctly paste in insert mode
paq 'sickill/vim-pasta' --" context-aware pasting

paq 'sheerun/vim-polyglot'

-- Paq.install()
-- Paq.update()
-- Paq.clean()

-- [ required.. ] --------------------------------------------------------------

-- require("settings")
-- require("plugins")
require("autocmds")
require("keymaps")

-- [ plugin config.. ] ---------------------------------------------------------

-- Colorscheme --
vim.o.background = 'dark'
vim.cmd [[ colorscheme nova ]]

-- FZF --
vim.g.fzf_layout = { window = { width= 0.6, height= 0.5 } }
--vim.g.fzf_action = { ctrl-s = 'split', ctrl-v = 'vsplit', enter = 'vsplit' }
vim.g.fzf_preview_window = {'right:50%:hidden', 'alt-p'}

utils.gmap("n", "<Leader>m", '<cmd>Files<CR>')
--return {
--  config = function()
--    vim.g.fzf_layout = { 'down': '~15%' }
--    vim.g.fzf_layout = { 'window': { 'width': 0.6, 'height': 0.5 } }
--    vim.g.fzf_action = {
--      \ 'ctrl-s': 'split',
--      \ 'ctrl-v': 'vsplit',
--      \ 'enter': 'vsplit'
--    \ }
--    vim.g.fzf_preview_window = {'right:50%:hidden', 'alt-p'}
--  end,
--  maps = function()
--    utils.gmap("n", "<Leader>m", '<cmd>Files<CR>')

--    -- wr.map('n', '<leader>fm', ':Marks<CR>')
--    -- wr.map('n', '<leader>ff', '<cmd>lua wr.fzfwrap.files()<cr>')
--    -- wr.map('n', '<leader>fb', '<cmd>lua wr.fzfwrap.buffers()<cr>')
--    -- wr.map('n', '<leader>fw', ':Windows<CR>')
--    -- wr.map('n', '<leader>fc', ':Commands<CR>')
--    -- wr.map('n', '<leader>f/', ':History/<CR>')
--    -- wr.map('n', '<leader>f;', ':History:<CR>')
--    -- wr.map('n', '<leader>fr', ':History<CR>')
--    -- wr.map('n', '<leader>fl', ':BLines<CR>')
--  end,
--}

-- Colorizer --
--   See https://github.com/norcalli/nvim-colorizer.lua
local has_colorizer, colorizer = pcall(require, "colorizer")
if has_colorizer then
    -- https://github.com/norcalli/nvim-colorizer.lua/issues/4#issuecomment-543682160
    colorizer.setup(
      {
        -- '*',
        -- '!vim',
        -- }, {
        css = {rgb_fn = true},
        scss = {rgb_fn = true},
        sass = {rgb_fn = true},
        stylus = {rgb_fn = true},
        vim = {names = false},
        tmux = {names = false},
        "eelixir",
        "javascript",
        "javascriptreact",
        "typescript",
        "typescriptreact",
        "zsh",
        "sh",
        "conf",
        html = {
          mode = "foreground"
        }
      }
    )
end

-- Golden Ratio --
--   See https://github.com/dm1try/golden_size#tips-and-tricks

local function ignore_by_buftype(types)
  local buftype = vim.api.nvim_buf_get_option(vim.api.nvim_get_current_buf(), "buftype")
  for _, type in pairs(types) do
    if type == buftype then
      return 1
    end
  end
end

local golden_size = require("golden_size")
-- set the callbacks, preserve the defaults
golden_size.set_ignore_callbacks(
  {
    {
      ignore_by_buftype,
      {
        "Undotree",
        "quickfix",
        "nerdtree",
        "current",
        "Vista",
        "LuaTree",
        "nofile"
      }
    },
    {golden_size.ignore_float_windows}, -- default one, ignore float windows
    {golden_size.ignore_by_window_flag} -- default one, ignore windows with w:ignore_gold_size=1
  }
)
-- require("p.telescope")
-- require("p.treesitter")

-- [ lsp.. ] -------------------------------------------------------------------

require("lc.config")
