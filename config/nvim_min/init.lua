_G.mega = {
  ui = {},
  lsp = {},
}

function _G.Plugin_enabled(plugin)
  if plugin then print(plugin) end
  return false
end

_G.L = vim.log.levels

local map = vim.keymap.set
local pack = vim.pack
local lsp = vim.lsp
local autocmd = vim.api.nvim_create_autocmd
local command = vim.api.nvim_create_user_command
local augroup = vim.api.nvim_create_augroup("mega_minvim", { clear = true })

-- theme & transparency
pcall(vim.cmd.colorscheme, "megaforest")

if vim.fn.executable("rg") == 1 then
  vim.opt.grepprg = "rg --vimgrep --smart-case"
  vim.opt.grepformat = "%f:%l:%c:%m"
end

-- Basic settings
vim.opt.number = true -- Line numbers
vim.opt.relativenumber = true -- Relative line numbers
vim.opt.cursorline = true -- Highlight current line
vim.opt.wrap = false -- Don't wrap lines
vim.opt.scrolloff = 10 -- Keep 10 lines above/below cursor
vim.opt.sidescrolloff = 8 -- Keep 8 columns left/right of cursor

-- Indentation
vim.opt.tabstop = 2 -- Tab width
vim.opt.shiftwidth = 2 -- Indent width
vim.opt.softtabstop = 2 -- Soft tab stop
vim.opt.expandtab = true -- Use spaces instead of tabs
vim.opt.smartindent = true -- Smart auto-indenting
vim.opt.autoindent = true -- Copy indent from current line

-- Search settings
vim.opt.ignorecase = true -- Case insensitive search
vim.opt.smartcase = true -- Case sensitive if uppercase in search
vim.opt.hlsearch = false -- Don't highlight search results
vim.opt.incsearch = true -- Show matches as you type

-- Visual settings
vim.opt.termguicolors = true -- Enable 24-bit colors
vim.opt.signcolumn = "yes" -- Always show sign column
vim.opt.colorcolumn = "100" -- Show column at 100 characters
vim.opt.showmatch = true -- Highlight matching brackets
vim.opt.matchtime = 2 -- How long to show matching bracket
vim.opt.cmdheight = 1 -- Command line height
vim.opt.completeopt = "menuone,noinsert,noselect" -- Completion options
vim.opt.showmode = false -- Don't show mode in command line
vim.opt.pumheight = 10 -- Popup menu height
vim.opt.pumblend = 10 -- Popup menu transparency
vim.opt.winblend = 0 -- Floating window transparency
vim.opt.conceallevel = 0 -- Don't hide markup
vim.opt.concealcursor = "" -- Don't hide cursor line markup
vim.opt.lazyredraw = true -- Don't redraw during macros
vim.opt.synmaxcol = 300 -- Syntax highlighting limit

-- File handling
vim.opt.backup = false -- Don't create backup files
vim.opt.writebackup = false -- Don't create backup before writing
vim.opt.swapfile = false -- Don't create swap files
vim.opt.undofile = true -- Persistent undo
vim.opt.undodir = vim.fn.expand("~/.vim/undodir") -- Undo directory
vim.opt.updatetime = 300 -- Faster completion
vim.opt.timeoutlen = 500 -- Key timeout duration
vim.opt.ttimeoutlen = 0 -- Key code timeout
vim.opt.autoread = true -- Auto reload files changed outside vim
vim.opt.autowrite = false -- Don't auto save

-- Behavior settings
vim.opt.hidden = true -- Allow hidden buffers
vim.opt.errorbells = false -- No error bells
vim.opt.backspace = "indent,eol,start" -- Better backspace behavior
vim.opt.autochdir = false -- Don't auto change directory
vim.opt.iskeyword:append("-") -- Treat dash as part of word
vim.opt.path:append("**") -- include subdirectories in search
vim.opt.selection = "exclusive" -- Selection behavior
vim.opt.mouse = "a" -- Enable mouse support
vim.opt.clipboard:append("unnamedplus") -- Use system clipboard
vim.opt.modifiable = true -- Allow buffer modifications
vim.opt.encoding = "UTF-8" -- Set encoding

