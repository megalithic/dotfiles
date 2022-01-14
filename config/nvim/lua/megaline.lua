-- I've taken aspects of my statusline from the following amazing devs:
-- @akinsho, @echasnovski, @lukas-reineke, @kristijanhusak

local C = require("colors")

local fn = vim.fn
local api = vim.api
local expand = fn.expand
local strwidth = fn.strwidth
local fnamemodify = fn.fnamemodify
local contains = vim.tbl_contains
local fmt = string.format
local H = require("utils.highlights")

local Megaline = {}
local utils = {}

--- Module setup
---
---@param config table: Module config table.
---@usage `require('mini.statusline').setup({})` (replace `{}` with your `config` table)
function Megaline.setup(config)
  -- use the statusline global variable which is set inside of statusline
  -- functions to the window for *that* statusline
  local curwin = vim.g.statusline_winid or 0
  local curbuf = vim.api.nvim_win_get_buf(curwin)

  -- TODO: reduce the available space whenever we add
  -- a component so we can use it to determine what to add
  -- local available_space = vim.api.nvim_win_get_width(curwin)

  utils.ctx = {
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

  -- Export module
  _G.MiniStatusline = Megaline

  -- Setup config
  config = utils.setup_config(config)

  -- Apply config
  utils.apply_config(config)

  -- Module behavior
  vim.api.nvim_exec(
    [[augroup MiniStatusline
        au!
        au WinEnter,BufEnter * setlocal statusline=%!v:lua.MiniStatusline.active()
        au WinLeave,BufLeave * setlocal statusline=%!v:lua.MiniStatusline.inactive()
      augroup END]],
    false
  )

  -- Create highlighting
  vim.api.nvim_exec(
    [[hi default link MiniStatuslineModeNormal  StModeNormal
      hi default link MiniStatuslineModeInsert  StModeInsert
      hi default link MiniStatuslineModeVisual  StModeVisual
      hi default link MiniStatuslineModeReplace StModeReplace
      hi default link MiniStatuslineModeCommand StModeCommand
      hi default link MiniStatuslineModeOther   Cursor

      hi default link MiniStatuslineDevinfo  StatusLine
      hi default link MiniStatuslineFilename StatusLineNC
      hi default link MiniStatuslineFileinfo StatusLine
      hi default link MiniStatuslineInactive StatusLineNC]],
    false
  )
end

Megaline.config = {
  -- Content of statusline as functions which return statusline string. See `:h
  -- statusline` and code of default contents (used when `nil` is supplied).
  content = {
    -- Content for active window
    active = nil,
    -- Content for inactive window(s)
    inactive = nil,
  },

  -- Whether to set Vim's settings for statusline
  set_vim_settings = true,
}

-- Module functionality =======================================================
--- Compute content for active window
function Megaline.active()
  if utils.is_disabled() then
    return ""
  end

  return (Megaline.config.content.active or utils.default_content_active)()
end

--- Compute content for inactive window
function Megaline.inactive()
  if utils.is_disabled() then
    return ""
  end

  return (Megaline.config.content.inactive or utils.default_content_inactive)()
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
function Megaline.combine_groups(groups)
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
    end
    return fmt("%%#%s# %s ", s.hl or "", table.concat(t, " "))
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
function Megaline.is_truncated(trunc_width)
  -- Use -1 to default to 'not truncated'
  return vim.api.nvim_win_get_width(0) < (trunc_width or -1)
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
Megaline.modes = setmetatable({
  ['n']    = { long = 'Normal',   short = 'N',   hl = 'MiniStatuslineModeNormal' },
  ['v']    = { long = 'Visual',   short = 'V',   hl = 'MiniStatuslineModeVisual' },
  ['V']    = { long = 'V-Line',   short = 'V-L', hl = 'MiniStatuslineModeVisual' },
  [CTRL_V] = { long = 'V-Block',  short = 'V-B', hl = 'MiniStatuslineModeVisual' },
  ['s']    = { long = 'Select',   short = 'S',   hl = 'MiniStatuslineModeVisual' },
  ['S']    = { long = 'S-Line',   short = 'S-L', hl = 'MiniStatuslineModeVisual' },
  [CTRL_S] = { long = 'S-Block',  short = 'S-B', hl = 'MiniStatuslineModeVisual' },
  ['i']    = { long = 'Insert',   short = 'I',   hl = 'MiniStatuslineModeInsert' },
  ['R']    = { long = 'Replace',  short = 'R',   hl = 'MiniStatuslineModeReplace' },
  ['c']    = { long = 'Command',  short = 'C',   hl = 'MiniStatuslineModeCommand' },
  ['r']    = { long = 'Prompt',   short = 'P',   hl = 'MiniStatuslineModeOther' },
  ['!']    = { long = 'Shell',    short = 'Sh',  hl = 'MiniStatuslineModeOther' },
  ['t']    = { long = 'Terminal', short = 'T',   hl = 'MiniStatuslineModeOther' },
}, {
  -- By default return 'Unknown' but this shouldn't be needed
  __index = function()
    return   { long = 'Unknown',  short = 'U',   hl = '%#MiniStatuslineModeOther#' }
  end,
})
-- stylua: ignore end

--- Section for Vim |mode()|
---
--- Short output is returned if window width is lower than `args.trunc_width`.
---
---@param args table: Section arguments.
---@return tuple: Section string and mode's highlight group.
function Megaline.section_mode(args)
  local mode_info = Megaline.modes[vim.fn.mode()]

  local mode = Megaline.is_truncated(args.trunc_width) and mode_info.short or mode_info.long

  return mode, mode_info.hl
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
function Megaline.section_git(args)
  if utils.isnt_normal_buffer() then
    return ""
  end

  local head = vim.b.gitsigns_head or "-"
  local signs = Megaline.is_truncated(args.trunc_width) and "" or (vim.b.gitsigns_status or "")
  local icon = args.icon or ""

  if signs == "" then
    if head == "-" or head == "" then
      return ""
    end
    return fmt("%s %s", icon, head)
  end
  return fmt("%s %s %s", icon, head, signs)
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
function Megaline.section_diagnostics(args)
  -- Assumption: there are no attached clients if table
  -- `vim.lsp.buf_get_clients()` is empty
  local no_attached_client = next(vim.lsp.buf_get_clients()) == nil
  local dont_show_lsp = Megaline.is_truncated(args.trunc_width) or utils.isnt_normal_buffer() or no_attached_client
  if dont_show_lsp then
    return ""
  end

  -- Construct diagnostic info using predefined order
  local t = {}
  for _, level in ipairs(utils.diagnostic_levels) do
    local n = utils.get_diagnostic_count(level.id)
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

--- Section for file name
---
--- Show full file name or relative in short output.
---
--- Short output is returned if window width is lower than `args.trunc_width`.
---
---@param args table: Section arguments.
---@return string: Section string.
function Megaline.section_filename(args)
  local ctx = utils.ctx
  local minimal = Megaline.is_truncated(args.trunc_width)
  local segments = utils.file(ctx, minimal)
  local dir, parent, file = segments.dir, segments.parent, segments.file
  local dir_item = utils.item(dir.item, dir.hl, dir.opts)
  local parent_item = utils.item(parent.item, parent.hl, parent.opts)
  local file_hl = ctx.modified and "StModified" or file.hl
  local file_item = utils.item(file.item, file_hl, file.opts)
  local readonly_item = utils.item(utils.readonly(ctx), "StError")

  return fmt("%s%s%s", unpack(dir_item), unpack(parent_item), unpack(file_item))

  -- -- In terminal always use plain name
  -- if vim.bo.buftype == "terminal" then
  --   return "%t"
  -- elseif Megaline.is_truncated(args.trunc_width) then
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
function Megaline.section_fileinfo(args)
  local ft = vim.bo.filetype

  -- Don't show anything if can't detect file type or not inside a "normal
  -- buffer"
  if (ft == "") or utils.isnt_normal_buffer() then
    return ""
  end

  -- Add filetype icon
  local icon = utils.get_filetype_icon()
  if icon ~= "" then
    ft = fmt("%s %s", icon, ft)
  end

  -- Construct output string if truncated
  if Megaline.is_truncated(args.trunc_width) then
    return ft
  end

  -- Construct output string with extra file info
  local encoding = vim.bo.fileencoding or vim.bo.encoding
  local format = vim.bo.fileformat
  local size = utils.get_filesize()

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
function Megaline.section_location(args)
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
  if Megaline.is_truncated(args.trunc_width) then
    return "%l│%2v"
  end

  return table.concat({
    " ",
    utils.wrap(prefix_color),
    prefix,
    " ",
    utils.wrap(current_hl),
    current_line,
    utils.wrap(sep_hl),
    sep,
    utils.wrap(total_hl),
    last_line,
    utils.wrap(col_hl),
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
function Megaline.section_searchcount(args)
  if vim.v.hlsearch == 0 or Megaline.is_truncated(args.trunc_width) then
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

-- Helper data ================================================================
-- Module default config
utils.default_config = Megaline.config

-- Showed diagnostic levels
utils.diagnostic_levels = nil
if vim.fn.has("nvim-0.6") == 1 then
  utils.diagnostic_levels = {
    { id = vim.diagnostic.severity.ERROR, sign = C.icons.lsp.error },
    { id = vim.diagnostic.severity.WARN, sign = C.icons.lsp.warn },
    { id = vim.diagnostic.severity.INFO, sign = C.icons.lsp.info },
    { id = vim.diagnostic.severity.HINT, sign = C.icons.lsp.hint },
  }
else
  utils.diagnostic_levels = {
    { id = "Error", sign = C.icons.lsp.error },
    { id = "Warning", sign = C.icons.lsp.warn },
    { id = "Information", sign = C.icons.lsp.info },
    { id = "Hint", sign = C.icons.lsp.hint },
  }
end

-- Helper functionality =======================================================
-- Settings -------------------------------------------------------------------
function utils.setup_config(config)
  -- General idea: if some table elements are not present in user-supplied
  -- `config`, take them from default config
  vim.validate({ config = { config, "table", true } })
  config = vim.tbl_deep_extend("force", utils.default_config, config or {})

  vim.validate({
    content = { config.content, "table" },
    ["content.active"] = { config.content.active, "function", true },
    ["content.inactive"] = { config.content.inactive, "function", true },

    set_vim_settings = { config.set_vim_settings, "boolean" },
  })

  return config
end

function utils.apply_config(config)
  Megaline.config = config

  -- Set settings to ensure statusline is displayed properly
  if config.set_vim_settings then
    vim.o.laststatus = 2 -- Always show statusline
  end
end

function utils.is_disabled()
  return vim.g.ministatusline_disable == true or vim.b.ministatusline_disable == true
end

-- Default content ------------------------------------------------------------
function utils.default_content_active()
  -- stylua: ignore start
  local mode, mode_hl = Megaline.section_mode({ trunc_width = 120 })
  local git           = Megaline.section_git({ trunc_width = 75 })
  local diagnostics   = Megaline.section_diagnostics({ trunc_width = 75 })
  local filename      = Megaline.section_filename({ trunc_width = 140 })
  local fileinfo      = Megaline.section_fileinfo({ trunc_width = 120 })
  local location      = Megaline.section_location({ trunc_width = 75 })

  -- Usage of `MiniStatusline.combine_groups()` ensures highlighting and
  -- correct padding with spaces between groups (accounts for 'missing'
  -- sections, etc.)
  return Megaline.combine_groups({
    { hl = mode_hl,                  strings = { mode } },
    { hl = 'MiniStatuslineDevinfo',  strings = { git, diagnostics } },
    '%<', -- Mark general truncate point
    { hl = 'MiniStatuslineFilename', strings = { filename } },
    '%=', -- End left alignment
    { hl = 'MiniStatuslineFileinfo', strings = { fileinfo } },
    { hl = mode_hl,                  strings = { location } },
  })
  -- stylua: ignore end
end

function utils.default_content_inactive()
  return "%#MiniStatuslineInactive#%F%="
end

-- Utilities ------------------------------------------------------------------
utils.exceptions = {
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
    vista = "פּ",
    tsplayground = "侮",
    fugitive = C.icons.git_symbol,
    fugitiveblame = C.icons.git_symbol,
    gitcommit = C.icons.git_symbol,
    startify = "",
    defx = "⌨",
    ctrlsf = "🔍",
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
    vista = "Vista",
    fugitive = "Fugitive",
    fugitiveblame = "Git blame",
    NeogitStatus = "Neogit Status",
    Trouble = "Lsp Trouble",
    gitcommit = "Git commit",
    startify = "Startify",
    defx = "Defx",
    ctrlsf = "CtrlSF",
    ["vim-plug"] = "vim plug",
    vimwiki = "vim wiki",
    help = "help",
    fzf = "fzf-lua",
    undotree = "UndoTree",
    octo = "Octo",
    ["coc-explorer"] = "Coc Explorer",
    NvimTree = "Nvim Tree",
    -- toggleterm = get_toggleterm_name,
    ["dap-repl"] = "Debugger REPL",
  },
}

--- @param hl string
function utils.wrap(hl)
  assert(hl, "A highlight name must be specified")
  return "%#" .. hl .. "#"
end

--- Creates a spacer statusline component i.e. for padding
--- or to represent an empty component
--- @param size number
--- @param filler string | nil
function utils.spacer(size, filler)
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
function utils.item(component, hl, opts)
  -- do not allow empty values to be shown note 0 is considered empty
  -- since if there is nothing of something I don't need to see it
  if not component or component == "" or component == 0 then
    return utils.spacer()
  end
  opts = opts or {}
  local before = opts.before or ""
  local after = opts.after or " "
  local prefix = opts.prefix or ""
  local prefix_size = strwidth(prefix)

  local prefix_color = opts.prefix_color or hl
  prefix = prefix ~= "" and utils.wrap(prefix_color) .. prefix .. " " or ""

  --- handle numeric inputs etc.
  if type(component) ~= "string" then
    component = tostring(component)
  end

  if opts.max_size and component and #component >= opts.max_size then
    component = component:sub(1, opts.max_size - 1) .. "…"
  end

  local parts = { before, prefix, utils.wrap(hl), component, "%*", after }
  return { table.concat(parts), #component + #before + #after + prefix_size }
end

--- @param item string
--- @param condition boolean
--- @param hl string
--- @param opts table
function utils.item_if(item, condition, hl, opts)
  if not condition then
    return utils.spacer()
  end
  return utils.item(item, hl, opts)
end

--- This function allow me to specify titles for special case buffers
--- like the preview window or a quickfix window
--- CREDIT: https://vi.stackexchange.com/a/18090
--- @param ctx table
function utils.special_buffers(ctx)
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
function utils.modified(ctx, icon)
  icon = icon or "✎"
  if ctx.filetype == "help" then
    return ""
  end
  return ctx.modified and icon or ""
end

--- @param ctx table
--- @param icon string | nil
function utils.readonly(ctx, icon)
  icon = icon or ""
  if ctx.readonly then
    return " " .. icon
  else
    return ""
  end
end

--- @param bufnum number
--- @param mod string
function utils.buf_expand(bufnum, mod)
  return expand("#" .. bufnum .. mod)
end

function utils.empty_opts()
  return { before = "", after = "" }
end

--- @param ctx table
--- @param modifier string
function utils.filename(ctx, modifier)
  modifier = modifier or ":t"
  local special_buf = utils.special_buffers(ctx)
  if special_buf then
    return "", "", special_buf
  end

  local fname = utils.buf_expand(ctx.bufnum, modifier)

  local name = utils.exceptions.names[ctx.filetype]
  if type(name) == "function" then
    return "", "", name(fname, ctx.bufnum)
  end

  if name then
    return "", "", name
  end

  if not fname then
    return "", "", "No Name"
  end

  local path = (ctx.buftype == "" and not ctx.preview) and utils.buf_expand(ctx.bufnum, ":~:.:h") or nil
  local is_root = path and #path == 1 -- "~" or "."
  local dir = path and not is_root and fn.pathshorten(fnamemodify(path, ":h")) .. "/" or ""
  local parent = path and (is_root and path or fnamemodify(path, ":t")) or ""
  parent = parent ~= "" and parent .. "/" or ""

  return dir, parent, fname
end

--- @param hl string
--- @param bg_hl string
function utils.highlight_ft_icon(hl, bg_hl)
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
function utils.filetype(ctx, opts)
  local ft_exception = utils.exceptions.filetypes[ctx.filetype]
  if ft_exception then
    return ft_exception, opts.default
  end
  local bt_exception = utils.exceptions.buftypes[ctx.buftype]
  if bt_exception then
    return bt_exception, opts.default
  end
  local icon, hl
  local extension = fnamemodify(ctx.bufname, ":e")
  local icons_loaded, devicons = mega.safe_require("nvim-web-devicons")
  if icons_loaded then
    icon, hl = devicons.get_icon(ctx.bufname, extension, { default = true })
    hl = utils.highlight_ft_icon(hl, opts.icon_bg)
  end
  return icon, hl
end

function utils.file(ctx, minimal)
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

  local ft_icon, icon_highlight = utils.filetype(ctx, { icon_bg = "StatusLine", default = "StComment" })

  local file_opts, parent_opts, dir_opts = utils.empty_opts(), utils.empty_opts(), utils.empty_opts()
  local directory, parent, file = utils.filename(ctx)

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

function utils.isnt_normal_buffer()
  -- For more information see ":h buftype"
  return vim.bo.buftype ~= ""
end

function utils.get_filesize()
  local size = vim.fn.getfsize(vim.fn.getreg("%"))
  if size < 1024 then
    return fmt("%dB", size)
  elseif size < 1048576 then
    return fmt("%.2fKiB", size / 1024)
  else
    return fmt("%.2fMiB", size / 1048576)
  end
end

function utils.get_filetype_icon()
  -- Have this `require()` here to not depend on plugin initialization order
  local has_devicons, devicons = pcall(require, "nvim-web-devicons")
  if not has_devicons then
    return ""
  end

  local file_name, file_ext = vim.fn.expand("%:t"), vim.fn.expand("%:e")
  return devicons.get_icon(file_name, file_ext, { default = true })
end

utils.get_diagnostic_count = nil
if vim.fn.has("nvim-0.6") == 1 then
  utils.get_diagnostic_count = function(id)
    return #vim.diagnostic.get(0, { severity = id })
  end
else
  utils.get_diagnostic_count = function(id)
    return vim.lsp.diagnostic.get_count(0, id)
  end
end

return Megaline

--
-- local C = require("colors")
-- local hi, au = mega.highlight, mega.au
-- local fn, vcmd, bo, wo, api = vim.fn, vim.cmd, vim.bo, vim.wo, vim.api

-- mega.statusline = {}

-- local c = {}
-- local s = {}

-- local curwin = vim.g.statusline_winid or 0
-- local curbuf = vim.api.nvim_win_get_buf(curwin)

-- local ctx = {
--   bufnum = curbuf,
--   winid = curwin,
--   bufname = vim.fn.bufname(curbuf),
--   preview = vim.wo[curwin].previewwindow,
--   readonly = vim.bo[curbuf].readonly,
--   filetype = vim.bo[curbuf].ft,
--   buftype = vim.bo[curbuf].bt,
--   modified = vim.bo[curbuf].modified,
--   fileformat = vim.bo[curbuf].fileformat,
--   shiftwidth = vim.bo[curbuf].shiftwidth,
--   expandtab = vim.bo[curbuf].expandtab,
-- }

-- function mega.statusline.colors()
--   s.inactive = { color = "%#StInactive#", no_padding = true }

--   s.mode_block = { color = "%#StMode#", sep_color = "%#StModeSep#", no_before = true, no_padding = true }
--   s.mode = { color = "%#StMode#", sep_color = "%#StModeSep#", no_before = true }
--   s.mode_right = vim.tbl_extend("force", s.mode, { side = "right", no_before = false })
--   s.section_2 = { color = "%#StItem2#", sep_color = "%#StSep2#" }
--   s.section_3 = { color = "%#StItem3#", sep_color = "%#StSep3#" }
--   s.lsp = vim.tbl_extend("force", s.section_3, { no_padding = true })
--   s.search = vim.tbl_extend("force", s.section_3, { color = "%#StItemSearch#" })
--   s.gps = vim.tbl_extend("force", s.section_3, { color = "%#StItemInfo#" })
--   s.err = { color = "%#StErr#", sep_color = "%#StErrSep#" }
--   s.err_right = vim.tbl_extend("force", s.err, { side = "right" })
--   s.warn_right = { color = "%#StWarn#", sep_color = "%#StWarnSep#", side = "right", no_after = true }
-- end

-- local function get_lsp_status()
--   -- # LSP status
--   local lsp_status = require("lsp-status")
--   lsp_status.register_progress()
--   lsp_status.config({
--     status_symbol = "",
--     indicator_errors = C.icons.statusline_error,
--     indicator_warnings = C.icons.statusline_warning,
--     indicator_info = C.icons.statusline_information,
--     indicator_hint = C.icons.statusline_hint,
--     indicator_ok = C.icons.statusline_ok,
--     -- spinner_frames = {"⣾", "⣽", "⣻", "⢿", "⡿", "⣟", "⣯", "⣷"},
--     spinner_frames = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" },
--   })

--   if #vim.lsp.buf_get_clients() > 0 then
--     return lsp_status.status(ctx.bufnum)
--   end
--   return ""
-- end

-- -- REF: https://github.com/kristijanhusak/neovim-config/blob/master/nvim/lua/partials/statusline.lua#L29-L57
-- local function seg(item, opts, show)
--   opts = opts or {}
--   if show == nil then
--     show = true
--   end
--   if not show then
--     return ""
--   end

--   local color = opts.color or "%#StItem#"
--   local pad = " "
--   if opts.no_padding then
--     pad = ""
--   end

--   return pad .. color .. item .. pad .. "%*"
-- end

-- local function mode_highlight(mode)
--   if mode == "n" then
--     hi("StModeSep", { guifg = c.normal_bg, guibg = c.normal_fg })
--     hi("StMode", { guifg = c.normal_fg, guibg = c.normal_bg, gui = "bold" })
--   elseif mode == "i" then
--     hi("StModeSep", { guifg = c.insert_bg, guibg = c.insert_fg })
--     hi("StMode", { guifg = c.insert_fg, guibg = c.insert_bg, gui = "bold" })
--   elseif vim.tbl_contains({ "v", "V", "" }, mode) then
--     hi("StModeSep", { guifg = c.visual_bg, guibg = c.visual_fg })
--     hi("StMode", { guifg = c.visual_fg, guibg = c.visual_bg, gui = "bold" })
--   elseif mode == "R" then
--     hi("StModeSep", { guifg = c.replace_bg, guibg = c.replace_fg })
--     hi("StMode", { guifg = c.replace_fg, guibg = c.replace_bg, gui = "bold" })
--   end
-- end

-- local function with_icon(value, icon, after)
--   if not value then
--     return value
--   end

--   if after then
--     return value .. " " .. icon
--   end

--   return icon .. " " .. value
-- end

-- local function get_mode_status()
--   local mode = api.nvim_get_mode().mode
--   mode_highlight(mode)
--   local modeMap = {
--     -- ["n"] = "NORMAL",
--     -- ["niI"] = "NORMAL",
--     -- ["niR"] = "NORMAL",
--     -- ["niV"] = "NORMAL",
--     -- ["v"] = "VISUAL",
--     -- ["V"] = "VLINE",
--     -- [""] = "VBLOCK",
--     -- ["s"] = "SELECT",
--     -- ["S"] = "SLINE",
--     -- [""] = "SBLOCK",
--     -- ["i"] = "INSERT",
--     -- ["ic"] = "INSERT",
--     -- ["ix"] = "INSERT",
--     -- ["R"] = "REPLACE",
--     -- ["Rc"] = "REPLACE",
--     -- ["Rx"] = "REPLACE",
--     -- ["Rv"] = "VREPLACE",
--     -- ["c"] = "COMMAND",
--     -- ["cv"] = "EX",
--     -- ["ce"] = "EX",
--     -- ["r"] = "R",
--     -- ["rm"] = "MORE",
--     -- ["r?"] = "CONFIRM",
--     -- ["!"] = "SHELL",
--     -- ["t"] = "TERMINAL",

--     ["n"] = "NORMAL",
--     ["no"] = "N·OPERATOR PENDING ",
--     ["v"] = "VISUAL",
--     ["V"] = "V·LINE",
--     [""] = "V·BLOCK",
--     ["s"] = "SELECT",
--     ["S"] = "S·LINE",
--     ["^S"] = "S·BLOCK",
--     ["i"] = "INSERT",
--     ["R"] = "REPLACE",
--     ["Rv"] = "V·REPLACE",
--     ["Rx"] = "C·REPLACE",
--     ["Rc"] = "C·REPLACE",
--     ["c"] = "COMMAND",
--     ["cv"] = "VIM EX",
--     ["ce"] = "EX",
--     ["r"] = "PROMPT",
--     ["rm"] = "MORE",
--     ["r?"] = "CONFIRM",
--     ["!"] = "SHELL",
--     ["t"] = "TERMINAL",

--     -- n = "NORMAL",
--     -- i = "INSERT",
--     -- R = "REPLACE",
--     -- v = "VISUAL",
--     -- V = "V-LINE",
--     -- c = "COMMAND",
--     -- [""] = "V-BLOCK",
--     -- s = "SELECT",
--     -- S = "S-LINE",
--     -- [""] = "S-BLOCK",
--     -- t = "TERMINAL",

--     -- ["n"] = "N",
--     -- ["niI"] = "N",
--     -- ["niR"] = "N",
--     -- ["niV"] = "N",
--     -- ["v"] = "V",
--     -- ["V"] = "VL",
--     -- [""] = "VB",
--     -- ["s"] = "S",
--     -- ["S"] = "SL",
--     -- [""] = "SB",
--     -- ["i"] = "I",
--     -- ["ic"] = "I",
--     -- ["ix"] = "I",
--     -- ["R"] = "R",
--     -- ["Rc"] = "R",
--     -- ["Rx"] = "R",
--     -- ["Rv"] = "VR",
--     -- ["c"] = "C",
--     -- ["cv"] = "EX",
--     -- ["ce"] = "EX",
--     -- ["r"] = "R",
--     -- ["rm"] = "MORE",
--     -- ["r?"] = "CONFIRM",
--     -- ["!"] = "SHELL",
--     -- ["t"] = "T"
--   }

--   -- return with_icon(fmt("%s", modeMap[mode]), colorscheme.icons.mode_symbol, true) or "?"
--   return with_icon(fmt("%s", modeMap[mode]), "", true) or "?"
-- end

-- local function get_mode_block()
--   get_mode_status()
--   local item = "" -- █
--   return item .. "" .. "%*"
-- end

-- local function get_vcs_status()
--   local result = {}
--   local branch = fn["gitbranch#name"]()
--   if branch ~= nil and branch:len() > 0 then
--     table.insert(result, branch)
--   end
--   if #result == 0 then
--     return ""
--   end
--   return with_icon(table.concat(result, " "), C.icons.git_symbol)
-- end

-- local function get_fileicon()
--   local filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":t")
--   local extension = string.match(filename, "%a+$")
--   local devicons = require("nvim-web-devicons")
--   local icon = devicons.get_icon(filename, extension) or ""
--   return icon
-- end

-- local function get_filepath(_uses_icon)
--   local uses_icon = _uses_icon == nil and true
--   local full_path = fn.expand("%:p")
--   local path = full_path
--   local cwd = fn.getcwd()
--   if path == "" then
--     path = cwd
--   end
--   local stats = vim.loop.fs_stat(path)
--   if stats and stats.type == "directory" then
--     return fn.fnamemodify(path, ":~")
--   end

--   if full_path:match("^" .. cwd) then
--     path = fn.expand("%:.")
--   else
--     path = fn.expand("%:~")
--   end

--   if #path < 20 then
--     return "%f"
--   end

--   local icon = uses_icon and get_fileicon() or ""
--   return table.concat({
--     icon,
--     " ",
--     fn.pathshorten(path),
--   }, "")
-- end

-- -- REF: https://github.com/vheon/home/blob/master/.config/nvim/lua/statusline.lua#L114-L132
-- local function get_filetype()
--   local icon = get_fileicon()
--   local ft = bo.filetype

--   return table.concat({
--     icon,
--     " ",
--     ft,
--   }, "")
-- end

-- local function search_result()
--   if vim.v.hlsearch == 0 then
--     return ""
--   end
--   local last_search = fn.getreg("/")
--   if not last_search or last_search == "" then
--     return ""
--   end
--   local searchcount = fn.searchcount({ maxcount = 9999 })
--   return " " .. last_search:gsub("\\v", "") .. "(" .. searchcount.current .. "/" .. searchcount.total .. ")"
-- end

-- local function get_lineinfo()
--   -- vert_sep = "\uf6d8"             "⋮
--   -- ln_sep   = "\ue0a1"             "ℓ
--   -- col_sep  = "\uf6da"             "
--   -- perc_sep = "\uf44e"             "
--   --
--   local item = "ℓ"
--   return "" .. item .. " %l:%c/%L%*"
-- end

-- -- local function get_container_info()
-- -- 	return vim.g.currentContainer
-- -- end

-- local function statusline_active()
--   -- -- TODO: reduce the available space whenever we add
--   -- -- a component so we can use it to determine what to add
--   -- local available_space = vim.api.nvim_win_get_width(curwin)

--   -- local plain = utils.is_plain(ctx)
--   -- local file_modified = utils.modified(ctx, "●")
--   -- local inactive = vim.api.nvim_get_current_win() ~= curwin
--   -- local focused = vim.g.vim_in_focus or true
--   -- local minimal = plain or inactive or not focused

--   -- local segments = utils.file(ctx, minimal)
--   -- local dir, parent, file = segments.dir, segments.parent, segments.file
--   -- local dir_item = utils.item(dir.item, dir.hl, dir.opts)
--   -- local parent_item = utils.item(parent.item, parent.hl, parent.opts)
--   -- local file_item = utils.item(file.item, file.hl, file.opts)

--   local mode_block = get_mode_block()
--   local vcs_status = get_vcs_status()
--   local search = search_result()
--   local ft = get_filetype()
--   local lsp = get_lsp_status()
--   -- local container_info = get_container_info()

--   local statusline_sections = {
--     seg(mode_block, s.mode_block),
--     seg(get_mode_status(), s.mode),
--     "%<",
--     seg(vcs_status, s.section_2, vcs_status ~= ""),
--     -- seg(container_info, s.section_3, container_info ~= ""),
--     seg(get_filepath(false), bo.modified and s.err or s.section_3),
--     -- seg(dir.item),
--     -- seg(parent.item),
--     -- seg(file.item),
--     -- dir_item,
--     -- parent_item,
--     -- file_item,
--     seg(fmt("%s", ""), vim.tbl_extend("keep", { no_padding = true }, s.err), bo.modified),
--     seg(fmt("%s", C.icons.readonly_symbol), s.err, not bo.modifiable),
--     seg("%w", nil, wo.previewwindow),
--     seg("%r", nil, bo.readonly),
--     seg("%q", nil, bo.buftype == "quickfix"),
--     "%=",
--     -- middle section for whatever we want..
--     "%=",
--     seg(search, vim.tbl_extend("keep", { side = "right" }, s.search), search ~= ""),
--     seg(lsp, vim.tbl_extend("keep", { side = "right" }, s.section_3), lsp ~= ""),
--     seg(ft, vim.tbl_extend("keep", { side = "right" }, s.section_2), ft ~= ""),
--     seg(get_lineinfo(), s.mode_right),
--     seg(mode_block, s.mode_block),
--     "%<",
--   }

--   return table.concat(statusline_sections, "")
-- end

-- local function statusline_inactive()
--   return seg([[%f %m %r]], s.inactive) -- relativepath modified readonly
-- end

-- function mega.statusline.setup()
--   local focus = vim.g.statusline_winid == fn.win_getid()
--   if focus then
--     return statusline_active()
--   end
--   return statusline_inactive()
-- end

-- au([[VimEnter,ColorScheme * call v:lua.mega.statusline.colors()]])
-- vim.wo.statusline = "%!v:lua.mega.statusline.setup()"
