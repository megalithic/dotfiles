-- I've taken various aspects of my statusline from the following amazing devs:
-- @akinsho, @echasnovski, @lukas-reineke, @kristijanhusak

local M = {}
-- Export module
_G.Megaline = M

local fn = vim.fn
local api = vim.api
local expand = fn.expand
local strwidth = fn.strwidth
local fnamemodify = fn.fnamemodify
local contains = vim.tbl_contains
local fmt = string.format
local C = require("colors")
local H = require("utils.highlights")
local U = {}

vim.o.laststatus = 2 -- Always show statusline

-- Module behavior
api.nvim_exec(
  [[augroup Megaline
        au!
        au WinEnter,BufEnter * setlocal statusline=%!v:lua.Megaline.active()
        " au FocusGained * setlocal let g:vim_in_focus = v:true
        au WinLeave,BufLeave * setlocal statusline=%!v:lua.Megaline.inactive()
        " au FocusLost * setlocal let g:vim_in_focus = v:false
      augroup END]],
  false
)

-- Showed diagnostic levels
U.diagnostic_levels = nil
U.diagnostic_levels = {
  { id = vim.diagnostic.severity.ERROR, sign = C.icons.lsp.error },
  { id = vim.diagnostic.severity.WARN, sign = C.icons.lsp.warn },
  { id = vim.diagnostic.severity.INFO, sign = C.icons.lsp.info },
  { id = vim.diagnostic.severity.HINT, sign = C.icons.lsp.hint },
}

-- local plain = utils.is_plain(ctx)
-- local file_modified = utils.modified(ctx, "●")
-- local inactive = vim.api.nvim_get_current_win() ~= curwin local focused = vim.g.vim_in_focus or true local minimal = plain or inactive or not focused Module functionality =======================================================
--- Compute content for active window
function M.active()
  if U.is_disabled() then
    return ""
  end

  -- use the statusline global variable which is set inside of statusline
  -- functions to the window for *that* statusline
  local curwin = vim.g.megaline_winid or 0
  local curbuf = vim.api.nvim_win_get_buf(curwin)

  -- TODO: reduce the available space whenever we add
  -- a component so we can use it to determine what to add
  -- local available_space = vim.api.nvim_win_get_width(curwin)

  U.ctx = {
    bufnum = curbuf,
    winid = curwin,
    bufname = vim.fn.bufname(curbuf),
    preview = vim.wo[curwin].previewwindow,
    readonly = vim.bo[curbuf].readonly,
    filetype = vim.bo[curbuf].ft,
    buftype = vim.bo[curbuf].bt,
    modified = vim.bo[curbuf].modified,
    fileformat = vim.bo[curbuf].fileformat,
    shiftwidth = vim.bo[curbuf].shiftwidth,
    expandtab = vim.bo[curbuf].expandtab,
  }

  return U.statusline_active()
end

--- Compute content for inactive window
function M.inactive()
  if U.is_disabled() then
    return ""
  end

  return U.statusline_inactive()
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
function M.build(groups)
  local t = vim.tbl_map(function(s)
    if not s then
      return ""
    end

    if type(s) == "string" then
      return s
    end

    local t = vim.tbl_filter(function(x)
      return not (x == nil or x == "")
    end, s.strings)
    -- Return highlight group to allow inheritance from later sections
    if vim.tbl_count(t) == 0 then
      return fmt("%%#%s#", s.hl or "")
      -- return fmt("%%#%s#", s.hl or "")
    end

    return fmt("%%#%s#%s", s.hl or "", table.concat(t, ""))
    -- return fmt("%%#%s# %s ", s.hl or "", table.concat(t, " "))
  end, groups)

  return table.concat(t, "")
end

--- Decide whether to truncate
---
--- This basically computes window width and compares it to `trunc_width`: if
--- window is smaller then truncate; otherwise don't. Don't truncate by
--- default.
---
--- Use this to manually decide if section needs truncation or not.
---
---@param trunc_width number: Truncation width. If `nil`, output is `false`.
---@return boolean: Whether to truncate.
function M.is_truncated(trunc_width)
  -- Use -1 to default to 'not truncated'
  return vim.api.nvim_win_get_width(0) < (trunc_width or -1)
end

-- Utilities ------------------------------------------------------------------
--
local function printf(format, current, total)
  if current == 0 and total == 0 then
    return ""
  end
  return fn.printf(format, current, total)
end

local function get_toggleterm_name(_, buf)
  local shell = fnamemodify(vim.env.SHELL, ":t")
  return fmt("Terminal(%s)[%s]", shell, api.nvim_buf_get_var(buf, "toggle_number"))
