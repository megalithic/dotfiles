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
au([[Syntax * syn match extTodo "\<\(NOTE\|HACK\|BAD\|TODO\):\?" containedin=.*Comment.* | hi! link extTodo Todo]])
au([[VimEnter * ++once lua require('mega.start').start()]])
au([[WinEnter * if &previewwindow | setlocal wrap | endif]])
au([[FileType fzf :tnoremap <buffer> <esc> <C-c>]])
au([[FileType help,startuptime,qf,lspinfo nnoremap,man <buffer><silent> q :quit<CR>]])
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

-- EXAMPLE of new nvim lua autocmd API:
-- vim.api.nvim_create_autocmd("FileType", {
--   pattern = { "yaml", "toml" },
--   callback = function()
--     map("n", "<C-a>", require("dial.map").inc_normal("dep_files"), { remap = true })
--   end,
-- })

augroup("AutoMkDir", {
  events = { "BufNewFile", "BufWritePre" },
  targets = { "*" },
  command = mega.auto_mkdir(),
})

augroup("Kitty", {
  {
    events = { "BufWritePost" },
    targets = { "kitty.conf" },
    command = function()
      -- auto-reload kitty upon kitty.conf write
      vim.cmd(":silent !kill -SIGUSR1 $(pgrep kitty)")
    end,
  },
})

augroup("Paq", {
  {
    events = { "BufWritePost" },
    targets = { "*/mega/plugins/*.lua" },
    command = function()
      -- auto-source paq-nvim upon plugins/*.lua buffer writes
      vim.cmd("luafile %")
    end,
  },
  {
    events = { "User PaqDoneSync" },
    command = function()
      vim.notify("Paq sync complete", nil, { title = "Paq" })
    end,
  },
  {
    events = { "User PaqDoneInstall" },
    command = function()
      vim.notify("Paq install complete", nil, { title = "Paq" })
    end,
  },
  {
    events = { "User PaqUpdateInstall" },
    command = function()
      vim.notify("Paq update complete", nil, { title = "Paq" })
    end,
  },
})

augroup("YankHighlightedRegion", {
  {
    events = { "TextYankPost" },
    targets = { "*" },
    command = "lua vim.highlight.on_yank({ higroup = 'Substitute', timeout = 150, on_macro = true })",
  },
})

augroup("Terminal", {
  {
    events = { "TermClose" },
    targets = { "*" },
    command = "noremap <buffer><silent><ESC> :bd!<CR>",
  },
  {
    events = { "TermClose" },
    targets = { "*" },
    command = function()
      --- automatically close a terminal if the job was successful
      if not vim.v.event.status == 0 then
        vim.cmd("bdelete! " .. fn.expand("<abuf>"))
      end
    end,
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

augroup("LazyLoads", {
  {
    -- nvim-bqf
    events = { "FileType" },
    targets = { "qf" },
    command = [[packadd nvim-bqf]],
  },
  {
    -- dash.nvim
    events = { "BufReadPre" },
    targets = { "*" },
    command = function()
      if mega.is_macos then
        print("should be loading dash.nvim")
        vim.cmd([[packadd dash.nvim]])
      end
    end,
  },
  {
    -- tmux-navigate
    -- vim-kitty-navigator
    events = { "FocusGained", "BufEnter", "VimEnter", "BufWinEnter" },
    targets = { "*" },
    command = function()
      if vim.env.TMUX ~= nil then
        vim.cmd([[packadd tmux-navigate]])
      else
        vim.cmd([[packadd vim-kitty-navigator]])
      end
    end,
  },
})