-- Cursor settings
vim.opt.guicursor =
  "n-v-c:block,i-ci-ve:block,r-cr:hor20,o:hor50,a:blinkwait700-blinkoff400-blinkon250-Cursor/lCursor,sm:block-blinkwait175-blinkoff150-blinkon175"

-- Folding settings
vim.opt.foldmethod = "expr" -- Use expression for folding
vim.opt.foldexpr = "nvim_treesitter#foldexpr()" -- Use treesitter for folding
vim.opt.foldlevel = 99 -- Start with all folds open

-- Split behavior
vim.opt.splitbelow = true -- Horizontal splits go below
vim.opt.splitright = true -- Vertical splits go right

vim.cmd([[ command -nargs=+ -complete=file -bar Rg silent! grep! <args> | cwindow | redraw! ]])

command("Up", "silent up | e", {}) -- Quick refresh if Treesitter bugs out
command("R", "silent restart", {}) -- Quick refresh if Treesitter bugs out

-- Key mappings
vim.g.mapleader = "," -- Set leader key to space
vim.g.maplocalleader = " " -- Set local leader key (NEW)

-- Normal mode mappings
map("n", "<leader>c", ":nohlsearch<CR>", { desc = "Clear search highlights" })

map("n", "<leader>o", ":update<CR> :source<CR>")
map("n", "<leader>w", ":write<CR>")
map("n", "<leader>q", ":quit<CR>")
map("n", "<localleader><localleader>", "<C-^>", { desc = "last buffer" })
map("n", "H", "^")
map("n", "L", "$")

map({ "v", "x" }, "L", "g_")
map({ "v", "x" }, "H", "g^")
map("n", "0", "^")
map({ "n", "v", "x" }, "<leader>y", "\"+y<CR>")
map({ "n", "v", "x" }, "<leader>d", "\"+d<CR>")

-- Y to EOL
map("n", "Y", "y$", { desc = "Yank to end of line" })

-- Center screen when jumping
map("n", "n", "nzzzv", { desc = "Next search result (centered)" })
map("n", "N", "Nzzzv", { desc = "Previous search result (centered)" })
map("n", "<C-d>", "<C-d>zz", { desc = "Half page down (centered)" })
map("n", "<C-u>", "<C-u>zz", { desc = "Half page up (centered)" })

-- Better paste behavior
map("x", "<leader>p", "\"_dP", { desc = "Paste without yanking" })

-- Delete without yanking
map({ "n", "v" }, "<leader>d", "\"_d", { desc = "Delete without yanking" })

-- Buffer navigation
map("n", "<leader>bn", ":bnext<CR>", { desc = "Next buffer" })
map("n", "<leader>bp", ":bprevious<CR>", { desc = "Previous buffer" })

-- Better window navigation
map("n", "<C-h>", "<C-w>h", { desc = "Move to left window" })
map("n", "<C-j>", "<C-w>j", { desc = "Move to bottom window" })
map("n", "<C-k>", "<C-w>k", { desc = "Move to top window" })
map("n", "<C-l>", "<C-w>l", { desc = "Move to right window" })

-- Splitting & Resizing
map("n", "<leader>sv", ":vsplit<CR>", { desc = "Split window vertically" })
map("n", "<leader>sh", ":split<CR>", { desc = "Split window horizontally" })
map("n", "<C-Up>", ":resize +2<CR>", { desc = "Increase window height" })
map("n", "<C-Down>", ":resize -2<CR>", { desc = "Decrease window height" })
map("n", "<C-Left>", ":vertical resize -2<CR>", { desc = "Decrease window width" })
map("n", "<C-Right>", ":vertical resize +2<CR>", { desc = "Increase window width" })

