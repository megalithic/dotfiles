local C = require("colors")
-- local utils = require("utils.statusline")
local hi, au = mega.highlight, mega.au
local fn, _, bo, wo, set, api = vim.fn, vim.cmd, vim.bo, vim.wo, vim.o, vim.api

mega.statusline = {}

local c = {}
local s = {}

local curwin = vim.g.statusline_winid or 0
local curbuf = vim.api.nvim_win_get_buf(curwin)

local ctx = {
  bufnum = curbuf,
  winid = curwin,
  bufname = vim.fn.bufname(curbuf),
  preview = vim.wo[curwin].previewwindow,
  readonly = vim.bo[curbuf].readonly,
  filetype = vim.bo[curbuf].ft,
  buftype = vim.bo[curbuf].bt,
  modified = vim.bo[curbuf].modified,
  fileformat = vim.bo[curbuf].fileformat,
  shiftwidth = vim.bo[curbuf].shiftwidth,
  expandtab = vim.bo[curbuf].expandtab,
}

function mega.statusline.colors()
  c.statusline_bg = C.cs.bg1

  c.normal_fg = C.cs.green
  c.normal_bg = c.statusline_bg
  c.insert_fg = C.cs.yellow
  c.insert_bg = c.statusline_bg
  c.replace_fg = C.cs.orange
  c.replace_bg = c.statusline_bg
  c.visual_fg = C.cs.red
  c.replace_bg = c.statusline_bg

  c.secondary_fg = C.cs.grey2
  c.secondary_bg = c.statusline_bg

  c.tertiary_fg = C.cs.grey0
  c.tertiary_bg = c.statusline_bg

  c.warning = C.status.warning_status
  c.error = C.status.error_status

  hi("StatusLine", { guibg = c.statusline_bg })

  hi("StItem", { guifg = c.normal_fg, guibg = c.normal_bg, gui = "bold" })
  hi("StItem2", { guifg = c.secondary_fg, guibg = c.secondary_bg })
  hi("StItem3", { guifg = c.tertiary_fg, guibg = c.tertiary_bg })
  hi("StItemInfo", { guifg = C.cs.blue, guibg = c.normal_bg })
  hi("StItemSearch", { guifg = C.cs.cyan, guibg = c.normal_bg })

  hi("StSep", { guifg = c.normal_bg, guibg = c.normal_fg })
  hi("StSep2", { guifg = c.secondary_bg, guibg = c.secondary_fg })
  hi("StSep3", { guifg = c.tertiary_bg, guibg = c.tertiary_fg })

  hi("StErr", { guifg = c.error, guibg = c.statusline_bg, gui = "italic" })
  hi("StErrSep", { guifg = c.statusline_bg, guibg = c.error })

  hi("StWarn", { guifg = c.normal, guibg = c.warning })
  hi("StWarnSep", { guifg = c.statusline_bg, guibg = c.warning })

  hi("StInactive", { guifg = C.cs.bg4, gui = "italic" })
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
  s.err_right = vim.tbl_extend("force", s.err, { side = "right" })
  s.warn_right = { color = "%#StWarn#", sep_color = "%#StWarnSep#", side = "right", no_after = true }
end

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
  local vcs_status = get_vcs_status()
  local search = search_result()
  local ft = get_filetype()
  local lsp = get_lsp_status()
  -- local container_info = get_container_info()

  local statusline_sections = {
    seg(mode_block, s.mode_block),
    seg(get_mode_status(), s.mode),
    "%<",
    seg(vcs_status, s.section_2, vcs_status ~= ""),
    -- seg(container_info, s.section_3, container_info ~= ""),
    seg(get_filepath(false), bo.modified and s.err or s.section_3),
    -- seg(dir.item),
    -- seg(parent.item),
    -- seg(file.item),
    -- dir_item,
    -- parent_item,
    -- file_item,
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
    seg(ft, vim.tbl_extend("keep", { side = "right" }, s.section_2), ft ~= ""),
    seg(get_lineinfo(), s.mode_right),
    seg(mode_block, s.mode_block),
    "%<",
  }

  return table.concat(statusline_sections, "")
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

-- mega.augroup("CustomStatusline", {
--   -- { events = { "FocusGained" }, targets = { "*" }, command = "let g:vim_in_focus = v:true" },
--   -- { events = { "FocusLost" }, targets = { "*" }, command = "let g:vim_in_focus = v:false" },
--   {
--     events = { "VimEnter", "ColorScheme" },
--     targets = { "*" },
--     command = mega.statusline.colors,
--   },
--   -- {
--   --   events = { "BufReadPre" },
--   --   modifiers = { "++once" },
--   --   targets = { "*" },
--   --   command = utils.git_updates,
--   -- },
--   -- {
--   --   events = { "DirChanged" },
--   --   targets = { "*" },
--   --   command = utils.git_update_toggle,
--   -- },
--   --- NOTE: enable to update search count on cursor move
--   -- {
--   --   events = { "CursorMoved", "CursorMovedI" },
--   --   targets = { "*" },
--   --   command = utils.update_search_count,
--   -- },
--   -- NOTE: user autocommands can't be joined into one autocommand
--   -- {
--   --   events = { "User NeogitStatusRefresh" },
--   --   command = utils.git_updates_refresh,
--   -- },
--   -- {
--   --   events = { "User FugitiveChanged" },
--   --   command = utils.git_updates_refresh,
--   -- },
-- })

au([[VimEnter,ColorScheme * call v:lua.mega.statusline.colors()]])
set.statusline = "%!v:lua.mega.statusline.setup()"
