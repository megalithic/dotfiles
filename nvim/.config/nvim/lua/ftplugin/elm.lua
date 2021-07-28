return function(_) -- bufnr
  vim.api.nvim_exec(
    [[
autocmd FileType elm nnoremap <leader>ep o\|> <ESC>a
autocmd FileType elm iabbrev ep    \|>
]],
    true
  )
end