-- Move lines up/down
map("n", "<A-j>", ":m .+1<CR>==", { desc = "Move line down" })
map("n", "<A-k>", ":m .-2<CR>==", { desc = "Move line up" })
map("v", "<A-j>", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
map("v", "<A-k>", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })

-- Better indenting in visual mode
map("v", "<", "<gv", { desc = "Indent left and reselect" })
map("v", ">", ">gv", { desc = "Indent right and reselect" })

-- Quick file navigation
map("n", "<leader>e", ":Explore<CR>", { desc = "Open file explorer" })
map("n", "<leader>ff", ":find ", { desc = "Find file" })
map("n", "<leader>a", ":vimgrep ", { desc = "Grep" })

-- Better J behavior
map("n", "J", "mzJ`z", { desc = "Join lines and keep cursor position" })

-- Quick config editing
map("n", "<leader>ec", ":e $MYVIMRC<CR>", { desc = "Edit config" })
map("n", "<leader>el", ":so $MYVIMRC<CR>", { desc = "Reload config" })
map("n", "<leader>er", ":restart<cr>", { desc = "Restart nvim" })

-- ============================================================================
-- USEFUL FUNCTIONS
-- ============================================================================

-- Copy Full File-Path
vim.keymap.set("n", "<leader>pa", function()
  local path = vim.fn.expand("%:p")
  vim.fn.setreg("+", path)
  print("file:", path)
end)

-- Basic autocommands
-- local augroup = vim.api.nvim_create_augroup("UserConfig", {})

-- Highlight yanked text
autocmd("TextYankPost", {
  group = augroup,
  callback = function() vim.highlight.on_yank() end,
})

-- Return to last edit position when opening files
autocmd("BufReadPost", {
  group = augroup,
  callback = function()
    local mark = vim.api.nvim_buf_get_mark(0, "\"")
    local lcount = vim.api.nvim_buf_line_count(0)
    if mark[1] > 0 and mark[1] <= lcount then pcall(vim.api.nvim_win_set_cursor, 0, mark) end
  end,
})

-- Set filetype-specific settings
autocmd("FileType", {
  group = augroup,
  pattern = { "lua", "python" },
  callback = function()
    vim.opt_local.tabstop = 4
    vim.opt_local.shiftwidth = 4
  end,
})

autocmd("FileType", {
  group = augroup,
  pattern = { "javascript", "typescript", "json", "html", "css" },
  callback = function()
    vim.opt_local.tabstop = 2
    vim.opt_local.shiftwidth = 2
  end,
})

-- Auto-close terminal when process exits
autocmd("TermClose", {
  group = augroup,
  callback = function()
    if vim.v.event.status == 0 then vim.api.nvim_buf_delete(0, {}) end
  end,
})

-- Disable line numbers in terminal
autocmd("TermOpen", {
  group = augroup,
  callback = function()
    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
    vim.opt_local.signcolumn = "no"
  end,
})

-- Auto-resize splits when window is resized
autocmd("VimResized", {
  group = augroup,
  callback = function() vim.cmd("tabdo wincmd =") end,
})

-- Create directories when saving files
autocmd("BufWritePre", {
  group = augroup,
  callback = function()
    local dir = vim.fn.expand("<afile>:p:h")
    if vim.fn.isdirectory(dir) == 0 then vim.fn.mkdir(dir, "p") end
  end,
})

lsp.enable({ "lua_ls", "biome", "tinymist", "emmetls" })

autocmd("LspAttach", {
  group = augroup,
  desc = "Handle lsp attaching to buffer",
  callback = function(evt)
    local client = lsp.get_client_by_id(evt.data.client_id)
    if client and client:supports_method("textDocument/completion") then
      vim.opt.completeopt = { "menu", "menuone", "noinsert", "fuzzy", "popup" }
      -- vim.cmd("set completeopt+=noselect")
      lsp.completion.enable(true, client.id, evt.buf, { autotrigger = true })
      map("i", "<C-y>", function() lsp.completion.get() end, { desc = "[comp] accept selection" })
    end
  end,
})

