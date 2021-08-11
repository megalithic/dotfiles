-- [ autocmds.. ] --------------------------------------------------------------

local au, exec, augroup = mega.au, mega.exec, mega.augroup_cmds

au([[FocusGained,BufEnter,CursorHold,CursorHoldI,BufWinEnter * if mode() != 'c' | checktime | endif]])
au([[StdinReadPost * set buftype=nofile]])
au([[FileType help wincmd L]])
au([[CmdwinEnter * nnoremap <buffer> <CR> <CR>]])
au([[VimResized * lua require('golden_size').on_win_enter()]])
au([[VimResized * wincmd =]])
au([[InsertLeave,CompleteDone * if pumvisible() == 0 | pclose | endif]])
au([[Syntax * call matchadd('Todo', '\W\zs\(TODO\|FIXME\|CHANGED\|BUG\|HACK\)')]])
au([[Syntax * call matchadd('Debug', '\W\zs\(NOTE\|INFO\|IDEA\|REF\)')]])
au([[WinEnter * if &previewwindow | setlocal wrap | endif]])
au("BufRead,BufNewFile *.md set filetype=markdown")
au([[FileType fzf :tnoremap <buffer> <esc> <C-c>]])
au([[FileType help,startuptime,qf,lspinfo nnoremap <buffer><silent> q :close<CR>]])
au([[FileType man nnoremap <buffer><silent> q :quit<CR>]])
au([[BufWritePre * %s/\n\+\%$//e]])
au([[TextYankPost * if v:event.operator is 'y' && v:event.regname is '+' | OSCYankReg + | endif]]) -- https://github.com/ojroques/vim-oscyank#configuration

--  Open multiple files in splits
exec([[
      if argc() > 1
        silent vertical all | lua require('golden_size').on_win_enter()
      endif
      ]])

augroup("paq", {
	{
		events = { "BufWritePost" },
		targets = { "packages.lua" },
		command = [[luafile %]],
	},
})

augroup("focus", {
	{
		events = { "BufEnter", "WinEnter" },
		targets = { "*" },
		command = "silent setlocal relativenumber number colorcolumn=81",
	},
	{
		events = { "BufLeave", "WinLeave" },
		targets = { "*" },
		command = "silent setlocal norelativenumber nonumber colorcolumn=0",
	},
})

augroup("yank_highlighted_region", {
	{
		events = { "TextYankPost" },
		targets = { "*" },
		command = "lua vim.highlight.on_yank({ higroup = 'Substitute', timeout = 170, on_macro = true })",
	},
})

augroup("terminal", {
	{
		events = { "TermClose" },
		targets = { "*" },
		command = "noremap <buffer><silent><ESC> :bd!<CR>",
	},
	{
		events = { "TermOpen" },
		targets = { "*" },
		command = [[setlocal nonumber norelativenumber conceallevel=0]],
	},
	{
		events = { "TermOpen" },
		targets = { "*" },
		command = "startinsert",
	},
})

augroup("filetypes", {
	{
		events = { "BufEnter", "BufRead", "BufNewFile" },
		targets = { "*.lexs" },
		command = "set filetype=elixir",
	},
	{
		events = { "BufEnter", "BufRead", "BufNewFile" },
		targets = { "Brewfile" },
		command = "set filetype=ruby",
	},
	-- {
	--   events = {"BufEnter", "BufNewFile", "FileType"},
	--   targets = {"*.md"},
	--   command = "lua require('ftplugin.markdown')()"
	-- }
})
