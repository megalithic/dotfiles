local colorscheme = require("colors")
local hi, au = mega.highlight, mega.au
local fn, cmd, bo, wo, set = vim.fn, vim.cmd, vim.bo, vim.wo, vim.o

local statusline = {}
au([[VimEnter,ColorScheme * call v:lua.mega.statusline.set_colors()]])
set.statusline = "%!v:lua.mega.statusline.setup()"

local c = {}
local s = {}

function statusline.set_colors()
	c.statusline_bg = colorscheme.cs.bg1

	c.normal_fg = colorscheme.cs.green
	c.normal_bg = c.statusline_bg
	c.insert_fg = colorscheme.cs.yellow
	c.insert_bg = c.statusline_bg
	c.replace_fg = colorscheme.cs.orange
	c.replace_bg = c.statusline_bg
	c.visual_fg = colorscheme.cs.red
	c.replace_bg = c.statusline_bg

	c.secondary_fg = colorscheme.cs.grey2
	c.secondary_bg = c.statusline_bg

	c.tertiary_fg = colorscheme.cs.grey0
	c.tertiary_bg = c.statusline_bg

	c.warning = colorscheme.status.warning_status
	c.error = colorscheme.status.error_status

	hi("StatusLine", { guibg = c.statusline_bg })

	hi("StItem", { guifg = c.normal_fg, guibg = c.normal_bg, gui = "bold" })
	hi("StItem2", { guifg = c.secondary_fg, guibg = c.secondary_bg })
	hi("StItem3", { guifg = c.tertiary_fg, guibg = c.tertiary_bg })
	hi("StItemInfo", { guifg = colorscheme.cs.blue, guibg = c.normal_bg })

	hi("StSep", { guifg = c.normal_bg, guibg = c.normal_fg })
	hi("StSep2", { guifg = c.secondary_bg, guibg = c.secondary_fg })
	hi("StSep3", { guifg = c.tertiary_bg, guibg = c.tertiary_fg })

	hi("StErr", { guifg = c.error, guibg = c.statusline_bg })
	hi("StErrSep", { guifg = c.statusline_bg, guibg = c.error })

	hi("StWarn", { guifg = c.normal, guibg = c.warning })
	hi("StWarnSep", { guifg = c.statusline_bg, guibg = c.warning })

	hi("StInactive", { guifg = colorscheme.cs.bg2, gui = "italic" })
	s.inactive = { color = "%#StInactive#", no_padding = true }

	s.mode_block = { color = "%#StMode#", sep_color = "%#StModeSep#", no_before = true, no_padding = true }
	s.mode = { color = "%#StMode#", sep_color = "%#StModeSep#", no_before = true }
	s.mode_right = vim.tbl_extend("force", s.mode, { side = "right", no_before = false })
	s.section_2 = { color = "%#StItem2#", sep_color = "%#StSep2#" }
	s.section_3 = { color = "%#StItem3#", sep_color = "%#StSep3#" }
	s.lsp = vim.tbl_extend("force", s.section_3, { no_padding = true })
	s.search = vim.tbl_extend("force", s.section_3, { color = "%#StItemInfo#" })
	s.err = { color = "%#StErr#", sep_color = "%#StErrSep#" }
	s.err_right = vim.tbl_extend("force", s.err, { side = "right" })
	s.warn_right = { color = "%#StWarn#", sep_color = "%#StWarnSep#", side = "right", no_after = true }
end

local function get_lsp_status()
	-- # LSP status
	local lsp_status = require("lsp-status")
	lsp_status.register_progress()
	lsp_status.config({
		status_symbol = "",
		indicator_errors = colorscheme.icons.statusline_error,
		indicator_warnings = colorscheme.icons.statusline_warning,
		indicator_info = colorscheme.icons.statusline_information,
		indicator_hint = colorscheme.icons.statusline_hint,
		indicator_ok = colorscheme.icons.statusline_ok,
		-- spinner_frames = {"⣾", "⣽", "⣻", "⢿", "⡿", "⣟", "⣯", "⣷"},
		-- spinner_frames = {"⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"}
	})

	if #vim.lsp.buf_get_clients() > 0 then
		return lsp_status.status()
	end
	return ""
end

