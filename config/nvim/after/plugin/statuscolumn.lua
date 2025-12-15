if not Plugin_enabled() then
  -- vim.o.statuscolumn = "%C%=%4{&nu && v:virtnum <= 0 ? (&rnu ? (v:lnum == line('.') ? v:lnum . ' ' : v:relnum) : v:lnum) : ''}%=%s"
  vim.o.statuscolumn =
    [[%C%=%4{&nu && v:virtnum <= 0 ? (&rnu ? (v:lnum == line('.') ? v:lnum . ' ' : v:relnum) : v:lnum) : ''}%{foldlevel(v:lnum) > foldlevel(v:lnum - 1) ? (foldclosed(v:lnum) == -1 ? "" : "") : " " }%=%s]]
  -- vim.o.statuscolumn = '%{foldlevel(v:lnum) > foldlevel(v:lnum - 1) ? (foldclosed(v:lnum) == -1 ? "" : "") : " " }%l%s'
  return
end

mega.ui.statuscolumn = {}

---@alias StringComponent {component: string, length: integer, priority: integer}
---@alias ExtmarkSign {[1]: number, [2]: number, [3]: number, [4]: {sign_text: string, sign_hl_group: string}}

local fn, v, api, opt = vim.fn, vim.v, vim.api, vim.opt
local U = require("config.utils")
local sep = Icons.separators
local strwidth = vim.api.nvim_strwidth
local fmt = string.format

local MIN_SIGN_WIDTH, space = 1, " "
local fcs = opt.fillchars:get()
local shade = sep.light_shade_block

local CLICK_END = "%X"
local padding = " "

local excluded_bts = { "terminal", "nofile", "input", "prompt" }
local excluded_fts = {
  "NeogitCommitMessage",
  "NeogitCommitView",
  "cmdline",
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
  "prompt",
  "cmd",
  "msg",
  "pager",
  "dialog",
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
  "snacks",
}

local should_hide_numbers = function(filetype, buftype)
  return vim.tbl_contains(excluded_fts, filetype) or vim.tbl_contains(excluded_bts, buftype)
end

---@return StringComponent
local function separator() return { component = "%=", length = 0, priority = 0 } end

---@param func_name string
---@param id string
---@return string
local function get_click_start(func_name, id)
  if not id then
    vim.schedule(function()
      local msg = fmt("An ID is needed to enable click handler %s to work", func_name)
      vim.notify_once(msg, L.ERROR, { title = "Statusline" })
    end)
    return ""
  end
  return ("%%%d@%s@"):format(id, func_name)
end

--- Creates a spacer statusline component i.e. for padding
--- or to represent an empty component
--- @param size integer?
--- @param opts table<string, any>?
--- @return ComponentOpts?
local function spacer(size, opts)
  opts = opts or {}
  local filler = opts.filler or " "
  local priority = opts.priority or 0
  if not size or size < 1 then return end
  local spc = string.rep(filler, size)
  return { { { spc } }, priority = priority, before = "", after = "" }
end

--- truncate with an ellipsis or if surrounded by quotes, replace contents of quotes with ellipsis
--- @param str string
--- @param max_size integer
--- @return string
local function truncate_str(str, max_size)
  if not max_size or strwidth(str) < max_size then return str end
  local match, count = str:gsub("(['\"]).*%1", "%1…%1")
  return count > 0 and match or str:sub(1, max_size - 1) .. "…"
end

---@alias Chunks {[1]: string | number, [2]: string, max_size: integer?}[]

---@param chunks Chunks
---@return string
local function chunks_to_string(chunks)
  if not chunks or not vim.islist(chunks) then return "" end
  local strings = U.fold(function(acc, item)
    local text, hl = unpack(item)
    if not U.falsy(text) then
      if type(text) ~= "string" then text = tostring(text) end
      if item.max_size then text = truncate_str(text, item.max_size) end
      text = text:gsub("%%", "%%%1")
      table.insert(acc, not U.falsy(hl) and ("%%#%s#%s%%*"):format(hl, text) or text)
    end

    return acc
  end, chunks, {})
  return table.concat(strings)
