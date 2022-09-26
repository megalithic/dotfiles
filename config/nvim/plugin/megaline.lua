-- I've taken various aspects of my statusline from the following amazing devs:
-- @akinsho, @echasnovski, @lukas-reineke, @kristijanhusak, @mfussenegger

if not mega then return end
if not vim.g.enabled_plugin["megaline"] then
  vim.o.statusline = "%#Statusline# %2{mode()} | %F %m %r %= %{&spelllang} %y %8(%l,%c%) %8p%%"
end

local M = {}

local fn = vim.fn
local api = vim.api
local expand = fn.expand
local strwidth = fn.strwidth
local fnamemodify = fn.fnamemodify
local fmt = string.format
local icons = mega.icons
local H = require("mega.utils.highlights")

vim.g.is_saving = false

mega.augroup("megaline", {
  {
    event = { "BufWritePre" },
    command = function()
      if not vim.g.is_saving and vim.bo.modified then
        vim.g.is_saving = true
        vim.defer_fn(function() vim.g.is_saving = false end, 1000)
      end
    end,
  },
})

-- ( SETTERS ) -----------------------------------------------------------------

local function seg(contents, hl, cond)
  if cond ~= nil and not cond then return "" end

  hl = hl or "Statusline"
  local segment = "%#" .. hl .. "#" .. contents
  return segment
end

--- variable sized spacer
--- @param size integer | nil
--- @param filler string | nil
local function seg_spacer(size, filler)
  filler = filler or " "
  if size and size >= 1 then
    local span = string.rep(filler, size)
    return seg(span)
  else
    return seg("")
  end
end

-- ( CONSTANTS ) ---------------------------------------------------------------

-- Custom `^V` and `^S` symbols to make this file appropriate for copy-paste
-- (otherwise those symbols are not displayed).
local CTRL_S = vim.api.nvim_replace_termcodes("<C-S>", true, true, true)
local CTRL_V = vim.api.nvim_replace_termcodes("<C-V>", true, true, true)
-- stylua: ignore start
local MODES = setmetatable({
  ['n']    = { long = 'Normal',   short = 'N',   hl = 'StModeNormal' },
  ['no']   = { long = 'N-OPERATOR PENDING',   short = 'N-OP',   hl = 'StModeNormal' },
  ['nov']   = { long = 'N-OPERATOR BLOCK',   short = 'N-OPv',   hl = 'StModeNormal' },
  ['noV']   = { long = 'N-OPERATOR LINE',   short = 'N-OPV',   hl = 'StModeNormal' },
  ['v']    = { long = 'Visual',   short = 'V',   hl = 'StModeVisual' },
  ['V']    = { long = 'V-Line',   short = 'V-L', hl = 'StModeVisual' },
  [CTRL_V] = { long = 'V-Block',  short = 'V-B', hl = 'StModeVisual' },
  ['s']    = { long = 'Select',   short = 'S',   hl = 'StModeVisual' },
  ['S']    = { long = 'S-Line',   short = 'S-L', hl = 'StModeVisual' },
  [CTRL_S] = { long = 'S-Block',  short = 'S-B', hl = 'StModeVisual' },
  ['i']    = { long = 'Insert',   short = 'I',   hl = 'StModeInsert' },
  ['R']    = { long = 'Replace',  short = 'R',   hl = 'StModeReplace' },
  ['c']    = { long = 'Command',  short = 'C',   hl = 'StModeCommand' },
  ['r']    = { long = 'Prompt',   short = 'P',   hl = 'StModeOther' },
  ['!']    = { long = 'Shell',    short = 'Sh',  hl = 'StModeOther' },
  ['t']    = { long = 'Terminal', short = 'T-I',   hl = 'StModeOther' },
  ['nt']    = { long = 'N-Terminal', short = 'T-N',   hl = 'StModeNormal' },
  ['r?']    = { long = 'Confirm', short = '?',   hl = 'StModeOther' },
}, {
  -- By default return 'Unknown' but this shouldn't be needed
  __index = function()
    return   { long = 'Unknown',  short = 'U',   hl = 'StModeOther' }
  end,
})
-- stylua: ignore end

