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

local U = require("mega.utils")
local fn = vim.fn
local api = vim.api
local map = vim.keymap.set
-- NOTE: all convenience mode mappers are on the _G global; so no local assigns needed

-- [convenience mappings] ------------------------------------------------------

-- deal with word wrap nicely
map("n", "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
map("n", "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

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

nmap("gb", "<cmd>Pick buffers<cr>", "current buffers")

nmap("J", "<nop>")

-- nmap("zs", mega.showCursorHighlights, "show syntax highlights under cursor")
nmap("zS", U.showCursorHighlights, "show syntax highlights under cursor")
nnoremap("zs", "<cmd>Inspect<cr>", "Inspect the cursor position")

nmap("<localleader>yg", "<cmd>CopyBranch<cr>", { desc = "git: copy current git branch" })
nmap("<localleader>ygh", "<cmd>CopyBranch<cr>", { desc = "git: copy current git branch" })
nmap("<localleader>gy", "<cmd>CopyBranch<cr>", { desc = "git: copy current git branch" })

nnoremap("<localleader>f", "<cmd>LspFormatWrite<cr>", "run lsp formatter")
-- nnoremap("<localleader>F", "<cmd>LspFormat<cr>", "run lsp formatter")

-- make the tab key match bracket pairs
vim.cmd("silent! unmap [%", true)
vim.cmd("silent! unmap ]%", true)

-- map(
--   { "n", "o", "s", "v", "x" },
--   "<Tab>",
--   "%",
--   { desc = "jump to opening/closing delimiter", remap = true, silent = false }
-- )

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

-- [overrides/remaps mappings] ---------------------------------------------------------

vim.cmd([[
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

nnoremap("<esc>", function()
  vim.cmd.doautoall("User EscDeluxeStart")
  U.clear_ui({ deluxe = true })
  vim.cmd.doautoall("User EscDeluxeEnd")

  vim.api.nvim_feedkeys(vim.keycode("<Esc>"), "n", true)
end, { silent = true, desc = "EscDeluxe + Clear/Reset UI" })

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

-- Map <localleader>o & <localleader>O to newline without insert mode
nnoremap("<localleader>o", ":<C-u>call append(line(\".\"), repeat([\"\"], v:count1))<CR>")
nnoremap("<localleader>O", ":<C-u>call append(line(\".\")-1, repeat([\"\"], v:count1))<CR>")

-- Jumplist mutations and dealing with word wrapped lines
-- nnoremap("k", "v:count == 0 ? 'gk' : (v:count > 5 ? \"m'\" . v:count : '') . 'k'", { expr = true })
-- nnoremap("j", "v:count == 0 ? 'gj' : (v:count > 5 ? \"m'\" . v:count : '') . 'j'", { expr = true })

-- Fast previous buffer switching
nnoremap("<leader><leader>", "<C-^>")

-- Use the text that has already been typed as the prefix for searching through commands
cnoremap("<C-p>", "<Up>", { desc = "Line Up (command-mode)" })
cnoremap("<C-n>", "<Down>", { desc = "Line Down (command-mode)" })

-- nnoremap("<C-f>", "<C-f>zz<Esc><Cmd>lua mega.blink_cursorline(75)<CR>")
-- nnoremap("<C-b>", "<C-b>zz<Esc><Cmd>lua mega.blink_cursorline(75)<CR>")
-- nnoremap("<C-d>", "<C-d>zz<Esc><Cmd>lua mega.blink_cursorline(75)<CR>")
-- nnoremap("<C-u>", "<C-u>zz<Esc><Cmd>lua mega.blink_cursorline(75)<CR>")

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

-- https://stackoverflow.com/questions/4256697/vim-search-and-highlight-but-do-not-jump#comment91750564_4257175
map("n", "*", "m`<Cmd>keepjumps normal! *``<CR>", { desc = "Don't jump on first * -- simpler vim-asterisk" })

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

-- nnoremap("<leader>yf", [[:let @*=expand("%:p")<CR>]], "yank file path into the clipboard")
-- nnoremap("yf", [[:let @*=expand("%:p")<CR>]], "yank file path into the clipboard")

map(
  "n",
  "zsc",
  function() vim.print(vim.treesitter.get_captures_at_cursor()) end,
  { desc = "[treesitter] Print treesitter captures under cursor" }
)

map("n", "yts", function()
  local captures = vim.treesitter.get_captures_at_cursor()
  if #captures == 0 then
    vim.notify(
      "No treesitter captures under cursor",
      L.ERROR,
      { title = "[yank] failed to yank treesitter captures", render = "compact" }
    )
    return
  end

  local parsedCaptures = vim.iter(captures):map(function(capture) return ("@%s"):format(capture) end):totable()
  local resultString = vim.inspect(parsedCaptures)
  vim.fn.setreg("+", resultString .. "\n")
  vim.notify(resultString, L.INFO, { title = "[yank] yanked treesitter capture", render = "compact" })
end, { desc = "[yank] copy treesitter captures under cursor" })

map("n", "<Leader>yn", function()
  local res = vim.fn.expand("%:t", false, false)
  if type(res) ~= "string" then return end
  if res == "" then
    vim.notify("Buffer has no filename", L.ERROR, { title = "[yank] failed to yank filename", render = "compact" })
    return
  end
  vim.fn.setreg("+", res)
  vim.notify(res, L.INFO, { title = "[yank] yanked filename" })
end, { desc = "[yank] yank the filename of current buffer" })

map("n", "<Leader>yp", function()
  local res = vim.fn.expand("%:p", false, false)
  if type(res) ~= "string" then return end
  res = res == "" and vim.uv.cwd() or res
  if res:len() then
    vim.fn.setreg("+", res)
    vim.notify(res, L.INFO, { title = "[yank] yanked filepath" })
  end
end, { desc = "[yank] yank the full filepath of current buffer" })

-- [custom mappings] -----------------------------------------------------------

-- Things 3
-- nnoremap("<leader>T", "<cmd>!open \"things:///add?show-quick-entry=true&title=%:t&notes=%\"<cr>", { expr = true })

-- Spelling
-- map("n", "<leader>s", "z=e") -- Correct current word
nmap("<localleader>sj", "]s", { desc = "[spell] Move to next misspelling" })
nmap("<localleader>sk", "[s", { desc = "[spell] Move to previous misspelling" })
nmap("<localleader>sf", function()
  local cur_pos = vim.api.nvim_win_get_cursor(0)
  vim.cmd.normal({ "1z=", bang = true })
  vim.api.nvim_win_set_cursor(0, cur_pos)
end, { desc = "[spell] Correct spelling of word under cursor" })

nmap("<localleader>sa", function()
  local cur_pos = vim.api.nvim_win_get_cursor(0)
  vim.cmd.normal({ "zg", bang = true })
  vim.api.nvim_win_set_cursor(0, cur_pos)
end, { desc = "[spell] Add word under cursor to dictionary" })

nmap(
  "<localleader>si",
  function() vim.cmd.normal("ysiw`") end,
  { desc = "[spell] Ignore spelling of word under cursor" }
)

-- map('n', '<leader>sf', function()
--   local cur_pos = vim.api.nvim_win_get_cursor(0)
--   vim.cmd.normal { '1z=', bang = true }
--   vim.api.nvim_win_set_cursor(0, cur_pos)
-- end, { desc = 'Correct spelling of word under cursor' })
-- nmap("<leader>S", "zg") -- Add word under cursor to dictionary

mega.map({ "x", "n" }, "gcd", function()
  local win = vim.api.nvim_get_current_win()
  local cur = vim.api.nvim_win_get_cursor(win)
  local vstart = vim.fn.getpos("v")[2]
  local current_line = vim.fn.line(".")
  local set_cur = vim.api.nvim_win_set_cursor
  if vstart == current_line then
    vim.cmd.yank()
    require("Comment.api").toggle.linewise.current()
    -- require("mini.comment").operator()
    vim.cmd.put()
    set_cur(win, { cur[1] + 1, cur[2] })
  else
    if vstart < current_line then
      vim.cmd(":" .. vstart .. "," .. current_line .. "y")
      vim.cmd.put()
      set_cur(win, { vim.fn.line("."), cur[2] })
    else
      vim.cmd(":" .. current_line .. "," .. vstart .. "y")
      set_cur(win, { vstart, cur[2] })
      vim.cmd.put()
      set_cur(win, { vim.fn.line("."), cur[2] })
    end
    require("Comment.api").toggle.linewise(vim.fn.visualmode())
    -- require("mini.comment").operator("visual")
    -- vim.cmd([[:<c-u>lua require('mini.comment').operator('visual')]])
  end
end, { silent = true, desc = "Comment and duplicate selected lines" })

-- # find and replace in multiple files
nnoremap("<leader>R", "<cmd>cfdo %s/<C-r>s//g<bar>update<cr>")

-- # save and execute vim/lua file
nmap("<leader>x", U.save_and_exec)

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

cnoremap("%%", "<C-r>=fnameescape(expand('%'))<cr>")
cnoremap("::", "<C-r>=fnameescape(expand('%:p:h'))<cr>/")

-- makes * and # work on visual selection mode
vim.cmd(
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

---------------------------------------------------------------------------------
-- Macros
---------------------------------------------------------------------------------

-- Map Q to replay q register for macro
nnoremap("<localleader>q", "q", "macros: start macro")
nnoremap("q", "<Nop>")
nnoremap("Q", "@qj", "macros: run `q` macro")
xnoremap("Q", ":norm @q<CR>", "macros: run `q` macro (selection)")

---------------------------------------------------------------------------------
-- Folds
---------------------------------------------------------------------------------
map("n", "<leader>z", "za", { desc = "Toggle current fold" })
map("x", "<leader>z", "zf", { desc = "Create fold from selection" })
map("n", "zf", function() vim.cmd.normal("zMzv") end, { desc = "Fold all except current" })
map("n", "zF", function() vim.cmd.normal("zMzvzczo") end, { desc = "Fold all except current and children of current" })
map("n", "zO", function() vim.cmd.normal("zR") end, { desc = "Open all folds" })
map("n", "zo", "zO", { desc = "Open all folds descending from current line" })

---------------------------------------------------------------------------------
-- Toggle list
---------------------------------------------------------------------------------
nnoremap("<leader>llq", function() U.toggle_list("quickfix") end, "lists: toggle quickfix")
nnoremap("<leader>llc", function() U.toggle_list("location") end, "lists: toggle location")

map(
  "n",
  "<leader>h",
  ":%s/\\<<C-r><C-w>\\>/<C-r><C-w>/gIc<Left><Left><Left><Left>",
  { desc = "Replace instances of hovered word" }
)
map(
  "n",
  "<leader>H",
  ":%S/<C-r><C-w>/<C-r><C-w>/gcw<Left><Left><Left><Left>",
  { desc = "Replace instances of hovered word (matching case)" }
)

map("x", "<leader>h", "\"hy:%s/<C-r>h/<C-r>h/gc<left><left><left>", {
  desc = [[Crude search & replace visual selection
                 (breaks on multiple lines & special chars)]],
})

map("x", "y", "ygv<Esc>", { desc = "Cursor-in-place copy" })
map("n", "P", function() vim.cmd.normal({ vim.v.count1 .. "P`[", bang = true }) end, { desc = "Cursor-in-place paste" })

map("i", "<C-p>", "<C-r>\"", { desc = "Paste from register in insert mode" })