end

--- @class ComponentOpts
--- @field [1] Chunks
--- @field priority number
--- @field click string
--- @field before string
--- @field after string
--- @field id number
--- @field max_size integer
--- @field cond boolean | number | table | string,

--- @param opts ComponentOpts
--- @return StringComponent?
local function component(opts)
  assert(opts, "component options are required")
  if opts.cond ~= nil and U.falsy(opts.cond) then return end

  local item = opts[1]
  if not vim.islist(item) then error(fmt("component options are required but got %s instead", vim.inspect(item))) end

  if not opts.priority then opts.priority = 10 end
  local before, after = opts.before or "", opts.after or padding

  local item_str = chunks_to_string(item)
  if strwidth(item_str) == 0 then return end

  local click_start = opts.click and get_click_start(opts.click, tostring(opts.id)) or ""
  local click_end = opts.click and CLICK_END or ""
  local component_str = table.concat({ click_start, before, item_str, after, click_end })
  return {
    component = component_str,
    length = api.nvim_eval_statusline(component_str, { maxwidth = 0 }).width,
    priority = opts.priority,
  }
end

local function sum_lengths(list)
  return U.fold(function(acc, item) return acc + (item.length or 0) end, list, 0)
end

local function is_lowest(item, lowest)
  -- if there hasn't been a lowest selected so far, then the item is the lowest
  if not lowest or not lowest.length then return true end
  -- if the item doesn't have a priority or a length, it is likely a special character so should never be the lowest
  if not item.priority or not item.length then return false end
  -- if the item has the same priority as the lowest, then if the item has a greater length it should become the lowest
  if item.priority == lowest.priority then return item.length > lowest.length end
  return item.priority > lowest.priority
end

--- Take the lowest priority items out of the statusline if we don't have
--- space for them.
--- TODO: currently this doesn't account for if an item that has a lower priority
--- could be fit in instead
--- @param statusline table
--- @param spc number
--- @param length number
local function prioritize(statusline, spc, length)
  length = length or sum_lengths(statusline)
  if length <= spc then return statusline end
  local lowest, index_to_remove
  for idx, c in ipairs(statusline) do
    if is_lowest(c, lowest) then
      lowest, index_to_remove = c, idx
    end
  end
  table.remove(statusline, index_to_remove)
  return prioritize(statusline, spc, length - lowest.length)
end

--- @param sections ComponentOpts[][]
--- @param available_space number?
--- @return string
local function display(sections, available_space)
  local components = U.fold(function(acc, section, count)
    if #section == 0 then
      table.insert(acc, separator())
      return acc
    end
    U.foreach(function(args, index)
      if not args then return end
      local ok, str = U.pcall("Error creating component", component, args)
      if not ok then return end
      table.insert(acc, str)
      if #section == index and count ~= #sections then table.insert(acc, separator()) end
    end, section)
    return acc
  end, sections)

  local items = available_space and prioritize(components, available_space) or components
  local str = vim.tbl_map(function(item) return item.component end, items)
  return table.concat(str)
end

