--[[
  ╭────────────────────────────────────────────────────────────────────────────╮
  │  Str  │  Help page   │  Affected modes                           │  VimL   │
  │────────────────────────────────────────────────────────────────────────────│
  │  ''   │  mapmode-nvo │  Normal, Visual, Select, Operator-pending │  :map   │
  │  'n'  │  mapmode-n   │  Normal                                   │  :nmap  │
  │  'v'  │  mapmode-v   │  Visual and Select                        │  :vmap  │
  │  's'  │  mapmode-s   │  Select                                   │  :smap  │
  │  'x'  │  mapmode-x   │  Visual                                   │  :xmap  │
  │  'o'  │  mapmode-o   │  Operator-pending                         │  :omap  │
  │  '!'  │  mapmode-ic  │  Insert and Command-line                  │  :map!  │
  │  'i'  │  mapmode-i   │  Insert                                   │  :imap  │
  │  'l'  │  mapmode-l   │  Insert, Command-line, Lang-Arg           │  :lmap  │
  │  'c'  │  mapmode-c   │  Command-line                             │  :cmap  │
  │  't'  │  mapmode-t   │  Terminal                                 │  :tmap  │
  ╰────────────────────────────────────────────────────────────────────────────╯
--]]

-- REFS:
-- https://github.com/BlakeJC94/.dots/blob/master/.config/nvim/lua/mappings.lua
-- https://github.com/rafamadriz/NeoCode/blob/main/lua/core/mappings.lua
-- https://github.com/rafamadriz/NeoCode/blob/main/lua/modules/plugins/which-key.lua
-- https://github.com/mbriggs/nvim/blob/main/lua/mb/which-key.lua
-- https://github.com/akinsho/dotfiles/blob/main/.config/nvim/lua/as/plugins/whichkey.lua

if not mega then return end
if not vim.g.enabled_plugin["mappings"] then return end

local fn = vim.fn
local exec = mega.exec
local api = vim.api
local map = vim.keymap.set
-- NOTE: all convenience mode mappers are on the _G global; so no local assigns needed

-- [convenience mappings] ------------------------------------------------------