autocmd("LspDetach", {
  group = augroup,
  desc = "Handle lsp deataching from buffer",
  callback = function(evt) end,
})

autocmd("BufWritePre", {
  group = augroup,
  desc = "Format on save (pre)",
  pattern = "*",
  callback = function(evt) lsp.buf.format({ bufnr = evt.buf }) end,
})

-- Command-line completion
vim.opt.wildmenu = true
vim.opt.wildmode = "longest:full,full"
vim.opt.wildignore:append({ "*.o", "*.obj", "*.pyc", "*.class", "*.jar" })

-- Better diff options
vim.opt.diffopt:append("linematch:60")

-- Performance improvements
vim.opt.redrawtime = 10000
vim.opt.maxmempattern = 20000

-- Create undo directory if it doesn't exist
local undodir = vim.fn.expand("~/.vim/undodir")
if vim.fn.isdirectory(undodir) == 0 then vim.fn.mkdir(undodir, "p") end

-- ============================================================================
-- FLOATING TERMINAL
-- ============================================================================

-- terminal
local terminal_state = {
  buf = nil,
  win = nil,
  is_open = false,
}

local function FloatingTerminal()
  -- If terminal is already open, close it (toggle behavior)
  if terminal_state.is_open and vim.api.nvim_win_is_valid(terminal_state.win) then
    vim.api.nvim_win_close(terminal_state.win, false)
    terminal_state.is_open = false
    return
  end

  -- Create buffer if it doesn't exist or is invalid
  if not terminal_state.buf or not vim.api.nvim_buf_is_valid(terminal_state.buf) then
    terminal_state.buf = vim.api.nvim_create_buf(false, true)
    -- Set buffer options for better terminal experience
    vim.api.nvim_buf_set_option(terminal_state.buf, "bufhidden", "hide")
  end

  -- Calculate window dimensions
  local width = math.floor(vim.o.columns * 0.8)
  local height = math.floor(vim.o.lines * 0.8)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  -- Create the floating window
  terminal_state.win = vim.api.nvim_open_win(terminal_state.buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
  })

  -- Set transparency for the floating window
  vim.api.nvim_win_set_option(terminal_state.win, "winblend", 0)

  -- Set transparent background for the window
  vim.api.nvim_win_set_option(
    terminal_state.win,
    "winhighlight",
    "Normal:FloatingTermNormal,FloatBorder:FloatingTermBorder"
  )

  -- Define highlight groups for transparency
  vim.api.nvim_set_hl(0, "FloatingTermNormal", { bg = "none" })
  vim.api.nvim_set_hl(0, "FloatingTermBorder", { bg = "none" })

  -- Start terminal if not already running
  local has_terminal = false
  local lines = vim.api.nvim_buf_get_lines(terminal_state.buf, 0, -1, false)
  for _, line in ipairs(lines) do
    if line ~= "" then
      has_terminal = true
      break
    end
  end

  if not has_terminal then vim.fn.termopen(os.getenv("SHELL")) end

  terminal_state.is_open = true
  vim.cmd("startinsert")

  -- Set up auto-close on buffer leave
  autocmd("BufLeave", {
    buffer = terminal_state.buf,
    callback = function()
      if terminal_state.is_open and vim.api.nvim_win_is_valid(terminal_state.win) then
        vim.api.nvim_win_close(terminal_state.win, false)
        terminal_state.is_open = false
      end
    end,
    once = true,
  })
end

-- Function to explicitly close the terminal
local function CloseFloatingTerminal()
  if terminal_state.is_open and vim.api.nvim_win_is_valid(terminal_state.win) then
    vim.api.nvim_win_close(terminal_state.win, false)
    terminal_state.is_open = false
  end
end