-- REF: https://github.com/kristijanhusak/neovim-config/blob/master/nvim/lua/partials/statusline.lua#L29-L57
local function seg(item, opts, show)
	opts = opts or {}
	if show == nil then
		show = true
	end
	if not show then
		return ""
	end

	local color = opts.color or "%#StItem#"
	local pad = " "
	if opts.no_padding then
		pad = ""
	end

	return pad .. color .. item .. pad .. "%*"
end

local function mode_highlight(mode)
	if mode == "n" then
		hi("StModeSep", { guifg = c.normal_bg, guibg = c.normal_fg })
		hi("StMode", { guifg = c.normal_fg, guibg = c.normal_bg, gui = "bold" })
	elseif mode == "i" then
		hi("StModeSep", { guifg = c.insert_bg, guibg = c.insert_fg })
		hi("StMode", { guifg = c.insert_fg, guibg = c.insert_bg, gui = "bold" })
	elseif vim.tbl_contains({ "v", "V", "" }, mode) then
		hi("StModeSep", { guifg = c.visual_bg, guibg = c.visual_fg })
		hi("StMode", { guifg = c.visual_fg, guibg = c.visual_bg, gui = "bold" })
	elseif mode == "R" then
		hi("StModeSep", { guifg = c.replace_bg, guibg = c.replace_fg })
		hi("StMode", { guifg = c.replace_fg, guibg = c.replace_bg, gui = "bold" })
	end
end

local function with_icon(value, icon, after)
	if not value then
		return value
	end

	if after then
		return value .. " " .. icon
	end

	return icon .. " " .. value
end

local function get_mode_status()
	local mode = fn.mode()
	mode_highlight(mode)
	local modeMap = {
		["n"] = "NORMAL",
		["niI"] = "NORMAL",
		["niR"] = "NORMAL",
		["niV"] = "NORMAL",
		["v"] = "VISUAL",
		["V"] = "VLINE",
		[""] = "VBLOCK",
		["s"] = "SELECT",
		["S"] = "SLINE",
		[""] = "SBLOCK",
		["i"] = "INSERT",
		["ic"] = "INSERT",
		["ix"] = "INSERT",
		["R"] = "REPLACE",
		["Rc"] = "REPLACE",
		["Rx"] = "REPLACE",
		["Rv"] = "VREPLACE",
		["c"] = "COMMAND",
		["cv"] = "EX",
		["ce"] = "EX",
		["r"] = "R",
		["rm"] = "MORE",
		["r?"] = "CONFIRM",
		["!"] = "SHELL",
		["t"] = "TERMINAL",

		-- n = "NORMAL",
		-- i = "INSERT",
		-- R = "REPLACE",
		-- v = "VISUAL",
		-- V = "V-LINE",
		-- c = "COMMAND",
		-- [""] = "V-BLOCK",
		-- s = "SELECT",
		-- S = "S-LINE",
		-- [""] = "S-BLOCK",
		-- t = "TERMINAL",

		-- ["n"] = "N",
		-- ["niI"] = "N",
		-- ["niR"] = "N",
		-- ["niV"] = "N",
		-- ["v"] = "V",
		-- ["V"] = "VL",
		-- [""] = "VB",
		-- ["s"] = "S",
		-- ["S"] = "SL",
		-- [""] = "SB",
		-- ["i"] = "I",
		-- ["ic"] = "I",
		-- ["ix"] = "I",
		-- ["R"] = "R",
		-- ["Rc"] = "R",
		-- ["Rx"] = "R",
		-- ["Rv"] = "VR",
		-- ["c"] = "C",
		-- ["cv"] = "EX",
		-- ["ce"] = "EX",
		-- ["r"] = "R",
		-- ["rm"] = "MORE",
		-- ["r?"] = "CONFIRM",
		-- ["!"] = "SHELL",
		-- ["t"] = "T"
	}

	-- return with_icon(string.format("%s", modeMap[mode]), colorscheme.icons.mode_symbol, true) or "?"
	return with_icon(string.format("%s", modeMap[mode]), "", true) or "?"
end

local function get_mode_block()
	get_mode_status()
	local item = "" -- █
	return item .. "" .. "%*"
end

