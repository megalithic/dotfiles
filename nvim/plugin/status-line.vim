function! InactiveLine()
  return luaeval("require'status-line'.inActiveLine()")
endfunction

function! ActiveLine()
  return luaeval("require'status-line'.activeLine()")
endfunction

" Change statusline automatically
augroup Statusline
  autocmd!
  autocmd WinEnter,BufEnter * setlocal statusline=%!ActiveLine()
  autocmd WinLeave,BufLeave * setlocal statusline=%!InactiveLine()
augroup END


function! TabLine()
  return luaeval("require'status-line'.TabLine()")
endfunction

set tabline=%!TabLine()
