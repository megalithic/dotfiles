augroup general
  autocmd!

  " if more than 1 files are passed to vim as arg, open them in vertical splits
  if argc() > 1
    silent vertical all
  endif

  autocmd BufRead * nohls

  " Automatically equalize window splits.
  autocmd VimResized * wincmd =

  " Syntax highlight a minimum of 2,000 lines. This greatly helps scroll
  " performance.
  autocmd Syntax * syntax sync minlines=2000

  " Restore default Enter/Return behaviour for the command line window.
  autocmd CmdwinEnter * nnoremap <buffer> <CR> <CR>

  " Save all files on focus lost, ignoring warnings about untitled buffers
  " autocmd FocusLost * silent! wa

  " Trigger `autoread` when files changes on disk
  " https://unix.stackexchange.com/questions/149209/refresh-changed-content-of-file-opened-in-vim/383044#383044
  " https://vi.stackexchange.com/questions/13692/prevent-focusgained-autocmd-running-in-command-line-editing-mode
  set autoread
  autocmd FocusGained,BufEnter,CursorHold,CursorHoldI * if mode() != 'c' | checktime | endif
  " Notification after file change
  " https://vi.stackexchange.com/questions/13091/autocmd-event-for-autoread
  autocmd FileChangedShellPost *
    \ echohl WarningMsg | echo "File changed on disk. Buffer reloaded." | echohl None

  " Refresh lightline when certain things happen
  " au TextChanged,InsertLeave,BufWritePost * call lightline#update()
  " autocmd BufWritePost * call lightline#update()

  " Handle window resizing
  autocmd VimResized * execute "normal! \<c-w>="

  " Help in vertical split (https://stackoverflow.com/a/21843502/213904)
  autocmd FileType help wincmd L

  " No formatting on o key newlines
  autocmd BufNewFile,BufEnter * set formatoptions-=o

  " " Trim trailing whitespace (presently uses w0rp/ale for this)
  " function! <SID>TrimWhitespace()
  "   let l = line(".")
  "   let c = col(".")
  "   keeppatterns %s/\v\s+$//e
  "   call cursor(l, c)
  " endfunction
  " autocmd FileType * autocmd BufWritePre <buffer> :call <SID>TrimWhitespace()

  " Remember cursor position between vim sessions
  autocmd BufReadPost *
        \ if line("'\"") > 0 && line ("'\"") <= line("$") |
        \   exe "normal! g'\"" |
        \ endif

  " Hide status bar while using fzf commands
  if has('nvim')
    autocmd! FileType fzf
    autocmd  FileType fzf set laststatus=0 | autocmd BufLeave,WinLeave <buffer> set laststatus=2
  endif

  " Auto-close preview window when completion is done.
  autocmd! InsertLeave,CompleteDone * if pumvisible() == 0 | pclose | endif

  " When terminal buffer ends allow to close it
  if has('nvim')
    autocmd TermClose * noremap <buffer><silent><CR> :bd!<CR>
    autocmd TermClose * noremap <buffer><silent><ESC> :bd!<CR>
    autocmd! TermOpen * setlocal nonumber norelativenumber
    autocmd! TermOpen * if &buftype == 'terminal'
          \| set nonumber norelativenumber
          \| endif
  endif

  autocmd Syntax * call matchadd('Todo', '\W\zs\(TODO\|FIXME\|CHANGED\|BUG\|HACK\)')
  autocmd Syntax * call matchadd('Debug', '\W\zs\(NOTE\|INFO\|IDEA\)')

  " coc.nvim - highlight all occurences of word under cursor
  " disable for now: annoying while on tmate and other things
  " autocmd CursorHold * silent call CocActionAsync('highlight')

  " Name tmux window/tab based on current opened buffer
  " autocmd BufReadPost,FileReadPost,BufNewFile,BufEnter *
  " autocmd BufReadPre,FileReadPre,BufNewFile,BufEnter *
  "       \ let tw = system("tmux display-message -p '\\#W'")
  "       \| echo "current tmux window: " . tw
  "       \| call system("tmux rename-window 'nvim | " . expand("%:t") . "'")
  " autocmd VimLeave * call system("tmux rename-window '" . tw . "'")

  " ----------------------------------------------------------------------------
  " ## Toggle certain accoutrements when entering and leaving a buffer & window

  " toggle syntax / dim / inactive (comment out when tadaa/vimade supports TUI)
  " autocmd WinEnter,BufEnter * silent set number relativenumber " call RainbowParentheses
  " autocmd WinLeave,BufLeave * silent set nonumber norelativenumber " call RainbowParentheses!

  " toggle linenumbering and cursorline
  " autocmd BufEnter,FocusGained,InsertLeave * silent set relativenumber cursorline
  " autocmd BufLeave,FocusLost,InsertEnter   * silent set norelativenumber nocursorline

  autocmd BufEnter,VimEnter,WinEnter,BufWinEnter * silent setl number relativenumber
  autocmd BufLeave,WinLeave * silent setl nonumber norelativenumber

  " toggle colorcolumn when in insertmode only
  autocmd InsertEnter * silent set colorcolumn=80
  autocmd InsertLeave * if &filetype != "markdown"
                            \ | silent set colorcolumn=""
                            \ | endif

  " Open QuickFix horizontally with line wrap
  autocmd FileType qf wincmd J | setlocal wrap

  " Preview window with line wrap
  autocmd WinEnter * if &previewwindow | setlocal wrap | endif

  " Neovim terminal tweaks.
  if has("nvim")
    autocmd TermOpen *        setlocal conceallevel=0 colorcolumn=0
    autocmd TermOpen *        startinsert
    autocmd BufEnter term://* startinsert
  endif

  " reload vim configuration (aka vimrc)
  command! ReloadVimConfigs so $MYVIMRC
    \| echo 'configs reloaded!'
