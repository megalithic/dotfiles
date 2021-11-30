local C = require("colors")
-- local utils = require("utils.statusline")
local hi, au = mega.highlight, mega.au
local fn, bo, wo, api = vim.fn, vim.bo, vim.wo, vim.api

mega.statusline = {}

local s = {}
s.inactive = { color = "%#StInactive#", no_padding = true }
s.mode_block = { color = "%#StMode#", sep_color = "%#StModeSep#", no_before = true, no_padding = true }
s.mode = { color = "%#StMode#", sep_color = "%#StModeSep#", no_before = true }
s.mode_right = vim.tbl_extend("force", s.mode, { side = "right", no_before = false })
s.section_2 = { color = "%#StItem2#", sep_color = "%#StSep2#" }
s.section_3 = { color = "%#StItem3#", sep_color = "%#StSep3#" }
s.lsp = vim.tbl_extend("force", s.section_3, { no_padding = true })
s.search = vim.tbl_extend("force", s.section_3, { color = "%#StItemSearch#" })
s.gps = vim.tbl_extend("force", s.section_3, { color = "%#StItemInfo#" })
s.err = { color = "%#StErr#", sep_color = "%#StErrSep#" }

local curwin = vim.g.statusline_winid or 0
local curbuf = vim.api.nvim_win_get_buf(curwin)

local ctx = {
  bufnum = curbuf,
  winid = curwin,
  bufname = fn.bufname(curbuf),
  preview = wo[curwin].previewwindow,
  readonly = bo[curbuf].readonly,
  filetype = bo[curbuf].ft,
  buftype = bo[curbuf].bt,
  modified = bo[curbuf].modified,
  fileformat = bo[curbuf].fileformat,
  shiftwidth = bo[curbuf].shiftwidth,
  expandtab = bo[curbuf].expandtab,
}

local function get_lsp_status()
  -- # LSP status
  local lsp_status = require("lsp-status")
  lsp_status.register_progress()
  lsp_status.config({
    status_symbol = "",
    indicator_errors = C.icons.statusline_error,
    indicator_warnings = C.icons.statusline_warning,
    indicator_info = C.icons.statusline_information,
    indicator_hint = C.icons.statusline_hint,
    indicator_ok = C.icons.statusline_ok,
    -- spinner_frames = {"⣾", "⣽", "⣻", "⢿", "⡿", "⣟", "⣯", "⣷"},
    spinner_frames = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" },
  })

  if #vim.lsp.buf_get_clients() > 0 then
    return lsp_status.status(ctx.bufnum)
  end
  return ""
end

local function seg(item, opts, show)
  opts = opts or {}
  if show == nil then
    show = true
  end
  if not show then
    return ""
  end

  local color = opts.color or "%#StItem1#"
  local pad = " "
  if opts.no_padding then
    pad = ""
  end

  return pad .. color .. item .. pad .. "%*"
end

local function mode_highlight(mode)
  if mode == "n" then
    hi("StModeSep", { guifg = C.cs.bg1, guibg = C.cs.bg5 })
    hi("StMode", { guifg = C.cs.bg5, guibg = C.cs.bg1 })
  elseif mode == "i" then
    hi("StModeSep", { guifg = C.cs.bg1, guibg = C.cs.yellow })
    hi("StMode", { guifg = C.cs.yellow, guibg = C.cs.bg1, gui = "bold" })
  elseif vim.tbl_contains({ "v", "V", "" }, mode) then
    hi("StModeSep", { guifg = C.cs.bg1, guibg = C.cs.red })
    hi("StMode", { guifg = C.cs.red, guibg = C.cs.bg1, gui = "bold" })
  elseif mode == "R" then
    hi("StModeSep", { guifg = C.cs.bg1, guibg = C.cs.orange })
    hi("StMode", { guifg = C.cs.orange, guibg = C.cs.bg1, gui = "bold" })
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
  local mode = api.nvim_get_mode().mode
  mode_highlight(mode)
  local modeMap = {
    -- ["n"] = "NORMAL",
    -- ["niI"] = "NORMAL",
    -- ["niR"] = "NORMAL",
    -- ["niV"] = "NORMAL",
    -- ["v"] = "VISUAL",
    -- ["V"] = "VLINE",
    -- [""] = "VBLOCK",
    -- ["s"] = "SELECT",
    -- ["S"] = "SLINE",
    -- [""] = "SBLOCK",
    -- ["i"] = "INSERT",
    -- ["ic"] = "INSERT",
    -- ["ix"] = "INSERT",
    -- ["R"] = "REPLACE",
    -- ["Rc"] = "REPLACE",
    -- ["Rx"] = "REPLACE",
    -- ["Rv"] = "VREPLACE",
    -- ["c"] = "COMMAND",
    -- ["cv"] = "EX",
    -- ["ce"] = "EX",
    -- ["r"] = "R",
    -- ["rm"] = "MORE",
    -- ["r?"] = "CONFIRM",
    -- ["!"] = "SHELL",
    -- ["t"] = "TERMINAL",

    ["n"] = "NORMAL",
    ["no"] = "N·OPERATOR PENDING ",
    ["v"] = "VISUAL",
    ["V"] = "V·LINE",
    [""] = "V·BLOCK",
    ["s"] = "SELECT",
    ["S"] = "S·LINE",
    ["^S"] = "S·BLOCK",
    ["i"] = "INSERT",
    ["R"] = "REPLACE",
    ["Rv"] = "V·REPLACE",
    ["Rx"] = "C·REPLACE",
    ["Rc"] = "C·REPLACE",
    ["c"] = "COMMAND",
    ["cv"] = "VIM EX",
    ["ce"] = "EX",
    ["r"] = "PROMPT",
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
  return with_icon(string.format("%s", modeMap[mode]), "", true) or "?"
end

local function get_mode_block()
  get_mode_status()
  local item = "" -- █
  return item .. "" .. "%*"
end

local function get_vcs_status()
  local result = {}
  local branch = fn["gitbranch#name"]()
  if branch ~= nil and branch:len() > 0 then
    table.insert(result, branch)
  end
  if #result == 0 then
    return ""
  end
  return with_icon(table.concat(result, " "), C.icons.git_symbol)
end

local function get_fileicon()
  local filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":t")
  local extension = string.match(filename, "%a+$")
  local devicons = require("nvim-web-devicons")
  local icon = devicons.get_icon(filename, extension) or ""
  return icon
