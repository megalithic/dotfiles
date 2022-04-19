-- I've taken various aspects of my statusline from the following amazing devs:
-- @akinsho, @echasnovski, @lukas-reineke, @kristijanhusak

local M = {}

local fn = vim.fn
local api = vim.api
local expand = fn.expand
local strwidth = fn.strwidth
local fnamemodify = fn.fnamemodify
local fmt = string.format
local search_count_timer
local H = require("mega.utils.highlights")
local U = {}

-- FIXME: https://github.com/SmiteshP/nvim-gps/issues/89
-- require("nvim-gps").setup({
--   languages = {
--     heex = false,
--     elixir = false,
--     eelixir = false,
--   },
-- })

--- Timer to update the search count as the file is travelled
---@return function
function U.update_search_count(timer)
  search_count_timer = timer
  timer:start(0, 200, function()
    vim.schedule(function()
      if timer == search_count_timer then
        fn.searchcount({ recompute = 1, maxcount = 0, timeout = 100 })
        vim.cmd("redrawstatus")
      end
    end)
  end)
end

-- FIXME: presently focus variable setting isn't being used right
mega.augroup("megaline", {
  {
    event = { "FocusGained" },
    command = function()
      vim.g.vim_in_focus = true
    end,
  },
  {
    event = { "FocusLost" },
    command = function()
      vim.g.vim_in_focus = false
    end,
  },
  {
    event = { "WinEnter", "BufEnter" },
    command = function()
      -- :h qf.vim, disable qf statusline
      -- NOTE: this allows for our custom statusline exception-based naming to work
      vim.g.qf_disable_statusline = 1
      vim.wo.statusline = "%!v:lua.__activate_statusline()"
    end,
  },
  {
    event = { "WinLeave", "BufLeave" },
    command = function()
      vim.wo.statusline = "%!v:lua.__deactivate_statusline()"
    end,
  },
  {
    event = { "BufWritePre" },
    command = function()
      if not vim.g.is_saving and vim.bo.modified then
        vim.g.is_saving = true
        vim.defer_fn(function()
          vim.g.is_saving = false
        end, 1000)
      end
    end,
  },
  {
    event = { "CursorMoved" },
    command = function()
      if vim.o.hlsearch then
        U.update_search_count(vim.loop.new_timer())
      end
    end,
  },
})

-- Showed diagnostic levels
U.diagnostic_levels = nil
U.diagnostic_levels = {
  { id = vim.diagnostic.severity.ERROR, sign = mega.icons.lsp.error },
  { id = vim.diagnostic.severity.WARN, sign = mega.icons.lsp.warn },
  { id = vim.diagnostic.severity.INFO, sign = mega.icons.lsp.info },
  { id = vim.diagnostic.severity.HINT, sign = mega.icons.lsp.hint },
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
  return api.nvim_win_get_width(0) < (trunc or -1)
end

-- local inactive = vim.api.nvim_get_current_win() ~= curwin
-- local minimal = plain or inactive or not focused

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
    "neoterm",
    "vista",
    "fugitive",
    "startify",
    "vimwiki",
    "markdown",
    "NeogitStatus",
    "dap-repl",
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
    fugitive = mega.icons.vcs,
    fugitiveblame = mega.icons.vcs,
    gitcommit = mega.icons.vcs,
    Trouble = "",
    NeogitStatus = mega.icons.git.symbol,
    ["vim-plug"] = "⚉",
    vimwiki = "ﴬ",
    help = "",
    undotree = "פּ",
    NvimTree = "פּ",
    dirbuf = "פּ",
    toggleterm = " ",
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
    dirbuf = "DirBuf",
    toggleterm = get_toggleterm_name,
    ["dap-repl"] = "Debugger REPL",
  },
}

local function matches(str, list)
  return #vim.tbl_filter(function(item)
    return item == str or string.match(str, item)
  end, list) > 0
end

--- @param hl string
local function wrap_hl(hl)
  assert(hl, "A highlight name must be specified")
  return "%#" .. hl .. "#"
end

