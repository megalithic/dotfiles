-- HT: https://github.com/akinsho/dotfiles/blob/main/.config/nvim/plugin/winbar.lua

if not mega then return end
if not vim.g.enabled_plugin["winbar"] then return end

local contains = vim.tbl_contains
local api = vim.api
local fn = vim.fn
local H = require("mega.utils.highlights")

local M = {}

_G.__winbar = M

-- vim.opt.laststatus = 3
-- vim.opt.winbar = [[%=%#WhiteSpace#%*%#SnapSelect#%f%*%#WhiteSpace#%*]]

-- local function get_filepath_parts()
--   local base = vim.fn.expand("%:~:.:h")
--   local filename = vim.fn.expand("%:~:.:t")
--   local prefix = (vim.fn.empty(base) == 1 or base == ".") and "" or base .. "/"

--   return { base, filename, prefix }
-- end

-- local function update_filepath_highlights()
--   if vim.bo.modified then
--     H.group("StatusLineFilePath", { link = "DiffChange" })
--     H.group("StatusLineNewFilePath", { link = "DiffChange" })
--   else
--     H.group("StatusLineFilePath", { link = "User6" })
--     H.group("StatusLineNewFilePath", { link = "User4" })
--   end

--   return ""
-- end

-- local function filepath()
--   local parts = get_filepath_parts()
--   local prefix = parts[3]
--   local filename = parts[2]

--   update_filepath_highlights()

--   local line = string.format("%s%%*%%#StatusLineFilePath#%s", prefix, filename)

--   if vim.fn.empty(prefix) == 1 and vim.fn.empty(filename) == 1 then line = "%#StatusLineNewFilePath# %f %*" end

--   return string.format("%%4*%s%%*", line)
-- end

-- function M.get_active_winbar()
--   if vim.bo.filetype == "help" or vim.bo.filetype == "man" then return "" end

--   local line = table.concat({
--     "%=",
--     -- '%#WhiteSpace#%*',
--     filepath(),
--     "%*",
--     -- '%#WhiteSpace#%*'
--   })

--   -- return line
--   return "%{%v:lua.require'nvim-navic'.get_location()%}"
-- end

-- function M.get_inactive_winbar()
--   if vim.bo.filetype == "help" or vim.bo.filetype == "man" then return "" end

--   local line = table.concat({
--     "%=",
--     -- '%#WhiteSpace#%*',
--     "%#LineNr#",
--     "%f",
--     "%*",
--     -- '%#WhiteSpace#%*'
--   })

--   return "" --line
-- end

-- function M.active() vim.api.nvim_win_set_option(0, "winbar", [[%!luaeval("__winbar.get_active_winbar()")]]) end

-- function M.inactive() vim.api.nvim_win_set_option(0, "winbar", [[%!luaeval("__winbar.get_inactive_winbar()")]]) end

-- function M.activate()
--   mega.augroup("MyWinbar", {
--     {
--       event = { "WinEnter", "BufEnter" },
--       pattern = { "*" },
--       command = __winbar.active,
--     },
--     {
--       event = { "WinLeave", "BufLeave" },
--       pattern = { "*" },
--       command = __winbar.inactive,
--     },
--   })
-- end

-- __winbar.activate()

-- local blocked_fts = {
--   "NeogitStatus",
--   "DiffviewFiles",
--   "NeogitCommitMessage",
--   "toggleterm",
--   "megaterm",
--   "gitcommit",
--   "DressingInput",
--   "org",
-- }
--
-- local allowed_fts = { "toggleterm", "neo-tree", "megaterm" }
-- local allowed_buftypes = { "terminal" }
--
-- local function set_winbar()
--   mega.foreach(function(w)
--     local buf, win = vim.bo[api.nvim_win_get_buf(w)], vim.wo[w]
--     local bt, ft, is_diff = buf.buftype, buf.filetype, win.diff
--     local ignored = contains(allowed_fts, ft) or contains(allowed_buftypes, bt)
--     if not ignored then
--       if
--         not contains(blocked_fts, ft)
--         and fn.win_gettype(api.nvim_win_get_number(w)) == ""
--         and bt == ""
--         and ft ~= ""
--         and not is_diff
--       then
--         win.winbar = "  %{%v:lua.require'nvim-navic'.get_location()%}"
--       elseif is_diff then
--         win.winbar = nil
--       end
--     end
--   end, api.nvim_tabpage_list_wins(0))
-- end
--
-- mega.augroup("AttachWinbar", {
--   {
--     event = { "BufWinEnter", "TabNew", "TabEnter", "BufEnter", "WinClosed" },
--     desc = "Toggle winbar",
--     command = set_winbar,
--   },
--   {
--     event = { "User" },
--     pattern = { "DiffviewDiffBufRead", "DiffviewDiffBufWinEnter" },
--     desc = "Toggle winbar",
--     command = set_winbar,
--   },
-- })
--
local function hl(group, text) return "%#" .. group .. "#" .. text .. "%*" end

function __get_navic()
  local navic = require("nvim-navic")
  local loc = navic.get_location()
  if loc and #loc > 0 then
    return fmt("   %%#NavicSeparator#> %s  ", navic.get_location())
  else
    return ""
  end
end

function __get_winbar()
  -- local bufnr = vim.api.nvim_get_current_buf()
  -- if vim.bo[bufnr].buftype == "terminal" then
  --   return table.concat({
  --     "terminal",
  --     -- string.match(vim.fn.expand('%'), '//%d+:(%S+)$'),
  --     "%=",
  --     string.format("[%d/%d]", vim.b[bufnr].terminal_index or -1, vim.g.terminal_count or -1),
  --   })
  -- end
  -- return "%f %h%w%m%r %=%(%l,%c%V %= %P%)"
  -- ﬿  
  -- return [[  %m %t %{%v:lua.__get_navic()%}]]
  return [[%{%v:lua.__get_navic()%}]]
end

vim.o.winbar = hl("TabFill", "%{%v:lua.__get_winbar()%}")
