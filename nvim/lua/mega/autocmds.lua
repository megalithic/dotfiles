-- [ autocmds.. ] --------------------------------------------------------------

local function au(cmd)
  vim.api.nvim_exec(cmd, true)
end

return {
  activate = function()
    mega.inspect("Activating autocmds..")

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
        au([[autocmd BufRead * nohls]])
        au([[autocmd InsertLeave,CompleteDone * if pumvisible() == 0 | pclose | endif]])
        au([[autocmd Syntax * call matchadd('Todo', '\W\zs\(TODO\|FIXME\|CHANGED\|BUG\|HACK\)')]])
        au([[autocmd Syntax * call matchadd('Debug', '\W\zs\(NOTE\|INFO\|IDEA\)')]])
      end
    )

    mega.augroup(
      "mega.focus",
      function()
        au([[autocmd BufEnter,FocusGained,WinEnter * silent setlocal number relativenumber colorcolumn=81,120]])
        au([[autocmd BufLeave,FocusLost,WinLeave * silent setlocal  norelativenumber colorcolumn=0]])
      end
    )

    mega.augroup(
      "mega.yank_highlighted_region",
      function()
        -- vim.api.nvim_exec([[autocmd! * <buffer>]], true)
        au([[autocmd!]])

        au(
          "autocmd TextYankPost * lua vim.highlight.on_yank({ higroup = 'HighlightedYankRegion', timeout = 130, on_macro = true })"
        )
      end
    )
  end
}
