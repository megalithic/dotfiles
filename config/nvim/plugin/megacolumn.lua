if not mega then return end
if not vim.g.enabled_plugin["megacolumn"] then return end

local fn, v, api = vim.fn, vim.v, vim.api
local ui, separators = mega.ui, mega.icons.separators

local shade = separators.light_shade_block
local border = separators.thin_block
local SIGN_COL_WIDTH, GIT_COL_WIDTH, space = 2, 1, " "
local fold_opened = "▽" -- '▼'
local fold_closed = "▷" -- '▶'
local active_border_hl = "%#StatusColumnActiveBorder#"
local inactive_border_hl = "%#StatusColumnInactiveBorder#"

ui.statuscolumn = {}

---@param group string
---@param text string
---@return string
local function hl(group, text) return "%#" .. group .. "#" .. text .. "%*" end

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
  local num = is_active and (vim.wo[win].relativenumber and not mega.empty(v.relnum) and v.relnum or v.lnum)
    or v.lnum
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
    separator_hl = v.virtnum >= 0 and mega.empty(v.relnum) and active_border_hl or ""
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
    sign and hl(sign.texthl, sign.text:gsub(space, "")) or space,
    git_sign and hl(git_sign.texthl, git_sign.text:gsub(space, "")) or space,
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
  "neo-tree",
  "NeogitStatus",
  "NeogitCommitMessage",
  "undotree",
  "log",
  "man",
  "dap-repl",
  "vimwiki",
  "vim-plug",
  "gitcommit",
  "toggleterm",
  "fugitive",
  "terminal",
  "firenvim",
  "megaterm",
  "list",
  "NvimTree",
  "lazy",
  "oil",
  "startify",
  "help",
  "orgagenda",
  "org",
  "himalaya",
  "Trouble",
  "NeogitCommitMessage",
  "NeogitRebaseTodo",
  "neotest-summary",
  "qf",
  "quickfixlist",
  "quickfix",
}

mega.augroup("MegaColumn", {
  {
    event = { "BufEnter", "FileType", "WinEnter", "FocusGained", "TermLeave" },
    command = function(args)
      -- dd(vim.inspect(args))
      if vim.api.nvim_buf_is_valid(args.buf) then
        local buf = vim.bo[args.buf]
        if buf.bt ~= "" or vim.tbl_contains(excluded, buf.ft) then
          -- dd("empty statuscolumn")
          vim.opt_local.statuscolumn = ""
        else
          -- dd("active statuscolumn")
          vim.opt_local.statuscolumn = [[%!v:lua.mega.ui.statuscolumn.render(v:true)]]
        end
      else
        -- dd("fallback active statuscolumn")
        vim.opt_local.statuscolumn = [[%!v:lua.mega.ui.statuscolumn.render(v:true)]]
      end
    end,
  },
  {
    event = { "BufLeave", "WinLeave", "FocusLost" },
    command = function(args)
      -- dd(vim.inspect(args))
      if vim.api.nvim_buf_is_valid(args.buf) then
        local buf = vim.bo[args.buf]
        if buf.bt ~= "" or vim.tbl_contains(excluded, buf.ft) then
          -- dd("empty statuscolumn")
          vim.opt_local.statuscolumn = ""
        else
          -- dd("inactive statuscolumn")
          vim.opt_local.statuscolumn = [[%!v:lua.mega.ui.statuscolumn.render(v:false)]]
        end
      else
        -- dd("fallback inactive statuscolumn")
        vim.opt_local.statuscolumn = [[%!v:lua.mega.ui.statuscolumn.render(v:false)]]
      end
    end,
  },
  -- {
  --   event = { "TermEnter", "TermOpen", "TermLeave" },
  --   command = function(args)
  --     dd(vim.inspect(args))
  --     -- dd(vim.inspect(args))
  --     -- if vim.api.nvim_buf_is_valid(args.buf) then
  --     --   local buf = vim.bo[args.buf]
  --     --   if buf.bt ~= "" or vim.tbl_contains(excluded, buf.ft) then
  --     --     -- dd("empty statuscolumn")
  --     --     vim.opt_local.statuscolumn = ""
  --     --   else
  --     --     -- dd("inactive statuscolumn")
  --     --     vim.opt_local.statuscolumn = [[%!v:lua.mega.ui.statuscolumn.render(v:false)]]
  --     --   end
  --     -- else
  --     --   -- dd("fallback inactive statuscolumn")
  --     --   vim.opt_local.statuscolumn = [[%!v:lua.mega.ui.statuscolumn.render(v:false)]]
  --     -- end
  --   end,
  -- },
})
