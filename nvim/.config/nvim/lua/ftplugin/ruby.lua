local bufmap = mega.bufmap

return function(_) -- bufnr
	vim.cmd([[setlocal iskeyword+=!,?]])
	-- bufmap("<C-e>", "end<C-o>O", "i")
end
