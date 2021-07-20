-- [ autocmds.. ] --------------------------------------------------------------

-- REF:
-- https://github.com/mhartington/dotfiles/blob/master/config/nvim/lua/mh/autocmds/init.lua

local au, exec, augroup = mega.au, mega.exec, mega.augroup_cmds

mega.inspect("activating autocmds..")

au([[FocusGained,BufEnter,CursorHold,CursorHoldI,BufWinEnter * if mode() != 'c' | checktime | endif]])
au([[StdinReadPost * set buftype=nofile]])
au([[FileType help wincmd L]])
au([[CmdwinEnter * nnoremap <buffer> <CR> <CR>]])
au([[VimResized * lua require('golden_size').on_win_enter()]])
au([[VimResized * wincmd =]])
au([[InsertLeave,CompleteDone * if pumvisible() == 0 | pclose | endif]])
au([[Syntax * call matchadd('Todo', '\W\zs\(TODO\|FIXME\|CHANGED\|BUG\|HACK\)')]])
au([[Syntax * call matchadd('Debug', '\W\zs\(NOTE\|INFO\|IDEA\)')]])
au([[WinEnter * if &previewwindow | setlocal wrap | endif]])
--  Open multiple files in splits
exec([[
      if argc() > 1
        silent vertical all | lua require('golden_size').on_win_enter()
      endif
      ]])

--  Trim Whitespace
vim.api.nvim_exec([[
    fun! TrimWhitespace()
        let l:save = winsaveview()
        keeppatterns %s/\s\+$//e
        call winrestview(l:save)
    endfun
    autocmd BufWritePre * :call TrimWhitespace()
]], false)

augroup(
  "paq",
  {
    {
      events = {"BufWritePost"},
      targets = {"packages.lua"},
      command = [[luafile %]]
    }
  }
)

augroup(
  "focus",
  {
    {
      events = {"BufEnter", "WinEnter"},
      targets = {"*"},
      command = "silent setlocal relativenumber number colorcolumn=81"
    },
    {
      events = {"BufLeave", "WinLeave"},
      targets = {"*"},
      command = "silent setlocal norelativenumber nonumber colorcolumn=0"
    }
  }
)

augroup(
  "yank_highlighted_region",
  {
    {
      events = {"TextYankPost"},
      targets = {"*"},
      command = "lua vim.highlight.on_yank({ higroup = 'HighlightedYankRegion', timeout = 170, on_macro = true })"
    }
  }
)

augroup(
  "terminal",
  {
    {
      events = {"TermClose"},
      targets = {"*"},
      command = "noremap <buffer><silent><ESC> :bd!<CR>"
    },
    {
      events = {"TermOpen"},
      targets = {"*"},
      command = [[setlocal nonumber norelativenumber conceallevel=0]]
    },
    {
      events = {"TermOpen"},
      targets = {"*"},
      command = "startinsert"
    }
  }
)

augroup(
  "filetypes",
  {
    {
      events = {"BufEnter", "BufRead", "BufNewFile"},
      targets = {"*.lexs"},
      command = "set filetype=elixir"
    },
    {
      events = {"BufEnter", "BufNewFile", "FileType"},
      targets = {"*.md"},
      command = "lua require('ftplugin.markdown')()"
    }
  }
)
