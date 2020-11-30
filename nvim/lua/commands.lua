-- [ commands.. ] -------------------------------------------------------------

local cmd = vim.cmd

cmd [[command! CopyFullName let @+=expand('%')]]
cmd [[command! CopyPath let @+=expand('%:h')]]
cmd [[command! CopyFileName let @+=expand('%:t')]]
-- " map ;gg           G$g<C-G>''
-- " command! Stats :!wc -m %<CR>
-- " https://superuser.com/questions/149854/how-can-i-get-gvim-to-display-the-character-count-of-the-current-file#:~:text=Press%20g%20CTRL%2DG%20in,the%20cursor%20and%20the%20file.&text=which%20gives%20you%20the%20number,and%20yank%20the%20current%20buffer).
