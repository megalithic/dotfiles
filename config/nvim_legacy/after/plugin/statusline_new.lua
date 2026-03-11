if not Plugin_enabled() then
  -- vim.o.statusline = "%#Statusline# %2{mode()} | %F %m %r %= %{&spelllang} %y %8(%l,%c%) %8p%%"
  return
end

-- TODO: track mutagen (or nix-shell status): https://github.com/folke/dot/blob/master/nvim/lua/plugins/ui.lua#L73-L140

local autocmd = vim.api.nvim_create_autocmd
local augroup = vim.api.nvim_create_augroup("mega_mvim_statusline", { clear = true })
local set_hl = vim.api.nvim_set_hl

local function is_truncated(trunc)
  return vim.api.nvim_win_get_width(0) < (trunc or -1)
end

-- internal state for toggles
local state = {
  show_path = true,
  show_branch = true,
}

-- config for placeholders + highlighting
local config = {
  icons = {
    path = "",
    branch_hidden = "",
  },
  placeholder_hl = "StatusLineDim", -- a dim highlight group we define below
}

-- helper to wrap text in a statusline highlight group
local function hl(group, text)
  return string.format("%%#%s#%s%%*", group, text)
end

-- set (or link) the dim highlight once
vim.api.nvim_set_hl(0, config.placeholder_hl, {}) -- create if missing
-- Link to Comment to keep it dim; adjust as you like
vim.api.nvim_set_hl(0, config.placeholder_hl, { link = "Comment" })

local function filepath()
  local fpath = vim.fn.fnamemodify(vim.fn.expand("%"), ":~:.:h")

  if fpath == "" or fpath == "." then
    return ""
  end

  if state.show_path then
    return string.format("%%<%s/", fpath)
  end

  return hl(config.placeholder_hl, config.icons.path .. "/")
end

local function file_size()
  local size = vim.fn.getfsize(vim.fn.expand("%"))
  if size < 0 then
    return ""
  end
  if size < 1024 then
    return size .. "B "
  elseif size < 1024 * 1024 then
    return string.format("%.1fK", size / 1024)
  else
    return string.format("%.1fM", size / 1024 / 1024)
  end
end

local CTRL_S = vim.keycode("<C-S>", true, true, true)
local CTRL_V = vim.keycode("<C-V>", true, true, true)
local MODES = setmetatable({
  ["n"] = { long = "Normal", short = "N", hl = "StModeNormal", separator_hl = "StSeparator" },
  ["no"] = { long = "N-OPERATOR PENDING", short = "N-OP", hl = "StModeNormal", separator_hl = "StSeparator" },
  ["nov"] = { long = "N-OPERATOR BLOCK", short = "N-OPv", hl = "StModeNormal", separator_hl = "StSeparator" },
  ["noV"] = { long = "N-OPERATOR LINE", short = "N-OPV", hl = "StModeNormal", separator_hl = "StSeparator" },
  ["v"] = { long = "Visual", short = "V", hl = "StModeVisual", separator_hl = "StSeparator" },
  ["V"] = { long = "V-Line", short = "V-L", hl = "StModeVisual", separator_hl = "StSeparator" },
  [CTRL_V] = { long = "V-Block", short = "V-B", hl = "StModeVisual", separator_hl = "StSeparator" },
  ["s"] = { long = "Select", short = "S", hl = "StModeVisual", separator_hl = "StSeparator" },
  ["S"] = { long = "S-Line", short = "S-L", hl = "StModeVisual", separator_hl = "StSeparator" },
  [CTRL_S] = { long = "S-Block", short = "S-B", hl = "StModeVisual", separator_hl = "StSeparator" },
  ["i"] = { long = "Insert", short = "I", hl = "StModeInsert", separator_hl = "StSeparator" },
  ["R"] = { long = "Replace", short = "R", hl = "StModeReplace", separator_hl = "StSeparator" },
  ["c"] = { long = "Command", short = "C", hl = "StModeCommand", separator_hl = "StSeparator" },
  ["r"] = { long = "Prompt", short = "P", hl = "StModeOther", separator_hl = "StSeparator" },
  ["!"] = { long = "Shell", short = "Sh", hl = "StModeOther", separator_hl = "StSeparator" },
  ["t"] = { long = "Terminal", short = "T-I", hl = "StModeOther", separator_hl = "StSeparator" },
  ["nt"] = { long = "N-Terminal", short = "T-N", hl = "StModeNormal", separator_hl = "StSeparator" },
  ["r?"] = { long = "Confirm", short = "?", hl = "StModeOther", separator_hl = "StSeparator" },
}, {
  -- By default return 'Unknown' but this shouldn't be needed
  __index = function()
    return { long = "Unknown", short = "U", hl = "StModeOther", separator_hl = "StSeparator" }
  end,
})

