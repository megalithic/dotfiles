if not mega then return end
if not vim.g.enabled_plugin["megacolumn"] then return end

-- _G.StatusColumn = {
--   handler = {
--     fold = function()
--       local lnum = vim.fn.getmousepos().line
--
--       -- Only lines with a mark should be clickable
--       if vim.fn.foldlevel(lnum) <= vim.fn.foldlevel(lnum - 1) then return end
--
--       local state
--       if vim.fn.foldclosed(lnum) == -1 then
--         state = "close"
--       else
--         state = "open"
--       end
--
--       vim.cmd.execute("'" .. lnum .. "fold" .. state .. "'")
--     end,
--   },
--   display = {
--     fold = function()
--       local lnum = vim.v.lnum
--       local icon = "  "
--
--       -- Line isn't in folding range
--       if vim.fn.foldlevel(lnum) <= 0 then return icon end
--
--       -- Not the first line of folding range
--       if vim.fn.foldlevel(lnum) <= vim.fn.foldlevel(lnum - 1) then return icon end
--
--       if vim.fn.foldclosed(lnum) == -1 then
--         icon = Icons.misc.expanded
--       else
--         icon = Icons.misc.collapsed
--       end
--
--       return icon
--     end,
--   },
-- }
--
-- local sign_column = {
--   [[%s]],
-- }
--
-- -- vim.v.wrap
-- local line_number = {
--   [[%=%{v:wrap ? "" : v:lnum}]],
-- }
--
-- local spacing = {
--   [[ ]],
-- }
--
-- local folds = {
--   [[%#FoldColumn#]], -- HL
--   [[%@v:lua.StatusColumn.handler.fold@]],
--   [[%{v:lua.StatusColumn.display.fold()}]],
-- }
--
-- local border = {
--   [[%#StatusColumnBorder#]], -- HL
--   [[▐]],
-- }
--
-- local padding = {
--   [[%#StatusColumnBuffer#]], -- HL
--   [[ ]],
-- }
--
-- local function build_statuscolumn(tbl)
--   local statuscolumn = {}
--
--   for _, value in ipairs(tbl) do
--     if type(value) == "string" then
--       table.insert(statuscolumn, value)
--     elseif type(value) == "table" then
--       table.insert(statuscolumn, build_statuscolumn(value))
--     end
--   end
--
--   return table.concat(statuscolumn)
-- end
--
-- vim.opt.statuscolumn = build_statuscolumn({ sign_column, line_number, spacing, folds, border, padding })
--
-- vim.o.statuscolumn =
--   [[%s%=%{v:wrap ? "" : v:lnum} %#FoldColumn#%@v:lua.StatusColumn.handler.fold@%{v:lua.StatusColumn.display.fold()}%#StatusColumnBorder#▐%#StatusColumnBuffer#]]
--

-- local M = {}
--
-- ---@return {name:string, text:string, texthl:string}[]
-- function M.get_signs()
--   local buf = vim.api.nvim_win_get_buf(vim.g.statusline_winid)
--   return vim.tbl_map(
--     function(sign) return vim.fn.sign_getdefined(sign.name)[1] end,
--     vim.fn.sign_getplaced(buf, { group = "*", lnum = vim.v.lnum })[1].signs
--   )
-- end

-- function _G.__statuscolumn()
--   local sign, git_sign
--   for _, s in ipairs(M.get_signs()) do
--     if s.name:find("GitSign") then
--       git_sign = s
--     else
--       sign = s
--     end
--   end
--
--   local nu = " "
--   local number = vim.api.nvim_win_get_option(vim.g.statusline_winid, "number")
--   if number and vim.wo.relativenumber and vim.v.virtnum == 0 then
--     nu = vim.v.relnum == 0 and vim.v.lnum or vim.v.relnum
--   end
--   local components = {
--     sign and ("%#" .. sign.texthl .. "#" .. sign.text .. "%*") or " ",
--     [[%=]],
--     nu .. " ",
--     git_sign and ("%#" .. git_sign.texthl .. "#" .. git_sign.text .. "%*") or "  ",
--   }
--   return table.concat(components, "")
-- end
-- vim.opt.statuscolumn = [[%!v:lua.__statuscolumn()]]
-- return M

-- local parts = {
--   ["fold"] = "%C",
--   ["num"] = "%{v:wrap? '-': (v:relnum?v:relnum:v:lnum)}",
--   ["sep"] = "%=",
--   ["signcol"] = "%s",
--   ["space"] = " ",
-- }
--
-- local order = {
--   "diag",
--   "sep",
--   "num",
--   "space",
--   "gitsigns",
--   "fold",
-- }
--
-- local function mk_hl(group, sym) return table.concat({ "%#", group, "#", sym, "%*" }) end
--
-- ---@return {name:string, text:string, texthl:string}[]
-- local function get_signs()
--   local buf = vim.api.nvim_win_get_buf(vim.g.statusline_winid or 0)
--
--   return vim.tbl_map(
--     function(sign) return vim.fn.sign_getdefined(sign.name)[1] end,
--     vim.fn.sign_getplaced(buf, { group = "*", lnum = vim.v.lnum })[1].signs
--   )
-- end
--
-- local function prepare_sign(sign)
--   if sign then
--     dd(mk_hl(sign.texthl, sign.text))
--     return mk_hl(sign.texthl, sign.text)
--   end
--
--   return "  "
-- end
--
-- function _G.__statuscolumn()
--   local str_tbl = {}
--
--   local diag_sign, git_sign
--   for _, sign_tbl in ipairs(get_signs()) do
--     if sign_tbl.name:find("GitSign") then
--       git_sign = sign_tbl
--     elseif sign_tbl.name:find("DiagnosticSign") and diag_sign == nil then
--       diag_sign = sign_tbl
--     end
--   end
--
--   parts["diag"] = prepare_sign(diag_sign)
--   parts["gitsigns"] = prepare_sign(git_sign)
--
--   for _, val in ipairs(order) do
--     table.insert(str_tbl, parts[val])
--   end
--
--   -- dd(table.concat(str_tbl))
--
--   return table.concat(str_tbl)
-- end
--
-- -- vim.opt.statuscolumn = "%!v:lua.__statuscolumn()"
-- vim.opt.statuscolumn = "%C%=%4{&nu ? (&rnu ? (v:lnum == line('.') ? v:lnum . ' ' : v:relnum . ' ') : v:lnum) : ''}%=%s"
--
-- -- @ref https://github.com/folke/dot/blob/master/config/nvim/lua/util/status.lua (modified)
-- local M = {}
-- _G.Status = M
--
-- ---@return {name:string, text:string, texthl:string}[]
-- function M.get_signs()
--   local buf = vim.api.nvim_win_get_buf(vim.g.statusline_winid)
--   return vim.tbl_map(
--     function(sign) return vim.fn.sign_getdefined(sign.name)[1] end,
--     vim.fn.sign_getplaced(buf, { group = "*", lnum = vim.v.lnum })[1].signs
--   )
-- end
--
-- function M.statuscolumn()
--   local diagnostic_sign, git_sign
--
--   for _, s in ipairs(M.get_signs()) do
--     if s.name:find("GitSign") then
--       git_sign = s
--     elseif s.name:find("Diagnostic") then
--       diagnostic_sign = s
--     end
--   end
--
--   local space = " "
--
--   local nu = space
--   local number = vim.api.nvim_win_get_option(vim.g.statusline_winid, "number")
--   if number and vim.wo.relativenumber and vim.v.virtnum == 0 then
--     nu = vim.v.relnum == 0 and vim.v.lnum or vim.v.relnum
--   end
--
--   -- the sign text (icon) strings all have an extra space at the end, so :sub(1, -2) removes that (allows for thinner statuscolumn)
--   local git_column = git_sign and ("%#" .. git_sign.texthl .. "#" .. git_sign.text:sub(1, -2) .. "%*") or space
--   local diagnostic_column = diagnostic_sign
--       and ("%#" .. diagnostic_sign.texthl .. "#" .. diagnostic_sign.text:sub(1, -2) .. "%*")
--     or space
--   -- right-aligned number column (thanks to the %=)
--   -- %= @ref :h statusline "Separation point between alignment sections. Each section will be separated by an equal number of spaces"
--   local number_column = "%=" .. nu .. space
--   -- local fold_column = space .. "%C" .. space -- make sure fold column is set to "1" if this is used
--   local fold_column = "%C" -- make sure fold column is set to "1" if this is used
--
--   local columns = {
--     diagnostic_column,
--     number_column,
--     git_column,
--     fold_column,
--   }
--
--   return table.concat(columns, "")
-- end
--
-- if vim.fn.has("nvim-0.9.0") == 1 then
--   vim.opt.foldcolumn = "1"
--   vim.opt.statuscolumn = [[%!v:lua.Status.statuscolumn()]]
-- end
--
-- return M
--
-- local fn, v = vim.fn, vim.v

-- mega.statuscolumn = {
--   separator = "│",
-- }
--
-- function mega.statuscolumn.fdm()
--   local is_folded = fn.foldlevel(v.lnum) > fn.foldlevel(v.lnum - 1)
--   return is_folded and (fn.foldclosed(v.lnum) == -1 and "▼" or " ") or " " --⏵
-- end
--
-- function mega.statuscolumn.nr() return (not mega.empty(v.relnum) and v.relnum or v.lnum) end
--
-- local excluded = {
--   "neo-tree",
--   "NeogitStatus",
--   "NeogitCommitMessage",
--   "undotree",
--   "log",
--   "man",
--   "dap-repl",
--   "markdown",
--   "vimwiki",
--   "vim-plug",
--   "gitcommit",
--   "toggleterm",
--   "fugitive",
--   "list",
--   "NvimTree",
--   "startify",
--   "help",
--   "orgagenda",
--   "org",
--   "himalaya",
--   "Trouble",
--   "NeogitCommitMessage",
--   "NeogitRebaseTodo",
-- }
--
-- vim.o.statuscolumn = " %=%{v:lua.mega.statuscolumn.nr()} │ %s%{v:lua.mega.statuscolumn.fdm()} " -- %C for folds
--
-- mega.augroup("StatusCol", {
--   {
--     event = { "BufEnter", "FileType" },
--     command = function(args)
--       local buf = vim.bo[args.buf]
--       if buf.bt ~= "" or vim.tbl_contains(excluded, buf.ft) then vim.opt_local.statuscolumn = "" end
--     end,
--   },
-- })
--

local fn, v, api = vim.fn, vim.v, vim.api

local space = " "
local shade = "░"
local separator = "▏" -- '│'
local fold_opened = "▼"
local fold_closed = "▶"
local sep_hl = "%#StatusColSep#"

mega.statuscolumn = {}

---@param group string
---@param text string
---@return string
local function hl(group, text) return "%#" .. group .. "#" .. text .. "%*" end

local function click(name, item) return "%@v:lua.mega.statuscolumn." .. name .. "@" .. item end

---@param buf number
---@return {name:string, text:string, texthl:string}[]
local function get_signs(buf)
  return vim.tbl_map(
    function(sign) return fn.sign_getdefined(sign.name)[1] end,
    fn.sign_getplaced(buf, { group = "*", lnum = v.lnum })[1].signs
  )
end

function mega.statuscolumn.toggle_breakpoint(_, _, _, mods)
  local ok, dap = pcall(require, "dap")
  if not ok then return end
  if mods:find("c") then
    vim.ui.input({ prompt = "Breakpoint condition: " }, function(input) dap.set_breakpoint(input) end)
  else
    dap.toggle_breakpoint()
  end
end

local function fdm()
  if fn.foldlevel(v.lnum) <= fn.foldlevel(v.lnum - 1) then return space end
  return fn.foldclosed(v.lnum) == -1 and fold_closed or fold_opened
end

local function is_virt_line() return v.virtnum < 0 end

local function nr(win)
  if is_virt_line() then return shade end -- virtual line
  local num = vim.wo[win].relativenumber and not mega.empty(v.relnum) and v.relnum or v.lnum
  local lnum = fn.substitute(num, "\\d\\zs\\ze\\" .. "%(\\d\\d\\d\\)\\+$", ",", "g")
  local num_width = (vim.wo[win].numberwidth - 1) - api.nvim_strwidth(lnum)
  local padding = string.rep(space, num_width)
  return click("toggle_breakpoint", padding .. lnum)
end

local function sep()
  local separator_hl = not is_virt_line() and mega.empty(v.relnum) and sep_hl or ""
  return separator_hl .. separator
end

function mega.statuscolumn.render()
  local curwin = api.nvim_get_current_win()
  local curbuf = api.nvim_win_get_buf(curwin)

  local sign, git_sign
  for _, s in ipairs(get_signs(curbuf)) do
    if s.name:find("GitSign") then
      git_sign = s
    else
      sign = s
    end
  end
  local components = {
    sign and hl(sign.texthl, sign.text:gsub(space, "")) or space,
    "%=",
    space,
    nr(curwin),
    space,
    git_sign and hl(git_sign.texthl, git_sign.text:gsub(space, "")) or space,
    sep(),
    fdm(),
    space,
  }
  return table.concat(components, "")
end

local excluded = {
  "neo-tree",
  "NeogitStatus",
  "NeogitCommitMessage",
  "undotree",
  "log",
  "man",
  "dap-repl",
  "markdown",
  "vimwiki",
  "vim-plug",
  "gitcommit",
  "toggleterm",
  "fugitive",
  "list",
  "NvimTree",
  "startify",
  "help",
  "orgagenda",
  "org",
  "himalaya",
  "Trouble",
  "NeogitCommitMessage",
  "NeogitRebaseTodo",
}

vim.o.statuscolumn = "%{%v:lua.mega.statuscolumn.render()%}"

mega.augroup("StatusCol", {
  {
    event = { "BufEnter", "FileType" },
    command = function(args)
      local buf = vim.bo[args.buf]
      if buf.bt ~= "" or vim.tbl_contains(excluded, buf.ft) then vim.opt_local.statuscolumn = "" end
    end,
  },
})
