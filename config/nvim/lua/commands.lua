local command = mega.command

vim.cmd([[
command! -nargs=1 Rg lua require("telescope.builtin").grep_string({ search = vim.api.nvim_eval('"<args>"') })
]])

command({ "Todo", [[noautocmd silent! grep! 'TODO\|FIXME\|BUG\|HACK' | copen]] })
-- command({ "TTodo", [[noautocmd silent! Rg "TODO\|FIXME\|BUG\|HACK"]] })
-- command({
--   "TTodo",
--   [[noautocmd lua require("telescope.builtin").grep_string({ use_regex = true, search = TODO\|FIXME\|BUG\|HACK })]],
-- })

-- REFs:
-- https://www.reddit.com/r/vim/comments/rrfc9i/moving_files_in_native_vim/hqg4hto/
-- https://salferrarello.com/vim-netrw-duplicate-file/#comment-15117
command({
  "Duplicate",
  [[noautocmd clear | silent! execute "!cp '%:p' '%:p:h/%:t:r-copy.%:e'"<bar>redraw<bar>echo "Copied " . expand('%:t') . ' to ' . expand('%:t:r') . '-copy.' . expand('%:e')]],
})

command({
  "Copy",
  [[noautocmd clear | :execute "saveas %:p:h/" .input('save as -> ') | :e]],
})

vim.cmd([[
function! Syn()
  for id in synstack(line("."), col("."))
    echo synIDattr(id, "name")
  endfor
endfunction
command! -nargs=0 Syn call Syn()
]])