-- Key mappings
vim.keymap.set("n", "<leader>t", FloatingTerminal, { noremap = true, silent = true, desc = "Toggle floating terminal" })
vim.keymap.set("t", "<Esc>", function()
  if terminal_state.is_open then
    vim.api.nvim_win_close(terminal_state.win, false)
    terminal_state.is_open = false
  end
end, { noremap = true, silent = true, desc = "Close floating terminal from terminal mode" })

-- ============================================================================
-- TABS
-- ============================================================================

-- Tab display settings
vim.opt.showtabline = 1 -- Always show tabline (0=never, 1=when multiple tabs, 2=always)
vim.opt.tabline = "" -- Use default tabline (empty string uses built-in)

-- Transparent tabline appearance
vim.cmd([[
  hi TabLineFill guibg=NONE ctermfg=242 ctermbg=NONE
]])

-- Alternative navigation (more intuitive)
vim.keymap.set("n", "<leader>tn", ":tabnew<CR>", { desc = "New tab" })
vim.keymap.set("n", "<leader>tx", ":tabclose<CR>", { desc = "Close tab" })

-- Tab moving
vim.keymap.set("n", "<leader>tm", ":tabmove<CR>", { desc = "Move tab" })
vim.keymap.set("n", "<leader>t>", ":tabmove +1<CR>", { desc = "Move tab right" })
vim.keymap.set("n", "<leader>t<", ":tabmove -1<CR>", { desc = "Move tab left" })

-- Function to open file in new tab
local function open_file_in_tab()
  vim.ui.input({ prompt = "File to open in new tab: ", completion = "file" }, function(input)
    if input and input ~= "" then vim.cmd("tabnew " .. input) end
  end)
end

-- Function to duplicate current tab
local function duplicate_tab()
  local current_file = vim.fn.expand("%:p")
  if current_file ~= "" then
    vim.cmd("tabnew " .. current_file)
  else
    vim.cmd("tabnew")
  end
end

-- Function to close tabs to the right
local function close_tabs_right()
  local current_tab = vim.fn.tabpagenr()
  local last_tab = vim.fn.tabpagenr("$")

  for i = last_tab, current_tab + 1, -1 do
    vim.cmd(i .. "tabclose")
  end
end

-- Function to close tabs to the left
local function close_tabs_left()
  local current_tab = vim.fn.tabpagenr()

  for i = current_tab - 1, 1, -1 do
    vim.cmd("1tabclose")
  end
end

-- Enhanced keybindings
vim.keymap.set("n", "<leader>tO", open_file_in_tab, { desc = "Open file in new tab" })
vim.keymap.set("n", "<leader>td", duplicate_tab, { desc = "Duplicate current tab" })
vim.keymap.set("n", "<leader>tr", close_tabs_right, { desc = "Close tabs to the right" })
vim.keymap.set("n", "<leader>tL", close_tabs_left, { desc = "Close tabs to the left" })

-- Function to close buffer but keep tab if it's the only buffer in tab
local function smart_close_buffer()
  local buffers_in_tab = #vim.fn.tabpagebuflist()
  if buffers_in_tab > 1 then
    vim.cmd("bdelete")
  else
    -- If it's the only buffer in tab, close the tab
    vim.cmd("tabclose")
  end
end
vim.keymap.set("n", "<leader>bd", smart_close_buffer, { desc = "Smart close buffer/tab" })

autocmd("LspAttach", {
  group = augroup,
  desc = "Handle lsp attaching to buffer",
  callback = function(evt)
    local client = lsp.get_client_by_id(evt.data.client_id)
    if client and client:supports_method("textDocument/completion") then
      vim.opt.completeopt = { "menu", "menuone", "noinsert", "fuzzy", "popup" }
      -- vim.cmd("set completeopt+=noselect")
      lsp.completion.enable(true, client.id, evt.buf, { autotrigger = true })
      map("i", "<C-y>", function() lsp.completion.get() end, { desc = "[comp] accept selection" })
    end
  end,
})

