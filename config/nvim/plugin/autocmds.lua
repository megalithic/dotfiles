local group = vim.api.nvim_create_augroup("mega.autocmds", { clear = true })

vim.api.nvim_create_autocmd("BufWritePre", {
  group = group,
  callback = function(args)
    if vim.bo[args.buf].filetype == "oil" or vim.api.nvim_buf_get_name(args.buf) == "" then return end

    local dir = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(args.buf), ":p:h")
    if dir == "" or dir:match("^%w%+://") or dir:match("^suda:") then return end

    local stats = vim.uv.fs_stat(dir)
    if stats and stats.type == "directory" then return end

    if vim.v.cmdbang == 0 then
      vim.fn.inputsave()
      local ok, result = pcall(vim.fn.input, string.format('"%s" does not exist. Create? [y/N] ', dir), "")
      vim.fn.inputrestore()
      if not ok or result:lower() ~= "y" then
        print("Canceled")
        return
      end
    end

    vim.fn.mkdir(dir, "p")
  end,
})

vim.api.nvim_create_autocmd("TextYankPost", {
  desc = "User: Highlighted Yank",
  callback = function() vim.hl.hl_op({ timeout = 250, on_visual = false, higroup = "VisualYank2" }) end,
})

vim.api.nvim_create_autocmd("VimResized", {
  desc = "User: keep splits equally sized on window resize",
  command = "wincmd =",
})

vim.api.nvim_create_autocmd("BufReadPost", {
  desc = "User: Restore cursor position",
  callback = function(ctx)
    local mark = vim.api.nvim_buf_get_mark(ctx.buf, '"')
    local lcount = vim.api.nvim_buf_line_count(ctx.buf)
    local line = mark[1]
    local ft = vim.bo[ctx.buf].filetype
    if
      line > 0
      and line <= lcount
      -- only real file buffers (buftype == ""); skip help/terminal/etc.
      and vim.bo[ctx.buf].buftype == ""
      and vim.fn.index({ "jjdescription", "commit", "gitrebase", "xxd" }, ft) == -1
      and not vim.o.diff
    then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

vim.api.nvim_create_autocmd({ "BufWinEnter", "WinEnter", "WinLeave" }, {
  desc = "User: Cursorline only in active window",
  callback = function(ctx)
    if vim.bo[ctx.buf].buftype ~= "" then return end
    vim.opt_local.cursorline = ctx.event ~= "WinLeave"
  end,
})

-- https://github.com/neovim/neovim/issues/26449#issuecomment-1845293096
-- using an insert-mode mapping on `esc` breaks `:abbreviate`, and `InsertLeave`
-- also does not work
vim.api.nvim_create_autocmd("WinScrolled", {
  desc = "User: exit snippet",
  callback = function() vim.snippet.stop() end,
})

vim.api.nvim_create_autocmd({ "CursorHold", "FocusGained", "CursorMoved" }, {
  callback = function() vim.cmd("silent! checktime") end,
})

vim.api.nvim_create_autocmd({ "ModeChanged", "CursorMoved", "BufEnter", "BufWinEnter", "TermOpen" }, {
  group = vim.api.nvim_create_augroup("DynamicLineNumbers", { clear = true }),
  callback = function()
    if not vim.bo.modifiable or vim.bo.buftype ~= "" or vim.bo.filetype == "help" then
      vim.opt_local.number = false
      vim.opt_local.relativenumber = false
      return
    end

    local mode = vim.api.nvim_get_mode().mode
    if vim.g.relnum_hybrid then -- MODERN RELOPS LOGIC
      local targeting_modes = {
        ["no"] = true, -- Operator-pending (pressed d, c, y)
        ["v"] = true, -- Visual
        ["n"] = true, -- Insert
        ["V"] = true, -- Visual Line
        ["\22"] = true, -- Visual Block (CTRL-V)
        ["c"] = true, -- Command-line (typing :)
        ["niI"] = true, -- Operator-pending in Insert mode (rare)
      }
      vim.opt_local.relativenumber = targeting_modes[mode] or false
    else -- STANDARD HYBRID LOGIC
      if mode == "i" then
        vim.opt_local.relativenumber = false
      else
        vim.opt_local.relativenumber = true
      end
    end

    vim.opt_local.number = true
  end,
})

-- Hammerspoon interop: register nvim --listen socket in /tmp/nvim-sockets/
-- so external tools (hammerspoon://nvim-open URL handler, etc.) can discover
-- and dispatch to this instance. See lua/utils/interop.lua (M.hs).
local hs_interop = require("utils.interop").hs

vim.api.nvim_create_autocmd("VimEnter", {
  desc = "Hammerspoon: register nvim socket",
  callback = function() hs_interop.register_socket() end,
})

vim.api.nvim_create_autocmd("VimLeavePre", {
  desc = "Hammerspoon: cleanup nvim socket file",
  callback = function() hs_interop.cleanup_socket() end,
})
