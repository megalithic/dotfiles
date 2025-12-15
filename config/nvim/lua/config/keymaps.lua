local fmt = string.format
local map = vim.keymap.set
local unmap = vim.keymap.del
local remap_opts = { noremap = false, silent = true }
local noremap_opts = { noremap = true, silent = true }
local U = require("config.utils")

-- -- Map a key in the given mode. Defaults to non-recursive and silent.
local function keymap(modes, from, to, opts)
  opts = opts or {}

  -- Ensure modes is a table
  if type(modes) == "string" then
    modes = { modes }
  end

  -- Handle function callbacks
  local callback = nil
  local cmd = to
  if type(to) == "function" then
    callback = to
    cmd = ""
    -- Set description if not provided
    if not opts.desc then
      opts.desc = "generic keymap"
    end
  elseif type(to) ~= "string" then
    callback = to
    cmd = ""
    if not opts.desc then
      opts.desc = tostring(to)
    end
  end

  -- Set default options
  if opts.noremap == nil then
    opts.noremap = true
  end
  if opts.expr and opts.replace_keycodes == nil then
    opts.replace_keycodes = true
  end
  if opts.silent == nil then
    opts.silent = true
  end

  -- Handle buffer-specific mappings
  local buf = nil
  if opts.buffer == true then
    buf = 0
  elseif type(opts.buffer) == "number" then
    buf = opts.buffer
  end
  opts.buffer = nil

  -- Create mappings for each mode
  for _, mode in ipairs(modes) do
    if callback then
      opts.callback = callback
      vim.keymap.set(mode, from, callback, opts)
    else
      if buf then
        vim.api.nvim_buf_set_keymap(buf, mode, from, cmd, opts)
      else
        vim.api.nvim_set_keymap(mode, from, cmd, opts)
      end
    end
  end
end
_G.Keymap = keymap

