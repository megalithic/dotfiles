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

-- [override mappings] ---------------------------------------------------------

-- Convenient Line operations
map("n", "H", "^")
map("n", "L", "$")
map("v", "L", "g_")
map("n", "Y", '"+y')
-- Remap VIM 0 to first non-blank character
map("n", "0", "^")

map("n", "q", "<Nop>")
map("n", "Q", "@q")
map("v", "Q", ":norm @q<CR>")

-- Join / Split Lines
map("n", "J", "mzJ`z") -- Join lines
map("n", "S", "i<CR><ESC>^mwgk:silent! s/\v +$//<CR>:noh<CR>`w") -- Split line

--Remap for dealing with word wrap
map('n', 'k', "v:count == 0 ? 'gk' : 'k'", { noremap = true, expr = true, silent = true })
api.nvim_set_keymap('n', 'j', "v:count == 0 ? 'gj' : 'j'", { noremap = true, expr = true, silent = true })

-- clear highlights
-- map("n", "<ESC>", "<cmd>syntax sync fromstart<CR>:nohlsearch<CR>:redrawstatus!<CR><ESC>", {silent = true})
api.nvim_exec([[nnoremap <silent><ESC> :syntax sync fromstart<CR>:nohlsearch<CR>:redrawstatus!<CR><ESC> ]], true)

-- keep line in middle of buffer when searching
map("n", "n", "(v:searchforward ? 'n' : 'N') . 'zzzv'", {noremap = true, expr = true})
map("n", "N", "(v:searchforward ? 'N' : 'n') . 'zzzv'", {noremap = true, expr = true})

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
  map("c", binding.lhs, binding.rhs, binding.opts)
end

-- Default to case insensitive search
-- map("n", "/", "/\v")
-- map("v", "/", "/\v")

-- [custom mappings] -----------------------------------------------------------

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

-- PROSE MODE
-- @evantravers, thanks!
function _G.toggle_prose()
  -- toggle_zen()
  local gitsigns = require("gitsigns")
  if (vim.g.proseMode == true) then
    -- vim.cmd "PencilOff"
    vim.cmd "Limelight!"
    vim.cmd "Goyo!"
    vim.cmd [[set wrap!]]
    vim.cmd [[set colorcolumn=+1]]
    vim.cmd [[silent !tmux set status on]]

    gitsigns.attach()
    vim.o.showmode = true
    vim.o.showcmd = true
    -- vim.wo.number = true
    -- vim.wo.relativenumber = true
    vim.g.proseMode = false
  else
    -- vim.cmd "packadd vim-pencil"
    vim.cmd "packadd goyo.vim"
    vim.cmd "packadd limelight.vim"
    vim.cmd [[set colorcolumn=0]]
    vim.cmd [[silent !tmux set status off]]
    vim.o.showmode = false
    vim.o.showcmd = false
    gitsigns.detach()
    -- vim.wo.number = false
    -- vim.wo.relativenumber = false
    vim.wo.foldlevel = 4
    -- vim.cmd "PencilSoft"
    vim.cmd "Limelight"
    vim.cmd "Goyo"
    vim.g.proseMode = true
  end
end

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
map("n", "<leader>mp", "<cmd>lua toggle_prose()<cr>")

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

-- # FZF
-- map("n", "<Leader>m", "<cmd>FzfFiles<CR>")
map("n", "<Leader>a", "<cmd>FzfRg<CR>")
map("n", "<Leader>A", "<ESC>:exe('FzfRg '.expand('<cword>'))<CR>")
map(
  "n",
  "<leader>ff",
  "<cmd>lua require('fzf-commands').files({ fzf = function(contents, options) return require('fzf').fzf(contents, options, { height = 50, width = 200 }) end })<CR>"
)

-- # Dash
map("n", "<leader>D", "<cmd>Dash<CR>")

-- # markdown-preview
map("n", "<leader>gm", "<Plug>(MarkdownPreview)")

-- # paq
map("n", "<F5>", "<cmd>lua mega.plugins()<cr>")

-- # bullets.vim
-- map(
--   "i",
--   "<CR>",
--   -- "<cmd>pumvisible() ? '\<C-y>' : ''",
--   -- function()
--   --   if vim.fn.pumvisible() == 0 then
--   --     -- vim.cmd[[pumvisible() ? "\<C-y>" : "\<Plug>(bullets-insert-new-bullet)"]]
--   --     vim.cmd([[InsertNewBullet]])
--   --   end
--   -- end,
--   {silent = false, expr = true, noremap = false}
-- )
-- map(
--   "i",
--   "<C-T>",
--   function()
--     vim.cmd([[BulletDemote]])
--   end
-- )
-- map(
--   "i",
--   "<C-D>",
--   function()
--     vim.cmd([[BulletPromote]])
--   end
-- )
-- vim.keymap.imap<silent><expr> <CR> pumvisible() ? "\<C-y>" : "\<Plug>(bullets-insert-new-bullet)"
-- inoremap {
--   "<M-CR>",
--   function()
--     vim.cmd [[InsertNewBullet]]
--   end,
--   {nowait = true, buffer = true}
-- }
-- inoremap {
--   "<C-T>",
--   function()
--     vim.cmd [[BulletDemote]]
--   end,
--   {nowait = true, buffer = true}
-- }
-- inoremap {
--   "<C-D>",
--   function()
--     vim.cmd [[BulletPromote]]
--   end,
--   {nowait = true, buffer = true}
-- }

-- # telescope
-- map("n", "<leader>ff", "<cmd>lua require('telescope.builtin').find_files({hidden = true})<cr>")
map(
  "n",
  "<leader>ff",
  "<cmd>lua require('telescope.builtin').git_files(require('telescope.themes').get_dropdown({}))<cr>"
)

-- map("n", "<leader>ff", ":lua require('telescope.builtin').find_files(require('telescope.themes').get_dropdown({ winblend = 10, hidden = true }))<cr>")
-- map("n", "<leader>ff", ":lua require('telescope.builtin').git_files()<cr>")
-- map("n", "<leader>m", ":lua require('telescope.builtin').find_files()<cr>")
map("n", "<leader>a", ":lua require('telescope.builtin').grep_string({ search = vim.fn.input('grep > ')})<CR>")
map("n", "<leader>A", ":lua require('telescope.builtin').grep_string { search = vim.fn.expand('<cword>') }<CR>")
-- map("n", "z=", "<cmd>lua require('telescope.builtin').spell_suggest()<CR>")

-- zettelkasten
function _G.search_zettel()
  require("telescope.builtin").find_files {
    prompt_title = "Search ZK",
    hidden = true,
    shorten_path = false,
    cwd = "~/Documents/_zettel"
  }
end
map("n", "<leader>fz", "<cmd>lua _G.search_zettel()<cr>")

-- orgmode
map('n', '<leader>os', [[<cmd>lua require('telescope.builtin').live_grep({search_dirs={'$HOME/Nextcloud/org'}})<cr>]])
map('n', '<leader>of', [[<cmd>lua require('telescope.builtin').find_files({search_dirs={'$HOME/Nextcloud/org'}})<cr>]])

map('n', '<leader>,', ':buffer *')
map('n', '<leader>.', ':e<space>**/')
map('n', '<leader>sT', ':tjump *')
