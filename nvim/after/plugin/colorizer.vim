" lua require'colorizer'.setup({ 'css'; 'sass'; 'scss'; 'less'; 'vim'; 'html'; 'eelixir'; 'javascript'; 'javascriptreact'; 'typescript'; 'typescriptreact'; 'tmux'; })

" augroup colorizer_load_autocmds
"   au!
"   au InsertEnter * ++once lua require('colorizer').setup { 'css'; 'sass'; 'scss'; 'less'; 'vim'; 'html'; 'eelixir'; 'javascript'; 'javascriptreact'; 'typescript'; 'typescriptreact'; 'tmux'; }
" augroup END