end

local plain_filetypes = {
  "alpha",
  "help",
  "ctrlsf",
  "minimap",
  "Trouble",
  "fzf",
  "tsplayground",
  "coc-explorer",
  "NvimTree",
  "undotree",
  "neoterm",
  "vista",
  "fugitive",
  "startify",
  "vimwiki",
  "markdown",
  "NeogitStatus",
}

local plain_buftypes = {
  "terminal",
  "quickfix",
  "nofile",
  "nowrite",
  "acwrite",
}

local exceptions = {
  buftypes = {
    terminal = " ",
    quickfix = "",
  },
  filetypes = {
    alpha = "",
    org = "",
    orgagenda = "",
    ["himalaya-msg-list"] = "",
    mail = "",
    dbui = "",
    tsplayground = "侮",
    fugitive = C.icons.git_symbol,
    fugitiveblame = C.icons.git_symbol,
    gitcommit = C.icons.git_symbol,
    Trouble = "",
    NeogitStatus = "",
    ["vim-plug"] = "⚉",
    vimwiki = "ﴬ",
    help = "",
    undotree = "פּ",
    ["coc-explorer"] = "",
    NvimTree = "פּ",
    toggleterm = " ",
    calendar = "",
    minimap = "",
    octo = "",
    ["dap-repl"] = "",
  },
  names = {
    alpha = "Alpha",
    orgagenda = "Org",
    ["himalaya-msg-list"] = "Inbox",
    mail = "Mail",
    minimap = "",
    dbui = "Dadbod UI",
    tsplayground = "Treesitter",
    fugitive = "Fugitive",
    fugitiveblame = "Git blame",
    NeogitStatus = "Neogit Status",
    Trouble = "Lsp Trouble",
    gitcommit = "Git commit",
    startify = "Startify",
    ["vim-plug"] = "vim plug",
    vimwiki = "vim wiki",
    help = "help",
    fzf = "fzf-lua",
    undotree = "UndoTree",
    octo = "Octo",
    NvimTree = "Nvim Tree",
    -- toggleterm = get_toggleterm_name,
    ["dap-repl"] = "Debugger REPL",
  },
}

--- @param hl string
function U.wrap_hl(hl)
  assert(hl, "A highlight name must be specified")
  return "%#" .. hl .. "#"
end

