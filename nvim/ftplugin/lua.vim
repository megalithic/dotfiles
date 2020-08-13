augroup ft_lua
  au!

  " REF: https://github.com/Koihik/LuaFormatter
  " - C17+ stuff: https://stackoverflow.com/a/63102701/213904
  autocmd FileType lua nnoremap <buffer> <Leader>lf :call LuaFormat()<CR>
  " autocmd BufWritePre *.lua call LuaFormat()
augroup END
