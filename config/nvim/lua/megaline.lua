-- I've taken aspects of my statusline from the following amazing devs:
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
    return fmt("%%#%s#%s ", s.hl or "", table.concat(t, " "))
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
function U.wrap(hl)
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
  prefix = prefix ~= "" and U.wrap(prefix_color) .. prefix .. " " or ""

  --- handle numeric inputs etc.
  if type(component) ~= "string" then
    component = tostring(component)
  end

  if opts.max_size and component and #component >= opts.max_size then
    component = component:sub(1, opts.max_size - 1) .. "…"
  end

  local parts = { before, prefix, U.wrap(hl), component, "%*", after }
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
function M.section_prefix(args)
  -- add({ item_if("▌", not minimal, "StIndicator", { before = "", after = "" }), 0 }, { utils.spacer(1), 0 })
  -- "זּ"
  -- "▌"
  -- "●"
  -- ""
  local prefix_item = U.item_if("▌", not M.is_truncated(args.trunc_width), "StIndicator", { before = "", after = "" })

  return fmt("%s", unpack(prefix_item))
end

--- Section for Vim |mode()|
---
--- Short output is returned if window width is lower than `args.trunc_width`.
---
---@param args table: Section arguments.
---@return tuple: Section string and mode's highlight group.
function M.section_mode(args)
  local mode_info = M.modes[vim.fn.mode()]

  local mode = M.is_truncated(args.trunc_width) and mode_info.short or mode_info.long

  return string.upper(mode), mode_info.hl
end

--- Section for Git information
---
--- Normal output contains name of `HEAD` (via |b:gitsigns_head|) and chunk
--- information (via |b:gitsigns_status|). Short output - only name of `HEAD`.
--- Note: requires 'lewis6991/gitsigns' plugin.
---
--- Short output is returned if window width is lower than `args.trunc_width`.
---
---@param args table: Section arguments. Use `args.icon` to supply your own icon.
---@return string: Section string.
function M.section_git(args)
  if U.isnt_normal_buffer() then
    return ""
  end

  local head = vim.b.gitsigns_head or "-"
  local signs = M.is_truncated(args.trunc_width) and "" or (vim.b.gitsigns_status or "")
  local icon = args.icon or C.icons.git

  if signs == "" then
    if head == "-" or head == "" then
      return ""
    end

    return unpack(U.item(head, "StBlue", { prefix = icon, prefix_color = "StGit" }))
  end

  return unpack(U.item(fmt("%s %s", head, signs), "StBlue", { prefix = icon, prefix_color = "StGit" }))
end

function M.section_gps(args)
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

--- Section for Neovim's builtin diagnostics
---
--- Shows nothing if there is no attached LSP clients or for short output.
--- Otherwise uses |vim.lsp.diagnostic.get_count()| to show number of errors
--- ('E'), warnings ('W'), information ('I'), and hints ('H').
---
--- Short output is returned if window width is lower than `args.trunc_width`.
---
---@param args table: Section arguments. Use `args.icon` to supply your own icon.
---@return string: Section string.
function M.section_diagnostics(args)
  -- Assumption: there are no attached clients if table
  -- `vim.lsp.buf_get_clients()` is empty
  local no_attached_client = next(vim.lsp.buf_get_clients()) == nil
  local dont_show_lsp = M.is_truncated(args.trunc_width) or U.isnt_normal_buffer() or no_attached_client
  if dont_show_lsp then
    return ""
  end

  -- Construct diagnostic info using predefined order
  local t = {}
  for _, level in ipairs(U.diagnostic_levels) do
    local n = U.get_diagnostic_count(level.id)
    -- Add level info only if diagnostic is present
    if n > 0 then
      table.insert(t, fmt(" %s %s", level.sign, n))
    end
  end

  local icon = args.icon or "ﯭ"
  if vim.tbl_count(t) == 0 then
    return ("%s -"):format(icon)
  end
  return fmt("%s %s", icon, table.concat(t, ""))
end

-- function M.section_diagnostics()
--  item(utils.lsp_status(ctx.bufnum), "StMetadata"),
--   item_if(diagnostics.error.count, diagnostics.error, "StError", {
--     prefix = diagnostics.error.sign,
--   }),
--   item_if(diagnostics.warning.count, diagnostics.warning, "StWarning", {
--     prefix = diagnostics.warning.sign,
--   }),
--   item_if(diagnostics.info.count, diagnostics.info, "StInfo", {
--     prefix = diagnostics.info.sign,
--   }),
--   item_if(diagnostics.hint.count, diagnostics.hint, "StHint", {
--     prefix = diagnostics.hint.sign,
--   }),
-- end