local plain_types = {
  filetypes = {
    "help",
    "ctrlsf",
    "minimap",
    "Trouble",
    "tsplayground",
    "coc-explorer",
    "NvimTree",
    "undotree",
    "neo-tree",
    "dirbuf",
    "neoterm",
    "vista",
    "fugitive",
    "startify",
    "vimwiki",
    "NeogitStatus",
    "dap-repl",
    "megaterm",
  },

  buftypes = {
    "terminal",
    "quickfix",
    "nofile",
    "nowrite",
    "acwrite",
  },
}

local exception_types = {
  buftypes = {
    terminal = " ",
    quickfix = "",
  },
  filetypes = {
    alpha = "",
    org = "",
    orgagenda = "",
    dbui = "",
    tsplayground = "侮",
    fugitive = icons.vcs,
    fugitiveblame = icons.vcs,
    gitcommit = icons.vcs,
    NeogitCommitMessage = icons.vcs,
    Trouble = "",
    NeogitStatus = icons.git.symbol,
    ["vim-plug"] = "⚉",
    vimwiki = "ﴬ",
    help = "",
    undotree = "פּ",
    NvimTree = "פּ",
    dirbuf = "פּ",
    ["neo-tree"] = "פּ",
    toggleterm = " ",
    megaterm = " ",
    calendar = "",
    minimap = "",
    octo = "",
    kittybuf = "",
    ["dap-repl"] = "",
  },
  names = {
    alpha = "Alpha",
    orgagenda = "Org",
    minimap = "",
    dbui = "Dadbod UI",
    tsplayground = "Treesitter",
    fugitive = "Fugitive",
    fugitiveblame = "Git blame",
    NeogitStatus = "Neogit status",
    Trouble = "Lsp Trouble",
    gitcommit = "Git commit",
    NeogitCommitMessage = "Neogit commit",
    startify = "Startify",
    vimwiki = "vim wiki",
    help = "help",
    fzf = "fzf-lua",
    undotree = "UndoTree",
    octo = "Octo",
    NvimTree = "Nvim Tree",
    ["neo-tree"] = function(fname, _)
      local parts = vim.split(fname, " ")
      return fmt("Neo-Tree(%s)", parts[2])
    end,
    dirbuf = "DirBuf",
    toggleterm = function(_, buf)
      local shell = fnamemodify(vim.env.SHELL, ":t")
      return seg("Terminal(%s)[%s]", shell, api.nvim_buf_get_var(buf, "toggle_number"))
    end,
    megaterm = function(_, buf)
      local shell = fnamemodify(vim.env.SHELL, ":t")
      local mode = MODES[api.nvim_get_mode().mode]
      local mode_hl = mode.short == "T-I" and "StModeInsert" or "StModeNormal"
      return seg(fmt("megaterm(%s)[%s] ⋮ %s", shell, api.nvim_buf_get_var(buf, "cmd") or buf, mode.short), mode_hl)
    end,
    ["dap-repl"] = "Debugger REPL",
    kittybuf = "Kitty Scrollback Buffer",
  },
}

-- ( UTILITIES ) ---------------------------------------------------------------

--- Decide whether to truncate
---
--- This basically computes window width and compares it to `trunc_width`: if
--- window is smaller then truncate; otherwise don't. Don't truncate by
--- default.
---
--- Use this to manually decide if section needs truncation or not.
---
---@param trunc number: Truncation width. If `nil`, output is `false`.
---@return boolean: Whether to truncate.
local function is_truncated(trunc)
  -- Use -1 to default to 'not truncated'
  local check = api.nvim_win_get_width(0) < (trunc or -1)

  if vim.api.nvim_get_option("laststatus") == 3 then check = vim.o.columns < (trunc or -1) end

  return check
end

local function matches(str, list)
  return #vim.tbl_filter(function(item) return item == str or string.match(str, item) end, list) > 0
end

--- This function allow me to specify titles for special case buffers
--- like the preview window or a quickfix window
--- CREDIT: https://vi.stackexchange.com/a/18090
local function special_buffers()
  local location_list = fn.getloclist(0, { filewinid = 0 })
  local is_loc_list = location_list.filewinid > 0
  local normal_term = M.ctx.buftype == "terminal" and M.ctx.filetype == ""

  if is_loc_list then return "Location List" end
  if M.ctx.buftype == "quickfix" then return "Quickfix List" end
  if normal_term then return "Terminal(" .. fnamemodify(vim.env.SHELL, ":t") .. ")" end
  if M.ctx.preview then return "preview" end

  return nil
