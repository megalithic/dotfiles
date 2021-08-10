local colorscheme = require("colors")
local hi, au = mega.highlight, mega.au
local fn, cmd = vim.fn, vim.cmd
local lsp_status = require "lsp-status"

local statusline = {}
au [[VimEnter,ColorScheme * call v:lua.mega.statusline.set_colors()]]
vim.o.statusline = "%!v:lua.mega.statusline.setup()"

local c = {}

function statusline.set_colors()
  c.statusline_bg = colorscheme.cs.bg1

  c.normal_fg = colorscheme.cs.green
  c.normal_bg = c.statusline_bg
  c.insert_fg = colorscheme.cs.fg
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

  hi("StItem", {guifg = c.normal_fg, guibg = c.normal_bg, gui = "bold"})
  hi("StItem2", {guifg = c.secondary_fg, guibg = c.secondary_bg})
  hi("StItem3", {guifg = c.tertiary_fg, guibg = c.tertiary_bg})

  hi("StSep", {guifg = c.normal_bg, guibg = c.normal_fg})
  hi("StSep2", {guifg = c.secondary_bg, guibg = c.secondary_fg})
  hi("StSep3", {guifg = c.tertiary_bg, guibg = c.tertiary_fg})

  hi("StErr", {guifg = c.error, guibg = c.statusline_bg})
  hi("StErrSep", {guifg = c.statusline_bg, guibg = c.error})

  hi("StWarn", {guifg = c.normal, guibg = c.warning})
  hi("StWarnSep", {guifg = c.statusline_bg, guibg = c.warning})
end

-- # LSP status
lsp_status.register_progress()
lsp_status.config {
  status_symbol = "",
  indicator_errors = colorscheme.icons.statusline_error,
  indicator_warnings = colorscheme.icons.statusline_warning,
  indicator_info = colorscheme.icons.statusline_information,
  indicator_hint = colorscheme.icons.statusline_hint,
  indicator_ok = colorscheme.icons.statusline_ok
  -- spinner_frames = {"⣾", "⣽", "⣻", "⢿", "⡿", "⣟", "⣯", "⣷"},
  -- spinner_frames = {"⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"}
}
local function get_lsp_status()
  if #vim.lsp.buf_get_clients() > 0 then
    return lsp_status.status()
  end
  return ""
end

-- REF: https://github.com/kristijanhusak/neovim-config/blob/master/nvim/lua/partials/statusline.lua#L29-L57
local function sep(item, opts, show)
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

local st_mode_block = {color = "%#StMode#", sep_color = "%#StModeSep#", no_before = true, no_padding = true}
local st_mode = {color = "%#StMode#", sep_color = "%#StModeSep#", no_before = true}
local st_mode_right = vim.tbl_extend("force", st_mode, {side = "right", no_before = false})
local section_2 = {color = "%#StItem2#", sep_color = "%#StSep2#"}
local section_3 = {color = "%#StItem3#", sep_color = "%#StSep3#"}
local st_err = {color = "%#StErr#", sep_color = "%#StErrSep#"}
local st_err_right = vim.tbl_extend("force", st_err, {side = "right"})
local st_warn_right = {color = "%#StWarn#", sep_color = "%#StWarnSep#", side = "right", no_after = true}

local function mode_highlight(mode)
  if mode == "n" then
    hi("StModeSep", {guifg = c.normal_bg, guibg = c.normal_fg})
    hi("StMode", {guifg = c.normal_fg, guibg = c.normal_bg, gui = "bold"})
  elseif mode == "i" then
    hi("StModeSep", {guifg = c.insert_bg, guibg = c.insert_fg})
    hi("StMode", {guifg = c.insert_fg, guibg = c.insert_bg, gui = "bold"})
  elseif vim.tbl_contains({"v", "V", ""}, mode) then
    hi("StModeSep", {guifg = c.visual_bg, guibg = c.visual_fg})
    hi("StMode", {guifg = c.visual_fg, guibg = c.visual_bg, gui = "bold"})
  elseif mode == "R" then
    hi("StModeSep", {guifg = c.replace_bg, guibg = c.replace_fg})
    hi("StMode", {guifg = c.replace_fg, guibg = c.replace_bg, gui = "bold"})
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
    -- t = "TERMINAL"
    ["n"] = "N",
    ["niI"] = "N",
    ["niR"] = "N",
    ["niV"] = "N",
    ["v"] = "V",
    ["V"] = "VL",
    [""] = "VB",
    ["s"] = "S",
    ["S"] = "SL",
    [""] = "SB",
    ["i"] = "I",
    ["ic"] = "I",
    ["ix"] = "I",
    ["R"] = "R",
    ["Rc"] = "R",
    ["Rx"] = "R",
    ["Rv"] = "VR",
    ["c"] = "C",
    ["cv"] = "EX",
    ["ce"] = "EX",
    ["r"] = "R",
    ["rm"] = "MORE",
    ["r?"] = "CONFIRM",
    ["!"] = "SHELL",
    ["t"] = "T"
  }

  return with_icon(string.format("%s", modeMap[mode]), colorscheme.icons.mode_symbol, true) or "?"
