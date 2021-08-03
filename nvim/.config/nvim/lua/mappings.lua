local api = vim.api
local map = mega.map

-- [convenience mappings] ------------------------------------------------------

-- make the tab key match bracket pairs
api.nvim_exec("silent! unmap [%", true)
api.nvim_exec("silent! unmap ]%", true)

map("n", "<Tab>", "%", {noremap = false})
map("s", "<Tab>", "%", {noremap = false})
map("n", "<Tab>", "%", {noremap = true})
map("v", "<Tab>", "%", {noremap = true})
map("x", "<Tab>", "%", {noremap = true})

-- [overrides/remaps mappings] ---------------------------------------------------------

-- useful remaps from theprimeagen:
-- - ref: https://www.youtube.com/watch?v=hSHATqh8svM

-- Convenient Line operations
map("n", "H", "^")
map("n", "L", "$")
map("v", "L", "g_")
-- map("n", "Y", '"+y$')
map("n", "Y", "yg_") -- copy to last non-blank char of the line

-- Remap VIM 0 to first non-blank character
map("n", "0", "^")

map("n", "q", "<Nop>")
map("n", "Q", "@q")
map("v", "Q", ":norm @q<CR>")

-- Join / Split Lines
map("n", "J", "mzJ`z") -- Join lines and keep our cursor stabilized
map("n", "S", "i<CR><ESC>^mwgk:silent! s/\v +$//<CR>:noh<CR>`w") -- Split line

-- TODO: merge the two remaps of j/k below
-- Jumplist mutations
map("n", "k", '(v:count > 5 ? "m\'" . v:count : \'\') . \'k\'', {expr = true})
map("n", "j", '(v:count > 5 ? "m\'" . v:count : \'\') . \'j\'', {expr = true})

-- Remap for dealing with word wrap
map("n", "k", "v:count == 0 ? 'gk' : 'k'", {expr = true})
map("n", "j", "v:count == 0 ? 'gj' : 'j'", {expr = true})

-- Clear highlights
api.nvim_exec([[nnoremap <silent><ESC> :syntax sync fromstart<CR>:nohlsearch<CR>:redrawstatus!<CR><ESC> ]], true)

-- Keep line in middle of buffer when searching
map("n", "n", "(v:searchforward ? 'n' : 'N') . 'zzzv'", {noremap = true, expr = true})
map("n", "N", "(v:searchforward ? 'N' : 'n') . 'zzzv'", {noremap = true, expr = true})

-- Readline bindings (command)
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
  map("c", binding.lhs, binding.rhs, binding.opts)
end

-- Undo breakpoints
map("i", ",", ",<C-g>u")
map("i", ".", ".<C-g>u")
map("i", "!", "!<C-g>u")
map("i", "?", "?<C-g>u")

-- nnoremap cn *``cgn
-- nnoremap cN *``cgN
-- - Go on top of a word you want to change
-- - Press cn or cN
-- - Type the new word you want to replace it with
-- - Smash that dot '.' multiple times to change all the other occurrences of the word
-- It's quicker than searching or replacing. It's pure magic.

-- Default to case insensitive search
-- map("n", "/", "/\v")
-- map("v", "/", "/\v")

-- [custom mappings] -----------------------------------------------------------

map("n", "<leader>,", ":buffer *")
map("n", "<leader>.", ":e<space>**/")
-- map("n", "<leader>sT", ":tjump *")

-- execute our current lua file
map("n", "<leader>x", "<cmd>luafile %<cr>")

-- Things 3
api.nvim_exec(
  [[command! -nargs=* Things :silent !open "things:///add?show-quick-entry=true&title=%:t&notes=%<cr>"]],
  true
)
map("n", "<Leader>T", "<cmd>Things<CR>")

-- Spelling
-- map("n", "<leader>s", "z=e") -- Correct current word
map("n", "<leader>s", "b1z=e") -- Correct previous word
map("n", "<leader>S", "zg") -- Add word under cursor to dictionary

-- # find and replace in multiple files
map("n", "<leader>R", "<cmd>cfdo %s/<C-r>s//g | update<cr>")

-- [plugin mappings] -----------------------------------------------------------

-- # golden_size
map("n", "<Leader>r", "<cmd>lua require('golden_size').on_win_enter()<CR>")

-- # git-related
map("n", "<Leader>gb", "<cmd>GitMessenger<CR>")
map("n", "<Leader>gh", "<cmd>GBrowse!<CR>")
map("x", "<Leader>gh", "<cmd>GBrowse!<CR>")
map("v", "<Leader>gh", "<cmd>GBrowse!<CR>")
map("v", "<Leader>gh", "<cmd>GBrowse!<CR>")

-- # markdown-related
map("n", "<Leader>mP", "<cmd>MarkdownPreview<CR>")

-- # slash
vim.cmd([[noremap <plug>(slash-after) zz]])
api.nvim_exec(
  [[
if has('timers')
  " Blink 2 times with 50ms interval
  noremap <expr> <plug>(slash-after) slash#blink(2, 50)
endif
  ]],
  true
)

-- # easy-align
-- start interactive EasyAlign in visual mode (e.g. vipga)
-- map("v", "<Enter>", "<Plug>(EasyAlign)")
map("v", "ga", "<Plug>(EasyAlign)")
map("x", "ga", "<Plug>(EasyAlign)")

-- start interactive EasyAlign for a motion/text object (e.g. gaip)
map("n", "ga", "<Plug>(EasyAlign)")

-- easyalign
map("v", "<Enter>", "<Plug>(EasyAlign)")
map("n", "<Leader>a", "<Plug>(EasyAlign)")

-- # Dash
map("n", "<leader>D", "<cmd>Dash<CR>")

-- # paq
map("n", "<F5>", "<cmd>lua mega.plugins()<cr>")

-- # telescope
map("n", "<leader>ff", "<cmd>lua require('telescope.builtin').git_files()<cr>")
map("n", "<leader>a", ":lua require('telescope.builtin').grep_string({ search = vim.fn.input('grep > ') })<CR>")
map("n", "<leader>A", ":lua require('telescope.builtin').grep_string({ search = vim.fn.expand('<cword>') })<CR>")
-- map("n", "z=", "<cmd>lua require('telescope.builtin').spell_suggest()<CR>")

-- telescope-zettelkasten
function _G.search_zettel()
  require("telescope.builtin").find_files {
    prompt_title = "Search ZK",
    hidden = true,
    shorten_path = false,
    cwd = "~/Documents/_zettel"
  }
end
map("n", "<leader>fz", "<cmd>lua _G.search_zettel()<cr>")

-- telescope-orgmode
map("n", "<leader>os", [[<cmd>lua require('telescope.builtin').live_grep({search_dirs={'$HOME/Nextcloud/org'}})<cr>]])
map("n", "<leader>of", [[<cmd>lua require('telescope.builtin').find_files({search_dirs={'$HOME/Nextcloud/org'}})<cr>]])

-- # fzf-lua
map("n", "<leader>ff", "<cmd>lua require('fzf-lua').files()<cr>")
map("n", "<leader>a", "<cmd>lua require('fzf-lua').live_grep()<cr>")
map("n", "<leader>A", "<cmd>lua require('fzf-lua').grep_cword()<cr>")
map("v", "<leader>A", "<cmd>lua require('fzf-lua').grep_visual()<cr>")
