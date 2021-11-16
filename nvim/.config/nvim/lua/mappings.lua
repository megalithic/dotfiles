local cmd = vim.cmd
local map, command, exec = mega.map, mega.command, mega.exec

--[[
  ╭────────────────────────────────────────────────────────────────────────────────────────────────────╮
  │  String value  │  Help page   │  Affected modes                           │  Vimscript equivalent  │
  │────────────────────────────────────────────────────────────────────────────────────────────────────│
  │  ''            │  mapmode-nvo │  Normal, Visual, Select, Operator-pending │  :map                  │
  │  'n'           │  mapmode-n   │  Normal                                   │  :nmap                 │
  │  'v'           │  mapmode-v   │  Visual and Select                        │  :vmap                 │
  │  's'           │  mapmode-s   │  Select                                   │  :smap                 │
  │  'x'           │  mapmode-x   │  Visual                                   │  :xmap                 │
  │  'o'           │  mapmode-o   │  Operator-pending                         │  :omap                 │
  │  '!'           │  mapmode-ic  │  Insert and Command-line                  │  :map!                 │
  │  'i'           │  mapmode-i   │  Insert                                   │  :imap                 │
  │  'l'           │  mapmode-l   │  Insert, Command-line, Lang-Arg           │  :lmap                 │
  │  'c'           │  mapmode-c   │  Command-line                             │  :cmap                 │
  │  't'           │  mapmode-t   │  Terminal                                 │  :tmap                 │
  ╰────────────────────────────────────────────────────────────────────────────────────────────────────╯
--]]

-- [convenience mappings] ------------------------------------------------------

-- make the tab key match bracket pairs
exec("silent! unmap [%", true)
exec("silent! unmap ]%", true)

map("n", "<Tab>", "%", { noremap = false })
map("s", "<Tab>", "%", { noremap = false })
map("v", "<Tab>", "%", { noremap = false })
map("x", "<Tab>", "%", { noremap = false })
map("o", "<Tab>", "%", { noremap = false })

-- map("x", "i<Tab>", "<Plug>(matchup-i%)", { noremap = false })
-- map("o", "i<Tab>", "<Plug>(matchup-i%)", { noremap = false })
-- map("x", "a<Tab>", "<Plug>(matchup-a%)", { noremap = false })
-- map("o", "a<Tab>", "<Plug>(matchup-a%)", { noremap = false })

-- [overrides/remaps mappings] ---------------------------------------------------------
--
exec([[
" -- ( overrides ) --
" Help
noremap <C-]> K

" Copy to system clipboard
noremap Y y$

" Better buffer navigation
"noremap J }
"noremap K {
noremap H ^
noremap L $
vnoremap L g_

" Start search on current word under the cursor
nnoremap <leader>/ /<CR>

" Start reverse search on current word under the cursor
nnoremap <leader>? ?<CR>

" Faster sort
vnoremap <leader>S :!sort<CR>

" Command mode conveniences
noremap <leader>: :!
noremap <leader>; :<Up>

" Remap VIM 0 to first non-blank character
map 0 ^

" ## Selections
" reselect pasted content:
nnoremap gV `[v`]
" select all text in the file
nnoremap <leader>v ggVG
" Easier linewise reselection of what you just pasted.
nnoremap <leader>V V`]
" gi already moves to 'last place you exited insert mode', so we'll map gI to
" something similar: move to last change
nnoremap gI `.
" reselect visually selected content:
xnoremap > >gv

" ## Indentions
" Indent/dedent/autoindent what you just pasted.
nnoremap <lt>> V`]<
nnoremap ><lt> V`]>
nnoremap =- V`]=

" Don't overwrite blackhole register with selection
" https://www.reddit.com/r/vim/comments/clccy4/pasting_when_selection_touches_eol/
xnoremap p "_c<c-r>"<esc>
xmap P p

" Better window navigation
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

" Better save and quit
silent! unmap <leader>w
nnoremap <silent><leader>w :w<CR>
nnoremap <silent><leader>W :w !sudo -S tee > /dev/null %<CR>
cmap w!! w !sudo tee > /dev/null %
nnoremap <leader>q :q<CR>

" open a (new)file in a new vsplit
" nnoremap <silent><leader>o :vnew<CR>:e<space><C-d>
" nnoremap <leader>o :vnew<CR>:e<space>

" Background (n)vim
vnoremap <C-z> <ESC>zv`<ztgv