end

local function get_mode_block()
  get_mode_status()
  local item = "" --█
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

local function get_filepath()
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

  return fn.pathshorten(path)
end

-- REF: https://github.com/vheon/home/blob/master/.config/nvim/lua/statusline.lua#L114-L132
local function get_filetype()
  local filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":t")
  local extension = string.match(filename, "%a+$")

  local ft = vim.bo.filetype

  local devicons = require("nvim-web-devicons")
  local icon = devicons.get_icon(filename, extension) or ""
  return table.concat(
    {
      icon,
      " ",
      ft
    },
    ""
  )
end

local function search_result()
  if vim.v.hlsearch == 0 then
    return ""
  end
  local last_search = fn.getreg("/")
  if not last_search or last_search == "" then
    return ""
  end
  local searchcount = fn.searchcount({maxcount = 9999})
  return " " .. last_search:gsub("\\v", "") .. "(" .. searchcount.current .. "/" .. searchcount.total .. ")"
end

-- local function lsp_status(type)
--   local count = vim.lsp.diagnostic.get_count(0, type)
--   if count > 0 then
--     return count .. " " .. type:sub(1, 1)
--   end
--   return ""
-- end

local function get_lineinfo()
  -- vert_sep = "\uf6d8"             "
  -- ln_sep   = "\ue0a1"             "
  -- col_sep  = "\uf6da"             "
  -- perc_sep = "\uf44e"             "
  return "%l:%c  %p%%/%L"
end

local function statusline_active()
  local mode_block = get_mode_block()
  local mode = get_mode_status()
  local vcs_status = get_vcs_status()
  local search = search_result()
  -- local db_ui = fn["db_ui#statusline"]() or ""
  local ft = get_filetype()
  local lineinfo = get_lineinfo()
  -- local err = lsp_status("Error")
  -- local warn = lsp_status("Warning")
  local lsp_status = get_lsp_status()

  local statusline_sections = {
    sep(mode_block, st_mode_block),
    sep(mode, st_mode),
    "%<",
    sep(vcs_status, section_2, vcs_status ~= ""),
    sep(get_filepath(), vim.bo.modified and st_err or section_3),
    sep(string.format("%s", colorscheme.icons.modified_symbol), st_err, vim.bo.modified),
    sep(string.format("%s", colorscheme.icons.readonly_symbol), st_err, not vim.bo.modifiable),
    sep("%w", nil, vim.wo.previewwindow),
    sep("%r", nil, vim.bo.readonly),
    sep("%q", nil, vim.bo.buftype == "quickfix"),
    -- sep(db_ui, sec_2, db_ui ~= ""),
    "%=",
    sep(lsp_status, vim.tbl_extend("keep", {side = "right"}, section_3), lsp_status ~= ""),
    sep(search, vim.tbl_extend("keep", {side = "right"}, section_3), search ~= ""),
    sep(ft, vim.tbl_extend("keep", {side = "right"}, section_2), ft ~= ""),
    -- sep("%l:%c", st_mode_right),
    sep(lineinfo, st_mode_right),
    -- sep(lineinfo, vim.tbl_extend("keep", {no_after = err == "" and warn == ""}, st_mode_right)),
    -- sep(err, vim.tbl_extend("keep", {no_after = warn == ""}, st_err_right), err ~= ""),
    -- sep(warn, st_warn_right, warn ~= ""),
    sep(mode_block, st_mode_block),
    "%<"
  }

  return table.concat(statusline_sections, "")
end

local function statusline_inactive()
  return [[%f %y %m]]
end

function statusline.setup()
  local focus = vim.g.statusline_winid == fn.win_getid()
  if focus then
    return statusline_active()
  end
  return statusline_inactive()
end

_G.mega.statusline = statusline