-- deal with word wrap nicely
vim.keymap.set("n", "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set("n", "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

-- go-to split (also, if in kitty, see nvim-kitty-navigator)
-- nnoremap("<C-h>", "<cmd>wincmd h<CR>", "split: go left")
-- nnoremap("<C-j>", "<cmd>wincmd j<CR>", "split: go down")
-- nnoremap("<C-k>", "<cmd>wincmd k<CR>", "split: go up")
-- nnoremap("<C-l>", "<cmd>wincmd l<CR>", "split: go right")

-- mega.augroup("AddTerminalMappings", {
--   event = { "TermOpen", "TermEnter" },
--   pattern = { "term://*" },
--   command = function()
--     -- if vim.tbl_contains({ "", "toggleterm", "megaterm" }, vim.bo.filetype) then
--     dd("terminal open -> mapping..")
--     local opts = { silent = false, buffer = 0 }
--     tnoremap("<esc>", [[<C-\><C-n>]], opts)
--     tnoremap("<C-h>", "<C-\\><C-N><C-w>h", opts)
--     tnoremap("<C-j>", "<C-\\><C-N><C-w>j", opts)
--     tnoremap("<C-k>", "<C-\\><C-N><C-w>k", opts)
--     tnoremap("<C-l>", "<C-\\><C-N><C-w>l", opts)
--
--     -- local opts = { silent = false, buffer = 0 }
--     -- tmap("<esc>", [[<C-\><C-n>]], opts)
--     -- tmap("jk", [[<C-\><C-n>]], opts)
--     -- tmap("<C-h>", "<Cmd>wincmd h<CR>", opts)
--     -- tmap("<C-j>", function() vim.cmd("wincmd j") end, opts)
--     -- vim.keymap.set("t", "<C-k>", function()
--     --   print("<C-k>'ing")
--     --   vim.api.nvim_feedkeys(vim.keycode([[<C-\><C-n>]], true, false, true), "t", true)
--     --   vim.cmd("wincmd k")
--     -- end, opts)
--     -- tnoremap("<C-l>", "<Cmd>wincmd l<CR>", opts)
--     -- end
--     -- if vim.bo.filetype == "" or vim.bo.filetype == "toggleterm" or vim.bo.filetype == "megaterm" then
--     --   local opts = { silent = false, buffer = 0 }
--     --   tnoremap("<esc>", [[<C-\><C-n>]], opts)
--     --   tnoremap("jk", [[<C-\><C-n>]], opts)
--     --   tnoremap("<C-h>", "<Cmd>wincmd h<CR>", opts)
--     --   tnoremap("<C-j>", "<Cmd>wincmd j<CR>", opts)
--     --   tnoremap("<C-k>", "<Cmd>wincmd k<CR>", opts)
--     --   tnoremap("<C-l>", "<Cmd>wincmd l<CR>", opts)
--     --   tnoremap("]t", "<Cmd>tablast<CR>")
--     --   tnoremap("[t", "<Cmd>tabnext<CR>")
--     --   tnoremap("<S-Tab>", "<Cmd>bprev<CR>")
--     --   tnoremap("<leader><Tab>", "<Cmd>close \\| :bnext<cr>")
--     -- end
--   end,
-- })

-- jump to tab
for i = 0, 9 do
  if i + 1 >= 10 then break end
  local key_string = tostring(i + 1)
  nnoremap("<localleader>" .. key_string, fmt("<cmd>%stabnext<cr>", key_string), fmt("tab: jump to tab %s", key_string))
end
map({ "i", "n", "t" }, "<C-Right>", ":tabn<CR>", { desc = "next tab", remap = true })
map({ "i", "n", "t" }, "<C-Left>", ":tabp<CR>", { desc = "prev tab", remap = true })
map({ "i", "n", "t" }, "<C-Up>", ":+tabmove<CR>", { desc = "move tab right", remap = true })
map({ "i", "n", "t" }, "<C-Down>", ":-tabmove<CR>", { desc = "move tab left", remap = true })

nmap("gb", string.format("<cmd>ls<CR>:b<space>%s", vim.keycode("<tab>")), "current buffers")
nmap("J", "<nop>")

-- nmap("zs", mega.showCursorHighlights, "show syntax highlights under cursor")
nmap("zS", mega.showCursorHighlights, "show syntax highlights under cursor")
nnoremap("zs", "<cmd>Inspect<cr>", "Inspect the cursor position")

nmap("<localleader>yg", "<cmd>CopyBranch<cr>", { desc = "Copy current git branch" })
nmap("<localleader>ygh", "<cmd>CopyBranch<cr>", { desc = "Copy current git branch" })

nnoremap("<localleader>f", "<cmd>LspFormatWrite<cr>", "run lsp formatter")
-- nnoremap("<localleader>F", "<cmd>LspFormat<cr>", "run lsp formatter")

-- -- These create newlines like o and O but stay in normal mode
-- map.mode_group('n', {
--   { 'zj', 'o<Esc>k' },
--   { 'zk', 'O<Esc>j' },
-- }, { silent = true })
--
-- -- Move lines in visual mode
-- map.mode_group('v', {
--   { 'J', ":m '>+1<cr>gv=gv" },
--   { 'K', ":m '<-2<cr>gv=gv" },
-- }, { noremap = true })
--
-- -- better undo breakpoints
-- map.mode_group('i', {
--   { ',', ',<c-g>u' },
--   { '.', '.<c-g>u' },
--   { '!', '!<c-g>u' },
--   { '?', '?<c-g>u' },
-- }, { noremap = true })

-- make the tab key match bracket pairs
exec("silent! unmap [%", true)
exec("silent! unmap ]%", true)

map(
  { "n", "o", "s", "v", "x" },
  "<Tab>",
  "%",
  { desc = "jump to opening/closing delimiter", remap = true, silent = false }
)
-- nmap("<Tab>", "%")
-- nnoremap("<Tab>", "%")
-- smap("<Tab>", "%")
-- vmap("<Tab>", "%")
-- xmap("<Tab>", "%")
-- omap("<Tab>", "%")

-- https://github.com/tpope/vim-rsi/blob/master/plugin/rsi.vim
-- c-a / c-e everywhere - RSI.vim provides these
cnoremap("<C-n>", "<Down>")
cnoremap("<C-p>", "<Up>")
-- <C-A> allows you to insert all matches on the command line e.g. bd *.js <c-a>
-- will insert all matching files e.g. :bd a.js b.js c.js
cnoremap("<c-x><c-a>", "<c-a>")
cnoremap("<C-a>", "<Home>")
cnoremap("<C-e>", "<End>")
cnoremap("<C-b>", "<Left>")
cnoremap("<C-d>", "<Del>")
cnoremap("<C-k>", [[<C-\>e getcmdpos() == 1 ? '' : getcmdline()[:getcmdpos() - 2]<CR>]])
-- move cursor one character backwards unless at the end of the command line
cnoremap("<C-f>", [[getcmdpos() > strlen(getcmdline())? &cedit: "\<Lt>Right>"]], { expr = true })
-- see :h cmdline-editing
cnoremap("<Esc>b", [[<S-Left>]])
cnoremap("<Esc>f", [[<S-Right>]])

inoremap("<C-a>", "<Home>")
inoremap("<C-e>", "<End>")

-----------------------------------------------------------------------------//
-- MACROS {{{
-----------------------------------------------------------------------------//
-- Absolutely fantastic function from stoeffel/.dotfiles which allows you to
-- repeat macros across a visual range
------------------------------------------------------------------------------
-- TODO: converting this to lua does not work for some obscure reason.
vim.cmd([[
  function! ExecuteMacroOverVisualRange()
    echo "@".getcmdline()
    execute ":'<,'>normal @".nr2char(getchar())
  endfunction
]])

xnoremap("@", ":<C-u>call ExecuteMacroOverVisualRange()<CR>", { silent = false })
--}}}

-- TLDR: Conditionally modify character at end of line
-- Description:
-- This function takes a delimiter character and:
--   * removes that character from the end of the line if the character at the end
--     of the line is that character
--   * removes the character at the end of the line if that character is a
--     delimiter that is not the input character and appends that character to
--     the end of the line
--   * adds that character to the end of the line if the line does not end with
--     a delimiter
-- Delimiters:
-- - ","
-- - ";"
---@param character string
---@return function
local function modify_line_end_delimiter(character)
  local delimiters = { ",", ";" }
  return function()
    local line = api.nvim_get_current_line()
    local last_char = line:sub(-1)
    if last_char == character then
      api.nvim_set_current_line(line:sub(1, #line - 1))
    elseif vim.tbl_contains(delimiters, last_char) then
      api.nvim_set_current_line(line:sub(1, #line - 1) .. character)
    else
      api.nvim_set_current_line(line .. character)
    end
  end
end

nnoremap("<localleader>,", modify_line_end_delimiter(","))
nnoremap("<localleader>;", modify_line_end_delimiter(";"))

-- Enter key should repeat the last macro recorded or just act as enter
nnoremap("<leader><CR>", [[empty(&buftype) ? '@@' : '<CR>']], { expr = true })

-- [overrides/remaps mappings] ---------------------------------------------------------

exec([[
" -- ( overrides ) --
" Help
noremap <C-]> K

" Copy to system clipboard
noremap Y y$

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

" gi already moves to 'last place you exited insert mode', so we'll map gI to
" something similar: move to last change
" nnoremap gI `.

" reselect visually selected content:
xnoremap > >gv

" ## Indentions
" Indent/dedent/autoindent what you just pasted.
nnoremap <lt>> V`]<
nnoremap ><lt> V`]>
nnoremap =- V`]=
]])

nnoremap("<leader>w", function(args)
  -- P(args)
  vim.api.nvim_command("silent! write")
end, "write buffer and stuff")
nnoremap("<leader>W", "<cmd>SudaWrite<cr>", "sudo write buffer and stuff")
nnoremap("<leader>q", "<cmd>q<cr>", "quit")
nnoremap("<leader>Q", "<cmd>q!<cr>", "quit!!11!!!")

nnoremap("g>", [[<cmd>set nomore<bar>40messages<bar>set more<CR>]], {
  desc = "show message history",
})

-- search and replace:
-- NOTE: see tpope/vim-abolish entry in plugins
-- nnoremap("<C-s>", [[:%s/\<<C-r>=expand("<cword>")<CR>\>/]], {
--   silent = false,
--   desc = "replace word under the cursor (file)",
-- })
-- nnoremap("<C-s>", [[:s/\<<C-r>=expand("<cword>")<CR>\>/]], {
--   silent = false,
--   desc = "replace word under the cursor (line)",
-- })
-- -- vnoremap("<C-r>", [["zy:%s/<C-r><C-o>"/]], {
-- --   silent = false,
-- --   desc = "replace word under the cursor (visual)",
-- -- })
-- vnoremap("<C-r>", [["hy:%Subvert/<C-r>h//gc<left><left><left>]], {
--   silent = false,
--   desc = "replace word under the cursor (line)",
-- })

-- Clear UI state via escape:
-- - Clear search highlight
-- - Clear command-line
-- - Close floating windows
-- nmap([[<Esc>]], [[<Nop>]])
nnoremap("<esc>", function()
  mega.clear_ui()
  vim.api.nvim_feedkeys(vim.keycode("<Esc>"), "n", true)
end, { silent = true, desc = "Clear UI" })

-- Use operator pending mode to visually select the whole buffer
-- e.g. dA = delete buffer ALL, yA = copy whole buffer ALL
omap("A", ":<C-U>normal! mzggVG<CR>`z")
xmap("A", ":<C-U>normal! ggVG<CR>")

-- useful remaps from theprimeagen:
-- - ref: https://www.youtube.com/watch?v=hSHATqh8svM
-- useful remaps/maps from lukas-reineke:
-- - ref: https://github.com/lukas-reineke/dotfiles/blob/master/vim/lua/mappings.lua

-- Convenient Line operations
nmap("H", "^")
nmap("L", "$")
vmap("L", "g_")

-- TODO: no longer needed; nightly adds these things?
-- map("n", "Y", '"+y$')
-- map("n", "Y", "yg_") -- copy to last non-blank char of the line

-- Remap VIM 0 to first non-blank character
nmap("0", "^")

nmap("q", "<Nop>")
nmap("Q", "@q")
vnoremap("Q", ":norm @q<CR>")

nnoremap("dd", function()
  if vim.fn.prevnonblank(".") ~= vim.fn.line(".") then
    return "\"_dd"
  else
    return "dd"
  end
end, { expr = true, desc = "Special Line Delete" })

-- selections
nnoremap("gv", "`[v`]", "reselect pasted content")
nnoremap("<leader>V", "V`]", "reselect pasted content")
nnoremap("gp", "`[v`]", "reselect pasted content")
nnoremap("gV", "ggVG", "select whole buffer")
nnoremap("<leader>v", "ggVG", "select whole buffer")

-- Map <leader>o & <leader>O to newline without insert mode
nnoremap("<leader>o", ":<C-u>call append(line(\".\"), repeat([\"\"], v:count1))<CR>")
nnoremap("<leader>O", ":<C-u>call append(line(\".\")-1, repeat([\"\"], v:count1))<CR>")

-- Jumplist mutations and dealing with word wrapped lines
-- nnoremap("k", "v:count == 0 ? 'gk' : (v:count > 5 ? \"m'\" . v:count : '') . 'k'", { expr = true })
-- nnoremap("j", "v:count == 0 ? 'gj' : (v:count > 5 ? \"m'\" . v:count : '') . 'j'", { expr = true })

-- Fast previous buffer switching
nnoremap("<leader><leader>", "<C-^>")

-- Use the text that has already been typed as the prefix for searching through commands
cnoremap("<C-p>", "<Up>", { desc = "Line Up (command-mode)" })
cnoremap("<C-n>", "<Down>", { desc = "Line Down (command-mode)" })

nnoremap("<C-f>", "<C-f>zz<Esc><Cmd>lua mega.blink_cursorline(75)<CR>")
nnoremap("<C-b>", "<C-b>zz<Esc><Cmd>lua mega.blink_cursorline(75)<CR>")

nnoremap("<C-d>", "<C-d>zz<Esc><Cmd>lua mega.blink_cursorline(75)<CR>")
nnoremap("<C-u>", "<C-u>zz<Esc><Cmd>lua mega.blink_cursorline(75)<CR>")

vnoremap([[J]], [[5j]], "Jump down")
vnoremap([[K]], [[5k]], "Jump up")

-- quickly enter command mode with substitution commands prefilled
-- TODO: need to force redraw
-- nnoremap ([[<leader>/]], [[:%s/]], "Substitute")
-- nnoremap ([[<leader>?]], [[:%S/]], "Substitute (rev)")
-- vnoremap ([[<leader>/]], [[:s/]],  "Substitute")
-- vnoremap ([[<leader>?]], [[:S/]],  "Substitute (rev)")

-- Readline bindings (command)
local rl_bindings = {
  { lhs = "<c-a>", rhs = "<home>" },
  { lhs = "<c-e>", rhs = "<end>" },
}
for _, binding in ipairs(rl_bindings) do
  cnoremap(binding.lhs, binding.rhs, binding.opts or {})
end

-- don't yank the currently pasted text // thanks @theprimeagen
vim.cmd([[xnoremap <expr> p 'pgv"' . v:register . 'y']])
-- xnoremap("p", "\"_dP", "paste with saved register contents")

-- yank to empty register for D, c, etc.
nnoremap("x", "\"_x")
nnoremap("X", "\"_X")
nnoremap("D", "\"_D")
nnoremap("c", "\"_c")
nnoremap("C", "\"_C")
nnoremap("cc", "\"_S")

xnoremap("x", "\"_x")
xnoremap("X", "\"_X")
xnoremap("D", "\"_D")
xnoremap("c", "\"_c")
xnoremap("C", "\"_C")

-- Undo breakpoints
imap(",", ",<C-g>u")
imap(".", ".<C-g>u")
imap("!", "!<C-g>u")
imap("?", "?<C-g>u")

-- REF: https://github.com/mhinz/vim-galore/blob/master/README.md#saner-behavior-of-n-and-n
-- nnoremap("n", "'Nn'[v:searchforward].'zzzv'.'<Esc><Cmd>lua mega.blink_cursorline(150)<CR>'", { expr = true })
-- xnoremap("n", "'Nn'[v:searchforward].'zzzv'.'<Esc><Cmd>lua mega.blink_cursorline(150)<CR>'", { expr = true })
-- onoremap("n", "'Nn'[v:searchforward].'zzzv'.'<Esc><Cmd>lua mega.blink_cursorline(150)<CR>'", { expr = true })
-- nnoremap("N", "'nN'[v:searchforward].'zzzv'.'<Esc><Cmd>lua mega.blink_cursorline(150)<CR>'", { expr = true })
-- xnoremap("N", "'nN'[v:searchforward].'zzzv'.'<Esc><Cmd>lua mega.blink_cursorline(150)<CR>'", { expr = true })
-- onoremap("N", "'nN'[v:searchforward].'zzzv'.'<Esc><Cmd>lua mega.blink_cursorline(150)<CR>'", { expr = true })

nnoremap("n", "nzz<esc><cmd>lua mega.blink_cursorline(50)<cr>")
xnoremap("n", "nzz<esc><cmd>lua mega.blink_cursorline(50)<cr>")
onoremap("n", "nzz<esc><cmd>lua mega.blink_cursorline(50)<cr>")
nnoremap("N", "Nzz<esc><cmd>lua mega.blink_cursorline(50)<cr>")
xnoremap("N", "Nzz<esc><cmd>lua mega.blink_cursorline(50)<cr>")
onoremap("N", "Nzz<esc><cmd>lua mega.blink_cursorline(50)<cr>")

-- smooth searching, allow tabbing between search results similar to using <c-g>
-- or <c-t> the main difference being tab is easier to hit and remapping those keys
-- to these would swallow up a tab mapping
local function search(direction_key, default)
  local c_type = fn.getcmdtype()
  return (c_type == "/" or c_type == "?") and fmt("<CR>%s<C-r>/", direction_key) or default
end
cnoremap("<Tab>", function() return search("/", "<Tab>") end, { expr = true })
cnoremap("<S-Tab>", function() return search("?", "<S-Tab>") end, { expr = true })

-- REF: https://github.com/mhinz/vim-galore/blob/master/README.md#saner-command-line-history
cnoremap("<C-n>", [[wildmenumode() ? "\<c-n>" : "\<down>"]], { expr = true })
cnoremap("<C-p>", [[wildmenumode() ? "\<c-p>" : "\<up>"]], { expr = true })

nnoremap("<leader>yf", [[:let @*=expand("%:p")<CR>]], "yank file path into the clipboard")
nnoremap("yf", [[:let @*=expand("%:p")<CR>]], "yank file path into the clipboard")

-- [custom mappings] -----------------------------------------------------------

-- Things 3
-- nnoremap("<leader>T", "<cmd>!open \"things:///add?show-quick-entry=true&title=%:t&notes=%\"<cr>", { expr = true })

-- Spelling
-- map("n", "<leader>s", "z=e") -- Correct current word
nmap("<leader>s", "b1z=e") -- Correct previous word
nmap("<leader>S", "zg") -- Add word under cursor to dictionary

-- # find and replace in multiple files
nnoremap("<leader>R", "<cmd>cfdo %s/<C-r>s//g<bar>update<cr>")

-- # save and execute vim/lua file
nmap("<leader>x", mega.save_and_exec)

-- # equal/golden-ratio window resizing
nmap("gw", function() mega.resize_windows() end, { desc = "window: resize splits (golden-ratio)" })
nmap("gW", "<cmd>wincmd =<cr>", { desc = "window: resize splits (equally)" })

-- [plugin mappings] -----------------------------------------------------------

-- # treesitter
-- ( ts units )
xnoremap("iu", ":lua require\"treesitter-unit\".select()<CR>")
xnoremap("au", ":lua require\"treesitter-unit\".select(true)<CR>")
onoremap("iu", ":<c-u>lua require\"treesitter-unit\".select()<CR>")
onoremap("au", ":<c-u>lua require\"treesitter-unit\".select(true)<CR>")

-- # dirbuf.nvim
nmap("-", "<Nop>") -- disable this mapping globally, only map in dirbuf ftplugin

-- # formatter.nvim
-- nmap("<leader>F", [[<cmd>FormatWrite<cr>]], "format file")

-- Map Q to replay q register
nnoremap("Q", "@q")

cnoremap("%%", "<C-r>=fnameescape(expand('%'))<cr>")
cnoremap("::", "<C-r>=fnameescape(expand('%:p:h'))<cr>/")

-- makes * and # work on visual selection mode
vim.api.nvim_exec(
  [[
  function! g:VSetSearch(cmdtype)
    let temp = @s
    norm! gv"sy
    let @/ = '\V' . substitute(escape(@s, a:cmdtype.'\'), '\n', '\\n', 'g')
    let @s = temp
  endfunction
  xnoremap * :<C-u>call g:VSetSearch('/')<CR>/<C-R>=@/<CR><CR>
  xnoremap # :<C-u>call g:VSetSearch('?')<CR>?<C-R>=@/<CR><CR>
]],
  false
)

-----------------------------------------------------------------------------//
-- Multiple Cursor Replacement
-- http://www.kevinli.co/posts/2017-01-19-multiple-cursors-in-500-bytes-of-vimscript/
-- @trial: https://github.com/otavioschwanck/cool-substitute.nvim
-----------------------------------------------------------------------------//
nnoremap("cn", "*``cgn")
nnoremap("cN", "*``cgN")

-- 1. Position the cursor over a word; alternatively, make a selection.
-- 2. Hit cq to start recording the macro.
-- 3. Once you are done with the macro, go back to normal mode.
-- 4. Hit Enter to repeat the macro over search matches.
function mega.mappings.setup_map() nnoremap("M", [[:nnoremap M n@z<CR>q:<C-u>let @z=strpart(@z,0,strlen(@z)-1)<CR>n@z]]) end

vim.g.mc = vim.keycode([[y/\V<C-r>=escape(@", '/')<CR><CR>]])
xnoremap("cn", [[g:mc . "``cgn"]], { expr = true, silent = true })
xnoremap("cN", [[g:mc . "``cgN"]], { expr = true, silent = true })
nnoremap("cq", [[:\<C-u>call v:lua.mega.mappings.setup_map()<CR>*``qz]])
nnoremap("cQ", [[:\<C-u>call v:lua.mega.mappings.setup_map()<CR>#``qz]])
xnoremap("cq", [[":\<C-u>call v:lua.mega.mappings.setup_map()<CR>gv" . g:mc . "``qz"]], { expr = true })
xnoremap(
  "cQ",
  [[":\<C-u>call v:lua.mega.mappings.setup_map()<CR>gv" . substitute(g:mc, '/', '?', 'g') . "``qz"]],
  { expr = true }
)

---------------------------------------------------------------------------------
-- Toggle list
---------------------------------------------------------------------------------
--- Utility function to toggle the location or the quickfix list
---@param list_type '"quickfix"' | '"location"'
---@return nil
function mega.toggle_list(list_type)
  local is_location_target = list_type == "location"
  local prefix = is_location_target and "l" or "c"
  local L = vim.log.levels
  local is_open = mega.is_vim_list_open()
  if is_open then return fn.execute(prefix .. "close") end
  local list = is_location_target and fn.getloclist(0) or fn.getqflist()
  if vim.tbl_isempty(list) then
    local msg_prefix = (is_location_target and "Location" or "QuickFix")
    return vim.notify(msg_prefix .. " List is Empty.", L.WARN)
  end

  local winnr = fn.winnr()
  fn.execute(prefix .. "open")
  if fn.winnr() ~= winnr then vim.cmd("wincmd p") end
end

nnoremap("<leader>llq", function() mega.toggle_list("quickfix") end, "lists: toggle quickfix")
nnoremap("<leader>llc", function() mega.toggle_list("location") end, "lists: toggle location")
