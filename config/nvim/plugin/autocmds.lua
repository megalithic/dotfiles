vim.api.nvim_create_autocmd("TextYankPost", {
  desc = "User: Highlighted Yank",
  callback = function() vim.hl.on_yank({ timeout = 250, on_visual = false, higroup = "VisualYank2" }) end,
})

vim.api.nvim_create_autocmd("VimResized", {
  desc = "User: keep splits equally sized on window resize",
  command = "wincmd =",
})

vim.api.nvim_create_autocmd("BufReadPost", {
  desc = "User: Restore cursor position",
  callback = function(ctx)
    -- if vim.bo[ctx.buf].buftype ~= "" then return end
    -- vim.cmd([[silent! normal! g`"]])

    local mark = vim.api.nvim_buf_get_mark(ctx.buf, '"')
    local lcount = vim.api.nvim_buf_line_count(ctx.buf)
    local line = mark[1]
    local ft = vim.bo.filetype
    if
      line > 0
      and line <= lcount
      and vim.bo[ctx.buf].buftype ~= ""
      and vim.fn.index({ "jjdescription", "commit", "gitrebase", "xxd" }, ft) == -1
      and not vim.o.diff
    then
      pcall(vim.api.nvim_win_set_cursor, ctx.buf, mark)
      -- vim.cmd([[silent! normal! g`"]])
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
  callback = function(ctx) vim.cmd("silent! checktime") end,
})

-- produce the ghostty progress bar, through tmux, for lsp progress messages.
local active_count = 0
local clear_timer = nil

local osc_seq_wrap = function(seq)
  if os.getenv("TMUX") then return string.format("\27Ptmux;\27%s\27\\", seq) end
  return seq
end

local function clear_progress()
  if clear_timer then
    clear_timer:stop()
    clear_timer = nil
  end
  vim.api.nvim_ui_send(osc_seq_wrap("\027]9;4;0\027\\"))
end

vim.api.nvim_create_autocmd("LspProgress", {
  callback = function(ev)
    local value = ev.data.params.value

    if clear_timer then
      clear_timer:stop()
      clear_timer = nil
    end

    if value.kind == "begin" then
      active_count = active_count + 1
      if value.percentage then
        vim.api.nvim_ui_send(osc_seq_wrap(string.format("\027]9;4;1;%d\027\\", value.percentage)))
      else
        vim.api.nvim_ui_send(osc_seq_wrap("\027]9;4;3\027\\"))
      end
    elseif value.kind == "report" then
      if value.percentage then
        vim.api.nvim_ui_send(osc_seq_wrap(string.format("\027]9;4;1;%d\027\\", value.percentage)))
      else
        vim.api.nvim_ui_send(osc_seq_wrap("\027]9;4;3\027\\"))
      end
    elseif value.kind == "end" then
      active_count = math.max(0, active_count - 1)
      if active_count == 0 then
        vim.api.nvim_ui_send(osc_seq_wrap("\027]9;4;1;100\027\\"))
        clear_timer = vim.uv.new_timer()
        if clear_timer ~= nil then
          clear_timer:start(1500, 0, vim.schedule_wrap(clear_progress))
        else
          clear_progress()
        end
      end
    end
  end,
})

vim.api.nvim_create_autocmd("QuitPre", {
  desc = "Clear ghostty progress bar on quit",
  callback = function()
    vim.schedule(function() vim.api.nvim_ui_send(osc_seq_wrap("\027]9;4;0\027\\")) end)
  end,
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
