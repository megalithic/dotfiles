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
mega.map("n", "<leader>s", "b1z=e") -- Correct previous word

-- PROSE MODE
-- @evantravers, thanks!
function _G.toggle_prose()
  -- toggle_zen()
  local gitsigns = require("gitsigns")
  if (vim.g.proseMode == true) then
    vim.cmd "PencilOff"
    vim.cmd "Limelight!"
    vim.cmd "Goyo!"
    vim.cmd [[set wrap!]]
    vim.cmd [[silent !tmux set status on]]

    gitsigns.attach()
    vim.o.showmode = true
    vim.o.showcmd = true
    -- vim.wo.number = true
    -- vim.wo.relativenumber = true
    vim.g.proseMode = false
  else
    vim.cmd "packadd vim-pencil"
    vim.cmd "packadd goyo.vim"
    vim.cmd "packadd limelight.vim"
    vim.cmd [[silent !tmux set status off]]
    vim.o.showmode = false
    vim.o.showcmd = false
    gitsigns.detach()
    -- vim.wo.number = false
    -- vim.wo.relativenumber = false
    vim.wo.foldlevel = 4
    vim.cmd "PencilSoft"
    vim.cmd "Limelight"
    vim.cmd "Goyo"
    vim.g.proseMode = true
  end
end
mega.map("n", "<leader>gp", "<cmd>lua toggle_prose()<cr>")

-- [plugin mappings] -----------------------------------------------------------

-- # git-related
mega.map("n", "<Leader>gb", "<cmd>GitMessenger<CR>")
mega.map("n", "<Leader>gh", "<cmd>GBrowse!<CR>")
mega.map("x", "<Leader>gh", "<cmd>GBrowse!<CR>")
mega.map("v", "<Leader>gh", "<cmd>GBrowse!<CR>")
mega.map("v", "<Leader>gh", "<cmd>GBrowse!<CR>")

-- # markdown-related
mega.map("n", "<Leader>mp", "<cmd>MarkdownPreview<CR>")

-- # slash
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

-- # easy-align
-- start interactive EasyAlign in visual mode (e.g. vipga)
-- mega.map("v", "<Enter>", "<Plug>(EasyAlign)")
mega.map("v", "ga", "<Plug>(EasyAlign)")
mega.map("x", "ga", "<Plug>(EasyAlign)")

-- start interactive EasyAlign for a motion/text object (e.g. gaip)
mega.map("n", "ga", "<Plug>(EasyAlign)")

-- # FZF
-- mega.map("n", "<Leader>m", "<cmd>FzfFiles<CR>")
mega.map("n", "<Leader>a", "<cmd>FzfRg<CR>")
mega.map("n", "<Leader>A", "<ESC>:exe('FzfRg '.expand('<cword>'))<CR>")
mega.map(
  "n",
  "<leader>ff",
  "<cmd>lua require('fzf-commands').files({ fzf = function(contents, options) return require('fzf').fzf(contents, options, { height = 50, width = 200 }) end })<CR>"
)

function _G.search_zettel()
  require("telescope.builtin").find_files {
    prompt_title = "Search ZK",
    hidden = true,
    shorten_path = false,
    cwd = "~/Documents/_zettel"
  }
end
mega.map("n", "<leader>fz", ":lua _G.search_zettel()<cr>")

-- # Dash
mega.map("n", "<leader>D", "<cmd>Dash<CR>")

-- # markdown-preview
mega.map("n", "<leader>gm", "<Plug>(MarkdownPreview)")

-- # telescope
-- mega.map("n", "<leader>ff", ":lua require('telescope.builtin').find_files({ hidden = true })<cr>")
-- mega.map("n", "<leader>ff", ":lua require('telescope.builtin').git_files()<cr>")
-- mega.map("n", "<leader>m", ":lua require('telescope.builtin').find_files()<cr>")
-- mega.map("n", "<leader>a", ":lua require('telescope.builtin').grep_string({ search = vim.fn.input('grep > ')})<CR>")
-- mega.map("n", "<leader>A", ":lua require('telescope.builtin').grep_string { search = vim.fn.expand('<cword>') }<CR>")
-- mega.map("n", "z=", "<cmd>lua require('telescope.builtin').spell_suggest()<CR>")