--- Creates a spacer statusline component i.e. for padding
--- or to represent an empty component
--- @param size number
--- @param filler string | nil
function U.spacer(size, filler)
  filler = filler or " "
  if size and size >= 1 then
    local spacer = string.rep(filler, size)
    return { spacer, #spacer }
  else
    return { "", 0 }
  end
end

--- @param component string
--- @param hl string
--- @param opts table
function U.item(component, hl, opts)
  -- do not allow empty values to be shown note 0 is considered empty
  -- since if there is nothing of something I don't need to see it
  if not component or component == "" or component == 0 then
    return U.spacer()
  end
  opts = opts or {}
  local before = opts.before or ""
  local after = opts.after or " "
  local prefix = opts.prefix or ""
  local prefix_size = strwidth(prefix)

  local prefix_color = opts.prefix_color or hl
  prefix = prefix ~= "" and U.wrap_hl(prefix_color) .. prefix .. " " or ""

  --- handle numeric inputs etc.
  if type(component) ~= "string" then
    component = tostring(component)
  end

  if opts.max_size and component and #component >= opts.max_size then
    component = component:sub(1, opts.max_size - 1) .. "…"
  end

  local parts = { before, prefix, U.wrap_hl(hl), component, "%*", after }
  return { table.concat(parts), #component + #before + #after + prefix_size }
end

--- @param item string
--- @param condition boolean
--- @param hl string
--- @param opts table
function U.item_if(item, condition, hl, opts)
  if not condition then
    return U.spacer()
  end
  return U.item(item, hl, opts)
end

--- @param ctx table
function M.is_plain(ctx)
  return contains(plain_filetypes, ctx.filetype) or contains(plain_buftypes, ctx.buftype) or ctx.preview
end

--- This function allow me to specify titles for special case buffers
--- like the preview window or a quickfix window
--- CREDIT: https://vi.stackexchange.com/a/18090
--- @param ctx table
function U.special_buffers(ctx)
  local location_list = fn.getloclist(0, { filewinid = 0 })
  local is_loc_list = location_list.filewinid > 0
  local normal_term = ctx.buftype == "terminal" and ctx.filetype == ""

  if is_loc_list then
    return "Location List"
  end
  if ctx.buftype == "quickfix" then
    return "Quickfix"
  end
  if normal_term then
    return "Terminal(" .. fnamemodify(vim.env.SHELL, ":t") .. ")"
  end
  if ctx.preview then
    return "preview"
  end

  return nil
end

--- @param ctx table
--- @param icon string | nil
function U.modified(ctx, icon)
  icon = icon or C.icons.modified
  if ctx.filetype == "help" then
    return ""
  end
  return ctx.modified and icon or ""
end

--- @param ctx table
--- @param icon string | nil
function U.readonly(ctx, icon)
  icon = icon or C.icons.readonly
  if ctx.readonly then
    return " " .. icon
  else
    return ""
  end
end

--- @param bufnum number
--- @param mod string
function U.buf_expand(bufnum, mod)
  return expand("#" .. bufnum .. mod)
end

function U.empty_opts()
  return { before = "", after = "" }
end

--- @param ctx table
--- @param modifier string
function U.filename(ctx, modifier)
  modifier = modifier or ":t"
  local special_buf = U.special_buffers(ctx)
  if special_buf then
    return "", "", special_buf
  end

  local fname = U.buf_expand(ctx.bufnum, modifier)

  local name = exceptions.names[ctx.filetype]
  if type(name) == "function" then
    return "", "", name(fname, ctx.bufnum)
  end

  if name then
    return "", "", name
  end

  if not fname then
    return "", "", "No Name"
  end

  local path = (ctx.buftype == "" and not ctx.preview) and U.buf_expand(ctx.bufnum, ":~:.:h") or nil
  local is_root = path and #path == 1 -- "~" or "."
  local dir = path and not is_root and fn.pathshorten(fnamemodify(path, ":h")) .. "/" or ""
  local parent = path and (is_root and path or fnamemodify(path, ":t")) or ""
  parent = parent ~= "" and parent .. "/" or ""

  return dir, parent, fname
end

--- @param hl string
--- @param bg_hl string
function U.highlight_ft_icon(hl, bg_hl)
  if not hl or not bg_hl then
    return
  end
  local name = hl .. "Statusline"
  -- TODO: find a mechanism to cache this so it isn't repeated constantly
  local fg_color = H.get_hl(hl, "fg")
  local bg_color = H.get_hl(bg_hl, "bg")
  if bg_color and fg_color then
    local cmd = { "highlight ", name, " guibg=", bg_color, " guifg=", fg_color }
    local str = table.concat(cmd)
    mega.augroup(name, { { events = { "ColorScheme" }, targets = { "*" }, command = str } })
    vim.cmd(fmt("silent execute '%s'", str))
  end
  return name
end

--- @param ctx table
--- @param opts table
--- @return string, string?
function U.filetype(ctx, opts)
  local ft_exception = exceptions.filetypes[ctx.filetype]
  if ft_exception then
    return ft_exception, opts.default
  end
  local bt_exception = exceptions.buftypes[ctx.buftype]
  if bt_exception then
    return bt_exception, opts.default
  end
  local icon, hl
  local extension = fnamemodify(ctx.bufname, ":e")
  local icons_loaded, devicons = mega.safe_require("nvim-web-devicons")
  if icons_loaded then
    icon, hl = devicons.get_icon(ctx.bufname, extension, { default = true })
    hl = U.highlight_ft_icon(hl, opts.icon_bg)
  end
  return icon, hl
end

function U.file(ctx, minimal)
  local curwin = ctx.winid
  -- highlight the filename components separately
  local filename_hl = minimal and "StFilenameInactive" or "StFilename"
  local directory_hl = minimal and "StInactiveSep" or "StDirectory"
  local parent_hl = minimal and directory_hl or "StParentDirectory"

  if H.has_win_highlight(curwin, "Normal", "StatusLine") then
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

  to_update.prefix = ft_icon
  to_update.prefix_color = not minimal and icon_highlight or nil
  return {
    file = { item = file, hl = filename_hl, opts = file_opts },
    dir = { item = directory, hl = directory_hl, opts = dir_opts },
    parent = { item = parent, hl = parent_hl, opts = parent_opts },
  }
end

function U.search_result()
  if vim.v.hlsearch == 0 then
    return ""
  end
  local last_search = fn.getreg("/")
  if not last_search or last_search == "" then
    return ""
  end
  local result = fn.searchcount({ maxcount = 9999 })
  if vim.tbl_isempty(result) then
    return ""
  end
  -- return " " .. last_search:gsub("\\v", "") .. " " .. result.current .. "/" .. result.total .. ""

  if result.incomplete == 1 then -- timed out
    return printf("  ?/?? ")
  elseif result.incomplete == 2 then -- max count exceeded
    if result.total > result.maxcount and result.current > result.maxcount then
      return printf("  >%d/>%d ", result.current, result.total)
    elseif result.total > result.maxcount then
      return printf("  %d/>%d ", result.current, result.total)
    end
  end
  return printf("  %d/%d ", result.current, result.total)
end

function U.isnt_normal_buffer()
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

function U.get_filetype_icon()
  -- Have this `require()` here to not depend on plugin initialization order
  local has_devicons, devicons = pcall(require, "nvim-web-devicons")
  if not has_devicons then
    return ""
  end

  local file_name, file_ext = vim.fn.expand("%:t"), vim.fn.expand("%:e")
  return devicons.get_icon(file_name, file_ext, { default = true })
end

U.get_diagnostic_count = nil
U.get_diagnostic_count = function(id)
  return #vim.diagnostic.get(0, { severity = id })
end

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
}, {
  -- By default return 'Unknown' but this shouldn't be needed
  __index = function()
    return   { long = 'Unknown',  short = 'U',   hl = '%#StModeOther#' }
  end,
})
-- stylua: ignore end

