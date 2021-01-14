-- [ autocmds.. ] --------------------------------------------------------------

local au=mega.au

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
        au([[autocmd BufEnter,FocusGained,WinEnter * silent setlocal relativenumber number colorcolumn=81 ]])
        au([[autocmd BufLeave,FocusLost,WinLeave * silent setlocal norelativenumber number colorcolumn=0]])
      end
    )

    mega.augroup(
      "mega.yank_highlighted_region",
      function()
        -- vim.api.nvim_exec([[autocmd! * <buffer>]], true)
        au([[autocmd!]])

        au(
          "autocmd TextYankPost * lua vim.highlight.on_yank({ higroup = 'HighlightedYankRegion', timeout = 170, on_macro = true })"
        )
      end
    )

    vim.api.nvim_exec(
      [[
augroup gitcommit
  autocmd!
  function! BufReadIndex()
    " Use j/k in status
    setlocal nohlsearch
    nnoremap <buffer> <silent> j :call search('^#\t.*','W')<Bar>.<CR>
    nnoremap <buffer> <silent> k :call search('^#\t.*','Wbe')<Bar>.<CR>
  endfunction

  function! BufEnterCommit()
    " Start in insert mode for commit
    normal gg0
    if getline('.') ==? ''
      start
    end

    " Allow automatic formatting of bulleted lists and blockquotes
    " https://github.com/lencioni/dotfiles/blob/master/.vim/after/ftplugin/gitcommit.vim
    setlocal comments+=fb:*
    setlocal comments+=fb:-
    setlocal comments+=fb:+
    setlocal comments+=b:>

    setlocal formatoptions+=c " Auto-wrap comments using textwidth
    setlocal formatoptions+=q " Allow formatting of comments with `gq`

    setlocal textwidth=72
    setlocal spell
    setlocal spelllang=en_us
    setlocal complete+=kspell
    setlocal nolist
    setlocal nonumber
    setlocal wrap
    setlocal linebreak
    setlocal colorcolumn=72
    echo "gitcommit entered"
  endfunction

  autocmd BufNewFile,BufRead .git/index setlocal nolist
  autocmd BufReadPost fugitive://* set bufhidden=delete
  autocmd BufReadCmd *.git/index exe BufReadIndex()
  autocmd BufEnter *.git/index silent normal gg0j
  autocmd BufEnter *COMMIT_EDITMSG,*PULLREQ_EDITMSG exe BufEnterCommit()
  autocmd FileType gitcommit,gitrebase exe BufEnterCommit()

  au BufReadPost,BufNewFile *.md,*.txt,COMMIT_EDITMSG set wrap linebreak nolist spell spelllang=en_us complete+=kspell
  au BufReadPost,BufNewFile .html,*.txt,*.md,*.adoc set spell spelllang=en_us complete+=kspell

augroup END
        ]],
      true
    )
  end
}
