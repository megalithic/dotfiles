vim.cmd([[if !exists("b:undo_ftplugin") | let b:undo_ftplugin .= '' | endif]])

vim.api.nvim_exec(
  [[
  function! Transform(cmd) abort
    let sub = ""
    let sub = substitute(a:cmd, './bin/rspec', 'rspec', '')
    echom "running test -> " . sub
    return sub
  endfunction
  let g:test#custom_transformations = {'transform': function('Transform')}
  let g:test#transformation = 'transform'
  ]],
  true
)