autocmd("LspDetach", {
  group = augroup,
  desc = "Handle lsp deataching from buffer",
  callback = function(evt) end,
})
autocmd("BufWritePre", {
  group = augroup,
  desc = "Format on save (pre)",
  pattern = "*",
  callback = function(evt) lsp.buf.format({ bufnr = evt.buf }) end,
})

-- -- [[ OPTS ]] --------------------------------------------------------------------------------------
-- vim.o.number = true
-- vim.o.relativenumber = true
-- vim.o.signcolumn = "yes"
-- vim.o.termguicolors = true
-- vim.o.wrap = false
-- vim.o.tabstop = 4
-- vim.o.swapfile = false
-- vim.g.mapleader = ","
-- vim.g.maplocalleader = " "
-- vim.o.winborder = "rounded"
-- vim.o.clipboard = "unnamedplus"
-- vim.o.cursorline = true
--
-- if vim.fn.executable "rg" == 1 then
--   vim.opt.grepprg = "rg --vimgrep --smart-case --path"
--   vim.opt.grepformat = "%f:%l:%c:%m"
-- end
--
-- -- [[ FUNCS ]] -------------------------------------------------------------------------------------
-- local function open_file_in_vsplit()
--   vim.ui.input({ prompt = 'File to open in new vsplit: ', completion = 'file' }, function(input)
--     if input and input ~= '' then
--       vim.cmd('vsplit ' .. input)
--     end
--   end)
-- end
--
-- -- [[ MAPS ]] --------------------------------------------------------------------------------------
-- map("n", "<leader>o", ":update<CR> :source<CR>")
-- map("n", "<leader>w", ":write<CR>")
-- map("n", "<leader>q", ":quit<CR>")
-- map("n", "<localleader><localleader>", "<C-^>", { desc = "last buffer" })
-- map("n", "H", "^")
-- map("n", "L", "$")
--
-- map({ "v", "x" }, "L", "g_")
-- map({ "v", "x" }, "H", "g^")
-- map("n", "0", "^")
-- map({ "n", "v", "x" }, "<leader>y", "\"+y<CR>")
-- map({ "n", "v", "x" }, "<leader>d", "\"+d<CR>")
--
-- map("n", "n", "nzz")
-- map("n", "N", "Nzz")
-- -- map("x", "p", [['pgv"' . v:register . 'y']], { expr = true, remap = false })
-- vim.cmd([[xnoremap <expr> p 'pgv"' . v:register . 'y']])
--
-- map("n", "x", "\"_x")
-- map("n", "X", "\"_X")
-- map("n", "D", "\"_D")
-- map("n", "c", "\"_c")
-- map("n", "C", "\"_C")
-- map("n", "cc", "\"_S")
--
-- map("x", "x", "\"_x")
-- map("x", "X", "\"_X")
-- map("x", "D", "\"_D")
-- map("x", "c", "\"_c")
-- map("x", "C", "\"_C")
--
-- map("n", "dd", function()
--   if vim.fn.prevnonblank(".") ~= vim.fn.line(".") then
--     return "\"_dd"
--   else
--     return "dd"
--   end
-- end, { expr = true, desc = "Special Line Delete" })
--
-- map("n", "<leader>ev", ":leftabove vsplit | vertical resize 40 | Oil<CR>")
-- map("n", "<leader>ff", ":Pick files<CR>")
-- map("n", "<leader>a", ":Pick grep_live<CR>")
-- map("n", "<leader>fh", ":Pick help<CR>")
-- map("n", "<leader>ev", ":leftabove vsplit | vertical resize 40 | Oil<CR>")
-- map("n", "<leader>F", lsp.buf.format)
--
-- map("n", "<C-h>", "<C-w><C-h>", { desc = "Move focus to the left window" })
-- map("n", "<C-l>", "<C-w><C-l>", { desc = "Move focus to the right window" })
-- map("n", "<C-j>", "<C-w><C-j>", { desc = "Move focus to the lower window" })
-- map("n", "<C-k>", "<C-w><C-k>", { desc = "Move focus to the upper window" })
--
--
-- map('n', '<leader>en', open_file_in_vsplit, { desc = 'Open file in new vsplit' })
--
--
-- pack.add({
--   { src = 'https://github.com/sainnhe/everforest' },
--   { src = "https://github.com/rktjmp/lush.nvim" },
--   { src = "https://github.com/everviolet/nvim",                             name = "evergarden" },
--   { src = "https://github.com/stevearc/oil.nvim" },
--   { src = "https://github.com/echasnovski/mini.pick" },
--   { src = "https://github.com/nvim-treesitter/nvim-treesitter",             version = "main" },
--   { src = "https://github.com/nvim-treesitter/nvim-treesitter-textobjects", version = "main" },
--   { src = "https://github.com/neovim/nvim-lspconfig" },
--   { src = "https://github.com/chomosuke/typst-preview.nvim" },
--   { src = "https://github.com/vague2k/vague.nvim" },
--   { src = "https://github.com/zenbones-theme/zenbones.nvim" },
-- })
--
--
-- require("mini.pick").setup()
-- require("nvim-treesitter").setup()
--
-- local treesitter_ensure_installed = { "svelte", "typescript", "tsx", "javascript", "jsx", "json", "toml", "yaml", "lua",
--   "heex", "elixir", "bash",
--   "comment",
--   "markdown", "markdown_inline", "sh", "html", "css" }
-- local installed = require("nvim-treesitter.config").get_installed("parsers")
-- local not_installed = vim.tbl_filter(function(parser) return not vim.tbl_contains(installed, parser) end,
--   treesitter_ensure_installed)
-- if #not_installed > 0 then require("nvim-treesitter").install(not_installed) end
--
-- local syntax_on = {
--   asciidoc = true,
--   elixir = true,
--   php = true,
-- }
--
-- local group = vim.api.nvim_create_augroup("mega_minvim_treesitter", { clear = true })
--
-- autocmd("FileType", {
--   group = group,
--   callback = function(args)
--     local bufnr = args.buf
--     local filetype = vim.api.nvim_get_option_value("filetype", { buf = bufnr })
--     if filetype == "" then return end -- Stops if no filetype is detected.
--
--     local ok, parser = pcall(vim.treesitter.get_parser, bufnr)
--     if not ok or not parser then
--       -- vim.notify(string.format("Missing ts parser %s for bufnr %d", parser, bufnr), L.WARN)
--       return
--     end
--
--     pcall(vim.treesitter.start)
--     -- if vim.treesitter.language.add(filetype) then
--     --   vim.treesitter.start(bufnr, filetype)
--     -- else
--     --   vim.notify(string.format("Missing ts parser for %s", filetype), L.WARN)
--     -- end
--
--     local ft = vim.bo[bufnr].filetype
--     if syntax_on[ft] then vim.bo[bufnr].syntax = "on" end
--
--     vim.schedule(function()
--       -- vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
--       vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
--     end)
--   end,
-- })
--
-- autocmd("User", {
--   group = group,
--   pattern = "TSUpdate",
--   callback = function()
--     local parsers = require("nvim-treesitter.parsers")
--
--     -- parsers.lua = {
--     --   tier = 0,
--     --
--     --   ---@diagnostic disable-next-line: missing-fields
--     --   install_info = {
--     --     path = "~/plugins/tree-sitter-lua",
--     --     files = { "src/parser.c", "src/scanner.c" },
--     --   },
--     -- }
--   end,
-- })
--
-- -- require("nvim-treesitter.configs").setup({
-- --   ensure_installed = {
-- --     "svelte", "typescript", "javascript", "lua", "heex", "elixir", "bash", "comment", "markdown", "markdown_inline"
-- --   },
-- --   auto_install = false,
-- --   highlight = {
-- --     enable = true,
-- --     additional_vim_regex_highlighting = false,
-- --   },
-- --   indent = {
-- --     enable = true,
-- --   },
-- -- })
-- do
--   function Oil_winbar()
--     local path = vim.fn.expand "%"
--     path = path:gsub("oil://", "")
--
--     return "  " .. vim.fn.fnamemodify(path, ":.")
--   end
--
--   require("oil").setup(
--     {
--       columns = {
--         "icon",
--         "permissions",
--         "size",
--         "mtime",
--       },
--       delete_to_trash = true,
--       keymaps = {
--         ["<CR>"] = { "actions.select", opts = { vertical = true, close = true }, desc = "Open the entry in a vertical split" },
--         ["<C-e>"] = { "actions.select", opts = {}, desc = "Open the entry in a current split" },
--         ["<M-h>"] = "actions.select_split",
--       },
--       win_options = {
--         winbar = "%{v:lua.Oil_winbar()}",
--       },
--       view_options = {
--         show_hidden = true,
--         is_always_hidden = function(name, _)
--           local folder_skip = { "dev-tools.locks", "dune.lock", "_build" }
--           return vim.tbl_contains(folder_skip, name)
--         end,
--       },
--     }
--   )
-- end
--
-- require("vague").setup({ transparent = true })
--
-- lsp.enable({ "lua_ls", "biome", "tinymist", "emmetls" })
--
--   pcall(vim.cmd.colorscheme, "megaforest")
--
-- command("Up", "silent up | e", {}) -- Quick refresh if Treesitter bugs out
-- command("R", "silent restart", {}) -- Quick refresh if Treesitter bugs out
--
--
-- -- Highlight yanked text
-- autocmd("TextYankPost", {
--   group = augroup,
--   desc = "Highlight on yank",
--   callback = function()
--     vim.highlight.on_yank()
--   end,
-- })
--
-- -- Return to last edit position when opening files
-- autocmd("BufReadPost", {
--   group = augroup,
--   desc = "Restore cursor position",
--   callback = function()
--     local mark = vim.api.nvim_buf_get_mark(0, '"')
--     local lcount = vim.api.nvim_buf_line_count(0)
--     if mark[1] > 0 and mark[1] <= lcount then
--       pcall(vim.api.nvim_win_set_cursor, 0, mark)
--     end
--   end,
-- })
--
-- autocmd("LspAttach", {
--   group = augroup,
--   desc = "Handle lsp attaching to buffer",
--   callback = function(evt)
--     local client = lsp.get_client_by_id(evt.data.client_id)
--     if client and client:supports_method("textDocument/completion") then
--       vim.opt.completeopt = { "menu", "menuone", "noinsert", "fuzzy", "popup" }
--       -- vim.cmd("set completeopt+=noselect")
--       lsp.completion.enable(true, client.id, evt.buf, { autotrigger = true })
--       map("i", "<C-y>", function() lsp.completion.get() end, { desc = "[comp] accept selection" })
--     end
--   end,
-- })
--
-- autocmd("LspDetach", {
--   group = augroup,
--   desc = "Handle lsp deataching from buffer",
--   callback = function(evt)
--   end,
-- })
--
-- autocmd("BufWritePre", {
--   group = augroup,
--   desc = "Format on save (pre)",
--   pattern = "*",
--   callback = function(evt)
--     lsp.buf.format({ bufnr = evt.buf })
--   end,
-- })
--
-- autocmd('PackChanged', {
--   desc = 'Handle nvim-treesitter updates',
--   group = augroup,
--   callback = function(evt)
--     if evt.data.kind == 'update' then
--       vim.notify('nvim-treesitter updated, running TSUpdate...', L.INFO)
--       ---@diagnostic disable-next-line: param-type-mismatch
--       local ok = pcall(vim.cmd, 'TSUpdate')
--       if ok then
--         vim.notify('TSUpdate completed successfully!', L.INFO)
--       else
--         vim.notify('TSUpdate command not available yet, skipping', L.WARN)
--       end
--     end
--   end,
-- })
