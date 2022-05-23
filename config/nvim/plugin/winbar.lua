-- @ht: akinsho and many of the other plugins coming out with winbar support

local gps = require("nvim-gps")
local devicons = require("nvim-web-devicons")
local highlights = require("mega.utils.highlights")

local fn = vim.fn
local api = vim.api
local fmt = string.format
local icons = mega.icons.misc

local function hl(str)
  return "%#" .. str .. "#"
end

local hl_end = "%*"

local separator = hl("WinbarDirectory") .. fmt(" %s ", icons.chevron_right) .. hl_end

local hl_map = {
  ["class"] = "Class",
  ["function"] = "Function",
  ["method"] = "Method",
  ["container"] = "Typedef",
  ["tag"] = "Tag",
  ["array"] = "Directory",
  ["object"] = "Structure",
  ["null"] = "Comment",
  ["boolean"] = "Boolean",
  ["number"] = "Number",
  ["string"] = "String",
}

local function get_icon_hl(t)
  if not t then
    return hl("WinbarIcon")
  end
  local icon_type = vim.split(t, "-")[1]
  return hl(hl_map[icon_type] or "WinbarIcon")
end

local hls = mega.fold(
  function(accum, hl_name, name)
    accum[fmt("Winbar%sIcon", name:gsub("^%l", string.upper))] = { foreground = { from = hl_name } }
    return accum
  end,
  hl_map,
  {
    Winbar = { bold = true },
    WinbarCrumb = { bold = true },
    WinbarIcon = { inherit = "Function" },
    WinbarDirectory = { inherit = "Directory" },
    WinbarCurrent = { bold = true, underline = true, sp = { from = "Directory", attr = "fg" } },
  }
)

highlights.plugin("winbar", hls)

--- TODO: if not the current window this should just show the fallback
--- Seeing the current symbol in a non-active window is pointless
local function breadcrumbs()
  local data = gps.is_available() and gps.get_data() or nil
  if not data or type(data) ~= "table" or vim.tbl_isempty(data) then
    return hl("NonText") .. "⋯"
  end
  local winline = ""
  for index, item in ipairs(data) do
    winline = winline
      .. get_icon_hl(item.type)
      .. item.icon
      .. " "
      .. hl_end
      .. hl("WinbarCrumb")
      .. item.text
      .. hl_end
      .. (next(data, index) and separator or "")
  end
  return winline
end

function mega.winbar()
  local bufname = api.nvim_buf_get_name(api.nvim_get_current_buf())
  local winline = " "
  if bufname == "" then
    return winline .. "[No name]"
  end
  local parts = vim.split(fn.fnamemodify(bufname, ":."), "/")
  local icon, color = devicons.get_icon(bufname, nil, { default = true })
  for idx, part in ipairs(parts) do
    if next(parts, idx) then
      winline = winline .. mega.truncate(part, 20) .. separator
    else
      winline = winline
        .. hl(color)
        .. icon
        .. " "
        .. hl("WinbarCurrent")
        .. part
        .. hl_end
        .. separator
        .. breadcrumbs()
    end
  end
  return winline
end

local excluded = { "NeogitStatus", "NeogitCommitMessage" }

mega.augroup("AttachWinbar", {
  {
    event = { "WinEnter", "BufEnter", "WinClosed" },
    desc = "Toggle winbar",
    command = function()
      for _, win in ipairs(api.nvim_tabpage_list_wins(0)) do
        local buf = api.nvim_win_get_buf(win)
        if
          not vim.tbl_contains(excluded, vim.bo[buf].filetype)
          and mega.empty(fn.win_gettype(win))
          and mega.empty(vim.bo[buf].buftype)
          and not mega.empty(vim.bo[buf].filetype)
        then
          vim.wo[win].winbar = "%{%v:lua.mega.winbar()%}"
        else
          vim.wo[win].winbar = ""
        end
      end
    end,
  },
})
