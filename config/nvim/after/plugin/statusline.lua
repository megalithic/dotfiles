if true then return end

if not mega then
  vim.o.statusline = "%#Statusline# %2{mode()} | %F %m %r %= %{&spelllang} %y %8(%l,%c%) %8p%%"
  return
end

local borders = {
  none = { "", "", "", "", "", "", "", "" },
  invs = { " ", " ", " ", " ", " ", " ", " ", " " },
  thin = { "╭", "─", "╮", "│", "╯", "─", "╰", "│" },
  edge = { "🭽", "▔", "🭾", "▕", "🭿", "▁", "🭼", "▏" }, -- Works in Kitty, Wezterm
}

mega.ui.statusline = {}
_G.tools = {
  ui = {
    cur_border = borders.invs,
    borders = borders,
    icons = {
      branch = "",
      bullet = "•",
      o_bullet = "○",
      check = "✔",
      d_chev = "∨",
      ellipses = "…",
      file = "╼ ",
      hamburger = "≡",
      lock = "",
      r_chev = ">",
      location = "⌘",
      square = "⏹ ",
      ballot_x = "🗴",
      up_tri = "▲",
      info_i = "¡",
    },
  },
  nonprog_modes = {
    ["markdown"] = true,
    ["org"] = true,
    ["orgagenda"] = true,
    ["text"] = true,
  },
}

-- ┌─────────┐
-- │functions│
-- └─────────┘
--------------------------------------------------
-- files and directories
--------------------------------------------------
-- provides a place to cache the root
-- directory for current editing session
local branch_cache = {}
local remote_cache = {}

--- get the path to the root of the current file. The
-- root can be anything we define, such as ".git",
-- "Makefile", etc.
-- see https://www.reddit.com/r/neovim/comments/zy5s0l/you_dont_need_vimrooter_usually_or_how_to_set_up/
-- @tparam  path: file to get root of
-- @treturn path to the root of the filepath parameter
tools.get_path_root = function(path)
  if path == "" then return end

  local root = vim.b.path_root
  if root ~= nil then return root end

  local root_items = {
    ".git",
  }

  root = vim.fs.root(0, root_items)
  if root == nil then return nil end
  vim.b.path_root = root

  return root
end

-- get the name of the remote repository
tools.get_git_remote_name = function(root)
  if root == nil then return end

  local remote = remote_cache[root]
  if remote ~= nil then return remote end

  -- see https://stackoverflow.com/a/42543006
  -- "basename" "-s" ".git" "`git config --get remote.origin.url`"
  local cmd = table.concat({ "git", "config", "--get remote.origin.url" }, " ")
  remote = vim.fn.system(cmd)

  if vim.v.shell_error ~= 0 then return nil end

  remote = vim.fs.basename(remote)
  if remote == nil then return end

  remote = vim.fn.fnamemodify(remote, ":r")
  remote_cache[root] = remote

  return remote
end

tools.set_git_branch = function(root)
  local cmd = table.concat({ "git", "-C", root, "branch --show-current" }, " ")
  local branch = vim.fn.system(cmd)
  if branch == nil then return nil end

  branch = branch:gsub("\n", "")
  branch_cache[root] = branch

  return branch
end

tools.get_git_branch = function(root)
  if root == nil then return end

  local branch = branch_cache[root]
  if branch ~= nil then return branch end

  return tools.set_git_branch(root)
end

tools.is_nonprog_ft = function() return tools.nonprog_modes[vim.bo.filetype] ~= nil end

--------------------------------------------------
-- LSP
--------------------------------------------------
tools.diagnostics_available = function()
  local clients = vim.lsp.get_clients({ bufnr = 0 })
  local diagnostics = vim.lsp.protocol.Methods.textDocument_publishDiagnostics

  for _, cfg in pairs(clients) do
    if cfg.supports_method(diagnostics) then return true end
  end

  return false
end

--------------------------------------------------
-- Highlighting
--------------------------------------------------
tools.hl_str = function(hl, str) return "%#" .. hl .. "#" .. str .. "%*" end

