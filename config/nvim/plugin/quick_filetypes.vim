" Quicker filetype setting:
"   :F html
" instead of
"   :setf html
" Can tab-complete filetype.
command! -nargs=1 -complete=filetype F set filetype=<args>

" Even quicker setting often-used filetypes.
command! FC set filetype=coffee
command! FR set filetype=ruby
command! FV set filetype=vim
command! FM set filetype=markdown
command! FE set filetype=elixir
command! FEE set filetype=eelixir
command! FEH set filetype=heex
command! FEL set filetype=elm
