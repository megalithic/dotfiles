local cmd, lsp, api, fn, w, g = vim.cmd, vim.lsp, vim.api, vim.fn, vim.w, vim.g
local map, bufmap, au = mega.map, mega.bufmap, mega.au

local M = { lsp = {} }
local windows = {}
local diagnostic_ns = vim.api.nvim_create_namespace("lsp_diagnostic")

local function set_auto_close()
	au([[ CursorMoved * ++once lua require('utils').remove_wins() ]])
end

local function fit_to_node(window)
	local node = require("nvim-treesitter.ts_utils").get_node_at_cursor()
	if node:type() == "identifier" then
		node = node:parent()
	end
	local start_row, _, end_row, _ = node:range()
	local new_height = math.min(math.max(end_row - start_row + 6, 15), 30)
	api.nvim_win_set_height(window, new_height)
end

local open_preview_win = function(target, position)
	local buffer = vim.uri_to_bufnr(target)
	local win_opts = {
		relative = "cursor",
		row = 4,
		col = 4,
		width = 120,
		height = 15,
		border = g.floating_window_border,
	}
	-- Don't jump immediately, we need the windows list to contain ID before autocmd
	windows[#windows + 1] = api.nvim_open_win(buffer, false, win_opts)
	api.nvim_set_current_win(windows[#windows])
	api.nvim_buf_set_option(buffer, "bufhidden", "wipe")
	set_auto_close()
	api.nvim_win_set_cursor(windows[#windows], position)
	fit_to_node(windows[#windows])
end

function M.remove_wins()
	local current = api.nvim_get_current_win()
	for i = #windows, 1, -1 do
		if current == windows[i] then
			break
		end
		pcall(api.nvim_win_close, windows[i], true)
		table.remove(windows, i)
	end
	if #windows > 0 then
		set_auto_close()
	end
end

function M.t(str)
	return api.nvim_replace_termcodes(str, true, true, true)
end

function M.check_back_space()
	local col = fn.col(".") - 1
	return col == 0 or fn.getline("."):sub(col, col):match("%s") ~= nil
end

-- # [ rename ] ----------------------------------------------------------------
-- REF:
-- - https://github.com/saadparwaiz1/dotfiles/blob/macOS/nvim/plugin/lsp.lua#L29-L74
-- - https://github.com/lukas-reineke/dotfiles/blob/master/vim/lua/lsp/rename.lua (simpler impl to investigate)
local function highlight_rename_word()
	local column = api.nvim_win_get_cursor(0)[2]
	local line = api.nvim_get_current_line()
	local cursorword = fn.matchstr(line:sub(1, column + 1), [[\k*$]])
		.. fn.matchstr(line:sub(column + 1), [[^\k*]]):sub(2)

	w.cursorword = cursorword
	-- w.cursorword_match_id = fn.matchadd("CursorWord", [[\<]] .. cursorword .. [[\>]])
end
local clear_rename_highlights = function()
	w.cursorword = nil
	if w.cursorword_match_id then
		pcall(fn.matchdelete, w.cursorword_match_id)
		w.cursorword_match_id = nil
	end
end

local rename_prompt = " -> "
M.lsp.rename = function()
	local current_name = vim.fn.expand("<cword>")
	-- rename_prompt = current_name .. rename_prompt
	local bufnr = vim.api.nvim_create_buf(false, true)
	highlight_rename_word()
	vim.api.nvim_buf_set_option(bufnr, "buftype", "prompt")
	vim.api.nvim_buf_set_option(bufnr, "bufhidden", "wipe")
	vim.api.nvim_buf_add_highlight(bufnr, -1, "NGPreviewTitle", 0, 0, #rename_prompt)
	vim.fn.prompt_setprompt(bufnr, rename_prompt)
	local width = #current_name + #rename_prompt + 10
	local winnr = vim.api.nvim_open_win(bufnr, true, {
		relative = "cursor",
		width = width,
		height = 1,
		row = -3,
		col = 1,
		style = "minimal",
		border = "single",
	})
	vim.api.nvim_win_set_option(winnr, "winhl", "Normal:Floating")
	vim.api.nvim_buf_set_option(bufnr, "filetype", "prompt")

	-- map("n", "<ESC>", "<cmd>bd!<CR>", { silent = true, buffer = 0 })
	map({ "n", "i" }, "<CR>", "<cmd>lua require('utils').rename_callback()<CR>", { silent = true, buffer = 0 })
	map({ "n", "i" }, "<BS>", [[<ESC>"_cl]], { silent = true, buffer = 0 })
	bufmap("<esc>", [[<cmd>lua require('utils').cancel_rename_callback()<cr>]], "n")
	bufmap("<esc>", [[<cmd>lua require('utils').cancel_rename_callback()<cr>]], "i")
	bufmap("<c-c>", [[<cmd>lua require('utils').cancel_rename_callback()<cr>]], "i")

	cmd("startinsert")
	-- vim.cmd(string.format("normal i%s", current_name))
end

M.rename_callback = function()
	local new_name = vim.trim(vim.fn.getline("."):sub(#rename_prompt + 1, -1))
	vim.cmd([[stopinsert]])
	vim.cmd([[bd!]])
	if #new_name == 0 or new_name == vim.fn.expand("<cword>") then
		return
	end
	local params = vim.lsp.util.make_position_params()
	params.newName = new_name
	vim.lsp.buf_request(0, "textDocument/rename", params)
end

function M.cancel_rename_callback()
	-- api.nvim_win_close(prompt_window, true)
	-- api.nvim_buf_delete(prompt_buf, { force = true })
	clear_rename_highlights()
	cmd([[stopinsert]])
	cmd([[bd!]])
end

-- local rename_prompt = "Rename -> "
-- local function make_prompt(opts)
-- 	local prompt_buf = api.nvim_create_buf(false, true)

-- 	api.nvim_buf_set_option(prompt_buf, "buftype", "prompt")

-- 	local prompt_window = api.nvim_open_win(
-- 		prompt_buf,
-- 		true,
-- 		{ relative = "cursor", row = 1, col = 1, width = 20, height = 1, border = "rounded", style = "minimal" }
-- 	)
-- 	fn.prompt_setprompt(prompt_buf, opts.prompt)

-- 	fn.prompt_setcallback(prompt_buf, function(text)
-- 		if opts.callback(text) then
-- 			M.cancel_rename_callback()
-- 		end
-- 	end)

-- 	if opts.initial then
-- 		cmd("norm i" .. opts.initial)
-- 	end

-- 	bufmap("<esc>", [[<cmd>lua require('utils').cancel_rename_callback()<cr>]], "i")
-- 	bufmap("<c-c>", [[<cmd>lua require('utils').cancel_rename_callback()<cr>]], "i")

-- 	cmd("startinsert")

-- 	return prompt_buf, prompt_window
-- end

-- function M.lsp.rename()
-- 	local bufnr = api.nvim_get_current_buf()
-- 	local params = lsp.util.make_position_params()
-- 	local prompt_prefix = " → "

-- 	highlight_rename_word()

-- 	make_prompt({
-- 		prompt = prompt_prefix,
-- 		callback = function(new_name)
-- 			if not (new_name and #new_name > 0) then
-- 				return true
-- 			end
-- 			params.newName = new_name
-- 			lsp.buf_request(bufnr, "textDocument/rename", params)
-- 			clear_rename_highlights()
-- 			return true
-- 		end,
-- 	})
-- end

-- M.lsp.rename = function()
-- 	local current_name = fn.expand("<cword>")
-- 	local bufnr = api.nvim_create_buf(false, true)
-- 	api.nvim_buf_set_option(bufnr, "buftype", "prompt")
-- 	api.nvim_buf_set_option(bufnr, "bufhidden", "wipe")
-- 	api.nvim_buf_add_highlight(bufnr, -1, "RenamePrompt", 0, 0, #rename_prompt)
-- 	fn.prompt_setprompt(bufnr, rename_prompt)
-- 	local winnr = api.nvim_open_win(bufnr, true, {
-- 		relative = "cursor",
-- 		width = 50,
-- 		height = 1,
-- 		row = -3,
-- 		col = 1,
-- 		style = "minimal",
-- 		border = g.floating_window_border,
-- 	})
-- 	api.nvim_win_set_option(winnr, "winhl", "Normal:Floating")
-- 	map("n", "<ESC>", "<cmd>bd!<CR>", { silent = true, buffer = true })
-- 	map({ "n", "i" }, "<CR>", M.callback, { silent = true, buffer = true, expr = true })
-- 	map("i", "<BS>", "<ESC>xi", { silent = true, buffer = true })
-- 	cmd(string.format("normal i%s", current_name))
-- end
-- M.callback = function()
-- 	local new_name = vim.trim(fn.getline("."):sub(#rename_prompt + 1, -1))
-- 	cmd([[stopinsert]])
-- 	cmd([[bd!]])
-- 	if #new_name == 0 or new_name == fn.expand("<cword>") then
-- 		return
-- 	end
-- 	local params = lsp.util.make_position_params()
-- 	params.newName = new_name
-- 	lsp.buf_request(0, "textDocument/rename", params)
-- end

-- local cancel_rename_callback = function()
-- 	clear_rename_highlights()
-- 	cmd([[stopinsert]])
-- 	cmd([[bd!]])
-- end
--
-- local rename_callback = function()
-- 	local new_name = vim.trim(fn.getline("."):sub(#rename_prompt + 1, -1))
-- 	cmd([[stopinsert]])
-- 	cmd([[bd!]])
-- 	if #new_name == 0 or new_name == fn.expand("<cword>") then
-- 		return
-- 	end
-- 	local params = lsp.util.make_position_params()
-- 	params.newName = new_name
-- 	lsp.buf_request(0, "textDocument/rename", params)
-- 	clear_rename_highlights()
-- end
--
-- M.lsp.rename = function()
-- 	local current_name = fn.expand("<cword>")
-- 	local bufnr = api.nvim_create_buf(false, true)
-- 	api.nvim_buf_set_option(bufnr, "buftype", "prompt")
-- 	api.nvim_buf_set_option(bufnr, "bufhidden", "wipe")
-- 	api.nvim_buf_add_highlight(bufnr, -1, "RenamePrompt", 0, 0, #rename_prompt)
-- 	highlight_rename_word()
-- 	fn.prompt_setprompt(bufnr, rename_prompt)
-- 	local winnr = api.nvim_open_win(bufnr, true, {
-- 		relative = "cursor",
-- 		width = 50,
-- 		height = 1,
-- 		row = -3,
-- 		col = 1,
-- 		style = "minimal",
-- 		border = g.floating_window_border,
-- 	})
-- 	api.nvim_win_set_option(winnr, "winhl", "Normal:Floating")
-- 	map("n", "<ESC>", cancel_rename_callback, { silent = true, buffer = true })
-- 	map({ "n", "i" }, "<CR>", rename_callback, { silent = true, buffer = true })
-- 	map("i", "<BS>", "<ESC>xi", { silent = true, buffer = true })
-- 	cmd(string.format("normal i%s", current_name))
-- end

-- # [ preview ] ---------------------------------------------------------------
function M.lsp.preview(request)
	local params = lsp.util.make_position_params()
	pcall(lsp.buf_request, 0, request, params, function(_, _, result)
		if not result then
			return
		end
		local data = result[1]
		local target = data.targetUri or data.uri
		local range = data.targetRange or data.range
		open_preview_win(target, { range.start.line + 1, range.start.character })

		bufmap("<esc>", [[lua require('utils').remove_wins()]])
		bufmap("<c-c>", [[lua require('utils').remove_wins()]])
		bufmap("q", [[lua require('utils').remove_wins()]])
	end)
end

-- # [ diagnostics ] -----------------------------------------------------------
function M.lsp.show_diagnostics()
	vim.schedule(function()
		local line = api.nvim_win_get_cursor(0)[1] - 1
		local diagnostics = vim.lsp.diagnostic.get_line_diagnostics()
		api.nvim_buf_clear_namespace(0, diagnostic_ns, 0, -1)
		if #diagnostics == 0 then
			return false
		end
		local virt_texts = vim.lsp.diagnostic.get_virtual_text_chunks_for_line(0, line, diagnostics)
		api.nvim_buf_set_virtual_text(0, diagnostic_ns, line, virt_texts, {})
	end)
end

-- # [ hover ] -----------------------------------------------------------------
function M.lsp.hover()
	if next(lsp.buf_get_clients()) == nil then
		cmd([[execute printf('h %s', expand('<cword>'))]])
	else
		lsp.buf.hover()
	end
end

-- # [ config ] ----------------------------------------------------------------
function M.lsp.config()
	local cfg = {}
	for _, client in pairs(lsp.get_active_clients()) do
		cfg[client.name] = { root_dir = client.config.root_dir, settings = client.config.settings }
	end

	mega.log(vim.inspect(cfg))
end

return M
