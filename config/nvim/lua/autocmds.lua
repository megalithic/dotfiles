-- [ autocmds.. ] --------------------------------------------------------------

local cmd, fn = vim.cmd, vim.fn
local au, exec, augroup = mega.au, mega.exec, mega.augroup

au([[FocusGained,BufEnter,CursorHold,CursorHoldI,BufWinEnter * if mode() != 'c' | checktime | endif]])
au([[StdinReadPost * set buftype=nofile]])
au([[FileType help wincmd L]])
au([[CmdwinEnter * nnoremap <buffer> <CR> <CR>]])
au([[VimResized * lua require('golden_size').on_win_enter()]])
au([[InsertLeave,CompleteDone * if pumvisible() == 0 | pclose | endif]])
au([[Syntax * call matchadd('TSNote', '\W\zs\(TODO\|CHANGED\)')]])
au([[Syntax * call matchadd('TSDanger', '\W\zs\(FIXME\|BUG\|HACK\)')]])
au([[Syntax * call matchadd('TSDanger', '^\(<\|=\|>\)\{7\}\([^=].\+\)\?$')]])
au([[Syntax * call matchadd('TSNote', '\W\zs\(NOTE\|INFO\|IDEA\|REF\)')]])
au([[WinEnter * if &previewwindow | setlocal wrap | endif]])
au([[FileType fzf :tnoremap <buffer> <esc> <C-c>]])
au([[FileType help,startuptime,qf,lspinfo nnoremap <buffer><silent> q :close<CR>]])
au([[FileType man nnoremap <buffer><silent> q :quit<CR>]])
au([[BufWritePre * %s/\n\+\%$//e]])
-- au([[TextYankPost * if v:event.operator is 'y' && v:event.regname is '+' | OSCYankReg + | endif]]) -- https://github.com/ojroques/vim-oscyank#configuration
-- vim.cmd([[if !exists("b:undo_ftplugin") | let b:undo_ftplugin .= '' | endif]])

-- NOTE: presently handled by null-ls/efm-ls
-- Trim Whitespace
-- exec(
--   [[
--     fun! TrimWhitespace()
--         let l:save = winsaveview()
--         keeppatterns %s/\s\+$//e
--         call winrestview(l:save)
--     endfun
--     autocmd BufWritePre * :call TrimWhitespace()
-- ]],
--   false
-- )

-- augroup("auto-cursor", {
--   -- When editing a file, always jump to the last known cursor position.
--   -- Don't do it for commit messages, when the position is invalid, or when
--   -- inside an event handler (happens when dropping a file on gvim).
--   events = { "BufReadPost" },
--   targets = { "*" },
--   command = function()
--     local pos = fn.line([['"]])
--     if vim.bo.ft ~= "gitcommit" and pos > 0 and pos <= fn.line("$") then
--       vim.cmd("keepjumps normal g`\"")
--     end
--   end,
-- })

augroup("auto-mkdir", {
  events = { "BufNewFile", "BufWritePre" },
  targets = { "*" },
  command = mega.auto_mkdir(),
})

-- auto-reload kitty upon kitty.conf write
augroup("kitty", {
  {
    events = { "BufWritePost" },
    targets = { "kitty.conf" },
    command = function()
      vim.cmd(":silent !kill -SIGUSR1 $(pgrep kitty)")
    end,
  },
})

augroup("paq", {
  {
    events = { "BufWritePost" },
    targets = { "plugins.lua" },
    command = function()
      vim.cmd("luafile %")
    end,
  },
})

augroup("yank_highlighted_region", {
  {
    events = { "TextYankPost" },
    targets = { "*" },
    command = "lua vim.highlight.on_yank({ higroup = 'Substitute', timeout = 150, on_macro = true })",
  },
})

augroup("terminal", {
  {
    events = { "TermClose" },
    targets = { "*" },
    command = "noremap <buffer><silent><ESC> :bd!<CR>",
  },
  {
    events = { "TermOpen" },
    targets = { "*" },
    command = [[setlocal nonumber norelativenumber conceallevel=0]],
  },
  {
    events = { "TermOpen" },
    targets = { "*" },
    command = "startinsert",
  },
})

augroup("filetypes", {
  {
    events = { "BufEnter", "BufRead", "BufNewFile" },
    targets = { "*.lexs", "*.exs" },
    command = "set filetype=elixir",
  },
  {
    events = { "BufEnter", "BufRead", "BufNewFile" },
    targets = { "*.eex" },
    command = "set filetype=eelixir",
  },
  {
    events = { "BufEnter", "BufRead", "BufNewFile" },
    targets = { "Brewfile", "Brewfile.mas", "Brewfile.cask" },
    command = "set filetype=ruby",
  },
  {
    events = { "BufEnter", "BufRead", "BufNewFile" },
    targets = { "Deskfile" },
    command = "set filetype=sh",
  },
  {
    events = { "BufEnter", "BufRead", "BufNewFile" },
    targets = { ".eslintrc" },
    command = "set filetype=javascript",
  },
  {
    events = { "BufEnter", "BufRead", "BufNewFile" },
    targets = { "*.jst.eco" },
    command = "set filetype=jst",
  },
  {
    events = { "BufEnter", "BufRead", "BufNewFile" },
    targets = { "*.md" },
    command = "set filetype=markdown",
  },
})
