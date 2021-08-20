local bufmap = mega.bufmap

return function(_) -- bufnr
	vim.cmd([[setlocal iskeyword+=!,?]])
end
