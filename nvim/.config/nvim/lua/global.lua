local api, fn, cmd = vim.api, vim.fn, vim.cmd
local M = { functions = {} }

function M:load_variables()
	local home = os.getenv("HOME")
	local path_sep = M.is_windows and "\\" or "/"
	local os_name = vim.loop.os_uname().sysname

	self.is_mac = os_name == "Darwin"
	self.is_linux = os_name == "Linux"
	self.is_windows = os_name == "Windows"
	self.vim_path = home .. path_sep .. ".config" .. path_sep .. "nvim"
	self.cache_dir = home .. path_sep .. ".cache" .. path_sep .. "nvim" .. path_sep
	self.local_share_dir = home .. path_sep .. ".local" .. path_sep .. "share" .. path_sep .. "nvim" .. path_sep
	self.modules_dir = self.vim_path .. path_sep .. "modules"
	self.path_sep = path_sep
	self.home = home

	return self
end
M:load_variables()

M.dirs = {}
M.dirs.dots = fn.expand("$HOME/.dotfiles")
M.dirs.icloud = fn.expand("$ICLOUD_DIR")
M.dirs.docs = fn.expand("$DOCUMENTS_DIR")
M.dirs.org = fn.expand(M.dirs.docs .. "/_org")
M.dirs.zettel = fn.expand("$ZK_NOTEBOOK_DIR")

--- Check if a directory exists in this path
function M.isdir(path)
	-- check if file exists
	local function file_exists(file)
		local ok, err, code = os.rename(file, file)
		if not ok then
			if code == 13 then
				-- Permission denied, but it exists
				return true
			end
		end
		return ok, err
	end

	-- "/" works on both Unix and Windows
	return file_exists(path .. "/")
end

function M.log(msg, hl, reason)
	if hl == nil and reason == nil then
		api.nvim_echo({ { msg } }, true, {})
	else
		local name = "megavim"
		local prefix = name .. " -> \n"
		if reason ~= nil then
			prefix = name .. " -> " .. reason .. "\n"
		end
		hl = hl or "Todo"
		api.nvim_echo({ { prefix, hl }, { msg } }, true, {})
	end
end

function M.warn(msg, reason)
	M.log(msg, "WarningMsg", reason) -- LspDiagnosticsDefaultWarning
end

function M.error(msg, reason)
	M.log(msg, "ErrorMsg", reason) -- LspDiagnosticsDefaultError
end

-- FIXME: this _DOES NOT_ work?
-- function M.dump(...)
-- 	print(unpack(vim.tbl_map(inspect, { ... })))
-- end

function M.get_log_string(label, level)
	local display_level = "[DEBUG]"
	local hl = "WarningMsg"

	if display_level ~= nil and (level == 4 or level == "ERROR" or level == vim.log.levels.ERROR) then
		display_level = "[ERROR]"
		hl = "ErrorMsg"
	end

	local str = string.format("%s %s", display_level, label)

	return str, hl
end

function M.inspect(label, v, level)
	local str, hl = M.get_log_string(label, level)

	M.log(str, hl)
	M.log(v)

	return v
end

-- a safe module loader
function M.load(module, opts)
	opts = opts or { silent = false, safe = false }

	if opts.key == nil then
		opts.key = "loader"
	end

	local ok, result = pcall(require, module)

	if not ok and not opts.silent then
		-- REF: https://github.com/neovim/neovim/blob/master/src/nvim/lua/vim.lua#L421
		local level = vim.log.levels.ERROR
		local reason = M.get_log_string("loading failed", level)

		M.error(result, reason)
	end

	if opts.safe == true then
		return ok, result
	else
		return result
	end
end

function M.execute(id)
	local func = M.functions[id]
	if not func then
		M.error("Function doest not exist: " .. id)
	end
	return func()
end

