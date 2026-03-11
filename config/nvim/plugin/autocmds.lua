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
    if vim.bo[ctx.buf].buftype ~= "" then return end
    vim.cmd([[silent! normal! g`"]])
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
