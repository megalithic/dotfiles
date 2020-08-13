augroup general
  autocmd!

  autocmd BufWritePost init.vim nested source $MYVIMRC

  " if more than 1 files are passed to vim as arg, open them in vertical splits
  if argc() > 1
    silent vertical all
    " silent :ArgForVerticalEdit
  endif

  autocmd StdinReadPost * set buftype=nofile

  autocmd BufRead * nohls

  " Syntax highlight a minimum of 2,000 lines. This greatly helps scroll
  " performance.
  autocmd Syntax * syntax sync minlines=1000

  " Restore default Enter/Return behaviour for the command line window.
  autocmd CmdwinEnter * nnoremap <buffer> <CR> <CR>

  " Save all files on focus lost, ignoring warnings about untitled buffers
  " autocmd FocusLost * silent! wa

  " Trigger `autoread` when files changes on disk
  " https://unix.stackexchange.com/questions/149209/refresh-changed-content-of-file-opened-in-vim/383044#383044
  " https://vi.stackexchange.com/questions/13692/prevent-focusgained-autocmd-running-in-command-line-editing-mode
  autocmd FocusGained,BufEnter,CursorHold,CursorHoldI,BufWinEnter * if mode() != 'c' | checktime | endif
  " Notification after file change
  " https://vi.stackexchange.com/questions/13091/autocmd-event-for-autoread
  autocmd FileChangedShellPost *
    \ echohl WarningMsg | echo "File changed on disk. Buffer reloaded." | echohl None

  " Handle window resizing
  " TODO: do we still want this, what with dm1try/golden_size being used?
  " autocmd VimResized * execute "normal! \<c-w>="

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
  " - FIXME: doesn't really work with neovim, it seems
  " autocmd BufReadPost * if expand('%:p') !~# '\m/\.git/' && line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif
  " Return to last edit position (You want this!) *N*
  " autocmd BufReadPost *
  "       \ if line("'\"") > 0 && line("'\"") <= line("$") |
  "       \   exe "normal! g`\"" |
  "       \ endif
  autocmd BufReadPost *
    \ if &filetype !~ 'commit\c' && line("'\"") > 0 && line("'\"") <= line("$") |
    \   exe "normal g'\"" |
    \ endif

  " Hide status bar while using fzf commands
  if has('nvim')
    " When terminal buffer ends allow to close it
    autocmd TermClose * noremap <buffer><silent><CR> :bd!<CR>
    autocmd TermClose * noremap <buffer><silent><ESC> :bd!<CR>
    autocmd! TermOpen * setlocal nonumber norelativenumber
    autocmd! TermOpen * if &buftype == 'terminal'
          \| set nonumber norelativenumber
          \| endif

    autocmd TermOpen *        setlocal conceallevel=0 colorcolumn=0
    autocmd TermOpen *        startinsert
    autocmd BufEnter term://* startinsert

    " autocmd TermClose * ++once :bd!
  endif

  " Auto-close preview window when completion is done.
  autocmd! InsertLeave,CompleteDone * if pumvisible() == 0 | pclose | endif

  autocmd Syntax * call matchadd('Todo', '\W\zs\(TODO\|FIXME\|CHANGED\|BUG\|HACK\)')
  autocmd Syntax * call matchadd('Debug', '\W\zs\(NOTE\|INFO\|IDEA\)')

  " ----------------------------------------------------------------------------
  " ## Toggle certain accoutrements when entering and leaving a buffer & window

  " toggle syntax / dim / inactive (comment out when tadaa/vimade supports TUI)
  " autocmd WinEnter,BufEnter * silent set number relativenumber " call RainbowParentheses
  " autocmd WinLeave,BufLeave * silent set nonumber norelativenumber " call RainbowParentheses!

  " toggle linenumbering and cursorline
  autocmd BufEnter,VimEnter,WinEnter,BufWinEnter * silent setlocal number relativenumber " signcolumn=yes:1
  autocmd BufLeave,WinLeave * silent setlocal nonumber norelativenumber " signcolumn=no

  " toggle colorcolumn when in insertmode only
  autocmd InsertEnter * silent set colorcolumn=80
  autocmd InsertLeave * if &filetype != "markdown"
                            \ | silent set colorcolumn=""
                            \ | endif

  autocmd FileType markdown nested setlocal spell complete+=kspell

  " Open QuickFix horizontally with line wrap
  autocmd FileType qf wincmd J | setlocal wrap

  " Preview window with line wrap
  autocmd WinEnter * if &previewwindow | setlocal wrap | endif

  " reload vim configuration (aka vimrc)
  command! ReloadVimConfigs so $MYVIMRC
    \| echo 'configs reloaded!'
augroup END

" augroup lua_autocmds
"   au!
"   lua vim.api.nvim_command [[au CursorHold * lua require'git'.blameVirtText()]]
" augroup END

" augroup modechange_settings
"   autocmd!
"   " Clear search context when entering insert mode, which implicitly stops the
"   " highlighting of whatever was searched for with hlsearch on. It should also
"   " not be persisted between sessions.
"   autocmd InsertEnter * let @/ = ''
"   autocmd BufReadPre,FileReadPre * let @/ = ''
"   autocmd InsertLeave * setlocal nopaste
" augroup END

augroup highlight_yank
  autocmd!
  autocmd TextYankPost * silent! lua require'vim.highlight'.on_yank({timeout=100, higroup="Search"})
augroup END

augroup mirrors
  autocmd!
  " ## Automagically update remote files via scp
  autocmd BufWritePost ~/.dotfiles/private/homeassistant/* silent! :MirrorPush hass
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
  endfunction

  autocmd BufNewFile,BufRead .git/index setlocal nolist
  autocmd BufReadPost fugitive://* set bufhidden=delete
  autocmd BufReadCmd *.git/index exe BufReadIndex()
  autocmd BufEnter *.git/index silent normal gg0j
  autocmd BufEnter *COMMIT_EDITMSG,*PULLREQ_EDITMSG exe BufEnterCommit()
  autocmd FileType gitcommit,gitrebase exe BufEnterCommit()

  au BufReadPost,BufNewFile *.md,*.txt,COMMIT_EDITMSG set wrap linebreak nolist spell spelllang=en_us complete+=kspell
  au BufReadPost,BufNewFile .html,*.txt,*.md,*.adoc set spell spelllang=en_us
augroup END

augroup ft_clang
  autocmd!

  autocmd FileType c setlocal tabstop=2 softtabstop=2 shiftwidth=2 expandtab
  autocmd FileType cpp setlocal tabstop=2 softtabstop=2 shiftwidth=2 expandtab
  autocmd FileType cs setlocal tabstop=2 softtabstop=2 shiftwidth=2 expandtab
  autocmd FileType c setlocal commentstring=/*\ %s\ */
  autocmd FileType c,cpp,cs setlocal commentstring=//\ %s
augroup END

augroup writing
  autocmd!

  au BufReadPost,BufNewFile *.md,*.txt set wrap linebreak nolist spell spelllang=en_us complete+=kspell
  au BufReadPost,BufNewFile .html,*.txt,*.md,*.adoc set spell spelllang=en_us
augroup END