-- Stolen from toggleterm.nvim
--
---Convert a hex color to an rgb color
---@param hex string
---@return number
---@return number
---@return number
local function hex_to_rgb(hex)
  if hex == nil then hex = "#000000" end
  return tonumber(hex:sub(2, 3), 16), tonumber(hex:sub(4, 5), 16), tonumber(hex:sub(6), 16)
end

-- Stolen from toggleterm.nvim
--
-- SOURCE: https://stackoverflow.com/questions/5560248/programmatically-lighten-or-darken-a-hex-color-or-rgb-and-blend-colors
-- @see: https://stackoverflow.com/questions/37796287/convert-decimal-to-hex-in-lua-4
--- Shade Color generate
--- @param hex string hex color
--- @param percent number
--- @return string
tools.tint = function(hex, percent)
  local r, g, b = hex_to_rgb(hex)

  -- If any of the colors are missing return "NONE" i.e. no highlight
  if not r or not g or not b then return "NONE" end

  r = math.floor(tonumber(r * (100 + percent) / 100) or 0)
  g = math.floor(tonumber(g * (100 + percent) / 100) or 0)
  b = math.floor(tonumber(b * (100 + percent) / 100) or 0)
  r, g, b = r < 255 and r or 255, g < 255 and g or 255, b < 255 and b or 255

  return "#" .. string.format("%02x%02x%02x", r, g, b)
end

---Get a hl group's rgb
---Note: Always gets linked colors
---@param opts table
---@param ns_id integer?
---@return table
tools.get_hl_hex = function(opts, ns_id)
  opts, ns_id = opts or {}, ns_id or 0
  assert(opts.name or opts.id, "Error: must have hl group name or ID!")
  opts.link = true

  local hl = vim.api.nvim_get_hl(ns_id, opts)

  return {
    fg = hl.fg and ("#%06x"):format(hl.fg),
    bg = hl.bg and ("#%06x"):format(hl.bg),
  }
end

-- insert grouping separators in numbers
-- viml regex: https://stackoverflow.com/a/42911668
-- lua pattern: stolen from Akinsho
tools.group_number = function(num, sep)
  if num < 999 then
    return tostring(num)
  else
    num = tostring(num)
    return num:reverse():gsub("(%d%d%d)", "%1" .. sep):reverse():gsub("^,", "")
  end
end

local utils = {}
utils.pad_str = function(in_str, width, align)
  local num_spaces = width - #in_str
  if num_spaces < 1 then num_spaces = 1 end

  local spaces = string.rep(" ", num_spaces)

  if align == "left" then return table.concat({ in_str, spaces }) end

  return table.concat({ spaces, in_str })
end
local get_opt = vim.api.nvim_get_option_value

local M = {}

-- see https://vimhelp.org/options.txt.html#%27statusline%27 for part fmt strs
local stl_parts = {
  buf_info = nil,
  diag = nil,
  git_info = nil,
  modifiable = nil,
  modified = nil,
  pad = " ",
  path = nil,
  ro = nil,
  scrollbar = nil,
  sep = "%=",
  trunc = "%<",
  venv = nil,
}

local stl_order = {
  "pad",
  "path",
  "mod",
  "ro",
  "sep",
  "venv",
  "sep",
  "diag",
  "fileinfo",
  "pad",
  "scrollbar",
  "pad",
}

local icons = tools.ui.icons

local ui_icons = {
  ["branch"] = { "DiagnosticOk", icons["branch"] },
  ["file"] = { "NonText", icons["file"] },
  ["fileinfo"] = { "DiagnosticInfo", icons["hamburger"] },
  ["nomodifiable"] = { "DiagnosticWarn", icons["bullet"] },
  ["modified"] = { "DiagnosticError", icons["bullet"] },
  ["readonly"] = { "DiagnosticWarn", icons["lock"] },
  ["searchcount"] = { "DiagnosticInfo", icons["location"] },
  ["error"] = { "DiagnosticError", icons["ballot_x"] },
  ["warn"] = { "DiagnosticWarn", icons["up_tri"] },
}

--------------------------------------------------
-- Utilities
--------------------------------------------------
local function hl_icons(icon_list)
  local hl_syms = {}

  for name, list in pairs(icon_list) do
    hl_syms[name] = tools.hl_str(list[1], list[2])
  end

  return hl_syms