" Default to case insensitive search
nnoremap / /\v
vnoremap / /\v

" always paste from 0 register to avoid pasting deleted text (from r/vim)
xnoremap <silent> p p:let @"=@0<CR>


function! Show_position()
  return ":\<c-u>echo 'start=" . string(getpos("v")) . " end=" . string(getpos(".")) . "'\<cr>gv"
endfunction
vmap <expr> <leader>P Show_position()

" flip between two last edited files/alternate/buffer
" nnoremap <Leader><Leader> <C-^>

" Don't overwrite blackhole register with selection
" https://www.reddit.com/r/vim/comments/clccy4/pasting_when_selection_touches_eol/
" xnoremap p "_c<c-r>"<esc>
" xmap P p

vnoremap <C-r> "hy:%Subvert/<C-r>h//gc<left><left><left>

" clear incsearch term
nnoremap <silent><ESC> :syntax sync fromstart<CR>:nohlsearch<CR>:redrawstatus!<CR><ESC>

" REF: https://github.com/savq/dotfiles/blob/master/nvim/init.lua#L90-L101
"      https://github.com/neovim/neovim/issues/4495#issuecomment-207825278
" nnoremap z= :setlocal spell<CR>z=
]])

-- useful remaps from theprimeagen:
-- - ref: https://www.youtube.com/watch?v=hSHATqh8svM
-- useful remaps/maps from lukas-reineke:
-- - ref: https://github.com/lukas-reineke/dotfiles/blob/master/vim/lua/mappings.lua

-- Convenient Line operations
map("n", "H", "^")
map("n", "L", "$")
map("v", "L", "g_")
-- TODO: no longer needed; nightly adds these things?
-- map("n", "Y", '"+y$')
-- map("n", "Y", "yg_") -- copy to last non-blank char of the line

-- Remap VIM 0 to first non-blank character
map("n", "0", "^")

map("n", "q", "<Nop>")
map("n", "Q", "@q")
map("v", "Q", ":norm @q<CR>")

-- Open file with wildmenu pum;
map("n", "<leader>e", ":vnew **/<TAB>")

-- Map <leader>o & <leader>O to newline without insert mode
map("n", "<leader>o", ':<C-u>call append(line("."), repeat([""], v:count1))<CR>', { noremap = true, silent = true })
map("n", "<leader>O", ':<C-u>call append(line(".")-1, repeat([""], v:count1))<CR>', { noremap = true, silent = true })

-- REF/HT:
-- https://github.com/ibhagwan/nvim-lua/blob/main/lua/keymaps.lua#L121-L139
--
-- <leader>v|<leader>s act as <cmd-v>|<cmd-s>
-- <leader>p|P paste from yank register (0)
-- map("n", "<leader>v", '"+p', { noremap = true })
-- map("n", "<leader>V", '"+P', { noremap = true })
-- map("v", "<leader>v", '"_d"+p', { noremap = true })
-- map("v", "<leader>v", '"_d"+P', { noremap = true })
-- map("n", "<leader>s", '"*p', { noremap = true })
-- map("n", "<leader>S", '"*P', { noremap = true })
-- map("v", "<leader>s", '"*p', { noremap = true })
-- map("v", "<leader>S", '"*p', { noremap = true })

-- -- Overloads for 'd|c' that don't pollute the unnamed registers
-- -- In visual-select mode 'd=delete, x=cut (unchanged)'
-- map("n", "<leader>d", '"_d', { noremap = true })
-- map("n", "<leader>D", '"_D', { noremap = true })
-- map("n", "<leader>c", '"_c', { noremap = true })
-- map("n", "<leader>C", '"_C', { noremap = true })
-- map("v", "<leader>c", '"_c', { noremap = true })
-- map("v", "d", '"_d', { noremap = true })

