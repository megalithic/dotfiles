local U = require("mega.utils")

local M = {}

--  See `:help vim.keymap.set()`
local map = vim.keymap.set

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

---create a mapping function factory
---@param mode string
---@param o table
---@return fun(lhs: string, rhs: string|function, opts: table|nil) 'create a mapping'
local function mapper(mode, o)
  -- copy the opts table as extends will mutate the opts table passed in otherwise
  local parent_opts = vim.deepcopy(o)
  ---Create a mapping
  ---@param lhs string
  ---@param rhs string|function
  ---@param opts table
  return function(lhs, rhs, opts)
    -- If the label is all that was passed in, set the opts automagically
    opts = type(opts) == "string" and { label = opts } or opts and vim.deepcopy(opts) or {}

    -- if not opts.has or client.server_capabilities[opts.has .. "Provider"] then
    if opts.label or opts.desc then
      local ok, wk = pcall(require, "which-key")
      if ok and wk then wk.register({ [lhs] = opts.label or opts.desc }, { mode = mode }) end
      if opts.label and not opts.desc then opts.desc = opts.label end
      opts.label = nil
    end

    if rhs == nil then
      vim.pprint(mode, lhs, rhs, opts, parent_opts)
    else
      map(mode, lhs, rhs, vim.tbl_extend("keep", opts, parent_opts))
    end
  end
end

local map_opts = { remap = true, silent = true }
local noremap_opts = { remap = false, silent = true }

-- TODO: https://github.com/b0o/nvim-conf/blob/main/lua/user/mappings.lua#L19-L37

for _, mode in ipairs({ "n", "x", "i", "v", "o", "t", "s", "c" }) do
  -- {
  -- n = "normal",
  -- v = "visual",
  -- s = "select",
  -- x = "visual & select",
  -- i = "insert",
  -- o = "operator",
  -- t = "terminal",
  -- c = "command",
  -- }

  -- recursive global mappings
  -- mega[mode .. "map"] = mapper(mode, map_opts)
  M[mode .. "map"] = mapper(mode, map_opts)
  _G[mode .. "map"] = mapper(mode, map_opts)
  -- non-recursive global mappings
  M[mode .. "noremap"] = mapper(mode, noremap_opts)
  _G[mode .. "noremap"] = mapper(mode, noremap_opts)
end

-- [[ tabs ]] ------------------------------------------------------------------
-- jump to tab
for i = 0, 9 do
  if i + 1 >= 10 then break end
  local key_string = tostring(i + 1)
  map("n", "<localleader>" .. key_string, string.format("<cmd>%stabnext<cr>", key_string), { desc = string.format("tab: jump to tab %s", key_string) })
end

