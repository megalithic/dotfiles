vim.cmd([[
  augroup MixFormat
    autocmd! * <buffer>
    mkview!
    autocmd BufWritePost <buffer> silent !mix format %
    loadview
  augroup END
]])
