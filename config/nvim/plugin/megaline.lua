-- I've taken various aspects of my statusline from the following amazing devs:
-- @akinsho, @echasnovski, @lukas-reineke, @kristijanhusak

local M = {}

local fn = vim.fn
local api = vim.api
local expand = fn.expand
local strwidth = fn.strwidth
local fnamemodify = fn.fnamemodify
local fmt = string.format
local icons = mega.icons
local H = require("mega.utils.highlights")
local U = {}

mega.augroup("megaline", {
  {
    event = { "FocusGained" },
    command = function() vim.g.vim_in_focus = true end,
  },
  {
    event = { "FocusLost" },
    command = function() vim.g.vim_in_focus = false end,
  },

  {
    event = { "VimEnter" },
    command = function()
      vim.g.vim_in_focus = true
      vim.go.statusline = "%{%v:lua.__statusline()%}"
    end,
  },
  {
    event = { "VimResized" },
    command = function() vim.cmd("redrawstatus") end,
  },
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

-- Showed diagnostic levels
U.diagnostic_levels = nil
U.diagnostic_levels = {
  { id = vim.diagnostic.severity.ERROR, sign = icons.lsp.error },
  { id = vim.diagnostic.severity.WARN, sign = icons.lsp.warn },
  { id = vim.diagnostic.severity.INFO, sign = icons.lsp.info },
  { id = vim.diagnostic.severity.HINT, sign = icons.lsp.hint },
}

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

-- local inactive = vim.api.nvim_get_current_win() ~= curwin
-- local minimal = plain or inactive or not focused

-- Utilities ------------------------------------------------------------------
--
local function printf(format, current, total)
  if current == 0 and total == 0 then return "" end
  return fn.printf(format, current, total)
end

local function get_toggleterm_name(_, buf)
  local shell = fnamemodify(vim.env.SHELL, ":t")
  return fmt("Terminal(%s)[%s]", shell, api.nvim_buf_get_var(buf, "toggle_number"))
end
local function get_megaterm_name(_, buf)
  local shell = fnamemodify(vim.env.SHELL, ":t")
  return fmt("Terminal(%s)[%s]", shell, buf)
  -- return fmt("Terminal(%s)[%s]", shell, api.nvim_buf_get_var(buf, "cmd") or buf)
end
-- Capture the type of the neo tree buffer opened
local function get_neotree_name(fname, _)
  local parts = vim.split(fname, " ")
  return fmt("Neo Tree(%s)", parts[2])
end

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
    NeogitStatus = "Neogit Status",
    Trouble = "Lsp Trouble",
    gitcommit = "Git commit",
    startify = "Startify",
    vimwiki = "vim wiki",
    help = "help",
    fzf = "fzf-lua",
    undotree = "UndoTree",
    octo = "Octo",
    NvimTree = "Nvim Tree",
    ["neo-tree"] = get_neotree_name,
    dirbuf = "DirBuf",
    toggleterm = get_toggleterm_name,
    megaterm = get_megaterm_name,
    ["dap-repl"] = "Debugger REPL",
  },
}

local function matches(str, list)
  return #vim.tbl_filter(function(item) return item == str or string.match(str, item) end, list) > 0
end

--- @param hl string
local function wrap_hl(hl)
  assert(hl, "A highlight name must be specified")
  return "%#" .. hl .. "#"
end

