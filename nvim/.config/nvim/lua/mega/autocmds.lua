-- [ autocmds.. ] --------------------------------------------------------------

-- REF:
-- https://github.com/mhartington/dotfiles/blob/master/config/nvim/lua/mh/autocmds/init.lua

local au = mega.au

mega.inspect("activating autocmds..")

vim.cmd('autocmd bufenter *.png,*.jpg,*.jpeg,*.gif exec "!imv \'".expand("%")."\' &" | :bd')
vim.cmd('autocmd bufenter *.pdf exec "!zathura \'".expand("%")."\' &" | :bw')

mega.augroup(
  "mega.general",
  function()
    au([[autocmd!]])
    au([[autocmd FocusGained,BufEnter,CursorHold,CursorHoldI,BufWinEnter * if mode() != 'c' | checktime | endif]])
    au([[
          if argc() > 1
            silent vertical all
          endif
          ]])
    au([[autocmd StdinReadPost * set buftype=nofile]])
    au([[autocmd FileType help wincmd L]])
    au([[autocmd CmdwinEnter * nnoremap <buffer> <CR> <CR>]])
    au([[autocmd VimResized * lua require('golden_size').on_win_enter()]])
    au([[autocmd InsertLeave,CompleteDone * if pumvisible() == 0 | pclose | endif]])
    au([[autocmd Syntax * call matchadd('Todo', '\W\zs\(TODO\|FIXME\|CHANGED\|BUG\|HACK\)')]])
    au([[autocmd Syntax * call matchadd('Debug', '\W\zs\(NOTE\|INFO\|IDEA\)')]])
    au([[autocmd WinEnter * if &previewwindow | setlocal wrap | endif]])
  end
)

mega.augroup_cmds(
  "mega.focus",
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

mega.augroup_cmds(
  "mega.yank_highlighted_region",
  {
    {
      events = {"TextYankPost"},
      targets = {"*"},
      command = "lua vim.highlight.on_yank({ higroup = 'HighlightedYankRegion', timeout = 170, on_macro = true })"
    }
  }
)

mega.augroup_cmds(
  "mega.terminal",
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

-- automatically clear commandline messages after a few seconds delay
-- source: https://unix.stackexchange.com/a/613645
_G.clear_messages = function()
  local id
  return function()
    if id then
      vim.fn.timer_stop(id)
    end
    id =
      vim.fn.timer_start(
      2000,
      function()
        if vim.fn.mode() == "n" then
          vim.cmd [[echon '']]
        end
      end
    )
  end
end

mega.augroup_cmds(
  "ClearCommandMessages",
  {
    {
      events = {"CmdlineLeave", "CmdlineChanged"},
      targets = {":"},
      command = "lua clear_messages()"
    }
  }
)

-- vim.api.nvim_exec(
--   [[
-- augroup fzf
--   autocmd!
--   function s:fzf_buf_in() abort
--     echo
--     set laststatus=0
--     set noruler
--     set nonumber
--     set norelativenumber
--     set signcolumn=no
--   endfunction

--   function s:fzf_buf_out() abort
--     set laststatus=2
--     set ruler
--   endfunction
--   autocmd FileType fzf call s:fzf_buf_in()
--   autocmd BufEnter \v[0-9]+;#FZF$ call s:fzf_buf_in()
--   autocmd BufLeave \v[0-9]+;#FZF$ call s:fzf_buf_out()
--   autocmd TermClose \v[0-9]+;#FZF$ call s:fzf_buf_out()
-- augroup END
-- ]],
--   false
-- )

-- _G.gitcommit_exec = function()
--   vim.cmd([[normal gg0]])

--   vim.bo.textwidth = 72
--   vim.wo.colorcolumn = "72"
--   vim.wo.spell = true
--   vim.bo.spelllang = "en_us"
--   vim.wo.list = false
--   vim.wo.number = false
--   vim.wo.relativenumber = false
--   vim.wo.wrap = true
--   vim.wo.linebreak = true

--   vim.cmd([[setlocal comments+=fb:*]])
--   vim.cmd([[setlocal comments+=fb:-]])
--   vim.cmd([[setlocal comments+=fb:+]])
--   vim.cmd([[setlocal comments+=b:>]])

--   vim.cmd([[setlocal formatoptions+=c]])
--   vim.cmd([[setlocal formatoptions+=q]])
-- end

-- mega.augroup(
--   "mega.git",
--   function()
--     au([[autocmd!]])
--     au([[autocmd! BufEnter,WinEnter,FocusGained *COMMIT_EDITMSG,*PULLREQ_EDITMSG exe v:lua.gitcommit_exec()]])
--     au([[autocmd! FileType gitcommit,gitrebase exe v:lua.gitcommit_exec()]])
--   end
-- )
