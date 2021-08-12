local cmd, lsp, api, fn, w = vim.cmd, vim.lsp, vim.api, vim.fn, vim.w
local bufmap, au = mega.bufmap, mega.au

local M = { lsp = {} }
local windows = {}
local prompt_window = {}
local prompt_buf = {}

local function add_highlights()
	local column = api.nvim_win_get_cursor(0)[2]
	local line = api.nvim_get_current_line()
	local cursorword = fn.matchstr(line:sub(1, column + 1), [[\k*$]])
		.. fn.matchstr(line:sub(column + 1), [[^\k*]]):sub(2)

	w.cursorword = cursorword
	w.cursorword_match_id = fn.matchadd("CursorWord", [[\<]] .. cursorword .. [[\>]])
end

local function clear_highlights()
	w.cursorword = nil
	if w.cursorword_match_id then
		pcall(fn.matchdelete, w.cursorword_match_id)
		w.cursorword_match_id = nil
	end
end

local function make_prompt(opts)
	prompt_buf = api.nvim_create_buf(false, true)

	api.nvim_buf_set_option(prompt_buf, "buftype", "prompt")

	prompt_window = api.nvim_open_win(
		prompt_buf,
		true,
		{ relative = "cursor", row = 1, col = 1, width = 20, height = 1, border = "rounded", style = "minimal" }
	)
	fn.prompt_setprompt(prompt_buf, opts.prompt)

	fn.prompt_setcallback(prompt_buf, function(text)
		if opts.callback(text) then
			M.halt_rename()
		end
	end)

	if opts.initial then
		cmd("norm i" .. opts.initial)
	end

	bufmap("<esc>", [[<cmd>lua require('utils').halt_rename()<cr>]], "i")
	bufmap("<c-c>", [[<cmd>lua require('utils').halt_rename()<cr>]], "i")

	cmd("startinsert")

	return prompt_buf, prompt_window
end

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
		border = vim.g.floating_window_border,
	}
	-- Don't jump immediately, we need the windows list to contain ID before autocmd
	windows[#windows + 1] = api.nvim_open_win(buffer, false, win_opts)
	api.nvim_set_current_win(windows[#windows])
	api.nvim_buf_set_option(buffer, "bufhidden", "wipe")
	set_auto_close()
	api.nvim_win_set_cursor(windows[#windows], position)
	fit_to_node(windows[#windows])
end

function M.halt_rename()
	api.nvim_win_close(prompt_window, true)
	api.nvim_buf_delete(prompt_buf, { force = true })
	clear_highlights()
	cmd("stopinsert")
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

function M.lsp.rename()
	local bufnr = api.nvim_get_current_buf()
	local params = lsp.util.make_position_params()
	local prompt_prefix = " → "

	add_highlights()

	make_prompt({
		prompt = prompt_prefix,
		callback = function(new_name)
			if not (new_name and #new_name > 0) then
				return true
			end
			params.newName = new_name
			lsp.buf_request(bufnr, "textDocument/rename", params)
			clear_highlights()
			return true
		end,
	})
end

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

function M.lsp.config()
	local cfg = {}
	for _, client in pairs(lsp.get_active_clients()) do
		cfg[client.name] = { root_dir = client.config.root_dir, settings = client.config.settings }
	end

	mega.log(vim.inspect(cfg))
end

return M