end

local function is_plain()
  return matches(M.ctx.filetype, plain_types.filetypes) or matches(M.ctx.buftype, plain_types.buftypes) or M.ctx.preview
end

local function is_abnormal_buffer()
  -- For more information see ":h buftype"
  return vim.bo.buftype ~= ""
end

local function is_valid_git()
  local status = vim.b.gitsigns_status_dict or {}
  local is_valid = status and status.head ~= nil
  return is_valid and status or is_valid
end

--- @param hl string
local function wrap_hl(hl)
  assert(hl, "A highlight name must be specified")
  return "%#" .. hl .. "#"
end

-- ( GETTERS ) -----------------------------------------------------------------

local function get_diagnostics()
  local function count(id) return #vim.diagnostic.get(0, { severity = id }) end
  if vim.tbl_isempty(vim.lsp.get_active_clients({ bufnr = 0 })) then return "" end

  local diags = {
    { num = count(vim.diagnostic.severity.ERROR), sign = mega.icons.lsp.error, hl = "StError" },
    { num = count(vim.diagnostic.severity.WARN), sign = mega.icons.lsp.warn, hl = "StWarn" },
    { num = count(vim.diagnostic.severity.INFO), sign = mega.icons.lsp.info, hl = "StInfo" },
    { num = count(vim.diagnostic.severity.HINT), sign = mega.icons.lsp.hint, hl = "StHint" },
  }

  for _, d in ipairs(diags) do
    if d.num > 0 then return seg(fmt("%s %s", d.sign, d.num), d.hl) end
  end

  return ""
end

local function get_lsp_status(messages)
  local percentage
  local result = {}
  for _, msg in pairs(messages) do
    if msg.message then
      table.insert(result, msg.title .. ": " .. msg.message)
    else
      table.insert(result, msg.title)
    end
    if msg.percentage then percentage = math.max(percentage or 0, msg.percentage) end
  end
  if percentage then
    return string.format("%03d: %s", percentage, table.concat(result, ", "))
  else
    return table.concat(result, ", ")
  end
end

local function get_hydra_status()
  local ok, hydra = mega.require("hydra.statusline")
  if not ok then return "" end

  local colors = {
    red = "HydraRedSt",
    blue = "HydraBlueSt",
    amaranth = "HydraAmaranthSt",
    teal = "HydraTealSt",
    pink = "HydraPinkSt",
  }
  local data = {
    name = hydra.get_name() or "UNKNOWN",
    hint = hydra.get_hint(),
    color = colors[hydra.get_color()],
  }

  if not hydra.is_active() then return "" end
  return seg(fmt("%s %s", mega.icons.misc.hydra, string.upper(data.name)), data.color)
end

local function get_substitution_status()
  local ok, cool = mega.require("cool-substitute.status")
  if not ok then return "" end

  -- P(fmt("cool writing active: %s", vim.g.cool_substitute_is_active))
  -- P(fmt("cool applying active: %s", vim.g.cool_substitute_is_applying))

  if not cool.status_with_icons() then return "" end
  -- local hl = ""
  -- if vim.g.cool_substitute_is_active then
  --   hl = H.set_hl("StSubstitution", { bg = cool.status_color() })
  -- elseif vim.g.cool_substitute_is_applying then
  -- end
  -- local writingHl = H.set_hl("StCoolSubWriting", { bg = cool.status_color() })
  -- local applyingHl = H.set_hl("StCoolSubWriting", { bg = cool.status_color() })
  -- P(cool.status_color())
  H.set_hl("StSubstitution", { foreground = cool.status_color() })
  return seg(cool.status_with_icons(), "StSubstitution")
end

local function get_dap_status()
  local ok, dap = mega.require("dap")
  if not ok then return "" end
  local status = dap.status()
  if status ~= "" then return status .. " | " end
  return ""
end