function M.section_modified(args)
  local ctx = U.ctx
  -- local minimal = M.is_truncated(args.trunc_width)
  if ctx.filetype == "help" then
    return ""
  end
  return unpack(U.item(U.modified(ctx), "StModified"))
end

function M.section_readonly(args)
  local ctx = U.ctx
  local minimal = M.is_truncated(args.trunc_width)
  -- return unpack(U.item_if(U.readonly(ctx), "StError"))
  return unpack(U.item_if(U.readonly(ctx), minimal, "StReadonly"))
end

-- { item_if(file_modified, ctx.modified, "StModified"), 1 },

--- Section for file name
---
--- Show full file name or relative in short output.
---
--- Short output is returned if window width is lower than `args.trunc_width`.
---
---@param args table: Section arguments.
---@return string: Section string.
function M.section_filename(args)
  local ctx = U.ctx
  local minimal = M.is_truncated(args.trunc_width)
  local segments = U.file(ctx, minimal)
  local dir, parent, file = segments.dir, segments.parent, segments.file
  local dir_item = U.item(dir.item, dir.hl, dir.opts)
  local parent_item = U.item(parent.item, parent.hl, parent.opts)
  local file_hl = ctx.modified and "StModified" or file.hl
  local file_item = U.item(file.item, file_hl, file.opts)
  local readonly_item = U.item(U.readonly(ctx), "StError")

  return fmt("%s%s%s", unpack(dir_item), unpack(parent_item), unpack(file_item))

  -- -- In terminal always use plain name
  -- if vim.bo.buftype == "terminal" then
  --   return "%t"
  -- elseif M.is_truncated(args.trunc_width) then
  --   -- File name with 'truncate', 'modified', 'readonly' flags
  --   -- Use relative path if truncated
  --   return "%f%m%r"
  -- else
  --   -- Use fullpath if not truncated
  --   return "%F%m%r"
  -- end
end

--- Section for file information
---
--- Short output contains only extension and is returned if window width is
--- lower than `args.trunc_width`.
---
---@param args table: Section arguments.
---@return string: Section string.
function M.section_fileinfo(args)
  local ft = vim.bo.filetype

  -- Don't show anything if can't detect file type or not inside a "normal
  -- buffer"
  if (ft == "") or U.isnt_normal_buffer() then
    return ""
  end

  -- Add filetype icon
  local icon = U.get_filetype_icon()
  if icon ~= "" then
    ft = fmt("%s %s", icon, ft)
  end

  -- Construct output string if truncated
  if M.is_truncated(args.trunc_width) then
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
function M.section_location(args)
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
  local current_col = "%v" -- can pad with `%<pad_n>v`
  -- local last_col = "%-2{col(\"$\") - 1}"

  -- local length = strwidth(prefix .. current .. col .. sep .. last)

  -- Use virtual column number to allow update when paste last column
  if M.is_truncated(args.trunc_width) then
    return "%l│%2v"
  end

  return table.concat({
    " ",
    U.wrap(prefix_color),
    prefix,
    " ",
    U.wrap(current_hl),
    current_line,
    U.wrap(sep_hl),
    sep,
    U.wrap(total_hl),
    last_line,
    U.wrap(col_hl),
    ":",
    current_col,
    " ",
  })
end

--- Section for current search count
---
--- Show the current status of |searchcount()|. Empty output is returned if
--- window width is lower than `args.trunc_width`, search highlighting is not
--- on (see |v:hlsearch|), or if number of search result is 0.
---
--- `args.options` is forwarded to |searchcount()|.  By default it recomputes
--- data on every call which can be computationally expensive (although still
--- usually same order of magnitude as 0.1 ms). To prevent this, supply
--- `args.options = {recompute = false}`.
---
---@param args table: Section arguments.
---@return string: Section string.
function M.section_searchcount(args)
  if vim.v.hlsearch == 0 or M.is_truncated(args.trunc_width) then
    return ""
  end
  local s_count = vim.fn.searchcount((args or {}).options or { recompute = true })
  if s_count.current == nil or s_count.total == 0 then
    return ""
  end

  if s_count.incomplete == 1 then
    return "?/?"
  end

  local total_sign = s_count.total > s_count.maxcount and ">" or ""
  local current_sign = s_count.current > s_count.maxcount and ">" or ""
  return ("%s%d/%s%d"):format(current_sign, s_count.current, total_sign, s_count.total)
