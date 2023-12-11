if not mega then return end
if not vim.g.enabled_plugin["megacolumn"] then return end

local fn, v, api = vim.fn, vim.v, vim.api
local ui, separators = mega.ui, mega.icons.separators
local U = require("mega.utils")

local shade = separators.light_shade_block
local border = separators.thin_block
local SIGN_COL_WIDTH, GIT_COL_WIDTH, space = 2, 1, " "
local fold_opened = "▽" -- '▼'
local fold_closed = "▷" -- '▶'
local active_border_hl = "%#StatusColumnActiveBorder#"
local inactive_border_hl = "%#StatusColumnInactiveBorder#"

vim.opt_local.statuscolumn = ""
ui.statuscolumn = {}

---@param group string
---@param text string
---@return string
local function hl(group, text)
  if group ~= nil and text ~= nil then return "%#" .. group .. "#" .. text .. "%*" end
  return ""
end

local function click(name, item) return "%@v:lua.mega.ui.statuscolumn." .. name .. "@" .. item end

local function get_signs(buf)
  return vim.tbl_map(
    function(sign) return fn.sign_getdefined(sign.name)[1] end,
    fn.sign_getplaced(buf, { group = "*", lnum = v.lnum })[1].signs
  )
end

function ui.statuscolumn.toggle_breakpoint(_, _, _, mods)
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

local function nr(win, _line_count, is_active)
  if v.virtnum < 0 then return shade end -- virtual line
  if v.virtnum > 0 then return space end -- wrapped line
  local num = is_active and (vim.wo[win].relativenumber and not U.empty(v.relnum) and v.relnum or v.lnum) or v.lnum
  local lnum = fn.substitute(num, "\\d\\zs\\ze\\" .. "%(\\d\\d\\d\\)\\+$", ",", "g")
  local num_width = (vim.wo[win].numberwidth - 1) - api.nvim_strwidth(lnum)
  local padding = string.rep(space, num_width)
  -- not using right now.. StatusColumnActiveLineNr
  local lnum_hl = is_active and "" or "StatusColumnInactiveLineNr"
  local highlighted_lnum = hl(lnum_hl, padding .. lnum)
  return click("toggle_breakpoint", highlighted_lnum)
end

local function sep(is_active)
  local separator_hl = ""
  if is_active then
    separator_hl = v.virtnum >= 0 and U.empty(v.relnum) and active_border_hl or ""
  else
    separator_hl = inactive_border_hl
  end

  return separator_hl .. border
end

function ui.statuscolumn.render(is_active)
  local curwin = api.nvim_get_current_win()
  local curbuf = api.nvim_win_get_buf(curwin)

  local line_count = api.nvim_buf_line_count(curbuf)

  local sign, git_sign
  for _, s in ipairs(get_signs(curbuf)) do
    if s.name:find("GitSign") then
      git_sign = s
    else
      sign = s
    end
  end

  local components = {
    "%=",
    space,
    sign ~= nil and hl(sign.numhl, (sign.text ~= nil and sign.text:gsub(space, "")) or "") or space,
    git_sign ~= nil and hl(git_sign.texthl, git_sign.text:gsub(space, "")) or space,
    fdm(),
    nr(curwin, line_count, is_active),
    sep(is_active),
    space,
  }

  if is_active then
    return table.concat(components, "")
  else
    return table.concat({
      "%=",
      space,
      space,
      space,
      space,
      nr(curwin, line_count, is_active),
      sep(is_active),
      space,

      -- FULLY EMPTY STATUSCOLUMN
      -- "%=",
      -- space,
      -- space,
      -- space,
      -- space,
      -- space,
      -- space,
      -- space,
      -- space,
      -- space,
    }, "")
  end
end

local excluded = {
  "NeogitCommitMessage",
  "NeogitCommitView",
  "NeogitRebaseTodo",
  "NeogitStatus",
  "NvimTree",
  "Trouble",
  "dap-repl",
  "fidget",
  "firenvim",
  "fugitive",
  "gitcommit",
  "help",
  "himalaya",
  "lazy",
  "list",
  "log",
  "man",
  "megaterm",
  "neo-tree",
  "neotest-summary",
  "oil",
  "org",
  "orgagenda",
  "outputpanel",
  "qf",
  "quickfix",
  "quickfixlist",
  "startify",
  "telescope",
  "TelescopePrompt",
  "TelescopeResults",
  "terminal",
  "toggleterm",
  "undotree",
  "vim-plug",
  "vimwiki",
}

function mega.set_statuscolumn(bufnr, is_active)
  local statuscolumn = ""
  if is_active then
    statuscolumn = [[%!v:lua.mega.ui.statuscolumn.render(v:true)]]
  else
    statuscolumn = [[%!v:lua.mega.ui.statuscolumn.render(v:false)]]
  end

  if vim.api.nvim_buf_is_valid(bufnr) then
    local buf = vim.bo[bufnr]
    if buf.bt ~= "" or vim.tbl_contains(excluded, buf.ft) then
      vim.opt_local.statuscolumn = ""
    else
      vim.opt_local.statuscolumn = statuscolumn
    end
  else
    vim.opt_local.statuscolumn = statuscolumn
  end
end

mega.augroup("MegaColumn", {
  {
    event = { "BufEnter", "BufReadPost", "FileType", "FocusGained", "WinEnter", "TermLeave" },
    command = function(args) mega.set_statuscolumn(args.buf, true) end,
  },
  {
    event = { "BufLeave", "WinLeave", "FocusLost" },
    command = function(args) mega.set_statuscolumn(args.buf, false) end,
  },
  -- {
  --   event = { "BufWinLeave" },
  --   command = function(args) mega.set_statuscolumn(args.buf, false) end,
  -- },
})