--- Creates a spacer statusline component i.e. for padding
--- or to represent an empty component
--- @param size number
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
  if not component or component == "" or component == 0 then
    return spacer()
  end
  opts = opts or {}
  local before = opts.before or ""
  local after = opts.after or " "
  local prefix = opts.prefix or ""
  local prefix_size = strwidth(prefix)

  local prefix_color = opts.prefix_color or hl
  prefix = prefix ~= "" and wrap_hl(prefix_color) .. prefix .. " " or ""

  --- handle numeric inputs etc.
  if type(component) ~= "string" then
    component = tostring(component)
  end

  if opts.max_size and component and #component >= opts.max_size then
    component = component:sub(1, opts.max_size - 1) .. "…"
  end

  local parts = { before, prefix, wrap_hl(hl), component, "%*", after }
  return { table.concat(parts), #component + #before + #after + prefix_size }
end

--- @param sl_item string
--- @param condition boolean
--- @param hl string
--- @param opts table
local function item_if(sl_item, condition, hl, opts)
  if not condition then
    return spacer()
  end
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
  if ctx.filetype == "help" then
    return ""
  end
  icon = icon or mega.icons.modified
  return ctx.modified and icon
end

--- @param ctx table
--- @param icon string | nil
function U.readonly(ctx, icon)
  icon = icon or mega.icons.readonly
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

  local name = exception_types.names[ctx.filetype]
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

---@param name string
---@param fg string
---@param bg string
local function create_hl(name, fg, bg)
  if fg and bg then
    api.nvim_set_hl(0, name, { foreground = fg, background = bg })
  end
end

--- @param hl string
--- @param bg_hl string
function U.highlight_ft_icon(color, hl, bg_hl)
  if not hl or not bg_hl then
    return
  end
  local name = hl .. "Statusline"
  -- TODO: find a mechanism to cache this so it isn't repeated constantly
  local fg_color = color -- H.get_hl(hl, "fg")
  local bg_color = H.get_hl(bg_hl, "bg")

  if bg_color and fg_color then
    -- local cmd = { "highlight ", name, " guibg=", bg_color, " guifg=", fg_color }
    -- local str = table.concat(cmd)
    -- mega.augroup(name, { event = "ColorScheme", command = str })
    -- vim.cmd(fmt("silent execute '%s'", str))
    mega.augroup(name, {
      {
        event = "ColorScheme",
        command = function()
          create_hl(name, fg_color, bg_color)
        end,
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
  if ft_exception then
    return ft_exception, opts.default
  end

  local bt_exception = exception_types.buftypes[ctx.buftype]
  if bt_exception then
    return bt_exception, opts.default
  end

  local icon, icon_hl, icon_color, hl
  local f_name, f_extension = vim.fn.expand("%:t") or ctx.bufname, vim.fn.expand("%:e")
  f_extension = f_extension ~= "" and f_extension or vim.bo.filetype

  local icons_loaded, devicons = mega.safe_require("nvim-web-devicons")
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

-- function U.get_filetype_icon()
--   -- Have this `require()` here to not depend on plugin initialization order
--   local has_devicons, devicons = pcall(require, "nvim-web-devicons")
--   if not has_devicons then
--     return ""
--   end

--   local file_name, file_ext = vim.fn.expand("%:t"), vim.fn.expand("%:e")
--   return devicons.get_icon(file_name, file_ext, { default = true })
-- end

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

function M.s_git(args)
  if U.abnormal_buffer() then
    return ""
  end

  local status = vim.b.gitsigns_status_dict or {}
  local signs = is_truncated(args.trunc_width) and "" or (vim.b.gitsigns_status or "")
  local branch = status.head

  if is_truncated(args.trunc_width) then
    branch = mega.truncate(branch or "", 12, false)
  end

  local head_str = unpack(
    item(
      branch,
      "StGitBranch",
      { before = " ", after = " ", prefix = mega.icons.git.symbol, prefix_color = "StGitSymbol" }
    )
  )
  local added_str = unpack(
    item(status.added, "StMetadataPrefix", { prefix = mega.icons.git.add, prefix_color = "StGitSignsAdd" })
  )
  local changed_str = unpack(
    item(status.changed, "StMetadataPrefix", { prefix = mega.icons.git.change, prefix_color = "StGitSignsChange" })
  )
  local removed_str = unpack(
    item(status.removed, "StMetadataPrefix", { prefix = mega.icons.git.remove, prefix_color = "StGitSignsDelete" })
  )

  if signs == "" then
    return head_str
  end

  return fmt("%s %s%s%s", head_str, added_str, changed_str, removed_str)
end

function M.s_gps(args)
  local gps = require("nvim-gps")
  if gps.is_available() then
    return unpack(item_if(gps.get_location(), is_truncated(args.trunc_width), "StMetaDataPrefix"))
  end

  return ""
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

  local buf = ctx.bufnum
  if vim.tbl_isempty(vim.lsp.buf_get_clients(buf)) then
    return { error = {}, warn = {}, info = {}, hint = {} }
  end
  return {
    error = { count = get_count(buf, "Error"), sign = mega.icons.lsp.error },
    warn = { count = get_count(buf, "Warn"), sign = mega.icons.lsp.warn },
    info = { count = get_count(buf, "Info"), sign = mega.icons.lsp.info },
    hint = { count = get_count(buf, "Hint"), sign = mega.icons.lsp.hint },
  }
end

function M.s_modified(args)
  if U.ctx.filetype == "help" then
    return ""
  end
  return unpack(item_if(U.modified(U.ctx), is_truncated(args.trunc_width), "StModified"))
end

function M.s_readonly(args)
  local readonly_hl = H.adopt_winhighlight(U.ctx.winid, "StatusLine", "StCustomError", "StError")
  return unpack(item_if(U.readonly(U.ctx), is_truncated(args.trunc_width), readonly_hl))
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
  local current_col = "%-3c"

  -- Use virtual column number to allow update when paste last column
  if is_truncated(args.trunc_width) then
    return "%l│%2v"
  end

  return table.concat({
    " ",
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

function M.s_indention()
  return unpack(item_if(U.ctx.shiftwidth, U.ctx.shiftwidth > 2 or not U.ctx.expandtab, "StTitle", {
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
local function statusline_active(ctx) -- _ctx
  -- stylua: ignore start
  local prefix                     = unpack(item_if(mega.icons.misc.block, not is_truncated(100), M.modes[vim.fn.mode()].hl, { before = "", after = "" }))
  local mode                       = M.s_mode({ trunc_width = 120 })
  local search                     = unpack(item_if(U.search_result(), not is_truncated(120) and vim.v.hlsearch > 0, "StCount", {before=" "}))
  local git                        = M.s_git({ trunc_width = 120 })
  local readonly                   = M.s_readonly({ trunc_width = 100 })
  local modified                   = M.s_modified({ trunc_width = 100 })
  local filename                   = M.s_filename({ trunc_width = 120 })
  local saving                     = unpack(item_if('Saving…', vim.g.is_saving, 'StComment', { before = ' ' }))
  local lineinfo                   = M.s_lineinfo({ trunc_width = 75 })
  local indention                  = M.s_indention()
  local diags                      = diagnostic_info()
  local diag_error                 = unpack(item_if(diags.error.count, diags.error, "StError", { prefix = diags.error.sign }))
  local diag_warn                  = unpack(item_if(diags.warn.count, diags.warn, "StWarn", { prefix = diags.warn.sign }))
  local diag_info                  = unpack(item_if(diags.info.count, diags.info, "StInfo", { prefix = diags.info.sign }))
  local diag_hint                  = unpack(item_if(diags.hint.count, diags.hint, "StHint", { prefix = diags.hint.sign }))
  -- local current_function           = M.s_gps({ trunc_width = 120 }) -- FIXME/related: https://github.com/andymass/vim-matchup/pull/216 and https://github.com/nvim-treesitter/nvim-treesitter/commit/c3848e713a8272e524a7eabe9eb0897cf2d6932e
  -- local fileinfo                = M.s_fileinfo({ trunc_width = 120 })
  -- stylua: ignore end

  local plain = U.is_plain(ctx)
  -- local file_modified = U.modified(ctx, mega.icons.misc.circle)
  local focused = vim.g.vim_in_focus or true

  if plain or not focused then
    return build({
      filename,
      modified,
      readonly,
    })
  end

  return build({
    prefix,
    mode,
    "%<", -- Mark general truncate point
    filename,
    modified,
    readonly,
    saving,
    search,
    "%=", -- End left alignment
    -- current_function,
    -- middle section for whatever we want..
    "%=",
    { hl = "Statusline", strings = { diag_error, diag_warn, diag_info, diag_hint } },
    git,
    lineinfo,
    indention,
  })
end

-- do the statusline things for the activate window
function _G.__activate_statusline()
  if U.is_disabled() then
    return ""
  end

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

  return statusline_active(ctx)
end

-- do the statusline things for the inactive window
function _G.__deactivate_statusline()
  return "%#StInactive#%F %m%="
end

return M