function M.s_mode(args)
  local mode_info = M.modes[vim.fn.mode()]
  local mode = M.is_truncated(args.trunc_width) and mode_info.short or mode_info.long

  return unpack(U.item(string.upper(mode), mode_info.hl, { before = " " }))
end

function M.s_git(args)
  if U.isnt_normal_buffer() then
    return ""
  end

  local status = vim.b.gitsigns_status_dict or {}
  local signs = M.is_truncated(args.trunc_width) and "" or (vim.b.gitsigns_status or "")

  local head_str = unpack(
    U.item(status.head, "StGitBranch", { before = " ", prefix = C.icons.git, prefix_color = "StGitSymbol" })
  )
  local added_str = unpack(U.item(status.added, "StTitle", { prefix = C.icons.git_added, prefix_color = "StGreen" }))
  local changed_str = unpack(
    U.item(status.changed, "StTitle", { prefix = C.icons.git_changed, prefix_color = "StWarning" })
  )
  local removed_str = unpack(
    U.item(status.removed, "StTitle", { prefix = C.icons.git_removed, prefix_color = "StError" })
  )

  if signs == "" then
    return head_str
  end

  return fmt("%s%s%s%s", head_str, added_str, changed_str, removed_str)
end

function M.s_gps(args)
  local ok, gps = mega.safe_require("nvim-gps")
  if ok and gps and gps.is_available() then
    return require("nvim-gps").get_location()
  end
end

function U.diagnostic_info(ctx)
  ctx = ctx or U.ctx
  ---Shim to handle getting diagnostics in nvim 0.5 and nightly
  ---@param buf number
  ---@param severity string
  ---@return number
  local function get_count(buf, severity)
    local s = vim.diagnostic.severity[severity:upper()]
    return #vim.diagnostic.get(buf, { severity = s })
  end

  local buf = ctx.bufnum
  if vim.tbl_isempty(vim.lsp.buf_get_clients(buf)) then
    return { error = {}, warn = {}, info = {}, hint = {} }
  end
  return {
    error = { count = get_count(buf, "Error"), sign = C.icons.lsp.error },
    warn = { count = get_count(buf, "Warn"), sign = C.icons.lsp.warn },
    info = { count = get_count(buf, "Info"), sign = C.icons.lsp.info },
    hint = { count = get_count(buf, "Hint"), sign = C.icons.lsp.hint },
  }
end

function M.s_modified(args)
  local minimal = M.is_truncated(args.trunc_width)
  if U.ctx.filetype == "help" then
    return ""
  end
  return unpack(U.item_if(U.modified(U.ctx), minimal, "StModified"))
end

function M.s_readonly(args)
  local minimal = M.is_truncated(args.trunc_width)
  return unpack(U.item_if(U.readonly(U.ctx), minimal, "StReadonly"))
end

--- Section for file name
--- Displays in smart short format with differing segment fg/gui
function M.s_filename(args)
  local ctx = U.ctx
  local minimal = M.is_truncated(args.trunc_width)
  local segments = U.file(ctx, minimal)
  local dir, parent, file = segments.dir, segments.parent, segments.file
  local dir_item = U.item(dir.item, dir.hl, dir.opts)
  local parent_item = U.item(parent.item, parent.hl, parent.opts)
  local file_hl = ctx.modified and "StModified" or file.hl
  local file_item = U.item(file.item, file_hl, file.opts)

  return fmt("%s%s%s", unpack(dir_item), unpack(parent_item), unpack(file_item))