end

function M.section_indention()
  return unpack(U.item_if(U.ctx.shiftwidth, U.ctx.shiftwidth > 2 or not U.ctx.expandtab, "StTitle", {
    prefix = U.ctx.expandtab and "Ξ" or "⇥",
    prefix_color = "StatusLine",
  }))
end

-- Helper functionality =======================================================
-- Settings -------------------------------------------------------------------
function U.is_disabled()
  return vim.g.megaline_disable == true or vim.b.megaline_disable == true
end

-- Default content ------------------------------------------------------------
function U.statusline_active()
  -- stylua: ignore start
  local prefix        = M.section_prefix({ trunc_width = 75 })
  local mode, mode_hl = M.section_mode({ trunc_width = 120 })
  local git           = M.section_git({ trunc_width = 75 })
  local diagnostics   = M.section_diagnostics({ trunc_width = 75 })
  -- FIXME: this doesn't bad things!
  -- local gps           = M.section_gps({ trunc_width = 75 })
  local diags         = U.diagnostic_info()
  local readonly      = M.section_readonly({ trunc_width = 75 })
  local modified      = M.section_modified({ trunc_width = 140 })
  local filename      = M.section_filename({ trunc_width = 140 })
  -- local fileinfo      = M.section_fileinfo({ trunc_width = 120 })
  local location      = M.section_location({ trunc_width = 75 })
  local indention   = M.section_indention()

  local diag_error =  unpack(U.item_if(diags.error.count, diags.error, "StError", { prefix = diags.error.sign }))
  local diag_warn =  unpack(U.item_if(diags.warn.count, diags.warn, "StWarn", { prefix = diags.warn.sign }))
  local diag_info =  unpack(U.item_if(diags.info.count, diags.info, "StInfo", { prefix = diags.info.sign }))
  local diag_hint =  unpack(U.item_if(diags.hint.count, diags.hint, "StHint", { prefix = diags.hint.sign }))

  -- Usage of `M.build()` ensures highlighting and
  -- correct padding with spaces between groups (accounts for 'missing'
  -- sections, etc.)
  return M.build({
    { hl = mode_hl,                   strings = { prefix } },
    { hl = mode_hl,                   strings = { mode } },
    '%<', -- Mark general truncate point
    { hl = 'StatusLine',              strings = { filename } },
    { hl = 'StModified',              strings = { modified } },
    { hl = 'StReadonly',              strings = { readonly } },
    '%=', -- End left alignment
    -- middle section for whatever we want..
    -- { hl = 'StatusLine',              strings = { gps } },
    '%=',
    { hl = 'Statusline', strings = { diag_error, diag_warn, diag_info, diag_hint }},
    -- { hl = 'StatusLine',              strings = { diagnostics } },
    { hl = 'StatusLine',              strings = { git } },
    -- { hl = 'StatusLine',              strings = { fileinfo } },
    { hl = mode_hl,                   strings = { location } },
    { hl = mode_hl,                   strings = { indention } },
  })
  -- stylua: ignore end
end

function U.statusline_inactive()
  -- stylua: ignore start
  -- local mode, mode_hl = M.section_mode({ trunc_width = 120 })
  -- local readonly      = M.section_readonly({ trunc_width = 75 })
  -- local modified      = M.section_modified({ trunc_width = 140 })
  -- local filename      = M.section_filename({ trunc_width = 140 })

  return "%#StInactive#%F%="
  -- return M.build({
  --   { hl = 'StInactive',              strings = { filename } },
  --   { hl = 'StInactive',              strings = { modified } },
  --   { hl = 'StInactive',              strings = { readonly } },
  --   '%=', -- End left alignment
  -- })
end

-- if minimal then
--   add(
--     { item_if(file_modified, ctx.modified, "StModified"), 1 },
--     { readonly_item, 1 },
--     { dir_item, 3 },
--     { parent_item, 2 },
--     { file_item, 0 }
--   )
--   return display(statusline, available_space)
-- end

return M
