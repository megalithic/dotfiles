if true then return end

if not mega then return end

mega.ui.winbar = {}

local api = vim.api
local fn = vim.fn

local NO_NAME = "[No name]"

function mega.ui.winbar.render()
  local win = vim.g.statusline_winid
  local buf = api.nvim_win_get_buf(win)
  local typ = vim.bo[buf].buftype
  local name = ""
  local flags = ""

  if typ == "quickfix" then
    local has_title, qf_title = pcall(api.nvim_win_get_var, win, "quickfix_title")

    name = (has_title and qf_title) and qf_title or NO_NAME
  elseif typ == "terminal" then
    local bufname = fn.bufname(buf)
    local parts = vim.split(bufname, ":", { trimempty = true })

    if #parts == 3 then bufname = "term:" .. parts[3] end

    name = bufname
  else
    local bufname = fn.bufname(buf)

    if bufname == "" then bufname = NO_NAME end

    -- Escape any literal percent signs so they aren't evaluated.
    if bufname:match("%%") then bufname = bufname:gsub("%%", "%%%%") end

    name = fn.fnamemodify(bufname, ":.")
    flags = "%( %m%r%)"
  end

  return table.concat({ name, flags, " ", "%#WinBarFill#" }, "")
end

vim.o.winbar = "%!v:lua.mega.ui.winbar.render()"