end

--- Section for file information
function M.s_fileinfo(args)
  local ft = vim.bo.filetype
  local minimal = M.is_truncated(args.trunc_width)

  if (ft == "") or U.isnt_normal_buffer() then
    return ""
  end

  -- Add filetype icon
  local icon = U.get_filetype_icon()
  if icon ~= "" then
    ft = fmt("%s %s", icon, ft)
  end

  -- Construct output string if truncated
  if minimal then
    return ft
  end

  -- Construct output string with extra file info
  local encoding = vim.bo.fileencoding or vim.bo.encoding
  local format = vim.bo.fileformat
  local size = U.get_filesize()

  return fmt("%s %s[%s] %s", ft, encoding, format, size)
end

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
  local minimal = M.is_truncated(args.trunc_width)
  local opts = {
    prefix = "ℓ",
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
  local current_col = "%v" -- pad with `%<pad_n>v`, e.g. `%2v`
  -- local last_col = "%-2{col(\"$\") - 1}"
  -- local length = strwidth(prefix .. current .. col .. sep .. last)

  -- Use virtual column number to allow update when paste last column
  if minimal then
    return "%l│%2v"
  end

  return table.concat({
    " ",
    U.wrap_hl(prefix_color),
    prefix,
    " ",
    U.wrap_hl(current_hl),
    current_line,
    U.wrap_hl(sep_hl),
    sep,
    U.wrap_hl(total_hl),
    last_line,
    U.wrap_hl(col_hl),
    ":",
    current_col,
    " ",
  })
end

function M.s_indention()
  return unpack(U.item_if(U.ctx.shiftwidth, U.ctx.shiftwidth > 2 or not U.ctx.expandtab, "StTitle", {
    prefix = U.ctx.expandtab and "Ξ" or "⇥",
    prefix_color = "StatusLine",
  }))
end

function M.s_lsp_client(args)
  local minimal = M.is_truncated(args.trunc_width)
  for _, client in ipairs(vim.lsp.buf_get_clients(0)) do
    if client.config and client.config.filetypes and vim.tbl_contains(client.config.filetypes, vim.bo.filetype) then
      return unpack(U.item_if(client.name, minimal, "StMetadata"))
    end
  end
end

-- Helper functionality =======================================================
-- Settings -------------------------------------------------------------------
function U.is_disabled()
  return vim.g.megaline_disable == true or vim.b.megaline_disable == true
end

-- Default content ------------------------------------------------------------
function U.statusline_active()
  -- stylua: ignore start
  local prefix        = unpack(U.item_if("▌", not M.is_truncated(100), "StIndicator", { before = "", after = "" }))
  local mode          = M.s_mode({ trunc_width = 120 })
  local search        = unpack(U.item_if(U.search_result(), not M.is_truncated(120), "StCount", {before=" "}))
  local git           = M.s_git({ trunc_width = 120 })
  local readonly      = M.s_readonly({ trunc_width = 140 })
  local modified      = M.s_modified({ trunc_width = 140 })
  local filename      = M.s_filename({ trunc_width = 120 })
  -- local fileinfo      = M.s_fileinfo({ trunc_width = 120 })
  local lineinfo      = M.s_lineinfo({ trunc_width = 75 })
  local indention     = M.s_indention()
  local lsp_client    = M.s_lsp_client({ trunc_width = 140 })
  local diags         = U.diagnostic_info()
  local diag_error    = unpack(U.item_if(diags.error.count, diags.error, "StError", { prefix = diags.error.sign }))
  local diag_warn     = unpack(U.item_if(diags.warn.count, diags.warn, "StWarn", { prefix = diags.warn.sign }))
  local diag_info     = unpack(U.item_if(diags.info.count, diags.info, "StInfo", { prefix = diags.info.sign }))
  local diag_hint     = unpack(U.item_if(diags.hint.count, diags.hint, "StHint", { prefix = diags.hint.sign }))
  -- stylua: ignore end

  return M.build({
    prefix,
    mode,
    "%<", -- Mark general truncate point
    filename,
    modified,
    readonly,
    search,
    "%=", -- End left alignment
    -- middle section for whatever we want..
    "%=",
    -- lsp_client,
    { hl = "Statusline", strings = { diag_error, diag_warn, diag_info, diag_hint } },
    git,
    lineinfo,
    indention,
  })
end

function U.statusline_inactive()
  return "%#StInactive#%F%="
end

return M
