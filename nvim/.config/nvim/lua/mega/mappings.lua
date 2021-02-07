-- [convenience mappings] ------------------------------------------------------

-- make the tab key match bracket pairs
vim.api.nvim_exec("silent! unmap [%", true)
vim.api.nvim_exec("silent! unmap ]%", true)

mega.map("n", "<Tab>", "%", {noremap = false})
mega.map("s", "<Tab>", "%", {noremap = false})
mega.map("n", "<Tab>", "%", {noremap = true})
mega.map("v", "<Tab>", "%", {noremap = true})
mega.map("x", "<Tab>", "%", {noremap = true})

-- [override mappings] ---------------------------------------------------------

-- Convenient Line operations
mega.map("n", "H", "^")
mega.map("n", "L", "$")
mega.map("v", "L", "g_")
mega.map("n", "Y", '"+y')
-- Remap VIM 0 to first non-blank character
mega.map("n", "0", "^")

mega.map("n", "q", "<Nop>")
mega.map("n", "Q", "@q")
mega.map("v", "Q", ":norm @q<CR>")

-- Join / Split Lines
mega.map("n", "J", "mzJ`z") -- Join lines
mega.map("n", "S", "i<CR><ESC>^mwgk:silent! s/\v +$//<CR>:noh<CR>`w") -- Split line

-- clear highlights
-- mega.map("n", "<ESC>", "<cmd>syntax sync fromstart<CR>:nohlsearch<CR>:redrawstatus!<CR><ESC>", {silent = true})
vim.api.nvim_exec([[nnoremap <silent><ESC> :syntax sync fromstart<CR>:nohlsearch<CR>:redrawstatus!<CR><ESC> ]], true)

-- keep line in middle of buffer when searching
mega.map("n", "n", "(v:searchforward ? 'n' : 'N') . 'zzzv'", {noremap = true, expr = true})
mega.map("n", "N", "(v:searchforward ? 'N' : 'n') . 'zzzv'", {noremap = true, expr = true})

-- readline bindings
local rl_bindings = {
  {lhs = "<c-a>", rhs = "<home>", opts = {noremap = true}},
  {lhs = "<c-e>", rhs = "<end>", opts = {noremap = true}},
  {lhs = "<c-f>", rhs = "<right>", opts = {noremap = true}},
  {lhs = "<c-b>", rhs = "<left>", opts = {noremap = true}},
  {lhs = "<c-p>", rhs = "<up>", opts = {noremap = true}},
  {lhs = "<c-n>", rhs = "<down>", opts = {noremap = true}},
  {lhs = "<c-d>", rhs = "<del>", opts = {noremap = true}}
}
for _, binding in ipairs(rl_bindings) do
  mega.map("c", binding.lhs, binding.rhs, binding.opts)
end

-- Default to case insensitive search
-- mega.map("n", "/", "/\v")
-- mega.map("v", "/", "/\v")

-- [custom mappings] -----------------------------------------------------------

-- Things 3
vim.api.nvim_exec(
  [[command! -nargs=* Things :silent !open "things:///add?show-quick-entry=true&title=%:t&notes=%<cr>"]],
  true
)
mega.map("n", "<Leader>T", "<cmd>Things<CR>")

-- Spelling
-- map("x", "b1z=e") -- Correct previous word
-- utils.lmap("c", "1z=1") -- Correct current word
-- utils.lmap("s", ":lua cycle_lang()<cr>") -- Change spelling language
--
--do
--  local i = 1
--  local langs = {"", "en", "es", "de"}
--  function cycle_lang()
--    i = (i % #langs) + 1 -- update index
--    b.spelllang = langs[i] -- change spelllang
--    w.spell = langs[i] ~= "" -- if empty then nospell
--  end
--end

-- Zoom the current split into it's own tab (toggleable)
-- local function toggle_zen()
--   vim.wo.list = not vim.wo.list --(hidden chars)
--   vim.wo.number = not vim.wo.number
--   vim.wo.relativenumber = not vim.wo.relativenumber
--   vim.wo.cursorline = not vim.wo.cursorline
--   vim.wo.cursorcolumn = not vim.wo.cursorcolumn
--   vim.wo.colorcolumn = vim.wo.colorcolumn == "0" and "80" or "0"
--   vim.wo.laststatus = vim.o.laststatus == 2 and 0 or 2
--   vim.o.ruler = not vim.o.ruler
-- end
-- mega.map("n", "<leader>z", ":lua toggle_zen()<cr>")

-- Other mappings
-- utils.lmap("l", "<cmd>luafile %<cr>") -- source lua file
-- utils.lmap("t", "<cmd> sp<cr>|<cmd>te   <cr>i") -- open terminal
-- utils.lmap("rc", "<cmd> e ~/.config/nvim <cr>") -- open config directory

vim.cmd([[noremap <plug>(slash-after) zz]])
vim.api.nvim_exec(
  [[
if has('timers')
  " Blink 2 times with 50ms interval
  noremap <expr> <plug>(slash-after) slash#blink(2, 50)
endif
  ]],
  true
)

-- [plugin mappings] -----------------------------------------------------------

mega.map("n", "<Leader>m", "<cmd>FzfFiles<CR>")
mega.map("n", "<Leader>a", "<cmd>FzfRg<CR>")
mega.map("n", "<Leader>A", "<ESC>:exe('FzfRg '.expand('<cword>'))<CR>")
mega.map("n", "<Leader>b", "<cmd>FzfBuffers<CR>")