local function get_search_results()
  if vim.v.hlsearch == 0 then return "" end
  local last_search = fn.getreg("/")
  if not last_search or last_search == "" then return "" end
  local result = fn.searchcount({ maxcount = 9999 })
  if vim.tbl_isempty(result) then return "" end
  -- return " " .. last_search:gsub("\\v", "") .. " " .. result.current .. "/" .. result.total .. ""

  if result.incomplete == 1 then -- timed out
    return fmt("%s ?/??", icons.misc.search)
  elseif result.incomplete == 2 then -- max count exceeded
    if result.total > result.maxcount and result.current > result.maxcount then
      return fmt("%s >%d/>%d", icons.misc.search, result.current, result.total)
    elseif result.total > result.maxcount then
      return fmt("%s %d/>%d", icons.misc.search, result.current, result.total)
    end
  end

  return fmt("%s %d/%d", icons.misc.search, result.current, result.total)
end

local function parse_filename(truncate_at)
  local function buf_expand(bufnr, mod) return expand("#" .. bufnr .. mod) end

  local modifier = ":t"
  local special_buf = special_buffers(M.ctx)
  if special_buf then return "", "", special_buf end

  local fname = buf_expand(M.ctx.bufnr, modifier)

  local name = exception_types.names[M.ctx.filetype]
  if type(name) == "function" then return "", "", name(fname, M.ctx.bufnr) end

  if name then return "", "", name end

  if not fname or mega.empty(fname) then return "", "", "No Name" end

  local path = (M.ctx.buftype == "" and not M.ctx.preview) and buf_expand(M.ctx.bufnr, ":~:.:h") or nil
  local is_root = path and #path == 1 -- "~" or "."
  local dir = path and not is_root and fn.pathshorten(fnamemodify(path, ":h")) .. "/" or ""
  local parent = path and (is_root and path or fnamemodify(path, ":t")) or ""
  parent = parent ~= "" and parent .. "/" or ""

  return dir, parent, fname
end

local function get_filename_parts(truncate_at)
  local filename_hl = "StFilename"
  local directory_hl = "StDirectory"
  local parent_hl = "StParentDirectory"

  if H.winhighlight_exists(M.ctx.winid, "Normal", "StatusLine") then
    directory_hl = H.adopt_winhighlight(M.ctx.winid, "StatusLine", "StCustomDirectory", "StTitle")
    filename_hl = H.adopt_winhighlight(M.ctx.winid, "StatusLine", "StCustomFilename", "StTitle")
    parent_hl = H.adopt_winhighlight(M.ctx.winid, "StatusLine", "StCustomParentDir", "StTitle")
  end

  local directory, parent, file = parse_filename(truncate_at)

  return {
    file = { item = file, hl = filename_hl },
    dir = { item = directory, hl = directory_hl },
    parent = { item = parent, hl = parent_hl },
  }
end

-- ( SEGMENTS ) ----------------------------------------------------------------

local function seg_filename(truncate_at)
  local segments = get_filename_parts(truncate_at)

  local dir, parent, file = segments.dir, segments.parent, segments.file

  local file_hl = M.ctx.modified and "StModified" or file.hl

  return fmt("%s%s%s", seg(dir.item, dir.hl), seg(parent.item, parent.hl), seg(file.item, file_hl))
end

local function seg_prefix(truncate_at)
  local mode_info = MODES[api.nvim_get_mode().mode]
  local prefix = is_truncated(truncate_at) and "" or mega.icons.misc.lblock
  return seg(prefix, mode_info.hl)
end

local function seg_mode(truncate_at)
  local mode_info = MODES[api.nvim_get_mode().mode]
  local mode = is_truncated(truncate_at) and mode_info.short or mode_info.long
  return seg(string.upper(mode), mode_info.hl)
end

local function seg_lsp_status(truncate_at)
  if is_truncated(truncate_at) then return "" end
  local messages = vim.lsp.util.get_progress_messages()

  if vim.tbl_isempty(messages) then return get_diagnostics() end

  if vim.g.notifier_enabled then return "" end

  return get_lsp_status(messages)
end

