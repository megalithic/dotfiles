local set, vcmd, fn = vim.o, vim.cmd, vim.fn
local map = mega.map

-- vim.g.dirvish_mode = ":sort ,^.*[\\/],"

set.ruler = false
set.number = false
set.relativenumber = false
set.signcolumn = "no"
set.cursorline = false

-- function Dirvish_open(cmd, bg)
-- 	mega.inspect("Dirvish_open", { cmd, bg })

-- 	local path = fn.getline(".")
-- 	if fn.isdirectory(path) == 1 then
-- 		if cmd == "edit" and not bg then
-- 			print("no bg, in edit cmd")
-- 			fn["dirvish#open"](cmd, 0)
-- 		end
-- 	else
-- 		if bg then
-- 			print("with bg and cmd: ", cmd)
-- 			fn["dirvish#open"](cmd, 1)
-- 		else
-- 			vcmd("bwipeout")
-- 			vcmd(cmd .. " " .. path)
-- 		end
-- 	end
-- end

-- map("n", "<CR>", ":<C-U>lua Dirvish_open('edit', false)<CR>", { buffer = 0 })
-- map("n", "v", ":<C-U>lua Dirvish_open('vsplit', false)<CR>", { buffer = 0 })
-- map("n", "V", ":<C-U>lua Dirvish_open('vsplit', true)<CR>", { buffer = 0 })
-- map("n", "s", ":<C-U>lua Dirvish_open('split', false)<CR>", { buffer = 0 })
-- map("n", "S", ":<C-U>lua Dirvish_open('split', true)<CR>", { buffer = 0 })
-- map("n", "t", ":<C-U>lua Dirvish_open('tabedit', false)<CR>", { buffer = 0 })
-- map("n", "T", ":<C-U>lua Dirvish_open('tabedit', true)<CR>", { buffer = 0 })

-- map("n", "-", "<Plug>(dirvish_up)", { buffer = 0 })
-- map("n", "<ESC>", ":bd<CR>", { buffer = 0 })
-- map("n", "q", ":bd<CR>", { buffer = 0 })

-- -- vim.cmd([[autocmd dirvish_config FileType dirvish nmap <buffer> <C-w> <nop>]])
-- -- vim.cmd([[autocmd dirvish_config FileType dirvish nmap <buffer> <C-h> <nop>]])
-- -- vim.cmd([[autocmd dirvish_config FileType dirvish nmap <buffer> <C-j> <nop>]])
-- -- vim.cmd([[autocmd dirvish_config FileType dirvish nmap <buffer> <C-k> <nop>]])
-- -- vim.cmd([[autocmd dirvish_config FileType dirvish nmap <buffer> <C-l> <nop>]])
