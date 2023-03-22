if not mega then return end
if not vim.g.enabled_plugin["megacolumn"] then return end
--
local fn, v, api = vim.fn, vim.v, vim.api
local ui, separators = mega.ui, mega.icons.separators

local space = " "
local shade = separators.light_shade_block
local separator = separators.left_thin_block -- '│'
-- local SIGN_COL_WIDTH, GIT_COL_WIDTH, space = 2, 1, ' '
-- local fcs = vim.opt.fillchars:get()
local fold_opened = "▽" -- '▼'
local fold_closed = "▷" -- '▶'
local sep_hl = "%#StatusColSep#"

ui.statuscolumn = {}

---@param group string
---@param text string
---@return string
local function hl(group, text) return "%#" .. group .. "#" .. text .. "%*" end

local function click(name, item) return "%@v:lua.mega.ui.statuscolumn." .. name .. "@" .. item end

---@param buf number
---@return {name:string, text:string, texthl:string}[]
local function get_signs(buf)
  return vim.tbl_map(function(sign)
    local signs = fn.sign_getdefined(sign.name)[1]
    for _, s in ipairs(signs) do
      if s.text then s.text = s.text:gsub("%s", "") end
    end
    return signs
  end, fn.sign_getplaced(buf, { group = "*", lnum = v.lnum })[1].signs)
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

local function nr(win)
  if v.virtnum < 0 then return shade end -- virtual line
  if v.virtnum > 0 then return space end -- wrapped line
  local num = vim.wo[win].relativenumber and not mega.empty(v.relnum) and v.relnum or v.lnum
  local lnum = fn.substitute(num, "\\d\\zs\\ze\\" .. "%(\\d\\d\\d\\)\\+$", ",", "g")
  local num_width = (vim.wo[win].numberwidth - 1) - api.nvim_strwidth(lnum)
  local padding = string.rep(space, num_width)
  return click("toggle_breakpoint", padding .. lnum)
end

local function sep()
  local separator_hl = v.virtnum >= 0 and mega.empty(v.relnum) and sep_hl or ""
  return separator_hl .. separator
end

function ui.statuscolumn.render()
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
    "%=",
    space,
    nr(curwin),
    space,
    sign and hl(sign.texthl, sign.text:gsub(space, "")) or space,
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
  "lazy",
  "dirbuf",
  "fzf",
  "fzflua",
  "fzf-lua",
  "startify",
  "help",
  "orgagenda",
  "org",
  "himalaya",
  "Trouble",
  "NeogitCommitMessage",
  "NeogitRebaseTodo",
  "qf",
  "quickfixlist",
  "quickfix",
}

-- vim.o.statuscolumn = "%{%v:lua.mega.ui.statuscolumn.render()%}"
vim.opt.statuscolumn = [[%!v:lua.mega.ui.statuscolumn.render()]]

mega.augroup("MegaColumn", {
  {
    event = { "BufEnter", "FileType", "WinEnter" },
    command = function(args)
      local buf = vim.bo[args.buf]
      if buf.bt ~= "" or vim.tbl_contains(excluded, buf.ft) then vim.opt_local.statuscolumn = "" end
    end,
  },
})
