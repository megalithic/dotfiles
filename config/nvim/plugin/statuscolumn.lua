if not mega then return end
if not vim.g.enabled_plugin["statuscolumn"] then return end

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

local parts = {
  ["fold"] = "%C",
  ["num"] = "%{v:wrap? '-': (v:relnum?v:relnum:v:lnum)}",
  ["sep"] = "%=",
  ["signcol"] = "%s",
  ["space"] = " ",
}

local order = {
  "diag",
  "sep",
  "num",
  "space",
  "gitsigns",
  "fold",
}

local function mk_hl(group, sym) return table.concat({ "%#", group, "#", sym, "%*" }) end

---@return {name:string, text:string, texthl:string}[]
local function get_signs()
  local buf = vim.api.nvim_win_get_buf(vim.g.statusline_winid or 0)

  return vim.tbl_map(
    function(sign) return vim.fn.sign_getdefined(sign.name)[1] end,
    vim.fn.sign_getplaced(buf, { group = "*", lnum = vim.v.lnum })[1].signs
  )
end

local function prepare_sign(sign)
  if sign then
    dd(mk_hl(sign.texthl, sign.text))
    return mk_hl(sign.texthl, sign.text)
  end

  return "  "
end

function _G.__statuscolumn()
  local str_tbl = {}

  local diag_sign, git_sign
  for _, sign_tbl in ipairs(get_signs()) do
    if sign_tbl.name:find("GitSign") then
      git_sign = sign_tbl
    elseif sign_tbl.name:find("DiagnosticSign") and diag_sign == nil then
      diag_sign = sign_tbl
    end
  end

  parts["diag"] = prepare_sign(diag_sign)
  parts["gitsigns"] = prepare_sign(git_sign)

  for _, val in ipairs(order) do
    table.insert(str_tbl, parts[val])
  end

  -- dd(table.concat(str_tbl))

  return table.concat(str_tbl)
end

-- vim.opt.statuscolumn = "%!v:lua.__statuscolumn()"
vim.opt.statuscolumn = "%C%=%4{&nu ? (&rnu ? (v:lnum == line('.') ? v:lnum . ' ' : v:relnum . ' ') : v:lnum) : ''}%=%s"