--- A helper class that allow collecting `...StringComponent`
--- into sections that can then be added to each other
--- i.e.
--- ```lua
--- section1:new(1, 2, 3) + section2:new(4, 5, 6) + section3(7, 8, 9)
--- {1, 2, 3, 4, 5, 6, 7, 8, 9} -- <--
--- ```
---@class Section
---@field __add fun(l:Section, r:Section): StringComponent[]
---@field __index Section
---@field new fun(...:StringComponent[]): Section
local section = {}
function section:new(...)
  local o = { ... }
  self.__index = self
  self.__add = function(l, r)
    local rt = { unpack(l) }
    for _, v in ipairs(r) do
      rt[#rt + 1] = v
    end
    return rt
  end
  return setmetatable(o, self)
end

local function fdm(lnum)
  if fn.foldlevel(lnum) <= fn.foldlevel(lnum - 1) then return space end
  return fn.foldclosed(lnum) == -1 and fcs.foldopen or fcs.foldclose
end

local function get_num_wraps(winnr)
  -- Calculate the actual buffer width, accounting for splits, number columns, and other padding
  -- local wrapped_lines = vim.api.nvim_win_call(winnr or 0, function()
  local wrapped_lines = vim.api.nvim_win_call(winnr or 0, function()
    -- local winid = vim.api.nvim_get_current_win()

    -- get the width of the buffer
    local winwidth = vim.api.nvim_win_get_width(winnr)
    local numberwidth = vim.wo.number and vim.wo.numberwidth or 0
    local signwidth = vim.fn.exists("*sign_define") == 1 and vim.fn.sign_getdefined() and 2 or 0
    local foldwidth = vim.wo.foldcolumn or 0

    -- subtract the number of empty spaces in your statuscol. I have
    -- four extra spaces in mine, to enhance readability for me
    local bufferwidth = winwidth - numberwidth - signwidth - foldwidth - 4

    -- fetch the line and calculate its display width
    local line = vim.fn.getline(vim.v.lnum)

    -- subtract one to solve issue where the cursor is right on the edge of a line
    -- and makes it so that the last line should be the end of the wraps but isn't
    local line_length = vim.fn.strdisplaywidth(line) - 1

    return math.floor(line_length / bufferwidth)
  end)

  return wrapped_lines
end

local function draw_wrap_symbols(winnr, virtnum, col_width)
  local num_wraps = get_num_wraps(winnr)
  local mode = vim.fn.mode()
  local normalized_mode = vim.fn.strtrans(mode):lower():gsub("%W", "")
  local line = ""

  if virtnum == num_wraps then
    line = "└"
  else
    line = "│"
  end

  if normalized_mode == "v" then
    local pos_list = vim.fn.getregionpos(vim.fn.getpos("v"), vim.fn.getpos("."), { type = mode, eol = true })
    local s_row, e_row = pos_list[1][1][2], pos_list[#pos_list][2][2]
    if vim.v.lnum >= s_row and vim.v.lnum <= e_row then return line, "CursorLineNr" end
  end

  if vim.fn.line(".") == vim.v.lnum then
    return line, "CursorLineNr"
  else
    return line, "LineNr"
  end
end

---@param win integer
---@param line_count integer
---@param lnum integer
---@param relnum integer
---@param virtnum integer
---@return string
local function nr(win, lnum, relnum, virtnum, line_count)
  local col_width = api.nvim_strwidth(tostring(line_count))
  -- local num_wraps = get_num_wraps()
  -- dbg(num_wraps)

  -- if virtnum and virtnum ~= 0 then
  --   return space:rep(col_width - 1) .. (virtnum < 0 and shade or space)
  -- end -- virtual line

  if virtnum and virtnum ~= 0 then
    local line, hl = draw_wrap_symbols(win, virtnum, col_width)

    return line -- virtual line
  end

  local num = vim.wo[win].relativenumber and not U.falsy(relnum) and relnum or lnum
  if line_count > 999 then col_width = col_width + 1 end
  local ln = tostring(num):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
  local num_width = col_width - api.nvim_strwidth(ln)
  return string.rep(space, num_width) .. ln
end

---@generic T:table<string, any>
---@param t T the object to format
---@param k string the key to format
---@return T?
local function format_text(t, k)
  if t == nil then return end
  local txt = (t and t[k]) and t[k]:gsub("%s", "") or ""
  if #txt < 1 then return end
  t[k] = txt
  return t
end

---@param curbuf integer
---@return StringComponent[], StringComponent[]
local function extmark_signs(curbuf, lnum)
  lnum = lnum - 1
  ---@type ExtmarkSign[]
  local signs = api.nvim_buf_get_extmarks(curbuf, -1, { lnum, 0 }, { lnum, -1 }, { details = true, type = "sign" })
  local sns = U.fold(function(acc, item)
    item = format_text(item[4], "sign_text")
    if not item then return acc end

    local txt, hl = item.sign_text, item.sign_hl_group
    -- if txt ~= "" and txt ~= " " then print(txt) end
    local is_git = hl ~= nil and hl:match("^Git")

    -- NOTE: use this so we can check if it's an nvim-lint sign; we'll use our own signs
    -- FIXME: do this in nvim-lint config instead with their vim.diagnostic.config settings
    local is_lint = string.find(txt, "[EWHI]+", 1) ~= nil

    local target = is_git and acc.git or acc.other
    -- table.insert(target, { { { txt, hl } }, after = "" })
    if not is_lint then table.insert(target, { { { txt, hl } }, after = "" }) end

    return acc
  end, signs, { git = {}, other = {} })
  if #sns.git == 0 then sns.git = { spacer(1) } end
  return sns.git, sns.other
end

function mega.ui.statuscolumn.render(is_active)
  local lnum, relnum, virtnum = v.lnum, v.relnum, v.virtnum
  local winnr = api.nvim_get_current_win()
  local bufnr = api.nvim_win_get_buf(winnr)
  local line_count = api.nvim_buf_line_count(bufnr)
  local is_actively_folding = is_active and vim.o.foldlevel > 0

  local git_signs, other_signs = extmark_signs(bufnr, lnum)

  while #other_signs < MIN_SIGN_WIDTH do
    table.insert(other_signs, spacer(1))
  end

  local r1_hl = is_active and "" or "StatusColumnInactiveLineNr"

  local ln_col = { nr(winnr, lnum, relnum, virtnum, line_count), r1_hl }
  local fold_col = {
    {
      { fdm(lnum), "FoldColumn" },
    },
  }

  local r1 = is_active and section:new(spacer(1), {
    {
      ln_col,
    },
  }, unpack(git_signs), spacer(1)) or section:new(spacer(1), {
    {
      ln_col,
    },
  }, spacer(2))

  local r2 = section:new({
    {
      { "", "LineNr" },
    },
    after = "",
  }, spacer(2))
  -- }, is_actively_folding and fold_col or spacer(2))

  if is_active then
    return display({
      section:new(spacer(1)),
      other_signs,
      r1 + r2,
    })
  else
    return display({
      section:new(spacer(2)),
      r1 + r2,
    })
  end
end

function mega.ui.statuscolumn.set(bufnr, is_active)
  local statuscolumn = ""

  if is_active then
    statuscolumn = [[%!v:lua.mega.ui.statuscolumn.render(v:true)]]
  else
    statuscolumn = [[%!v:lua.mega.ui.statuscolumn.render(v:false)]]
  end

  local buftype = vim.bo[bufnr].buftype
  local filetype = vim.bo[bufnr].filetype

  if should_hide_numbers(filetype, buftype) then
    vim.opt_local.statuscolumn = ""
    -- vim.api.nvim_buf_call(bufnr, function() vim.opt.statuscolumn = "" end)
  else
    vim.opt_local.statuscolumn = statuscolumn
    -- vim.api.nvim_buf_call(bufnr, function() vim.opt.statuscolumn = statuscolumn end)
  end
end

Augroup("mega_mvim.ui.statuscolumn", {
  {
    -- event = { "BufEnter", "BufReadPost", "FileType", "FocusGained", "BufWinEnter", "TermLeave", "WinNew", "TermOpen" },
    event = { "BufEnter", "BufReadPost", "FileType", "FocusGained", "WinEnter", "TermLeave" },
    command = function(args) mega.ui.statuscolumn.set(args.buf, true) end,
  },
  {
    event = { "BufLeave", "WinLeave", "FocusLost" },
    command = function(args) mega.ui.statuscolumn.set(args.buf, false) end,
  },
})