-- look at exposing some map helpers like b0o/mapx does
function M.map(modes, lhs, rhs, opts)
	-- TODO: extract these to a function or a module var
	local map_opts = { noremap = true, silent = true, expr = false, nowait = false }

	opts = vim.tbl_extend("force", map_opts, opts or {})
	local buffer = opts.buffer
	opts.buffer = nil

	-- let's us pass in local lua functions without having to shove them on the
	-- global first!
	if type(rhs) == "function" then
		table.insert(M.functions, rhs)
		if opts.expr then
			rhs = ([[luaeval('require("global").execute(%d)')]]):format(#M.functions)
		else
			rhs = ("<cmd>lua require('global').execute(%d)<cr>"):format(#M.functions)
		end
	end

	-- just a string mode? shove that junk into a table!
	if type(modes) ~= "table" then
		modes = { modes }
	end

	for i = 1, #modes do
		if buffer then
			vim.api.nvim_buf_set_keymap(0, modes[i], lhs, rhs, opts)
		else
			vim.api.nvim_set_keymap(modes[i], lhs, rhs, opts)
		end
	end
end

-- this assumes the first buffer (0); refactor to accept a buffer
function M.bufmap(lhs, rhs, mode, expr)
	mode = mode or "n"

	if mode == "n" then
		rhs = "<cmd>" .. rhs .. "<cr>"
	end

	M.map(mode, lhs, rhs, { noremap = true, silent = true, expr = expr, buffer = 0 })
end

function M.au(s)
	cmd("au!" .. s)
end

function M.augroup(name, commands)
	cmd("augroup " .. name)
	cmd("autocmd!")
	for _, c in ipairs(commands) do
		cmd(
			string.format(
				"autocmd %s %s %s %s",
				table.concat(c.events, ","),
				table.concat(c.targets or {}, ","),
				table.concat(c.modifiers or {}, " "),
				c.command
			)
		)
	end
	cmd("augroup END")
end

--- TODO eventually move to using `nvim_set_hl`
--- however for the time being that expects colors
--- to be specified as rgb not hex
---@param name string
---@param opts table
function M.highlight(name, opts)
	local force = opts.force or true
	if name and vim.tbl_count(opts) > 0 then
		if opts.link and opts.link ~= "" then
			cmd("highlight" .. (force and "!" or "") .. " link " .. name .. " " .. opts.link)
		else
			local hi_opt = { "highlight", name }
			if opts.guifg and opts.guifg ~= "" then
				table.insert(hi_opt, "guifg=" .. opts.guifg)
			end
			if opts.guibg and opts.guibg ~= "" then
				table.insert(hi_opt, "guibg=" .. opts.guibg)
			end
			if opts.gui and opts.gui ~= "" then
				table.insert(hi_opt, "gui=" .. opts.gui)
			end
			if opts.guisp and opts.guisp ~= "" then
				table.insert(hi_opt, "guisp=" .. opts.guisp)
			end
			if opts.cterm and opts.cterm ~= "" then
				table.insert(hi_opt, "cterm=" .. opts.cterm)
			end
			cmd(table.concat(hi_opt, " "))
		end
	end
end
M.hi = M.highlight

function M.hi_link(src, dest)
	cmd("hi! link " .. src .. " " .. dest)
end

function M.exec(c)
	api.nvim_exec(c, true)
end

function M.table_merge(t1, t2, opts)
	opts = opts or { strategy = "deep" }

	if opts.strategy == "deep" then
		-- # deep_merge:
		for k, v in pairs(t2) do
			if (type(v) == "table") and (type(t1[k] or false) == "table") then
				M.table_merge(t1[k], t2[k])
			else
				t1[k] = v
			end
		end
	else
		-- # shallow_merge:
		for k, v in pairs(t2) do
			t1[k] = v
		end
	end

	return t1
end
M.deep_merge = function(...)
	M.table_merge(..., { strategy = "deep" })
end
M.shallow_merge = function(...)
	M.table_merge(..., { strategy = "shallow" })
end

-- helps with nerdfonts usages
local bytemarkers = { { 0x7FF, 192 }, { 0xFFFF, 224 }, { 0x1FFFFF, 240 } }
function M.utf8(decimal)
	if decimal < 128 then
		return string.char(decimal)
	end
	local charbytes = {}
	for bytes, vals in ipairs(bytemarkers) do
		if decimal <= vals[1] then
			for b = bytes + 1, 2, -1 do
				local mod = decimal % 64
				decimal = (decimal - mod) / 64
				charbytes[b] = string.char(128 + mod)
			end
			charbytes[1] = string.char(vals[2] + decimal)
			break
		end
	end
	return table.concat(charbytes)
end

function M.has(feature)
	return fn.has(feature) > 0
end

-- TODO: would like to add ability to gather input for continuing; ala `jordwalke/VimAutoMakeDirectory`
function M.auto_mkdir()
	local dir = fn.expand("%:p:h")

	if fn.isdirectory(dir) == 0 then
		fn.mkdir(dir, "p")
	end
end

function M.zetty(args)
	local default_opts = {
		cmd = "meeting",
		action = "edit",
		title = "",
		notebook = "",
		tags = "",
		attendees = "",
	}

	local opts = vim.tbl_extend("force", default_opts, args or {})

	local title = string.format([[%s]], string.gsub(opts.title, "|", "&"))

	local content = ""

	if opts.attendees ~= nil and opts.attendees ~= "" then
		content = string.format("Attendees:\n%s\n\n---\n", opts.attendees)
	end

	local changed_title = fn.input(string.format("[?] Change title from [%s] to: ", title))
	if changed_title ~= "" then
		title = changed_title
	end

	if opts.cmd == "meeting" then
		require("zk.command").new({ title = title, action = "edit", notebook = "meetings", content = content })
	elseif opts.cmd == "new" then
		require("zk.command").new({ title = title, action = "edit" })
	end
end

function M.plugins()
	M.log("paq-nvim: syncing plugins..")

	package.loaded["plugins"] = nil
	require("paq"):setup({ verbose = false })(require("plugins")):sync()
end

return M