--- Creates a spacer statusline component i.e. for padding
--- or to represent an empty component
--- @param size integer
--- @param filler string | nil
local function spacer(size, filler)
  filler = filler or " "
  if size and size >= 1 then
    local space = string.rep(filler, size)
    return { space, #space }
  else
    return { "", 0 }
  end
end

--- @param component string
--- @param hl string
--- @param opts table
local function item(component, hl, opts)
  -- do not allow empty values to be shown note 0 is considered empty
  -- since if there is nothing of something I don't need to see it
  if not component or component == "" or component == 0 then return spacer() end
  opts = opts or {}
  local before = opts.before or ""
  local after = opts.after or " "
  local prefix = opts.prefix or ""
  local prefix_size = strwidth(prefix)
  local suffix = opts.suffix or ""
  local suffix_size = strwidth(suffix)

  local prefix_color = opts.prefix_color or hl
  prefix = prefix ~= "" and wrap_hl(prefix_color) .. prefix .. " " or ""

  local suffix_color = opts.suffix_color or hl
  suffix = suffix ~= "" and wrap_hl(suffix_color) .. suffix .. " " or ""

  --- handle numeric inputs etc.
  if type(component) ~= "string" then component = tostring(component) end

  if opts.max_size and component and #component >= opts.max_size then
    component = component:sub(1, opts.max_size - 1) .. "…"
  end

  local parts = { before, prefix, wrap_hl(hl), component, suffix, "%*", after }
  return { table.concat(parts), #component + #before + #after + prefix_size + suffix_size }
end

--- @param sl_item string
--- @param condition boolean
--- @param hl string
--- @param opts table
local function item_if(sl_item, condition, hl, opts)
  if not condition then return spacer() end
  return item(sl_item, hl, opts)
end

-- local function matches(str, list)
--   return #vim.tbl_filter(function(item)
--     return item == str or string.match(str, item)
--   end, list) > 0
-- end

--- @param ctx table
function U.is_plain(ctx)
  return matches(ctx.filetype, plain_types.filetypes) or matches(ctx.buftype, plain_types.buftypes) or ctx.preview
end

--- Combine groups of sections
---
--- Each group can be either a string or a table with fields `hl` (group's
--- highlight group) and `strings` (strings representing sections).
---
--- General idea of this function is as follows. String group is used as is
--- (useful for special strings like `%<` or `%=`). Each group defined by table
--- has own highlighting (if not supplied explicitly, the previous one is
--- used). Non-empty strings inside group are separated by one space. Non-empty
--- groups are separated by two spaces (one for each highlighting).
---
---@param groups table: Array of groups
---@return string: String suitable for 'statusline'.
local function build(groups)
  local t = vim.tbl_map(function(s)
    if not s then return "" end

    if type(s) == "string" then return s end

    local t = vim.tbl_filter(function(x) return not (x == nil or x == "") end, s.strings)
    -- Return highlight group to allow inheritance from later sections
    if vim.tbl_count(t) == 0 then return fmt("%%#%s#", s.hl or "") end

    return fmt("%%#%s#%s", s.hl or "", table.concat(t, ""))
  end, groups)

  return table.concat(t, "")
end

--- This function allow me to specify titles for special case buffers
--- like the preview window or a quickfix window
--- CREDIT: https://vi.stackexchange.com/a/18090
--- @param ctx table
function U.special_buffers(ctx)
  local location_list = fn.getloclist(0, { filewinid = 0 })
  local is_loc_list = location_list.filewinid > 0
  local normal_term = ctx.buftype == "terminal" and ctx.filetype == ""

  if is_loc_list then return "Location List" end
  if ctx.buftype == "quickfix" then return "Quickfix List" end
  if normal_term then return "Terminal(" .. fnamemodify(vim.env.SHELL, ":t") .. ")" end
  if ctx.preview then return "preview" end

  return nil
end

--- @param ctx table
--- @param icon string | nil
function U.modified(ctx, icon)
  if ctx.filetype == "help" then return "" end
  icon = icon or icons.modified
  return ctx.modified and " " .. icon
end

--- @param ctx table
--- @param icon string | nil
function U.readonly(ctx, icon)
  icon = icon or icons.readonly
  return ctx.readonly and " " .. icon
end

--- @param bufnum number
--- @param mod string
function U.buf_expand(bufnum, mod) return expand("#" .. bufnum .. mod) end

function U.empty_opts() return { before = "", after = "" } end

--- @param ctx table
--- @param modifier string
function U.filename(ctx, modifier)
  modifier = modifier or ":t"
  local special_buf = U.special_buffers(ctx)
  if special_buf then return "", "", special_buf end

  local fname = U.buf_expand(ctx.bufnum, modifier)

  local name = exception_types.names[ctx.filetype]
  if type(name) == "function" then return "", "", name(fname, ctx.bufnum) end

  if name then return "", "", name end

  if not fname or mega.empty(fname) then return "", "", "No Name" end

  local path = (ctx.buftype == "" and not ctx.preview) and U.buf_expand(ctx.bufnum, ":~:.:h") or nil
  local is_root = path and #path == 1 -- "~" or "."
  local dir = path and not is_root and fn.pathshorten(fnamemodify(path, ":h")) .. "/" or ""
  local parent = path and (is_root and path or fnamemodify(path, ":t")) or ""
  parent = parent ~= "" and parent .. "/" or ""

  return dir, parent, fname
end

---@param name string
---@param fg string
---@param bg string
local function create_hl(name, fg, bg)
  if fg and bg then api.nvim_set_hl(0, name, { foreground = fg, background = bg }) end
end

--- @param hl string
--- @param bg_hl string
function U.highlight_ft_icon(color, hl, bg_hl)
  if not hl or not bg_hl then return end
  local name = hl .. "Statusline"
  -- TODO: find a mechanism to cache this so it isn't repeated constantly
  local fg_color = color -- H.get_hl(hl, "fg")
  local bg_color = H.get_hl(bg_hl, "bg")

  if bg_color and fg_color then
    mega.augroup(name, {
      {
        event = "ColorScheme",
        command = function() create_hl(name, fg_color, bg_color) end,
      },
    })
    create_hl(name, fg_color, bg_color)
  end

  return name
end

--- @param ctx table
--- @param opts table
--- @return string, string?
function U.filetype(ctx, opts)
  local ft_exception = exception_types.filetypes[ctx.filetype]
  if ft_exception then return ft_exception, opts.default end

  local bt_exception = exception_types.buftypes[ctx.buftype]
  if bt_exception then return bt_exception, opts.default end

  local icon, icon_hl, icon_color, hl
  local f_name, f_extension = vim.fn.expand("%:t") or ctx.bufname, vim.fn.expand("%:e")
  f_extension = f_extension ~= "" and f_extension or vim.bo.filetype

  local icons_loaded, devicons = pcall(require, "nvim-web-devicons")
  if icons_loaded then
    _, icon_hl = devicons.get_icon(f_name, f_extension)
    -- to get color rendering working propertly, we have to use the get_icon_color/3 fn
    icon, icon_color = devicons.get_icon_color(f_name, f_extension, { default = true })
    hl = U.highlight_ft_icon(icon_color, icon_hl, opts.icon_bg)
  end

  return icon, hl
end

function U.file(ctx, trunc)
  local is_minimal = is_truncated(trunc)
  local curwin = ctx.winid
  -- highlight the filename components separately
  -- local filename_hl = is_minimal and "StFilenameInactive" or "StFilename"
  -- local directory_hl = is_minimal and "StInactiveSep" or "StDirectory"
  -- local parent_hl = is_minimal and directory_hl or "StParentDirectory"

  local filename_hl = "StFilename"
  local directory_hl = "StDirectory"
  local parent_hl = "StParentDirectory"

  if H.winhighlight_exists(curwin, "Normal", "StatusLine") then
    directory_hl = H.adopt_winhighlight(curwin, "StatusLine", "StCustomDirectory", "StTitle")
    filename_hl = H.adopt_winhighlight(curwin, "StatusLine", "StCustomFilename", "StTitle")
    parent_hl = H.adopt_winhighlight(curwin, "StatusLine", "StCustomParentDir", "StTitle")
  end

  local ft_icon, icon_highlight = U.filetype(ctx, { icon_bg = "StatusLine", default = "StComment" })
  local file_opts, parent_opts, dir_opts = U.empty_opts(), U.empty_opts(), U.empty_opts()
  local directory, parent, file = U.filename(ctx)

  -- Depending on which filename segments are empty we select a section to add the file icon to
  local dir_empty, parent_empty = mega.empty(directory), mega.empty(parent)
  local to_update = dir_empty and parent_empty and file_opts or dir_empty and parent_opts or dir_opts

  if not is_minimal then
    to_update.prefix = ft_icon
    to_update.prefix_color = icon_highlight or nil
  end

  return {
    file = { item = file, hl = filename_hl, opts = file_opts },
    dir = { item = directory, hl = directory_hl, opts = dir_opts },
    parent = { item = parent, hl = parent_hl, opts = parent_opts },
  }
end

function M.s_search_result()
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

function U.abnormal_buffer()
  -- For more information see ":h buftype"
  return vim.bo.buftype ~= ""
end

function U.get_filesize()
  local size = vim.fn.getfsize(vim.fn.getreg("%"))
  if size < 1024 then
    return fmt("%dB", size)
  elseif size < 1048576 then
    return fmt("%.2fKiB", size / 1024)
  else
    return fmt("%.2fMiB", size / 1048576)
  end
end

U.get_diagnostic_count = function(id) return #vim.diagnostic.get(0, { severity = id }) end

-- Sections ===================================================================
-- Functions should return output text without whitespace on sides or empty
-- string to omit section

-- Mode
-- Custom `^V` and `^S` symbols to make this file appropriate for copy-paste
-- (otherwise those symbols are not displayed).
local CTRL_S = vim.api.nvim_replace_termcodes("<C-S>", true, true, true)
local CTRL_V = vim.api.nvim_replace_termcodes("<C-V>", true, true, true)

-- stylua: ignore start
M.modes = setmetatable({
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
  ['t']    = { long = 'Terminal', short = 'T',   hl = 'StModeOther' },
  ['nt']    = { long = 'N-Terminal', short = 'T',   hl = 'StModeNormal' },
}, {
  -- By default return 'Unknown' but this shouldn't be needed
  __index = function()
    return   { long = 'Unknown',  short = 'U',   hl = 'StModeOther' }
  end,
})
-- stylua: ignore end

function M.s_mode(args)
  local mode_info = M.modes[api.nvim_get_mode().mode]
  local mode = is_truncated(args.trunc_width) and mode_info.short or mode_info.long

  return unpack(item(string.upper(mode), mode_info.hl, { before = " " }))
end

function M.s_hydra(args)
  local ok, _ = pcall(require, "hydra")

  if is_truncated(args.trunc_width) then return "" end

  if ok then
    hydra_statusline = require("hydra.statusline")
    return unpack(
      item_if(hydra_statusline.get_name(), hydra_statusline.is_active(), "StMetadata", { before = "", after = " " })
    )
  end

  return ""
end

function M.s_git(args)
  if U.abnormal_buffer() then return "" end

  local status = vim.b.gitsigns_status_dict or {}
  local signs = is_truncated(args.trunc_width) and "" or (vim.b.gitsigns_status or "")
  local branch = status.head

  if is_truncated(args.trunc_width) then branch = mega.truncate(branch or "", 11, false) end

  local head_str = unpack(item(branch, "StGitBranch", {
    before = "  ",
    after = "",
    prefix = is_truncated(80) and "" or icons.git.symbol,
    prefix_color = "StGitSymbol",
  }))
  local added_str =
    unpack(item(status.added, "StMetadataPrefix", { prefix = icons.git.add, prefix_color = "StGitSignsAdd" }))
  local changed_str =
    unpack(item(status.changed, "StMetadataPrefix", { prefix = icons.git.change, prefix_color = "StGitSignsChange" }))
  local removed_str =
    unpack(item(status.removed, "StMetadataPrefix", { prefix = icons.git.remove, prefix_color = "StGitSignsDelete" }))

  if signs == "" then return head_str end

  return fmt("%s %s%s%s", head_str, added_str, changed_str, removed_str)
end

local function diagnostic_info(ctx)
  ctx = ctx or U.ctx
  ---Shim to handle getting diagnostics in nvim 0.5 and nightly
  ---@param buf number
  ---@param severity string
  ---@return number
  local function get_count(buf, severity)
    local s = vim.diagnostic.severity[severity:upper()]
    return #vim.diagnostic.get(buf, { severity = s })
  end

  local bufnr = ctx.bufnum
  if vim.tbl_isempty(vim.lsp.get_active_clients({ bufnr = bufnr })) then
    return { error = {}, warn = {}, info = {}, hint = {} }
  end

  return {
    error = { count = get_count(bufnr, "Error"), sign = icons.lsp.error },
    warn = { count = get_count(bufnr, "Warn"), sign = icons.lsp.warn },
    info = { count = get_count(bufnr, "Info"), sign = icons.lsp.info },
    hint = { count = get_count(bufnr, "Hint"), sign = icons.lsp.hint },
  }
end

function M.s_modified(args)
  if U.ctx.filetype == "help" then return "" end
  return unpack(item_if(U.modified(U.ctx), not is_truncated(args.trunc_width), "StModified"))
end

function M.s_readonly(args)
  local readonly_hl = H.adopt_winhighlight(U.ctx.winid, "StatusLine", "StCustomError", "StError")
  return unpack(item_if(U.readonly(U.ctx), not is_truncated(args.trunc_width), readonly_hl))
end

--- Section for file name
--- Displays in smart short format with differing segment fg/gui
function M.s_filename(args)
  local ctx = U.ctx
  local segments = U.file(ctx, args.trunc_width)
  local dir, parent, file = segments.dir, segments.parent, segments.file
  local dir_item = item(dir.item, dir.hl, dir.opts)
  local parent_item = item(parent.item, parent.hl, parent.opts)
  local file_hl = ctx.modified and "StModified" or file.hl
  local file_item = item(file.item, file_hl, file.opts)

  return fmt("%s%s%s", unpack(dir_item), unpack(parent_item), unpack(file_item))
end

--- Section for file information
-- function M.s_fileinfo(args)
--   local ft = vim.bo.filetype

--   if (ft == "") or U.isnt_normal_buffer() then
--     return ""
--   end

--   local icon = U.get_filetype_icon()
--   if icon ~= "" then
--     ft = fmt("%s %s", icon, ft)
--   end

--   -- Construct output string if truncated
--   if is_truncated(args.trunc_width) then
--     return ft
--   end

--   -- Construct output string with extra file info
--   local encoding = vim.bo.fileencoding or vim.bo.encoding
--   local format = vim.bo.fileformat
--   local size = U.get_filesize()

--   return fmt("%s %s[%s] %s", ft, encoding, format, size)
-- end

--- Section for location (#lineinfo, #line_info) inside buffer
---
--- Show location inside buffer in the form:
--- - Normal: '<cursor line>|<total lines>│<cursor column>|<total columns>'.
--- - Short: '<cursor line>│<cursor column>'.
---
--- Short output is returned if window width is lower than `args.trunc_width`.
---
---@param args table: Section arguments.
---@return string: Section string.
function M.s_lineinfo(args)
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
  if is_truncated(args.trunc_width) then return "%l/%L:%v" end

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

local function is_focused() return tonumber(vim.g.actual_curwin) == vim.api.nvim_get_current_win() end

-- do the statusline things for the activate window
function _G.__statusline()
  -- use the statusline global variable which is set inside of statusline
  -- functions to the window for *that* statusline
  local curwin = vim.g.statusline_winid or 0
  local curbuf = api.nvim_win_get_buf(curwin)
  -- local available_space = vim.o.columns

  local ctx = {
    bufnum = curbuf,
    winid = curwin,
    bufname = api.nvim_buf_get_name(curbuf),
    preview = vim.wo[curwin].previewwindow,
    readonly = vim.bo[curbuf].readonly,
    filetype = vim.bo[curbuf].ft,
    buftype = vim.bo[curbuf].bt,
    modified = vim.bo[curbuf].modified,
    fileformat = vim.bo[curbuf].fileformat,
    shiftwidth = vim.bo[curbuf].shiftwidth,
    expandtab = vim.bo[curbuf].expandtab,
  }

  U.ctx = ctx

  local plain = U.is_plain(ctx)
  local focused = vim.g.vim_in_focus and is_focused()
  -- local focused = vim.g.vim_in_focus or is_focused()
  -- if not plain and focused and not disabled then

  if focused then
    -- stylua: ignore start
    local diags                       = diagnostic_info()
    local diag_error                  = unpack(item_if(diags.error.count, not is_truncated(100) and diags.error, "StError", { prefix = diags.error.sign }))
    local diag_warn                   = unpack(item_if(diags.warn.count, not is_truncated(100) and diags.warn, "StWarn", { prefix = diags.warn.sign }))
    local diag_info                   = unpack(item_if(diags.info.count, not is_truncated(100) and diags.info, "StInfo", { prefix = diags.info.sign }))
    local diag_hint                   = unpack(item_if(diags.hint.count, not is_truncated(100) and diags.hint, "StHint", { prefix = diags.hint.sign }))
    -- stylua: ignore end

    if plain then
      return build({
        -- filename parts
        M.s_filename({ trunc_width = 120 }),
        -- modified indicator
        M.s_modified({ trunc_width = 100 }),
        -- readonly indicator
        M.s_readonly({ trunc_width = 100 }),
        -- saving indicator
        unpack(item_if("Saving…", vim.g.is_saving, "StComment", { before = " " })),
        "%=", -- end left alignment
      })
    end

    return build({
      -- prefix
      unpack(item_if(icons.misc.lblock, not is_truncated(100), M.modes[vim.fn.mode()].hl, { before = "", after = "" })),
      -- mode
      M.s_mode({ trunc_width = 120 }),
      -- M.s_hydra({ trunc_width = 75 }),
      "%<", -- mark general truncate point
      -- filename parts
      M.s_filename({ trunc_width = 120 }),
      -- modified indicator
      M.s_modified({ trunc_width = 100 }),
      -- readonly indicator
      M.s_readonly({ trunc_width = 100 }),
      -- saving indicator
      unpack(item_if("Saving…", vim.g.is_saving, "StComment", { before = " " })),
      -- search results
      unpack(
        item_if(
          M.s_search_result(),
          not is_truncated(120) and vim.v.hlsearch > 0,
          "StCount",
          { before = " ", after = " ", prefix = " ", suffix = " " }
        )
      ),
      "%=", -- end left alignment
      -- middle section for whatever we want..
      "%=",
      -- diagnostics
      { hl = "Statusline", strings = { diag_error, diag_warn, diag_info, diag_hint } },
      -- git status/branch
      M.s_git({ trunc_width = 120 }),
      -- line information
      M.s_lineinfo({ trunc_width = 75 }),
      -- suffix
      -- unpack(item_if(icons.misc.rblock, not is_truncated(100), M.modes[vim.fn.mode()].hl, { before = "", after = "" })),
    })
    -- elseif plain and focused and not disabled then
    --   return build({
    --     "%<", -- mark general truncate point
    --     -- filename parts
    --     M.s_filename({ trunc_width = 120 }),
    --     -- modified indicator
    --     M.s_modified({ trunc_width = 100 }),
    --     -- readonly indicator
    --     M.s_readonly({ trunc_width = 100 }),
    --     "%=", -- end left alignment
    --     -- middle section for whatever we want..
    --     "%=",
    --   })
  else
    -- barebones inactive mode
    return "%#StInactive#%F %m%="
  end
end

return M