end

-- Get fmt strs from dict and concatenate them into one string.
-- @param key_list: table of keys to use to access fmt strings
-- @param dict: associative array to get fmt strings from
-- @return string of concatenated fmt strings and data that will create the
-- statusline when evaluated
local function ordered_tbl_concat(order_tbl, stl_part_tbl)
  local str_table = {}
  local part = nil

  for _, val in ipairs(order_tbl) do
    part = stl_part_tbl[val]
    if part then table.insert(str_table, part) end
  end

  return table.concat(str_table, " ")
end

--------------------------------------------------
-- String Generation
--------------------------------------------------
local hl_ui_icons = hl_icons(ui_icons)

local function escape_str(str)
  local output = str:gsub("([%(%)%%%+%-%*%?%[%]%^%$])", "%%%1")
  return output
end

-- PATH WIDGET
--- Create a string containing info for the current git branch
--- @return string: branch info
local function get_path_info(root, fname, icon_tbl)
  local file_name = vim.fn.fnamemodify(fname, ":t")

  local file_icon, icon_hl = require("mini.icons").get("file", file_name)
  file_icon = file_name ~= "" and tools.hl_str(icon_hl, file_icon) or ""

  local file_icon_name = table.concat({ file_icon, file_name })

  if vim.bo.buftype == "help" then return table.concat({ icon_tbl["file"], file_icon_name }) end

  local remote = tools.get_git_remote_name(root)
  local branch = tools.get_git_branch(root)
  local dir_path = vim.fn.fnamemodify(fname, ":h") .. "/"
  local win_width = vim.api.nvim_win_get_width(0)
  local dir_threshold_width = 15
  local repo_threshold_width = 10

  local repo_info = ""
  if remote and branch then
    dir_path = string.gsub(dir_path, "^" .. escape_str(root) .. "/", "")

    repo_info = table.concat({
      icon_tbl["branch"],
      " ",
      remote,
      ":",
      branch,
      " ",
    })
  end

  dir_path = win_width >= dir_threshold_width + #repo_info + #dir_path + #file_icon_name and dir_path or ""

  repo_info = win_width >= repo_threshold_width + #repo_info + #file_icon_name and repo_info or ""

  return table.concat({
    repo_info,
    icon_tbl["file"],
    dir_path,
    file_icon_name,
  })
end

-- DIAGNOSTIC WIDGET
--- Create a string of diagnostic information
--- @return string available diagnostics
local function get_diag_str()
  if not tools.diagnostics_available() then return "" end

  local diag_tbl = {}
  local total = vim.diagnostic.count()
  local err_total = total[1] or 0
  local warn_total = total[2] or 0

  vim.list_extend(diag_tbl, { hl_ui_icons["error"], " ", utils.pad_str(tostring(err_total), 3, "left"), " " })
  vim.list_extend(diag_tbl, { hl_ui_icons["warn"], " ", utils.pad_str(tostring(warn_total), 3, "left"), " " })

  return table.concat(diag_tbl)
end