-- Join / Split Lines
map("n", "J", "mzJ`z") -- Join lines and keep our cursor stabilized
map("n", "S", "i<CR><ESC>^mwgk:silent! s/\v +$//<CR>:noh<CR>`w") -- Split line

-- TODO: merge the two remaps of j/k below
-- Jumplist mutations and dealing with word wrapped lines
map("n", "k", "v:count == 0 ? 'gk' : (v:count > 5 ? \"m'\" . v:count : '') . 'k'", { expr = true })
map("n", "j", "v:count == 0 ? 'gj' : (v:count > 5 ? \"m'\" . v:count : '') . 'j'", { expr = true })

-- Clear highlights
cmd([[nnoremap <silent><ESC> :syntax sync fromstart<CR>:nohlsearch<CR>:redrawstatus!<CR><ESC> ]])

-- Fast previous buffer switching
map("n", "<leader><leader>", "<C-^>", { noremap = true })

-- Keep line in middle of buffer when searching
map("n", "n", "(v:searchforward ? 'n' : 'N') . 'zzzv'", { noremap = true, expr = true })
map("n", "N", "(v:searchforward ? 'N' : 'n') . 'zzzv'", { noremap = true, expr = true })

-- Readline bindings (command)
local rl_bindings = {
  { lhs = "<c-a>", rhs = "<home>", opts = { noremap = true } },
  { lhs = "<c-e>", rhs = "<end>", opts = { noremap = true } },
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

-- REF: https://github.com/mhinz/vim-galore/blob/master/README.md#saner-behavior-of-n-and-n
map("n", "n", "'Nn'[v:searchforward]", { expr = true })
map("x", "n", "'Nn'[v:searchforward]", { expr = true })
map("o", "n", "'Nn'[v:searchforward]", { expr = true })
map("n", "N", "'nN'[v:searchforward]", { expr = true })
map("x", "N", "'nN'[v:searchforward]", { expr = true })
map("o", "N", "'nN'[v:searchforward]", { expr = true })

-- REF: https://github.com/mhinz/vim-galore/blob/master/README.md#saner-command-line-history
map("c", "<C-n>", [[wildmenumode() ? "\<c-n>" : "\<down>"]], { expr = true })
map("c", "<C-p>", [[wildmenumode() ? "\<c-p>" : "\<up>"]], { expr = true })

-- [custom mappings] -----------------------------------------------------------

-- # simple REPLs -- TODO: find something more robust?
map("n", "<leader>rsh", [[:12sp | term<cr>]])
map("n", "<leader>rpy", [[:12so | e term://python3 -q | wincmd k<cr>]])
map("n", "<leader>rex", [[:12sp | e term://iex | wincmd k<cr>]])
map("n", "<leader>rjs", [[:12sp | e term://node | wincmd k<cr>]])

-- Things 3
exec([[command! -nargs=* Things :silent !open "things:///add?show-quick-entry=true&title=%:t&notes=%<cr>"]], true)
map("n", "<Leader>T", "<cmd>Things<CR>")

-- Spelling
-- map("n", "<leader>s", "z=e") -- Correct current word
map("n", "<leader>s", "b1z=e") -- Correct previous word
map("n", "<leader>S", "zg") -- Add word under cursor to dictionary

-- # find and replace in multiple files
map("n", "<Leader>R", "<cmd>cfdo %s/<C-r>s//g | update<cr>")

-- # save and execute vim/lua file
map("n", "<Leader>x", mega.save_and_exec)

-- # open uri under cursor:
map("n", "go", mega.open_uri)

-- [plugin mappings] -----------------------------------------------------------

-- # golden_size
map("n", "<Leader>r", "<cmd>lua require('golden_size').on_win_enter()<CR>")

-- # git-related (fugitive, et al)
-- map("n", "<Leader>gb", "<cmd>GitMessenger<CR>")
-- map("n", "<Leader>gh", "<cmd>GBrowse<CR>")
-- map("v", "<Leader>gh", ":'<,'>GBrowse<CR>")
map("n", "<Leader>gd", "<cmd>DiffviewOpen<CR>")

-- # gist
-- vim.g.gist_open_url = true
-- vim.g.gist_default_private = true
-- map("v", "<Leader>gG", ":Gist -po<CR>")

-- # markdown-related
map("n", "<Leader>mp", "<cmd>MarkdownPreview<CR>")

-- # slash
exec(
  [[
  noremap <plug>(slash-after) zz
  if has('timers')
    " blink 2 times with 50ms interval
    noremap <expr> <plug>(slash-after) 'zz'.slash#blink(2, 50)
  endif
  ]],
  true
)

-- # lightspeed
-- do -- this continues to break my f/t movements :(
-- 	function repeat_ft(reverse)
-- 		local ls = require("lightspeed")
-- 		ls.ft["instant-repeat?"] = true
-- 		ls.ft:to(reverse, ls.ft["prev-t-like?"])
-- 	end

-- 	-- map({ "n", "x" }, ";", repeat_ft(false))
-- 	-- map({ "n", "x" }, ",", repeat_ft(true))
-- 	map({ "n", "x" }, ";", "<cmd>lua repeat_ft(false)<cr>")
-- 	map({ "n", "x" }, ",", "<cmd>lua repeat_ft(true)<cr>")
-- end

-- # zk
-- REF: https://github.com/mhanberg/.dotfiles/blob/main/config/nvim/lua/plugin/zk.lua
map("n", "<leader>zi", "<cmd>ZkIndex<cr>")
map("v", "<leader>zn", "<cmd>'<,'>lua vim.lsp.buf.range_code_action()<cr>")
map("n", "<leader>zn", "<cmd>ZkNew {title = vim.fn.input('Title: ')}<cr>")
-- bufmap("n", "<leader>zl", ":ZkNew {dir = 'log'}<CR>")
-- bufmap("n", "<leader>zj", ":ZkNew {dir = 'journal/daily'}<CR>")

-- # treesitter
map("o", "m", ":<C-U>lua require('tsht').nodes()<CR>")
map("v", "m", ":'<'>lua require('tsht').nodes()<CR>", { noremap = true })

-- # easy-align
-- start interactive EasyAlign in visual mode (e.g. vipga)
map("v", "ga", "<Plug>(EasyAlign)")
map("x", "ga", "<Plug>(EasyAlign)")
-- start interactive EasyAlign for a motion/text object (e.g. gaip)
map("n", "ga", "<Plug>(EasyAlign)")

-- # Dash
map("n", "<leader>d", "<cmd>Dash<CR>")
map("n", "<leader>D", "<cmd>DashWord<CR>")

-- # paq
-- map("n", "<F5>", mega.sync_plugins())
map("n", "<F5>", "<cmd>lua mega.sync_plugins()<cr>")
-- # fzf-lua
map("n", "<leader>ff", "<cmd>lua require('fzf-lua').files()<cr>")
map("n", "<leader>fb", "<cmd>lua require('fzf-lua').buffers()<cr>")
map("n", "<leader>fm", "<cmd>lua require('fzf-lua').oldfiles()<cr>")
map("n", "<leader>fk", "<cmd>lua require('fzf-lua').keymaps()<cr>")
map("n", "<leader>fh", "<cmd>lua require('fzf-lua').help_tags()<cr>")
map("n", "<leader>a", "<cmd>lua require('fzf-lua').live_grep()<cr>")
map("n", "<leader>A", "<cmd>lua require('fzf-lua').grep_cword()<cr>")
map("v", "<leader>A", "<cmd>lua require('fzf-lua').grep_visual()<cr>")
-- TODO: figure out how to use shortened paths
map("n", "<leader>fo", [[<cmd>lua require("fzf-lua").files({ cwd = mega.dirs.org, prompt = "ORG  " })<cr>]])
map("n", "<leader>fz", [[<cmd>lua require("fzf-lua").files({ cwd = mega.dirs.zettel, prompt = "ZK  " })<cr>]])

-- # nvim-tree
map("n", "<C-p>", "<cmd>NvimTreeToggle<CR>")

-- # commands

command({ "Todo", [[noautocmd silent! grep! 'TODO\|FIXME\|BUG\|HACK' | copen]] })