local function seg_lineinfo(truncate_at)
  local opts = {
    prefix = icons.ln_sep,
    prefix_color = "StMetadataPrefix",
    current_hl = "StTitle",
    total_hl = "StComment",
    col_hl = "StComment",
    sep_hl = "StComment",
  }
  local sep = opts.sep or "/"
  local prefix = opts.prefix or "L"
  local prefix_color = opts.prefix_color
  local current_hl = opts.current_hl
  local col_hl = opts.col_hl
  local total_hl = opts.total_hl
  local sep_hl = opts.total_hl

  local current_line = "%l"
  local last_line = "%L"
  local current_col = "%-3c"

  -- Use virtual column number to allow update when paste last column
  if is_truncated(truncate_at) then return "%l/%L:%v" end

  return table.concat({
    "  ",
    wrap_hl(prefix_color),
    prefix,
    " ",
    wrap_hl(current_hl),
    current_line,
    wrap_hl(sep_hl),
    sep,
    wrap_hl(total_hl),
    last_line,
    wrap_hl(col_hl),
    ":",
    current_col,
  })
end

local function seg_modified()
  if not M.ctx.modified then return "" end

  return seg(mega.icons.modified, "StModified")
end

local function seg_search_results(truncate_at)
  return seg(fmt(" %s ", get_search_results()), "StCount", not is_truncated(truncate_at) and vim.v.hlsearch > 0)
end

local function seg_git_symbol(truncate_at)
  if is_abnormal_buffer() or not is_valid_git() then return "" end

  local symbol = is_truncated(truncate_at) and "" or mega.icons.git.symbol
  return seg(symbol, "StGitSymbol")
end

local function seg_git_status(truncate_at)
  if is_abnormal_buffer() then return "" end

  local status = is_valid_git()
  if not status then return "" end

  local branch = is_truncated(truncate_at) and mega.truncate(status.head or "", 11, false) or status.head
  return seg(branch, "StGitBranch")
end

local function is_focused() return tonumber(vim.g.actual_curwin) == vim.api.nvim_get_current_win() end

-- ( STATUSLINE ) --------------------------------------------------------------

function _G.__statusline()
  local winnr = vim.g.statusline_winid or 0
  local bufnr = api.nvim_win_get_buf(winnr)

  M.ctx = {
    bufnr = bufnr,
    winid = winnr,
    bufname = api.nvim_buf_get_name(bufnr),
    preview = vim.wo[winnr].previewwindow,
    readonly = vim.bo[bufnr].readonly,
    filetype = vim.bo[bufnr].ft,
    buftype = vim.bo[bufnr].bt,
    modified = vim.bo[bufnr].modified,
    fileformat = vim.bo[bufnr].fileformat,
    shiftwidth = vim.bo[bufnr].shiftwidth,
    expandtab = vim.bo[bufnr].expandtab,
  }

  if not is_focused() then return "%#StInactive# %F %m %r %= %{&spelllang} %y %8(%l,%c%) %8p%%" end

  if is_plain() then
    local parts = {
      seg_filename(120),
      seg(" %m %r", "StModified"),
      -- end left alignment
      "%=",
    }

    return table.concat(parts, "")
  end

  local parts = {
    seg([[%<]]),
    seg_prefix(100),
    seg_spacer(1),
    seg_mode(120),
    seg_spacer(1),
    seg_spacer(1),
    seg_filename(120),
    seg_modified(),
    seg_spacer(1),
    seg("%r", "StModified"),
    seg_spacer(1),
    seg("%{&paste?'[paste] ':''}", "warningmsg"),
    seg_spacer(1),
    seg("Saving…", "StComment", vim.g.is_saving),
    seg_spacer(1),
    seg_search_results(120),
    -- end left alignment
    seg([[%=]]),
    seg(get_hydra_status()),
    -- seg(get_substitution_status()),
    seg([[%=]]),
    -- begin right alignment
    seg("%*"),
    seg("%{&ff!='unix'?'['.&ff.'] ':''}", "warningmsg"),
    seg("%*"),
    seg("%{(&fenc!='utf-8'&&&fenc!='')?'['.&fenc.'] ':''}", "warningmsg"),
    seg("%*"),
    seg_spacer(2),
    seg_lsp_status(100),
    seg_spacer(2),
    seg_git_symbol(80),
    seg_spacer(1),
    seg_git_status(120),
    seg(get_dap_status()),
    seg_lineinfo(75),
  }

  return table.concat(parts, "")
end

vim.o.statusline = "%{%v:lua.__statusline()%}"