for _, mode in ipairs({ "n", "x", "i", "v", "o", "t", "s", "c" }) do
  --[[

  local nmap, cmap, xmap, imap, vmap, omap, tmap, smap
  local nnoremap, cnoremap, xnoremap, inoremap, vnoremap, onoremap, tnoremap, snoremap
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

  -- recursive global mappings
  _G[mode .. "map"] = function(from, to, opts)
    if type(opts) == "string" then
      opts = { desc = opts }
    end
    return keymap(mode, from, to, vim.tbl_extend("keep", remap_opts, opts or {}))
  end
  -- non-recursive global mappings
  _G[mode .. "noremap"] = function(from, to, opts)
    if type(opts) == "string" then
      opts = { desc = opts }
    end
    return keymap(mode, from, to, vim.tbl_extend("keep", noremap_opts, opts or {}))
  end
end

local M = { keymap = keymap }

-- [[ unmap ]] -----------------------------------------------------------------
unmap("n", "gra") -- lsp default: code actions
unmap("n", "grn") -- lsp default: rename
unmap("n", "grr") -- lsp default: references
unmap("n", "grt") -- lsp default: type_definitions
unmap("n", "gri") -- lsp default: implementation

-- `:help vim.keymap.set()`
-- local nmap, cmap, xmap, imap, vmap, omap, tmap, smap
-- local nnoremap, cnoremap, xnoremap, inoremap, vnoremap, onoremap, tnoremap, snoremap

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

local function leaderMapper(mode, key, rhs, opts)
  if type(opts) == "string" then
    opts = { desc = opts }
  end
  map(mode, "<leader>" .. key, rhs, opts)
end

local function localLeaderMapper(mode, key, rhs, opts)
  if type(opts) == "string" then
    opts = { desc = opts }
  end
  map(mode, "<localleader>" .. key, rhs, opts)
end

-- [[ tabs ]] ------------------------------------------------------------------
-- jump to tab
for i = 0, 9 do
  if i + 1 >= 10 then
    break
  end
  local key_string = tostring(i + 1)
  map(
    "n",
    "<localleader>" .. key_string,
    string.format("<cmd>%stabnext<cr>", key_string),
    { desc = string.format("tab: jump to tab %s", key_string) }
  )
end

-- Exit terminal mode in the builtin terminal with a shortcut that is a bit easier
-- for people to discover. Otherwise, you normally need to press <C-\><C-n>, which
-- is not what someone will guess without a bit more experience.
--
-- NOTE: This won't work in all terminal emulators/tmux/etc. Try your own mapping
-- or just use <C-\><C-n> to exit terminal mode
tmap("<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

-- [[ command mode ]] ----------------------------------------------------------
vmap("<leader>S", ":!sort<cr>", { desc = "Sort selection" })
nmap("<leader>:", ":!", { desc = "Execute last command" })

nmap("<leader>;", ":<up>", { desc = "Go to last command" })
-- nmap("<leader>;", function()
--   vim.cmd("<Up>")
--   -- vim.api.nvim_feedkeys("<Up>", "m", true)
--   -- vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("z=", true, false, true), "m", true)
-- end, { desc = "Go to last command" })

-- https://github.com/tpope/vim-rsi/blob/master/plugin/rsi.vim
-- c-a / c-e everywhere - RSI.vim provides these
cmap("<C-n>", "<Down>")
cmap("<C-p>", "<Up>")
-- <C-A> allows you to insert all matches on the command line e.g. bd *.js <c-a>
-- will insert all matching files e.g. :bd a.js b.js c.js
cmap("<c-x><c-a>", "<c-a>")
cmap("<C-a>", "<Home>")
cmap("<C-e>", "<End>")
cmap("<C-b>", "<Left>")
cmap("<C-d>", "<Del>")
cmap("<C-k>", [[<C-\>e getcmdpos() == 1 ? '' : getcmdline()[:getcmdpos() - 2]<CR>]])
-- move cursor one character backwards unless at the end of the command line
cmap("<C-f>", [[getcmdpos() > strlen(getcmdline())? &cedit: "\<Lt>Right>"]], { expr = true })
-- see :h cmdline-editing
cmap("<Esc>b", [[<S-Left>]])
cmap("<Esc>f", [[<S-Right>]])

-- [[ line movements ]] --------------------------------------------------------
imap("<C-a>", "<Home>")
imap("<C-e>", "<End>")

-- [[ ui/vim behaviours ]] -----------------------------------------------------
map("n", "<esc>", function()
  U.deluxe_clear_ui()
end, { noremap = false, silent = true, desc = "EscDeluxe + Clear/Reset UI" })

--  See `:help wincmd` for a list of all window commands
-- @see: smart-splits.nvim
map("n", "<C-h>", "<C-w><C-h>", { desc = "Move focus to the left window" })
map("n", "<C-l>", "<C-w><C-l>", { desc = "Move focus to the right window" })
map("n", "<C-j>", "<C-w><C-j>", { desc = "Move focus to the lower window" })
map("n", "<C-k>", "<C-w><C-k>", { desc = "Move focus to the upper window" })

map("n", "<leader>w", function(_args)
  vim.api.nvim_command("silent! write")
end, { desc = "write buffer" })
map("n", "<leader>W", require("config.utils").sudo_write, { desc = "sudo write buffer" })
map("n", "<leader>q", "<cmd>q<cr>", { desc = "quit" })
map("n", "<leader>Q", "<cmd>q!<cr>", { desc = "really quit" })

-- Undo breakpoints
map("i", ",", ",<C-g>u")
map("i", ".", ".<C-g>u")
map("i", "!", "!<C-g>u")
map("i", "?", "?<C-g>u")

-- we don't want line joining with `J`
map("n", "J", "<nop>")

-- go to last buffer
map("n", "gbn", "<cmd>bnext<cr>", { desc = "next buffer" })
map("n", "gbp", "<cmd>bprev<cr>", { desc = "prev buffer" })
map("n", "<localleader><localleader>", "<C-^>", { desc = "last buffer" })

-- [[ better movements within a buffer ]] --------------------------------------
map("n", "H", "^")
map("n", "L", "$")
map({ "v", "x" }, "L", "g_")
map({ "v", "x" }, "H", "g^")
map("n", "0", "^")

-- Map <localleader>o & <localleader>O to newline without insert mode
map("n", "<localleader>o", ':<C-u>call append(line("."), repeat([""], v:count1))<CR>')
map("n", "<localleader>O", ':<C-u>call append(line(".")-1, repeat([""], v:count1))<CR>')

-- ignores line wraps
map("n", "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
map("n", "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

-- map({ "n", "x", "o" }, "n", "nzz<esc><cmd>lua mega.ui.blink_cursorline(50)<cr>")
-- map({ "n", "x", "o" }, "N", "Nzz<esc><cmd>lua mega.ui.blink_cursorline(50)<cr>")
-- map({ "n", "x", "o" }, "n", "nzz")
-- map({ "n", "x", "o" }, "N", "Nzz")

map({ "n", "x", "o" }, "n", "nzzzv<esc><cmd>lua mega.ui.blink_cursorline(150)<cr>", { desc = "Fwd  search '/' or '?'" })
map({ "n", "x", "o" }, "N", "Nzzzv<esc><cmd>lua mega.ui.blink_cursorline(150)<cr>", { desc = "Back search '/' or '?'" })

nnoremap("<C-f>", "<C-f>zz<Esc><Cmd>lua mega.ui.blink_cursorline(75)<CR>")
nnoremap("<C-b>", "<C-b>zz<Esc><Cmd>lua mega.ui.blink_cursorline(75)<CR>")

nnoremap("<C-d>", "<C-d>zz<Esc><Cmd>lua mega.ui.blink_cursorline(75)<CR>")
nnoremap("<C-u>", "<C-u>zz<Esc><Cmd>lua mega.ui.blink_cursorline(75)<CR>")

-- noremap Zz <c-w>_ \| <c-w>\|
-- noremap Zo <c-w>=

-- [[ macros ]] ----------------------------------------------------------------
-- Map Q to replay q register for macro
map("n", "q", "<Nop>")
map("n", "<localleader>q", "q", { desc = "macros: start macro" })
map("n", "Q", "@qj", { desc = "macros: run `q` macro" })
map("n", "Q", ":norm @q<CR>", { desc = "macros: run `q` macro (selection)" })

-- [[ folds ]] -----------------------------------------------------------------
map("n", "<leader>z", "za", { desc = "Toggle current fold" })
map("x", "<leader>z", "zf", { desc = "Create fold from selection" })
map("n", "zf", function()
  vim.cmd.normal("zMzv")
end, { desc = "Fold all except current" })
map("n", "zF", function()
  vim.cmd.normal("zMzvzczo")
end, { desc = "Fold all except current and children of current" })
map("n", "zO", function()
  vim.cmd.normal("zR")
end, { desc = "Open all folds" })
map("n", "zo", "zO", { desc = "Open all folds descending from current line" })

-- [[ plugin management ]] -----------------------------------------------------
map("n", "<leader>ps", "<cmd>Lazy sync<cr>", { desc = "[lazy] sync plugins" })
map("n", "<leader>pm", "<cmd>Lazy<cr>", { desc = "[lazy] plugins" })

-- [[ indents ]] ---------------------------------------------------------------
local indent_opts = { desc = "VSCode-style block indentation" }
map("x", ">>", function()
  vim.cmd.normal({ vim.v.count1 .. ">gv", bang = true })
end, indent_opts)
map("x", "<<", function()
  vim.cmd.normal({ vim.v.count1 .. "<gv", bang = true })
end, indent_opts)

-- [[ opening/closing delimiters/matchup/pairs ]] ------------------------------
map(
  { "n", "o", "s", "v", "x" },
  "<Tab>",
  "%",
  { desc = "jump to opening/closing delimiter", remap = false, silent = false }
)
-- map({ "n" }, "<Tab>", "%", { desc = "jump to opening/closing delimiter", remap = true, silent = false })

-- [[ copy/paste/yank/registers ]] ---------------------------------------------
-- don't yank the currently pasted text // thanks @theprimeagen
vim.cmd([[xnoremap <expr> p 'pgv"' . v:register . 'y']])

map("i", "<C-n>", "<Nop>", { desc = "Disable default autocompletion menu" })
map("i", "<C-p>", '<C-r>"', { desc = "Paste from register in insert mode" })

-- xnoremap("p", "\"_dP", "paste with saved register contents")

-- yank to empty register for D, c, etc.
map("n", "x", '"_x')
map("n", "X", '"_X')
map("n", "D", '"_D')
map("n", "c", '"_c')
map("n", "C", '"_C')
map("n", "cc", '"_S')

map("x", "x", '"_x')
map("x", "X", '"_X')
map("x", "D", '"_D')
map("x", "c", '"_c')
map("x", "C", '"_C')

map("n", "dd", function()
  if vim.fn.prevnonblank(".") ~= vim.fn.line(".") then
    return '"_dd'
  else
    return "dd"
  end
end, { expr = true, desc = "Special Line Delete" })

map("n", "<localleader>yts", function()
  local captures = vim.treesitter.get_captures_at_cursor()
  if #captures == 0 then
    vim.notify(
      "No treesitter captures under cursor",
      L.ERROR,
      { title = "[yank] failed to yank treesitter captures", render = "compact" }
    )
    return
  end

  local parsedCaptures = vim
    .iter(captures)
    :map(function(capture)
      return ("@%s"):format(capture)
    end)
    :totable()
  local resultString = vim.inspect(parsedCaptures)
  vim.fn.setreg("+", resultString .. "\n")
  vim.notify(resultString, L.INFO, { title = "[yank] yanked treesitter capture", render = "compact" })
end, { desc = "[yank] copy treesitter captures under cursor" })

map("n", "<localleader>yn", function()
  local res = vim.fn.expand("%:t", false, false)
  if type(res) ~= "string" then
    return
  end
  if res == "" then
    vim.notify("Buffer has no filename", L.ERROR, { title = "[yank] failed to yank filename", render = "compact" })
    return
  end
  vim.fn.setreg("+", res)
  vim.notify(res, L.INFO, { title = "[yank] yanked filename" })
end, { desc = "[yank] yank the filename of current buffer" })

map("n", "<localleader>yp", function()
  local res = vim.fn.expand("%:p", false, false)
  if type(res) ~= "string" then
    return
  end
  res = res == "" and vim.uv.cwd() or res
  if res:len() then
    vim.fn.setreg("+", res)
    vim.notify(res, L.INFO, { title = "[yank] yanked filepath" })
  end
end, { desc = "[yank] yank the full filepath of current buffer" })

-- [[ search ]] --------------------------------------------
map("n", "*", "m`<cmd>keepjumps normal! *``<CR>", { desc = "Don't jump on first * -- simpler vim-asterisk" })

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

map("x", "<leader>h", '"hy:%s/<C-r>h/<C-r>h/gc<left><left><left>', {
  desc = [[Crude search & replace visual selection
                 (breaks on multiple lines & special chars)]],
})

-- [[ spelling ]] --------------------------------------------------------------
-- map("n", "<leader>s", "z=e") -- Correct current word
map("n", "<localleader>sj", "]s", { desc = "[spell] move to next misspelling" })
map("n", "<localleader>sk", "[s", { desc = "[spell] move to previous misspelling" })
map("n", "<localleader>sf", function()
  local cur_pos = vim.api.nvim_win_get_cursor(0)
  vim.cmd.normal({ "1z=", bang = true })
  vim.api.nvim_win_set_cursor(0, cur_pos)
end, { desc = "[spell] fix spelling of word under cursor" })

-- Undo zw, remove the word from the entry in 'spellfile'.
map("n", "<localleader>su", function()
  vim.cmd("normal! zug")
end, { desc = "[spell] remove word from list" })

map("n", "<localleader>sa", function()
  local cur_pos = vim.api.nvim_win_get_cursor(0)
  vim.cmd.normal({ "zg", bang = true })
  vim.api.nvim_win_set_cursor(0, cur_pos)
end, { desc = "[spell] add word under cursor to dict" })
map("n", "<localleader>ss", function()
  -- Simulate pressing "z=" with "m" option using feedkeys
  -- vim.api.nvim_replace_termcodes ensures "z=" is correctly interpreted
  -- 'm' is the {mode}, which in this case is 'Remap keys'. This is default.
  -- If {mode} is absent, keys are remapped.
  --
  -- I tried this keymap as usually with
  vim.cmd("normal! 1z=")
  -- But didn't work, only with nvim_feedkeys
  -- vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("z=", true, false, true), "m", true)
end, { desc = "[spell] suggestions" })
-- map("n", "<localleader>si", function() vim.cmd.normal({ "ysiw`", bang = true }) end, { desc = "[spell] ignore spelling of word under cursor" })

-- [[ selections ]] ------------------------------------------------------------
map("n", "gv", "`[v`]", { desc = "reselect pasted content" })
map("n", "<leader>V", "V`]", { desc = "reselect pasted content" })
map("n", "gp", "`[v`]", { desc = "reselect pasted content" })
map("n", "gV", "ggVG", { desc = "select whole buffer" })
map("n", "<leader>v", "ggVG", { desc = "select whole buffer" })

-- [[ line editing ]] ----------------------------------------------------------
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
local function toggle_line_end_delimiter(character)
  local delimiters = { ",", ";" }
  return function()
    local line = vim.api.nvim_get_current_line()
    local last_char = line:sub(-1)
    if last_char == character then
      vim.api.nvim_set_current_line(line:sub(1, #line - 1))
    elseif vim.tbl_contains(delimiters, last_char) then
      vim.api.nvim_set_current_line(line:sub(1, #line - 1) .. character)
    else
      vim.api.nvim_set_current_line(line .. character)
    end
  end
end

map("n", "<localleader>,", toggle_line_end_delimiter(","), { desc = "add comma `,` to end of current line" })
map("n", "<localleader>/", toggle_line_end_delimiter("/"), { desc = "add slash `/` to end of current line" })
map("n", "<localleader>;", toggle_line_end_delimiter(";"), { desc = "add semicolon `;` to end of current line" })

map({ "x", "n" }, "gcd", function()
  local win = vim.api.nvim_get_current_win()
  local cur = vim.api.nvim_win_get_cursor(win)
  local vstart = vim.fn.getpos("v")[2]
  local current_line = vim.fn.line(".")
  local set_cur = vim.api.nvim_win_set_cursor
  if vstart == current_line then
    vim.cmd.yank()
    vim.cmd.normal("gcc")
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
    vim.cmd.normal("gvgc")
  end
end, { silent = true, desc = "[g]o [c]omment and [d]uplicate selected lines" })

-- [[ treesitter captures ]] ---------------------------------------------------

-- map({ "o", "x" }, "m", ":<C-U>lua require('tsht').nodes()<cr>", { desc = "ts hop range ops" })

map("n", "Ss", function()
  vim.print(vim.treesitter.get_captures_at_cursor())
end, { desc = "Print treesitter captures under cursor" })

map("n", "Sy", function()
  local captures = vim.treesitter.get_captures_at_cursor()
  if #captures == 0 then
    vim.notify(
      "No treesitter captures under cursor",
      vim.log.levels.ERROR,
      { title = "Yank failed", render = "wrapped-compact" }
    )
    return
  end

  local parsedCaptures = vim
    .iter(captures)
    :map(function(capture)
      return ("@%s"):format(capture)
    end)
    :totable()
  local resultString = vim.inspect(parsedCaptures)
  vim.fn.setreg("+", resultString .. "\n")
  vim.notify(resultString, vim.log.levels.INFO, { title = "Yanked capture", render = "wrapped-compact" })
end, { desc = "Copy treesitter captures under cursor" })

-- [[ terminal ]] --------------------------------------------------------------

map("n", "<leader>tt", "<cmd>T direction=horizontal move_on_direction_change=true<cr>", { desc = "horizontal" })
map("n", "<leader>tf", "<cmd>T direction=float move_on_direction_change=true<cr>", { desc = "float" })
map("n", "<leader>tv", "<cmd>T direction=vertical move_on_direction_change=true<cr>", { desc = "vertical" })
map("n", "<leader>tp", "<cmd>T direction=tab<cr>", { desc = "tab-persistent" })

-- map("n", "<leader>`", function()
--   if term_win_id and vim.api.nvim_win_is_valid(term_win_id) then
--     vim.api.nvim_set_current_win(term_win_id)
--     vim.cmd("startinsert")
--     return
--   end

--   vim.cmd("botright 15split")
--   vim.cmd("terminal")
--   vim.cmd("startinsert")

--   term_win_id = vim.api.nvim_get_current_win()
-- end, { desc = "term: open static terminal" })

-- [[ edit files / file explorering / executions ]] ------------------------------------------------------------
local editFileMappings = {
  r = { vim.cmd.restart, "[e]dit -> restart" },
  R = {
    function()
      require("config.utils").lsp.rename_file()
    end,
    "[e]dit file -> lsp rename as <input>",
  },
  s = {
    function()
      vim.cmd([[SaveAsFile]])
    end,
    "[e]dit file -> [s]ave as <input>",
  },
  f = {
    function()
      vim.ui.open(vim.fn.expand("%:p:h:~"))
    end,
    "[e]xplore cwd -> [f]inder",
  },
  d = {
    function()
      if vim.fn.confirm("Duplicate file?", "&Yes\n&No", 2, "Question") == 1 then
        vim.cmd("Duplicate")
      end
    end,
    "[e]dit file -> duplicate?",
  },
  D = {
    function()
      local current_file = vim.fn.expand("%:p")
      if current_file and current_file ~= "" then
        -- Check if trash utility is installed
        if vim.fn.executable("trash") == 0 then
          vim.api.nvim_echo({
            { "- Trash utility not installed. Make sure to install it first\n", "ErrorMsg" },
            { "- In macOS run `brew install trash`\n", nil },
          }, false, {})
          return
        end
        -- Prompt for confirmation before deleting the file
        if vim.fn.confirm(fmt("Delete %s?", current_file), "&Yes\n&No", 2, "Question") == 1 then
          -- vim.ui.input({
          --   prompt = "Type 'del' to delete the file '" .. current_file .. "': ",
          -- }, function(input)
          --   if input == "del" then
          -- Delete the file using trash app
          local success, _ = pcall(function()
            vim.fn.system({ "trash", vim.fn.fnameescape(current_file) })
          end)
          if success then
            vim.api.nvim_echo({
              { "File deleted from disk:\n", "Normal" },
              { current_file, "Normal" },
            }, false, {})
            -- Close the buffer after deleting the file
            vim.cmd("bd!")
          else
            vim.api.nvim_echo({
              { "Failed to delete file:\n", "ErrorMsg" },
              { current_file, "ErrorMsg" },
            }, false, {})
          end
        else
          vim.api.nvim_echo({
            { "File deletion canceled.", "Normal" },
          }, false, {})
        end
        -- end)
      else
        vim.api.nvim_echo({
          { "No file to delete", "WarningMsg" },
        }, false, {})
      end
      -- if vim.fn.confirm("Delete file?", "&Yes\n&No", 2, "Question") == 1 then vim.cmd("Delete") end
    end,
    "[e]dit file -> delete?",
  },
  yp = {
    function()
      vim.cmd([[let @+ = expand("%")]])
      vim.notify(fmt("yanked %s to clipboard", vim.fn.expand("%")))
    end,
    "[e]xplore file -> yank path",
  },
  xf = {
    function()
      local filetype = vim.bo.ft
      local file = vim.fn.expand("%") -- Get the current file name
      local first_line = vim.fn.getline(1) -- Get the first line of the file
      if string.match(first_line, "^#!/") then -- If first line contains shebang
        local escaped_file = vim.fn.shellescape(file) -- Properly escape the file name for shell commands

        -- Execute the script on a tmux pane on the right. On my mac I use zsh, so
        -- running this script with bash to not execute my zshrc file after
        -- vim.cmd("silent !tmux split-window -h -l 60 'bash -c \"" .. escaped_file .. "; exec bash\"'")
        -- `-l 60` specifies the size of the tmux pane, in this case 60 columns
        vim.notify("executing shell script in tmux split")
        vim.cmd(
          "silent !tmux split-window -h -l 60 'bash -c \""
            .. escaped_file
            .. "; echo; echo Press any key to exit...; read -n 1; exit\"'"
        )
      elseif filetype == "lua" then
        vim.notify("sourcing file")
        vim.cmd("source %")
      else
        vim.notify("Not a script. Shebang line not found.")
        -- vim.cmd("echo 'Not a script. Shebang line not found.'")
      end
    end,
    "e[x]ecute [f]ile",
  },
  xl = {
    function()
      local file_dir = vim.fn.expand(vim.g.notes_path)
      -- local file_dir = vim.fn.expand("%:p:h") -- Get the directory of the current file
      local pane_width = 60
      local right_pane_id =
        vim.fn.system("tmux list-panes -F '#{pane_id} #{pane_width}' | awk '$2 == " .. pane_width .. " {print $1}'")
      if right_pane_id ~= "" then
        -- If the right pane exists, close it
        vim.fn.system("tmux kill-pane -t " .. right_pane_id)
      else
        -- If the right pane doesn't exist, open it
        vim.fn.system("tmux split-window -h -l " .. pane_width .. " 'cd \"" .. file_dir .. "\" && zsh -i'")
      end
    end,
    "e[x]ecute [l]ine",
  },
  tt = {
    function()
      local file_dir = vim.fn.expand("%:p:h") -- Get the directory of the current file
      local pane_width = 60
      local right_pane_id =
        vim.fn.system("tmux list-panes -F '#{pane_id} #{pane_width}' | awk '$2 == " .. pane_width .. " {print $1}'")
      if right_pane_id ~= "" then
        -- If the right pane exists, close it
        vim.fn.system("tmux kill-pane -t " .. right_pane_id)
      else
        -- If the right pane doesn't exist, open it
        vim.fn.system("tmux split-window -h -l " .. pane_width .. " 'cd \"" .. file_dir .. "\" && zsh -i'")
        vim.fn.system("tmux send-keys 'ls' 'C-m'")
      end
    end,
    "[e]xplore cwd files -> [t]mux",
  },
  tn = {
    function()
      local file_dir = vim.fn.expand(vim.g.notes_path)
      local pane_width = 60
      local right_pane_id =
        vim.fn.system("tmux list-panes -F '#{pane_id} #{pane_width}' | awk '$2 == " .. pane_width .. " {print $1}'")
      if right_pane_id ~= "" then
        -- If the right pane exists, close it
        vim.fn.system("tmux kill-pane -t " .. right_pane_id)
      else
        -- If the right pane doesn't exist, open it
        vim.fn.system("tmux split-window -h -l " .. pane_width .. " 'cd \"" .. file_dir .. "\" && zsh -i'")
        vim.fn.system("tmux send-keys 'ls' 'C-m'")
      end
    end,
    "[e]xplore notes files -> tmux",
  },
}
-- <leader>e<key>
vim.iter(editFileMappings):each(function(key, rhs)
  leaderMapper("n", "e" .. key, rhs[1], rhs[2])
end)

return M