local function get_vcs_status()
	local result = {}
	local branch = fn["fugitive#head"](7)
	if branch ~= nil and branch:len() > 0 then
		table.insert(result, branch)
	end
	if #result == 0 then
		return ""
	end
	return with_icon(table.concat(result, " "), colorscheme.icons.git_symbol)
end

local function get_fileicon()
	local filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":t")
	local extension = string.match(filename, "%a+$")
	local devicons = require("nvim-web-devicons")
	local icon = devicons.get_icon(filename, extension) or ""
	return icon
end

local function get_filepath(_uses_icon)
	local uses_icon = _uses_icon or true
	local full_path = fn.expand("%:p")
	local path = full_path
	local cwd = fn.getcwd()
	if path == "" then
		path = cwd
	end
	local stats = vim.loop.fs_stat(path)
	if stats and stats.type == "directory" then
		return fn.fnamemodify(path, ":~")
	end

	if full_path:match("^" .. cwd) then
		path = fn.expand("%:.")
	else
		path = fn.expand("%:~")
	end

	if #path < 20 then
		return "%f"
	end

	local icon = uses_icon and get_fileicon() or ""
	return table.concat({
		icon,
		" ",
		fn.pathshorten(path),
	}, "")
end

-- REF: https://github.com/vheon/home/blob/master/.config/nvim/lua/statusline.lua#L114-L132
local function get_filetype()
	local icon = get_fileicon()
	local ft = bo.filetype

	return table.concat({
		icon,
		" ",
		ft,
	}, "")
end

local function search_result()
	if vim.v.hlsearch == 0 then
		return ""
	end
	local last_search = fn.getreg("/")
	if not last_search or last_search == "" then
		return ""
	end
	local searchcount = fn.searchcount({ maxcount = 9999 })
	return " " .. last_search:gsub("\\v", "") .. "(" .. searchcount.current .. "/" .. searchcount.total .. ")"
end

local function get_lineinfo()
	-- vert_sep = "\uf6d8"             "
	-- ln_sep   = "\ue0a1"             "
	-- col_sep  = "\uf6da"             "
	-- perc_sep = "\uf44e"             "
	local item = ""
	return "" .. item .. " %l:%c  %p%%/%L%*"
end

local function get_gps_status()
	local gps = require("nvim-gps")

	gps.is_available() -- Returns boolean value indicating whether a output can be provided
	if gps.is_available() then
		return " " .. gps.get_location() -- Returns a string with context information
	else
		return ""
	end
end

local function statusline_active()
	local mode_block = get_mode_block()
	local vcs_status = get_vcs_status()
	local search = search_result()
	local ft = get_filetype()
	local lsp = get_lsp_status()
	local gps = get_gps_status()

	local statusline_sections = {
		seg(mode_block, s.mode_block),
		seg(get_mode_status(), s.mode),
		"%<",
		seg(vcs_status, s.section_2, vcs_status ~= ""),
		seg(get_filepath(true), bo.modified and s.err or s.section_3),
		seg(string.format("%s", ""), vim.tbl_extend("keep", { no_padding = true }, s.err), bo.modified),
		seg(string.format("%s", colorscheme.icons.readonly_symbol), s.err, not bo.modifiable),
		seg("%w", nil, wo.previewwindow),
		seg("%r", nil, bo.readonly),
		seg("%q", nil, bo.buftype == "quickfix"),
		"%=",
		seg(gps, s.search, gps ~= ""),
		"%=",
		seg(lsp, vim.tbl_extend("keep", { side = "right" }, s.section_3), lsp ~= ""),
		seg(search, vim.tbl_extend("keep", { side = "right" }, s.search), search ~= ""),
		seg(ft, vim.tbl_extend("keep", { side = "right" }, s.section_2), ft ~= ""),
		seg(get_lineinfo(), s.mode_right),
		seg(mode_block, s.mode_block),
		"%<",
	}

	return table.concat(statusline_sections, "")
end

local function statusline_inactive()
	return seg([[%f %y %m]], s.inactive)
end

function statusline.setup()
	local focus = vim.g.statusline_winid == fn.win_getid()
	if focus then
		return statusline_active()
	end
	return statusline_inactive()
end

_G.mega.statusline = statusline