-- FILEINFO WIDGET
local function get_filesize()
  local suffix = { "b", "k", "M", "G", "T", "P", "E" }
  local fsize = vim.fn.getfsize(vim.api.nvim_buf_get_name(0))

  -- Handle invalid file size
  if fsize < 0 then return "0b" end

  local i = math.floor(math.log(fsize) / math.log(1024))
  -- Ensure index is within suffix range
  i = math.min(i, #suffix - 1)

  return string.format("%.1f%s", fsize / 1024 ^ i, suffix[i + 1])
end

local function get_vlinecount_str()
  local raw_count = vim.fn.line(".") - vim.fn.line("v")
  raw_count = raw_count < 0 and raw_count - 1 or raw_count + 1

  return tools.group_number(math.abs(raw_count), ",")
end

local function is_user_typing_search()
  local cmd_type = vim.fn.getcmdtype()
  return cmd_type == "/" or cmd_type == "?"
end

--- Get wordcount for current buffer or visual selection
--- @return string word count
local function get_fileinfo_widget(icon_tbl)
  if vim.v.hlsearch == 1 and not is_user_typing_search() then
    local sinfo = vim.fn.searchcount()
    local search_stat = sinfo.incomplete > 0 and "press enter" or sinfo.total > 0 and ("%s/%s"):format(sinfo.current, sinfo.total) or nil

    if search_stat ~= nil then return table.concat({ icon_tbl.searchcount, " ", search_stat, " " }) end
  end

  local ft = get_opt("filetype", {})
  local lines = tools.group_number(vim.api.nvim_buf_line_count(0), ",")

  -- For source code: return icon and line count
  if not tools.nonprog_modes[ft] then return table.concat({ icon_tbl.fileinfo, " ", lines, " lines" }) end

  local wc_table = vim.fn.wordcount()
  if not wc_table.visual_words or not wc_table.visual_chars then
    -- Normal mode word count and file info
    return table.concat({
      icon_tbl.fileinfo,
      " ",
      get_filesize(),
      "  ",
      lines,
      " lines  ",
      tools.group_number(wc_table.words, ","),
      " words ",
    })
  else
    -- Visual selection mode: line count, word count, and char count
    return table.concat({
      tools.hl_str("DiagnosticInfo", "‹›"),
      " ",
      get_vlinecount_str(),
      " lines  ",
      tools.group_number(wc_table.visual_words, ","),
      " words  ",
      tools.group_number(wc_table.visual_chars, ","),
      " chars",
    })
  end
end

--- Get the name of the current venv in Python
--- @return string|nil name of venv or nil
--- From JDHao; see https://www.reddit.com/r/neovim/comments/16ya0fr/show_the_current_python_virtual_env_on_statusline/
local get_py_venv = function()
  local venv_path = os.getenv("VIRTUAL_ENV")
  if venv_path then
    local venv_name = vim.fn.fnamemodify(venv_path, ":t")
    return string.format("'.venv': %s  ", venv_name)
  end

  local conda_env = os.getenv("CONDA_DEFAULT_ENV")
  if conda_env then return string.format("conda: %s  ", conda_env) end

  return nil
end

local function get_scrollbar()
  local sbar_chars = {
    "▔",
    "🮂",
    "🬂",
    "🮃",
    "▀",
    "▄",
    "▃",
    "🬭",
    "▂",
    "▁",
  }

  local cur_line = vim.api.nvim_win_get_cursor(0)[1]
  local lines = vim.api.nvim_buf_line_count(0)

  local i = math.floor((cur_line - 1) / lines * #sbar_chars) + 1
  local sbar = string.rep(sbar_chars[i], 2)

  return tools.hl_str("Substitute", sbar)
end

--- Creates statusline
--- @return string statusline text to be displayed
function mega.ui.statusline.render()
  local fname = vim.api.nvim_buf_get_name(0)
  local root = nil
  if vim.bo.buftype == "terminal" or vim.bo.buftype == "nofile" or vim.bo.buftype == "prompt" then
    fname = vim.bo.ft
  else
    root = tools.get_path_root(fname)
  end

  local buf_num = vim.api.nvim_win_get_buf(vim.g.statusline_winid or 0)

  stl_parts["path"] = get_path_info(root, fname, hl_ui_icons)
  stl_parts["ro"] = get_opt("readonly", { buf = buf_num }) and hl_ui_icons["readonly"] or ""

  if not get_opt("modifiable", { buf = buf_num }) then
    stl_parts["mod"] = hl_ui_icons["nomodifiable"]
  elseif get_opt("modified", { buf = buf_num }) then
    stl_parts["mod"] = hl_ui_icons["modified"]
  else
    stl_parts["mod"] = " "
  end

  -- middle
  -- filetype-specific info
  if vim.bo.filetype == "python" then stl_parts["venv"] = get_py_venv() end

  -- right
  stl_parts["diag"] = get_diag_str()
  stl_parts["fileinfo"] = get_fileinfo_widget(hl_ui_icons)
  stl_parts["scrollbar"] = get_scrollbar()

  -- turn all of these pieces into one string
  return ordered_tbl_concat(stl_order, stl_parts)
end

-- vim.o.statusline = "%!v:lua.require('mega.ui.statusline').render()"
vim.o.statusline = "%{%v:lua.mega.ui.statusline.render()%}"

return M