-- Exit terminal mode in the builtin terminal with a shortcut that is a bit easier
-- for people to discover. Otherwise, you normally need to press <C-\><C-n>, which
-- is not what someone will guess without a bit more experience.
--
-- NOTE: This won't work in all terminal emulators/tmux/etc. Try your own mapping
-- or just use <C-\><C-n> to exit terminal mode
map("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

-- [[ command mode ]] ----------------------------------------------------------
map("v", "<leader>S", ":!sort<cr>", { desc = "Sort selection" })
map("n", "<leader>:", ":!", { desc = "Execute last command" })
map("n", "<leader>;", ":<Up>", { desc = "Go to last command" })
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
map("n", "<esc>", function() U.deluxe_clear_ui() end, { noremap = false, silent = true, desc = "EscDeluxe + Clear/Reset UI" })

--  See `:help wincmd` for a list of all window commands
-- @see: smart-splits.nvim
-- map("n", "<C-h>", "<C-w><C-h>", { desc = "Move focus to the left window" })
-- map("n", "<C-l>", "<C-w><C-l>", { desc = "Move focus to the right window" })
-- map("n", "<C-j>", "<C-w><C-j>", { desc = "Move focus to the lower window" })
-- map("n", "<C-k>", "<C-w><C-k>", { desc = "Move focus to the upper window" })

map("n", "<leader>w", function(_args) vim.api.nvim_command("silent! write") end, { desc = "write buffer" })
map("n", "<leader>W", "<cmd>SudaWrite<cr>", { desc = "sudo write buffer" })
map("n", "<leader>q", "<cmd>q<cr>", { desc = "quit" })
map("n", "<leader>Q", "<cmd>q!<cr>", { desc = "really quit" })

-- Undo breakpoints
map("i", ",", ",<C-g>u")
map("i", ".", ".<C-g>u")
map("i", "!", "!<C-g>u")
map("i", "?", "?<C-g>u")

-- we don't want line joining with `J`
map("n", "J", "<nop>")

map("n", "<localleader><localleader>", "<C-^>")

-- [[ better movements within a buffer ]] --------------------------------------
map("n", "H", "^")
map("n", "L", "$")
map({ "v", "x" }, "L", "g_")
map("n", "0", "^")

-- Map <localleader>o & <localleader>O to newline without insert mode
map("n", "<localleader>o", ":<C-u>call append(line(\".\"), repeat([\"\"], v:count1))<CR>")
map("n", "<localleader>O", ":<C-u>call append(line(\".\")-1, repeat([\"\"], v:count1))<CR>")

-- ignores line wraps
map("n", "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
map("n", "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

-- map({ "n", "x", "o" }, "n", "nzz<esc><cmd>lua mega.blink_cursorline(50)<cr>")
-- map({ "n", "x", "o" }, "N", "Nzz<esc><cmd>lua mega.blink_cursorline(50)<cr>")
-- map({ "n", "x", "o" }, "n", "nzz")
-- map({ "n", "x", "o" }, "N", "Nzz")

map({ "n", "x", "o" }, "n", "nzzzv<esc><cmd>lua mega.blink_cursorline(150)<cr>", { desc = "Fwd  search '/' or '?'" })
map({ "n", "x", "o" }, "N", "Nzzzv<esc><cmd>lua mega.blink_cursorline(150)<cr>", { desc = "Back search '/' or '?'" })

nnoremap("<C-f>", "<C-f>zz<Esc><Cmd>lua mega.blink_cursorline(75)<CR>")
nnoremap("<C-b>", "<C-b>zz<Esc><Cmd>lua mega.blink_cursorline(75)<CR>")

nnoremap("<C-d>", "<C-d>zz<Esc><Cmd>lua mega.blink_cursorline(75)<CR>")
nnoremap("<C-u>", "<C-u>zz<Esc><Cmd>lua mega.blink_cursorline(75)<CR>")

-- [[ macros ]] ----------------------------------------------------------------
-- Map Q to replay q register for macro
map("n", "q", "<Nop>")
map("n", "<localleader>q", "q", { desc = "macros: start macro" })
map("n", "Q", "@qj", { desc = "macros: run `q` macro" })
map("n", "Q", ":norm @q<CR>", { desc = "macros: run `q` macro (selection)" })

-- [[ folds ]] -----------------------------------------------------------------
map("n", "<leader>z", "za", { desc = "Toggle current fold" })
map("x", "<leader>z", "zf", { desc = "Create fold from selection" })
map("n", "zf", function() vim.cmd.normal("zMzv") end, { desc = "Fold all except current" })
map("n", "zF", function() vim.cmd.normal("zMzvzczo") end, { desc = "Fold all except current and children of current" })
map("n", "zO", function() vim.cmd.normal("zR") end, { desc = "Open all folds" })
map("n", "zo", "zO", { desc = "Open all folds descending from current line" })

-- [[ plugin management ]] -----------------------------------------------------
map("n", "<leader>ps", "<cmd>Lazy sync<cr>", { desc = "[lazy] sync plugins" })

-- [[ opening/closing delimiters/matchup/pairs ]] ------------------------------
map({ "n", "o", "s", "v", "x" }, "<Tab>", "%", { desc = "jump to opening/closing delimiter", remap = true, silent = false })

-- [[ copy/paste/yank/registers ]] ---------------------------------------------
-- don't yank the currently pasted text // thanks @theprimeagen
vim.cmd([[xnoremap <expr> p 'pgv"' . v:register . 'y']])
-- xnoremap("p", "\"_dP", "paste with saved register contents")

-- yank to empty register for D, c, etc.
map("n", "x", "\"_x")
map("n", "X", "\"_X")
map("n", "D", "\"_D")
map("n", "c", "\"_c")
map("n", "C", "\"_C")
map("n", "cc", "\"_S")

map("x", "x", "\"_x")
map("x", "X", "\"_X")
map("x", "D", "\"_D")
map("x", "c", "\"_c")
map("x", "C", "\"_C")

map("n", "dd", function()
  if vim.fn.prevnonblank(".") ~= vim.fn.line(".") then
    return "\"_dd"
  else
    return "dd"
  end
end, { expr = true, desc = "Special Line Delete" })

map("n", "<localleader>yts", function()
  local captures = vim.treesitter.get_captures_at_cursor()
  if #captures == 0 then
    vim.notify("No treesitter captures under cursor", L.ERROR, { title = "[yank] failed to yank treesitter captures", render = "compact" })
    return
  end

  local parsedCaptures = vim.iter(captures):map(function(capture) return ("@%s"):format(capture) end):totable()
  local resultString = vim.inspect(parsedCaptures)
  vim.fn.setreg("+", resultString .. "\n")
  vim.notify(resultString, L.INFO, { title = "[yank] yanked treesitter capture", render = "compact" })
end, { desc = "[yank] copy treesitter captures under cursor" })

map("n", "<localleader>yn", function()
  local res = vim.fn.expand("%:t", false, false)
  if type(res) ~= "string" then return end
  if res == "" then
    vim.notify("Buffer has no filename", L.ERROR, { title = "[yank] failed to yank filename", render = "compact" })
    return
  end
  vim.fn.setreg("+", res)
  vim.notify(res, L.INFO, { title = "[yank] yanked filename" })
end, { desc = "[yank] yank the filename of current buffer" })

map("n", "<localleader>yp", function()
  local res = vim.fn.expand("%:p", false, false)
  if type(res) ~= "string" then return end
  res = res == "" and vim.uv.cwd() or res
  if res:len() then
    vim.fn.setreg("+", res)
    vim.notify(res, L.INFO, { title = "[yank] yanked filepath" })
  end
end, { desc = "[yank] yank the full filepath of current buffer" })

-- [[ search ]] --------------------------------------------
map("n", "*", "m`<cmd>keepjumps normal! *``<CR>", { desc = "Don't jump on first * -- simpler vim-asterisk" })

map("n", "<leader>h", ":%s/\\<<C-r><C-w>\\>/<C-r><C-w>/gIc<Left><Left><Left><Left>", { desc = "Replace instances of hovered word" })
map("n", "<leader>H", ":%S/<C-r><C-w>/<C-r><C-w>/gcw<Left><Left><Left><Left>", { desc = "Replace instances of hovered word (matching case)" })

map("x", "<leader>h", "\"hy:%s/<C-r>h/<C-r>h/gc<left><left><left>", {
  desc = [[Crude search & replace visual selection
                 (breaks on multiple lines & special chars)]],
})

-- [[ spelling ]] --------------------------------------------------------------
-- map("n", "<leader>s", "z=e") -- Correct current word
map("n", "<localleader>sj", "]s", { desc = "[spell] Move to next misspelling" })
map("n", "<localleader>sk", "[s", { desc = "[spell] Move to previous misspelling" })
map("n", "<localleader>sf", function()
  local cur_pos = vim.api.nvim_win_get_cursor(0)
  vim.cmd.normal({ "1z=", bang = true })
  vim.api.nvim_win_set_cursor(0, cur_pos)
end, { desc = "[spell] Correct spelling of word under cursor" })

map("n", "<localleader>sa", function()
  local cur_pos = vim.api.nvim_win_get_cursor(0)
  vim.cmd.normal({ "zg", bang = true })
  vim.api.nvim_win_set_cursor(0, cur_pos)
end, { desc = "[spell] Add word under cursor to dictionary" })

map("n", "<localleader>si", function() vim.cmd.normal("ysiw`") end, { desc = "[spell] Ignore spelling of word under cursor" })

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
local function modify_line_end_delimiter(character)
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

map("n", "<localleader>,", modify_line_end_delimiter(","), { desc = "add comma `,` to end of current line" })
map("n", "<localleader>;", modify_line_end_delimiter(";"), { desc = "add semicolon `;` to end of current line" })

-- [Terminal] ------------------------------------------------------------------

local nnoremap = function(lhs, rhs, desc) vim.keymap.set("n", lhs, rhs, { buffer = 0, desc = "term: " .. desc }) end
map("n", "<leader>tt", "<cmd>T direction=horizontal move_on_direction_change=true<cr>", { desc = "horizontal" })
map("n", "<leader>tf", "<cmd>T direction=float move_on_direction_change=true<cr>", { desc = "float" })
map("n", "<leader>tv", "<cmd>T direction=vertical move_on_direction_change=true<cr>", { desc = "vertical" })
map("n", "<leader>tp", "<cmd>T direction=tab<cr>", { desc = "tab-persistent" })

-- [[ executions ]] ------------------------------------------------------------

-- If this is a bash script, make it executable, and execute it in a tmux pane on the right
-- Using a tmux pane allows me to easily select text
-- Had to include quotes around "%" because there are some apple dirs that contain spaces, like iCloud
map("n", "<leader>exf", function()
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
    vim.cmd("silent !tmux split-window -h -l 60 'bash -c \"" .. escaped_file .. "; echo; echo Press any key to exit...; read -n 1; exit\"'")
  elseif filetype == "lua" then
    vim.notify("sourcing file")
    vim.cmd("source %")
  else
    vim.notify("Not a script. Shebang line not found.")
    -- vim.cmd("echo 'Not a script. Shebang line not found.'")
  end
end, { desc = "e[x]ecute [f]ile" })
map("n", "<leader>exl", "<cmd>.lua<CR>", { desc = "e[x]ecute [l]ine" })

-- Toggle a tmux pane on the right in bash, in the same directory as the current file
-- Opening it in bash because it's faster, I don't have to run my .zshrc file,
-- which pulls from my repo and a lot of other stuff
map("n", "<leader>en", function()
  local file_dir = vim.fn.expand(vim.g.notes_path)
  -- local file_dir = vim.fn.expand("%:p:h") -- Get the directory of the current file
  local pane_width = 60
  local right_pane_id = vim.fn.system("tmux list-panes -F '#{pane_id} #{pane_width}' | awk '$2 == " .. pane_width .. " {print $1}'")
  if right_pane_id ~= "" then
    -- If the right pane exists, close it
    vim.fn.system("tmux kill-pane -t " .. right_pane_id)
  else
    -- If the right pane doesn't exist, open it
    vim.fn.system("tmux split-window -h -l " .. pane_width .. " 'cd \"" .. file_dir .. "\" && zsh -i'")
  end
end)
map("n", "<leader>et", function()
  local file_dir = vim.fn.expand("%:p:h") -- Get the directory of the current file
  local pane_width = 60
  local right_pane_id = vim.fn.system("tmux list-panes -F '#{pane_id} #{pane_width}' | awk '$2 == " .. pane_width .. " {print $1}'")
  if right_pane_id ~= "" then
    -- If the right pane exists, close it
    vim.fn.system("tmux kill-pane -t " .. right_pane_id)
  else
    -- If the right pane doesn't exist, open it
    vim.fn.system("tmux split-window -h -l " .. pane_width .. " 'cd \"" .. file_dir .. "\" && zsh -i'")
  end
end)

return M