end

local function get_filepath(_uses_icon)
  local uses_icon = _uses_icon == nil and true
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
  -- vert_sep = "\uf6d8"             "⋮
  -- ln_sep   = "\ue0a1"             "ℓ
  -- col_sep  = "\uf6da"             "
  -- perc_sep = "\uf44e"             "
  --
  local item = "ℓ"
  return "" .. item .. " %l:%c/%L%*"
end

-- local function get_container_info()
-- 	return vim.g.currentContainer
-- end

local function statusline_active()
  -- -- TODO: reduce the available space whenever we add
  -- -- a component so we can use it to determine what to add
  -- local available_space = vim.api.nvim_win_get_width(curwin)

  -- local plain = utils.is_plain(ctx)
  -- local file_modified = utils.modified(ctx, "●")
  -- local inactive = vim.api.nvim_get_current_win() ~= curwin
  -- local focused = vim.g.vim_in_focus or true
  -- local minimal = plain or inactive or not focused

  -- local segments = utils.file(ctx, minimal)
  -- local dir, parent, file = segments.dir, segments.parent, segments.file
  -- local dir_item = utils.item(dir.item, dir.hl, dir.opts)
  -- local parent_item = utils.item(parent.item, parent.hl, parent.opts)
  -- local file_item = utils.item(file.item, file.hl, file.opts)

  local mode_block = get_mode_block()
  local git = get_vcs_status()
  local search = search_result()
  local ft = get_filetype()
  local lsp = get_lsp_status()

  local statusline_segments = {
    seg(mode_block, s.mode_block),
    seg(get_mode_status(), s.mode),
    "%<",
    seg(get_filepath(false), bo.modified and s.err or s.section_3),
    seg(string.format("%s", ""), vim.tbl_extend("keep", { no_padding = true }, s.err), bo.modified),
    seg(string.format("%s", C.icons.readonly_symbol), s.err, not bo.modifiable),
    seg("%w", nil, wo.previewwindow),
    seg("%r", nil, bo.readonly),
    seg("%q", nil, bo.buftype == "quickfix"),
    "%=",
    -- middle section for whatever we want..
    "%=",
    seg(search, vim.tbl_extend("keep", { side = "right" }, s.search), search ~= ""),
    seg(lsp, vim.tbl_extend("keep", { side = "right" }, s.section_3), lsp ~= ""),
    seg(git, s.section_2, git ~= ""),
    seg(ft, vim.tbl_extend("keep", { side = "right" }, s.section_2), ft ~= ""),
    seg(get_lineinfo(), s.mode_right),
    seg(mode_block, s.mode_block),
    "%<",
  }

  return table.concat(statusline_segments, "")
end

local function statusline_inactive()
  return seg([[%f %m %r]], s.inactive) -- relativepath modified readonly
end

function mega.statusline.setup()
  local focus = vim.g.statusline_winid == fn.win_getid()
  if focus then
    return statusline_active()
  end
  return statusline_inactive()
end

vim.o.statusline = "%!v:lua.mega.statusline.setup()"