local function mode(truncate_at)
  local mode_info = MODES[vim.api.nvim_get_mode().mode]
  local mode = is_truncated(truncate_at) and mode_info.short or mode_info.long
  return hl(mode_info.hl, string.upper(mode))
end

-- Mode indicators with icons
local function mode_icon()
  local mode = vim.fn.mode()
  local modes = {
    n = "NORMAL",
    i = "INSERT",
    v = "VISUAL",
    V = "V-LINE",
    ["\22"] = "V-BLOCK", -- Ctrl-V
    c = "COMMAND",
    s = "SELECT",
    S = "S-LINE",
    ["\19"] = "S-BLOCK", -- Ctrl-S
    R = "REPLACE",
    r = "REPLACE",
    ["!"] = "SHELL",
    t = "TERMINAL",
  }
  return modes[mode] or "  " .. mode:upper()
end

local function git()
  local git_info = vim.b.gitsigns_status_dict
  if not git_info or git_info.head == "" then
    return ""
  end

  local head = git_info.head
  local added = git_info.added and (" +" .. git_info.added) or ""
  local changed = git_info.changed and (" ~" .. git_info.changed) or ""
  local removed = git_info.removed and (" -" .. git_info.removed) or ""
  if git_info.added == 0 then
    added = ""
  end
  if git_info.changed == 0 then
    changed = ""
  end
  if git_info.removed == 0 then
    removed = ""
  end

  if not state.show_branch then
    head = hl(config.placeholder_hl, config.icons.branch_hidden)
  end

  return table.concat({
    "[ ",
    head,
    added,
    changed,
    removed,
    "]",
  })
end

Statusline = {}

function Statusline.active()
  -- return table.concat {
  --   "[", filepath(), "%t] ",
  --   git(),
  --   "%=",
  --   "%y [%P %l:%c]"
  -- }
  return table.concat({
    "%#StatusLine#",
    "%<",
    -- hl("StatusLineBold", mode_icon()),
    hl("StatusLineBold", mode()),
    " ",
    string.format("%s%s", filepath(), "%t"),
    -- "%f %h",
    " ",
    hl("StModified", "%m"),
    " ",
    "%r",
    -- "%{v:lua.file_type()}",
    " ",
    -- "%{v:lua.file_size()}",
    "%=", -- center
    -- "%{v:lua.lsp_status()}",
    "%=", -- right
    -- "%{v:lua.git_branch()}",
    git(),
    " %l:%c  %P ", -- Line:Column and Percentage
  })
end

function Statusline.inactive()
  return " %t"
end

function Statusline.toggle_path()
  state.show_path = not state.show_path
  vim.cmd("redrawstatus")
end

function Statusline.toggle_branch()
  state.show_branch = not state.show_branch
  vim.cmd("redrawstatus")
end

autocmd({ "WinEnter", "BufEnter", "FocusGained" }, {
  group = augroup,
  desc = "Focused statusline",
  callback = function()
    vim.opt_local.statusline = "%!v:lua.Statusline.active()"
  end,
})

autocmd({ "WinLeave", "BufLeave", "FocusLost" }, {
  group = augroup,
  desc = "Unfocused statusline",
  callback = function()
    vim.opt_local.statusline = "%!v:lua.Statusline.inactive()"
  end,
})