augroup END

augroup mirrors
  autocmd!
  " ## Automagically update remote files via scp
  autocmd BufWritePost ~/.dotfiles/private/homeassistant/* silent! :MirrorPush ha
  autocmd BufWritePost ~/.dotfiles/private/domains/nginx/* silent! :MirrorPush nginx
  autocmd BufWritePost ~/.dotfiles/private/domains/fathom/* silent! :MirrorPush fathom
augroup END

function s:fzf_buf_in() abort
  echo
  set laststatus=0
  set noruler
  set nonumber
  set norelativenumber
  set signcolumn=no
endfunction

function s:fzf_buf_out() abort
  set laststatus=2
  set ruler
endfunction

augroup fzf
  autocmd!
  autocmd FileType fzf call s:fzf_buf_in()
  autocmd BufEnter \v[0-9]+;#FZF$ call s:fzf_buf_in()
  autocmd BufLeave \v[0-9]+;#FZF$ call s:fzf_buf_out()
  autocmd TermClose \v[0-9]+;#FZF$ call s:fzf_buf_out()
augroup END

augroup gitcommit
  autocmd!

  " pivotalTracker.vim
  let g:pivotaltracker_name = "smesser"
  autocmd FileType gitcommit setlocal completefunc=pivotaltracker#stories
  autocmd FileType gitcommit setlocal omnifunc=pivotaltracker#stories

  function! BufReadIndex()
    " Use j/k in status
    setl nohlsearch
    nnoremap <buffer> <silent> j :call search('^#\t.*','W')<Bar>.<CR>
    nnoremap <buffer> <silent> k :call search('^#\t.*','Wbe')<Bar>.<CR>
  endfunction

  function! BufEnterCommit()
    " Start in insert mode for commit
    normal gg0
    if getline('.') ==? ''
      start
    end

    " disable coc.nvim for gitcommit
    " autocmd BufNew,BufEnter *.json,*.vim,*.lua execute "silent! CocEnable"
    " autocmd InsertEnter * execute "silent! CocDisable"

    " Allow automatic formatting of bulleted lists and blockquotes
    " https://github.com/lencioni/dotfiles/blob/master/.vim/after/ftplugin/gitcommit.vim
    setlocal comments+=fb:*
    setlocal comments+=fb:-
    setlocal comments+=fb:+
    setlocal comments+=b:>

    setlocal formatoptions+=c " Auto-wrap comments using textwidth
    setlocal formatoptions+=q " Allow formatting of comments with `gq`

    setlocal textwidth=72
    " setl spell
    " setl spelllang=en
    " setl nolist
    " setl nonumber
  endfunction

  autocmd BufNewFile,BufRead .git/index setlocal nolist
  autocmd BufReadPost fugitive://* set bufhidden=delete
  autocmd BufReadCmd *.git/index exe BufReadIndex()
  autocmd BufEnter *.git/index silent normal gg0j
  autocmd BufEnter *COMMIT_EDITMSG,*PULLREQ_EDITMSG exe BufEnterCommit()
  autocmd FileType gitcommit,gitrebase exe BufEnterCommit()
augroup END

" augroup ft_elixir
"   autocmd!
"   autocmd FileType elixir,eelixir nnoremap <silent> <buffer> <leader>ed orequire IEx; IEx.pry<ESC>:w<CR>
"   autocmd FileType elixir,eelixir nnoremap <silent> <buffer> <leader>ep o\|> <ESC>a
"   autocmd FileType elixir,eelixir nnoremap <silent> <buffer> <leader>ei o\|> IO.inspect()<ESC>i
"   autocmd FileType elixir,eelixir nnoremap <silent> <buffer> <leader>eil o\|> IO.inspect(label: "")<ESC>hi
"   autocmd FileType elixir,eelixir inoremap <silent> <buffer> <leader>ep o\|> <ESC>a
"   autocmd FileType elixir,eelixir inoremap <silent> <buffer> <leader>ei o\|> IO.inspect()<ESC>i
"   autocmd FileType elixir,eelixir inoremap <silent> <buffer> <leader>eil o\|> IO.inspect(label: "")<ESC>hi

"   if has('nvim')
"     function! s:iex_for_project() abort
"       let l:root = finddir('.git/..', expand('%:p:h').';')

"       if !empty(glob(l:root .. "/mix.exs"))
"         echohl Comment | echom printf('iex -S mix (%s)', l:root) | echohl None
"         :Repl iex -S mix
"       else
"         echohl Comment | echom printf('iex (%s)', l:root) | echohl None
"         :Repl iex
"       endif
"     endfunction

"     autocmd FileType elixir,eelixir nnoremap <silent> <buffer> <leader>er :call <SID>iex_for_project()<CR>
"   endif

"   autocmd FileType elixir,eelixir iabbrev epry  require IEx; IEx.pry
"   autocmd FileType elixir,eelixir iabbrev ep    \|>
"   autocmd FileType elixir,eelixir iabbrev ei    IO.inspect
"   autocmd FileType elixir,eelixir iabbrev eputs IO.puts
" augroup END

augroup ft_elm
  autocmd!
  autocmd FileType elm nnoremap <leader>ep o\|> <ESC>a

  if has('nvim')
    function! s:elm_repl_for_project() abort
      let l:root = finddir('.git/..', expand('%:p:h').';')

      if !empty(glob(l:root .. "/elm.json"))
        echohl Comment | echom printf('elm repl (%s)', l:root) | echohl None
        :Repl elm repl
      else
        echohl Comment | echom printf('elm_repl (%s)', l:root) | echohl None
        :Repl elm_repl
      endif
    endfunction

    autocmd FileType elm nnoremap <silent> <buffer> <leader>er :call <SID>elm_repl_for_project()<CR>
  endif

  autocmd FileType elm iabbrev ep    \|>
augroup END

augroup ft_clang
  autocmd FileType c setlocal tabstop=2 softtabstop=2 shiftwidth=2 expandtab
  autocmd FileType cpp setlocal tabstop=2 softtabstop=2 shiftwidth=2 expandtab
  autocmd FileType cs setlocal tabstop=2 softtabstop=2 shiftwidth=2 expandtab
  autocmd FileType c setlocal commentstring=/*\ %s\ */
  autocmd FileType c,cpp,cs setlocal commentstring=//\ %s
augroup END
