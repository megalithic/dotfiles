-- local map = vim.keymap.set
local map = mega.u.safe_keymap_set
local unmap = vim.keymap.del

-- [[ unmap ]] -----------------------------------------------------------------
unmap({ "x", "n" }, "gra") -- lsp default: code actions
unmap("n", "grn") -- lsp default: rename
unmap("n", "grr") -- lsp default: references
unmap("n", "grt") -- lsp default: type_definitions
unmap("n", "gri") -- lsp default: implementation

-- [[ escape deluxe ]] ---------------------------------------------------------
-- Close all floating windows (hover docs, popups, etc.)
local function close_floats()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_is_valid(win) then
      local config = vim.api.nvim_win_get_config(win)
      -- Close editor-relative floats, but not window-relative (like scrollbars)
      if config.relative ~= "" and config.relative ~= "win" then pcall(vim.api.nvim_win_close, win, false) end
    end
  end
end

-- Clear commandline
local function clear_commandline()
  if vim.fn.mode() == "n" then
    vim.api.nvim_echo({}, false, {})
    vim.cmd.echon("''")
  end
end

-- Escape key does many things: clear UI, dismiss notifications, auto-save
local function escape_deluxe()
  -- Clear search highlighting
  vim.cmd.nohlsearch()

  -- Update diff if in diff mode
  vim.cmd.diffupdate()

  -- Resync syntax highlighting (fixes occasional glitches)
  vim.cmd("syntax sync fromstart")

  -- Close floating windows (hover docs, etc.)
  close_floats()

  -- Dismiss snacks notifications
  local ok, snacks = pcall(require, "snacks")
  if ok and snacks.notifier then snacks.notifier.hide() end

  -- Blink cursorline for visual feedback
  mega.ui.blink_cursorline()

  -- Force redraw
  vim.cmd.redraw({ bang = true })

  -- Auto-save if buffer has filename (not scratch buffers)
  if vim.fn.bufname("%") ~= "" then vim.cmd.update({ bang = true }) end

  -- Clear commandline
  clear_commandline()

  -- Send actual escape key for any remaining mode cleanup
  vim.api.nvim_feedkeys(vim.keycode("<Esc>"), "n", true)
end

map("c", "<C-n>", "<Down>")
map("c", "<C-p>", "<Up>")
-- <C-A> allows you to insert all matches on the command line e.g. bd *.js <c-a>
-- will insert all matching files e.g. :bd a.js b.js c.js
map("c", "<c-x><c-a>", "<c-a>")
map("c", "<C-a>", "<Home>")
map("c", "<C-e>", "<End>")
map("c", "<C-b>", "<Left>")
map("c", "<C-d>", "<Del>")
map("c", "<C-k>", [[<C-\>e getcmdpos() == 1 ? '' : getcmdline()[:getcmdpos() - 2]<CR>]])
-- move cursor one character backwards unless at the end of the command line
map("c", "<C-f>", [[getcmdpos() > strlen(getcmdline())? &cedit: "\<Lt>Right>"]], { expr = true })
-- see :h cmdline-editing
map("c", "<Esc>b", [[<S-Left>]])
map("c", "<Esc>f", [[<S-Right>]])

map("i", "<C-a>", "<Home>")
map("i", "<C-e>", "<End>")

map("n", "<Esc>", escape_deluxe, { desc = "Escape deluxe: clear UI, save buffer" })

map("n", "<leader>w", function(_args) vim.api.nvim_command("silent! write") end, { desc = "write buffer" })
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

-- Center screen and blink after search navigation
map({ "n", "x", "o" }, "n", function()
  local ok = pcall(vim.cmd.normal, { "nzzzv", bang = true })
  if ok then mega.ui.blink_cursorline(150) end
end, { desc = "Fwd search '/' or '?'" })

map({ "n", "x", "o" }, "N", function()
  local ok = pcall(vim.cmd.normal, { "Nzzzv", bang = true })
  if ok then mega.ui.blink_cursorline(150) end
end, { desc = "Back search '/' or '?'" })

-- Page navigation with center + blink
map("n", "<C-d>", function()
  vim.cmd.normal({ vim.api.nvim_replace_termcodes("<C-d>zz", true, false, true), bang = true })
  mega.ui.blink_cursorline(75)
end, { desc = "Half-page down" })

map("n", "<C-u>", function()
  vim.cmd.normal({ vim.api.nvim_replace_termcodes("<C-u>zz", true, false, true), bang = true })
  mega.ui.blink_cursorline(75)
end, { desc = "Half-page up" })

map("n", "<C-f>", function()
  vim.cmd.normal({ vim.api.nvim_replace_termcodes("<C-f>zz", true, false, true), bang = true })
  mega.ui.blink_cursorline(75)
end, { desc = "Page down" })

map("n", "<C-b>", function()
  vim.cmd.normal({ vim.api.nvim_replace_termcodes("<C-b>zz", true, false, true), bang = true })
  mega.ui.blink_cursorline(75)
end, { desc = "Page up" })

-- Restart (saves session to XDG state dir, restarts, reloads, cleans up)

local tmp_session = vim.fn.stdpath("state") .. "/tmp_restart_session.vim"

function _G.after_restart(orig_session)
  vim.g.session_load = false -- NOTE: See `MiniSession`
  vim.cmd.source(tmp_session)
  vim.fs.rm(tmp_session, { force = true })
  vim.v.this_session = orig_session
end

vim.keymap.set("n", "<Leader>R", function()
  local this_session = vim.v.this_session
  vim.cmd.write({ mods = { silent = true, emsg_silent = true } })
  vim.cmd.mksession({ tmp_session, bang = true })
  vim.cmd.restart(string.format("lua _G.after_restart('%s')", this_session))
end, { desc = "Restart" })

-- don't yank the currently pasted text // thanks @theprimeagen
vim.cmd([[xnoremap <expr> p 'pgv"' . v:register . 'y']])
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

local repeatable = mega.u.repeatable

map({ "n", "x", "o" }, ";", function() repeatable.repeat_last_move() end)
-- NOTE: Don't map "," - it's the leader key. Use ; to repeat, f/F/t/T to change direction.

map({ "n", "x", "o" }, "f", repeatable.builtin_f_expr, { expr = true })
map({ "n", "x", "o" }, "F", repeatable.builtin_F_expr, { expr = true })
map({ "n", "x", "o" }, "t", repeatable.builtin_t_expr, { expr = true })
map({ "n", "x", "o" }, "T", repeatable.builtin_T_expr, { expr = true })

-- [[ pairs/delimiters ]] ------------------------------------------------------
-- Tab jumps between matching pairs (uses nvim-tree-pairs which is treesitter-aware)
map({ "n", "x", "o" }, "<Tab>", "%", { remap = true, desc = "Jump to matching pair" })

-- [[ shade ]] -----------------------------------------------------------------
-- Smart toggle: hide if inside Shade, show/focus if outside
map(
  { "n", "i", "t" },
  "<C-n>",
  function() require("utils.interop").shade.smart_toggle() end,
  { desc = "Shade: smart toggle" }
)
