if not Plugin_enabled() then return end

mega.ui.tabline = {}
vim.o.showtabline = 2

-- local num_icons = {
--   "󰎦 ",
--   "󰎩 ",
--   "󰎬 ",
--   "󰎮 ",
--   "󰎰 ",
--   "󰎵 ",
--   "󰎸 ",
--   "󰎻 ",
--   "󰎾 ",
--   "󰽾 ",
-- }

-- -- highlighting -----------------------------
-- local function hl_str(hl, str) return "%#" .. hl .. "#" .. str .. "%*" end

-- function mega.ui.tabline.render()
--   local current = vim.fn.tabpagenr()
--   local total = vim.fn.tabpagenr("$")
--   local out = {}

--   for tab = 1, total do
--     local hl = (tab == current) and "%#TabLineSel#" or "%#TabLine#"
--     local icon = num_icons[tab] or tostring(tab)

--     local names = {}
--     for _, buf in ipairs(vim.fn.tabpagebuflist(tab)) do
--       if vim.fn.buflisted(buf) == 1 then
--         local n = vim.fn.bufname(buf)
--         if n == "" then n = "[No Name]" end
--         table.insert(names, vim.fn.fnamemodify(n, ":t"))
--       end
--     end
--     table.insert(out, string.format("  %s %s%s ", hl, icon, table.concat(names, " ")))
--   end

--   return hl_str("TabLineFill", "  ") .. table.concat(out) .. "%#TabLineFill#"
-- end

-- -- vim.o.statusline = "%{%v:lua.mega.ui.tabline.render()%}"
-- vim.o.tabline = "%!v:lua.mega.ui.tabline.render()"
--
local api, fn = vim.api, vim.fn

local filetypes = {
  git = "Git",
  fugitive = "Fugitive",
  TelescopePrompt = "Telescope",
}

--- @param name string
--- @return {bg?:integer, fg?:integer}
local function get_hl(name) return api.nvim_get_hl(0, { name = name }) end

local buftypes = {
  help = function(file) return "help:" .. fn.fnamemodify(file, ":t:r") end,
  quickfix = "quickfix",
  terminal = function(file)
    local mtch = string.match(file, "term:.*:(%a+)")
    return mtch or fn.fnamemodify(vim.env.SHELL, ":t")
  end,
}

local function title(bufnr)
  local filetype = vim.bo[bufnr].filetype

  if filetypes[filetype] then return filetypes[filetype] end

  local file = fn.bufname(bufnr)
  local buftype = vim.bo[bufnr].buftype

  local bt = buftypes[buftype]
  if bt then
    if type(bt) == "function" then return bt(file) end
    return bt
  end

  if file == "" then return "[No Name]" end
  return fn.pathshorten(fn.fnamemodify(file, ":p:~:t"))
end

local function flags(bufnr)
  local ret = {} --- @type string[]
  if vim.bo[bufnr].modified then ret[#ret + 1] = "[+]" end
  if not vim.bo[bufnr].modifiable then ret[#ret + 1] = "[RO]" end
  return table.concat(ret)
end

--- @type table<string,true>
local devhls = {}

--- @param bufnr integer
--- @param hl_base string
--- @return string
local function devicon(bufnr, hl_base)
  local file = fn.bufname(bufnr)
  local buftype = vim.bo[bufnr].buftype
  local filetype = vim.bo[bufnr].filetype
  local devicons = require("nvim-web-devicons")

  --- @type string, string
  local icon, devhl
  if filetype == "fugitive" then
    --- @type string, string
    icon, devhl = devicons.get_icon("git")
  elseif filetype == "vimwiki" then
    --- @type string, string
    icon, devhl = devicons.get_icon("markdown")
  elseif buftype == "terminal" then
    --- @type string, string
    icon, devhl = devicons.get_icon("zsh")
  else
    --- @type string, string
    icon, devhl = devicons.get_icon(file, fn.expand("#" .. bufnr .. ":e"))
  end

  if icon then
    local hl = hl_base .. "Dev" .. devhl
    if not devhls[hl] then
      devhls[hl] = true
      api.nvim_set_hl(0, hl, {
        fg = get_hl(devhl).fg,
        bg = get_hl(hl_base).bg,
      })
    end

    local hl_start = "%#" .. hl .. "#"
    local hl_end = "%#" .. hl_base .. "#"

    return string.format("%s%s%s ", hl_start, icon, hl_end)
  end
  return ""
end

local function separator(index)
  local selected = fn.tabpagenr()
  -- Don't add separator before or after selected
  if selected == index or selected - 1 == index then return " " end
  return index < fn.tabpagenr("$") and "%#FloatBorder#│" or ""
end

local icons = {
  Error = "",
  Warn = "",
  Hint = "",
  Info = "I",
}

--- @param buflist integer[]
--- @param hl_base string
--- @return string
local function get_diags(buflist, hl_base)
  local diags = {} --- @type string[]
  for _, ty in ipairs({ "Error", "Warn", "Info", "Hint" }) do
    local n = 0
    for _, bufnr in ipairs(buflist) do
      n = n + #vim.diagnostic.get(bufnr, { severity = ty })
    end
    if n > 0 then diags[#diags + 1] = ("%%#Diagnostic%s%s#%s%s"):format(ty, hl_base, icons[ty], n) end
  end

  return table.concat(diags, " ")
end

--- @param index integer
--- @param selected boolean
--- @return string
local function cell(index, selected)
  local buflist = fn.tabpagebuflist(index)
  local winnr = fn.tabpagewinnr(index)
  local bufnr = buflist[winnr]

  local bufnrs = vim.tbl_filter(function(b) return vim.bo[b].buftype ~= "nofile" end, buflist)

  local hl = not selected and "TabLineFill" or "TabLineSel"
  local common = "%#" .. hl .. "#"
  local ret = string.format("%s%%%dT %s%s%s ", common, index, devicon(bufnr, hl), title(bufnr), flags(bufnr))

  if #bufnrs > 1 then ret = string.format("%s%s(%d) ", ret, common, #bufnrs) end

  return ret .. get_diags(bufnrs, hl) .. "%T" .. separator(index)
end

function mega.ui.tabline.render()
  local parts = {} --- @type string[]

  local len = 0

  local sel_start --- @type integer

  for i = 1, fn.tabpagenr("$") do
    local selected = fn.tabpagenr() == i

    local part = cell(i, selected)

    --- @type integer
    local width = api.nvim_eval_statusline(part, { use_tabline = true }).width

    if selected then sel_start = len end

    len = len + width

    -- Make sure the start of the selected tab is always visible
    if sel_start and len > sel_start + vim.o.columns then break end

    parts[#parts + 1] = part
  end
  return table.concat(parts) .. "%#TabLineFill#%="
end

local function hldefs()
  for _, hl_base in ipairs({ "TabLineSel", "TabLineFill" }) do
    local bg = get_hl(hl_base).bg
    for _, ty in ipairs({ "Warn", "Error", "Info", "Hint" }) do
      local hl = get_hl("Diagnostic" .. ty)
      local name = ("Diagnostic%s%s"):format(ty, hl_base)
      api.nvim_set_hl(0, name, { fg = hl.fg, bg = bg })
    end
  end
end

local group = api.nvim_create_augroup("tabline", {})
api.nvim_create_autocmd("ColorScheme", {
  group = group,
  callback = hldefs,
})
hldefs()

-- vim.opt.tabline = "%!v:lua.require'lewis6991.tabline'.tabline()"

vim.opt.tabline = "%!v:lua.mega.ui.tabline.render()"
