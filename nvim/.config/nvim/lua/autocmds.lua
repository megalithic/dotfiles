-- [ autocmds.. ] --------------------------------------------------------------

local cmd, fn = vim.cmd, vim.fn
local au, exec, augroup = mega.au, mega.exec, mega.augroup

au([[BufWritePre * lua mega.auto_mkdir()]])
au([[FocusGained,BufEnter,CursorHold,CursorHoldI,BufWinEnter * if mode() != 'c' | checktime | endif]])
au([[StdinReadPost * set buftype=nofile]])
au([[FileType help wincmd L]])
au([[CmdwinEnter * nnoremap <buffer> <CR> <CR>]])
au([[VimResized * lua require('golden_size').on_win_enter()]])
au([[InsertLeave,CompleteDone * if pumvisible() == 0 | pclose | endif]])
au([[Syntax * call matchadd('Todo', '\W\zs\(TODO\|FIXME\|CHANGED\|BUG\|HACK\)')]])
au([[Syntax * call matchadd('Debug', '\W\zs\(NOTE\|INFO\|IDEA\|REF\)')]])
au([[WinEnter * if &previewwindow | setlocal wrap | endif]])
au([[FileType fzf :tnoremap <buffer> <esc> <C-c>]])
au([[FileType help,startuptime,qf,lspinfo nnoremap <buffer><silent> q :close<CR>]])
au(
	[[FileType help,startuptime,qf,lspinfo,fzf,prompt,rename setlocal nonumber norelativenumber nocursorline nocursorcolumn nospell]]
)
au([[FileType man nnoremap <buffer><silent> q :quit<CR>]])
au([[BufWritePre * %s/\n\+\%$//e]])
-- au([[TextYankPost * if v:event.operator is 'y' && v:event.regname is '+' | OSCYankReg + | endif]]) -- https://github.com/ojroques/vim-oscyank#configuration
-- vim.cmd([[if !exists("b:undo_ftplugin") | let b:undo_ftplugin .= '' | endif]])

--  Open multiple files in splits
exec([[ if argc() > 1 | silent vertical all | endif ]])

--  Open :intro only if no file args passed in
-- cmd([[ if argc() == 0 && !exists("s:std_in") | :intro | endif ]])

--  Trim Whitespace
exec(
	[[
    fun! TrimWhitespace()
        let l:save = winsaveview()
        keeppatterns %s/\s\+$//e
        call winrestview(l:save)
    endfun
    autocmd BufWritePre * :call TrimWhitespace()
]],
	false
)

augroup("auto-cursor", {
	-- When editing a file, always jump to the last known cursor position.
	-- Don't do it for commit messages, when the position is invalid, or when
	-- inside an event handler (happens when dropping a file on gvim).
	events = { "BufReadPost" },
	targets = { "*" },
	command = function()
		local pos = fn.line([['"]])
		if vim.bo.ft ~= "gitcommit" and pos > 0 and pos <= fn.line("$") then
			vim.cmd('keepjumps normal g`"')
		end
	end,
})

-- augroup("NvimTreeOverrides", {
-- 	{
-- 		events = { "ColorScheme" },
-- 		targets = { "*" },
-- 		command = set_highlights,
-- 	},
-- 	{
-- 		events = { "FileType" },
-- 		targets = { "NvimTree" },
-- 		command = set_highlights,
-- 	},
-- })

augroup("paq", {
	{
		events = { "BufWritePost" },
		targets = { "packages.lua" },
		command = [[luafile %]],
	},
})

augroup("focus", {
	{
		events = { "BufEnter", "FileType", "FocusGained", "InsertLeave" },
		targets = { "*" },
		command = "silent setlocal relativenumber number",
	},
	{
		events = { "FocusLost", "BufLeave", "InsertEnter" },
		targets = { "*" },
		command = "silent setlocal norelativenumber number",
	},
	{
		events = { "TermOpen" },
		targets = { "*" },
		command = "silent setlocal norelativenumber nospell nonumber nocursorcolumn nocursorline",
	},
})

augroup("yank_highlighted_region", {
	{
		events = { "TextYankPost" },
		targets = { "*" },
		command = "lua vim.highlight.on_yank({ higroup = 'Substitute', timeout = 150, on_macro = true })",
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
		targets = { "*.lexs", "*.heex", "*.exs" },
		command = "set filetype=elixir",
	},
	{
		events = { "BufEnter", "BufRead", "BufNewFile" },
		targets = { "Brewfile", "Brewfile.mas", "Brewfile.cask" },
		command = "set filetype=ruby",
	},
	{
		events = { "BufEnter", "BufRead", "BufNewFile" },
		targets = { "Deskfile" },
		command = "set filetype=sh",
	},
	{
		events = { "BufEnter", "BufRead", "BufNewFile" },
		targets = { ".eslintrc" },
		command = "set filetype=javascript",
	},
	{
		events = { "BufEnter", "BufRead", "BufNewFile" },
		targets = { "*.jst.eco" },
		command = "set filetype=jst",
	},
	{
		events = { "BufEnter", "BufRead", "BufNewFile" },
		targets = { "*.md" },
		command = "set filetype=markdown",
	},
})
