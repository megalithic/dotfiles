if not Plugin_enabled() then
  vim.o.statusline = "%#Statusline# %2{mode()} | %F %m %r %= %{&spelllang} %y %8(%l,%c%) %8p%%"
  return
end

mega.ui.statusline = {}

-- HT: @akinsho, @echasnovski, @lukas-reineke, @kristijanhusak, @mfussenegger

local M = {}

local fn = vim.fn
local api = vim.api
local expand = fn.expand
local strwidth = fn.strwidth
local fnamemodify = fn.fnamemodify
local fmt = string.format
local get_opt = api.nvim_get_option_value

-- local mini_icons = require("mini.icons")

local U = require("config.utils")
local SETTINGS = require("config.options")

vim.g.is_saving = false
vim.g.lsp_progress_messages = ""

local redrawstatus = vim.schedule_wrap(function()
  vim.cmd.redrawstatus()
  -- api.nvim__redraw({ statusline = true })
end)

local clear_messages_timer
local clear_messages_on_end

-- local function setup_highlights()
--   vim.api.nvim_set_hl(0, "BuffersActive", state.config.colors.active)
--   vim.api.nvim_set_hl(0, "BuffersPrevious", state.config.colors.previous)
--   vim.api.nvim_set_hl(0, "BuffersInactive", state.config.colors.inactive)
--   vim.api.nvim_set_hl(0, "BuffersError", state.config.colors.error)
--   vim.api.nvim_set_hl(0, "BuffersModified", state.config.colors.modified)
-- end

--
---- Include parent directory for index files or duplicates
-- if name:match("^index%.") or has_duplicate then
--   local parent = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ":h:t")
--   return parent .. "/" .. name
-- end

Augroup("mega.ui.statusline", {
  {
    event = { "BufWritePre" },
    command = function()
      if not vim.g.is_saving and vim.bo.modified then
        vim.g.is_saving = true
        vim.cmd([[checktime]])
        vim.defer_fn(function()
          vim.g.is_saving = false
          pcall(vim.cmd.redrawstatus)
        end, 500)
      end
    end,
  },
  {
    event = { "User" },
    pattern = "GitSignsUpdate",
    command = redrawstatus,
  },
  {
    event = { "DiagnosticChanged" },
    command = redrawstatus,
  },
  {
    event = { "LspProgress" },
    command = function(ctx)
      local clientName = vim.lsp.get_client_by_id(ctx.data.client_id).name

      ---@type {percentage: number, title?: string, kind: string, message?: string}
      local progress = ctx.data.params.value
      local progress_icons = { "󰫃", "󰫄", "󰫅", "󰫆", "󰫇", "󰫈" }

      if not (progress and progress.title) then return end

      local idx = math.floor(#progress_icons / 2)
      local percentage = string.format("%.0f󱉸 ", 0)
      local text = ""
      local firstWord = vim.split(progress.title, " ")[1]:lower()

      if clear_messages_timer then
        clear_messages_timer:close()
        clear_messages_on_end()
      end

      clear_messages_on_end = function()
        clear_messages_timer = nil
        clear_messages_on_end = nil
        vim.g.lsp_progress_messages = ""
        pcall(vim.cmd.redrawstatus)
      end

      if progress.kind == "end" then
        vim.g.lsp_progress_messages = fmt("%s %s loaded.", Icons.lsp.ok, clientName)

        clear_messages_timer = vim.defer_fn(clear_messages_on_end, 1000)
      else
        if progress.percentage ~= nil then
          if progress.percentage == nil or progress.percentage == 0 then
            idx = 1
          elseif progress.percentage > 0 and progress.percentage < 100 then
            idx = math.ceil(progress.percentage / 100 * #progress_icons)
            percentage = string.format("%.0f󱉸 ", progress.percentage)
          else
            percentage = ""
          end

          local firstWord = vim.split(progress.title, " ")[1]:lower()

          text = table.concat({ progress_icons[idx], percentage, clientName, firstWord }, " ")

          vim.g.lsp_progress_messages = text
        else
          text = table.concat({ clientName, firstWord }, " ")

          vim.g.lsp_progress_messages = text
        end
      end

      pcall(vim.cmd.redrawstatus)
    end,
  },
})

-- ( SETTERS ) -----------------------------------------------------------------

--- @param hl string
local function wrap(hl, contents)
  assert(hl, "A highlight name must be specified")
  contents = contents or ""
  return "%#" .. hl .. "#" .. contents
end

local function seg(contents, hl, cond, opts)
  if type(hl) == "table" then
    opts = hl
    hl = "Statusline"
    cond = true
  else
    hl = hl or "Statusline"
  end

  -- effectively shifting the cond argument and using the table as opts
  if type(cond) == "table" then
    opts = cond
    cond = true
  end

  if cond ~= nil and not cond then return "" end

  --[[

  -- |  -- --- --  | --
  |  |  |   |   |  |  |
  M  F  P   C   P  S  M

  M - margin
  F - prefix characters
  P - padding
  C - content
  P - padding
  S - suffix characters
  M - margin

  --]]

  opts = vim.tbl_extend("force", {
    margin = { 0, 0 },
    prefix = "",
    prefix_hl = hl,
    padding = { 0, 0 },
    suffix = "",
    suffix_hl = hl,
  }, opts or {})

  -- local segment = "%#" .. hl .. "#" .. contents

  return table.concat({
    string.rep(" ", opts.margin[1]),
    wrap(opts.prefix_hl),
    opts.prefix,
    wrap(hl),
    string.rep(" ", opts.padding[1]),
    contents,
    string.rep(" ", opts.padding[2]),
    wrap(opts.suffix_hl),
    opts.suffix,
    string.rep(" ", opts.margin[2]),
  })
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

-- insert grouping separators in numbers
-- viml regex: https://stackoverflow.com/a/42911668
-- lua pattern: stolen from Akinsho
local function group_number(num, sep)
  if num < 999 then return tostring(num) end

  num = tostring(num)
  return num:reverse():gsub("(%d%d%d)", "%1" .. sep):reverse():gsub("^,", "")
end

-- ( CONSTANTS ) ---------------------------------------------------------------

-- Custom `^V` and `^S` symbols to make this file appropriate for copy-paste
-- (otherwise those symbols are not displayed).
local CTRL_S = vim.keycode("<C-S>", true, true, true)
local CTRL_V = vim.keycode("<C-V>", true, true, true)
local MODES = setmetatable({
  ["n"] = { long = "Normal", short = "N", hl = "StModeNormal", separator_hl = "StSeparator" },
  ["no"] = { long = "N-OPERATOR PENDING", short = "N-OP", hl = "StModeNormal", separator_hl = "StSeparator" },
  ["nov"] = { long = "N-OPERATOR BLOCK", short = "N-OPv", hl = "StModeNormal", separator_hl = "StSeparator" },
  ["noV"] = { long = "N-OPERATOR LINE", short = "N-OPV", hl = "StModeNormal", separator_hl = "StSeparator" },
  ["v"] = { long = "Visual", short = "V", hl = "StModeVisual", separator_hl = "StSeparator" },
  ["V"] = { long = "V-Line", short = "V-L", hl = "StModeVisual", separator_hl = "StSeparator" },
  [CTRL_V] = { long = "V-Block", short = "V-B", hl = "StModeVisual", separator_hl = "StSeparator" },
  ["s"] = { long = "Select", short = "S", hl = "StModeVisual", separator_hl = "StSeparator" },
  ["S"] = { long = "S-Line", short = "S-L", hl = "StModeVisual", separator_hl = "StSeparator" },
  [CTRL_S] = { long = "S-Block", short = "S-B", hl = "StModeVisual", separator_hl = "StSeparator" },
  ["i"] = { long = "Insert", short = "I", hl = "StModeInsert", separator_hl = "StSeparator" },
  ["R"] = { long = "Replace", short = "R", hl = "StModeReplace", separator_hl = "StSeparator" },
  ["c"] = { long = "Command", short = "C", hl = "StModeCommand", separator_hl = "StSeparator" },
  ["r"] = { long = "Prompt", short = "P", hl = "StModeOther", separator_hl = "StSeparator" },
  ["!"] = { long = "Shell", short = "Sh", hl = "StModeOther", separator_hl = "StSeparator" },
  ["t"] = { long = "Terminal", short = "T-I", hl = "StModeOther", separator_hl = "StSeparator" },
  ["nt"] = { long = "N-Terminal", short = "T-N", hl = "StModeNormal", separator_hl = "StSeparator" },
  ["r?"] = { long = "Confirm", short = "?", hl = "StModeOther", separator_hl = "StSeparator" },
}, {
  -- By default return 'Unknown' but this shouldn't be needed
  __index = function() return { long = "Unknown", short = "U", hl = "StModeOther", separator_hl = "StSeparator" } end,
})

local plain_types = {
  filetypes = {
    "help",
    "minimap",
    "Trouble",
    "tsplayground",
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
    "oil",
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
    terminal = fmt("%s ", Icons.misc.terminal),
    quickfix = fmt("%s ", Icons.misc.terminal),
  },
  filenames = {
    __committia_diff__ = "git commit (diff)",
    __committia_status__ = "git commit (status)",
    COMMIT_EDITMSG = "git commit (message)",
  },
  filetypes = {
    alpha = "",
    org = "",
    orgagenda = "",
    dbui = "",
    tsplayground = "󰺔",
    fugitive = Icons.vcs,
    fugitiveblame = Icons.vcs,
    gitcommit = Icons.vcs,
    NeogitCommitMessage = Icons.vcs,
    Trouble = "",
    NeogitStatus = Icons.git.symbol,
    vimwiki = "󰖬",
    help = Icons.misc.help,
    undotree = fmt("%s", Icons.misc.file_tree),
    NvimTree = fmt("%s", Icons.misc.file_tree),
    dirbuf = "",
    oil = "",
    ["neo-tree"] = fmt("%s", Icons.misc.file_tree),
    toggleterm = fmt("%s ", Icons.misc.terminal),
    megaterm = fmt("%s ", Icons.misc.terminal),
    terminal = fmt("%s ", Icons.misc.terminal),
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
    dirbuf = function(fname, buf)
      -- local shell = fnamemodify(vim.env.SHELL, ":t")
      -- local parts = vim.split(fname, " ")
      -- dd(parts)
      return seg(fmt("DirBuf %s", vim.fn.expand("%:p")))
    end,
    oil = function(fname, buf)
      -- local shell = fnamemodify(vim.env.SHELL, ":t")
      -- local parts = vim.split(fname, " ")
      -- dd(parts)
      return seg(fmt("%s", vim.fn.expand("%:p")))
    end,
    toggleterm = function(_, bufnr)
      local shell = fnamemodify(vim.env.SHELL, ":t")
      return seg(fmt("Terminal(%s)[%s]", shell, api.nvim_buf_get_var(bufnr, "toggle_number")))
    end,
    megaterm = function(_, bufnr)
      local shell = fnamemodify(vim.env.SHELL, ":t") or vim.o.shell
      local mode = MODES[api.nvim_get_mode().mode]
      local mode_hl = mode.short == "T-I" and "StModeTermInsert" or "StModeTermNormal"
      local term_buf_var = vim.api.nvim_buf_get_var(bufnr, "term_buf")
      if vim.g.term_buf ~= nil or term_buf_var ~= nil then
        return seg(
          string.format(
            "%s(%s)[%s]",
            vim.api.nvim_buf_get_var(bufnr, "term_name"),
            shell,
            vim.api.nvim_buf_get_var(bufnr, "term_cmd") or bufnr
          ),
          mode_hl
        )
        -- return seg(
        --   string.format("megaterm#%d(%s)[%s]", vim.api.nvim_buf_get_var(bufnr, "term_buf"), shell, vim.api.nvim_buf_get_var(bufnr, "term_cmd") or bufnr),
        --   mode_hl
        -- )
      end

      return seg(string.format("megaterm#%d(%s)", bufnr, shell), mode_hl)
    end,
    ["dap-repl"] = "Debugger REPL",
    firenvim = function(fname, buf) return seg(fmt("%s firenvim (%s)", Icons.misc.flames, M.ctx.filetype)) end,
  },
}

-- ( UTILITIES ) ---------------------------------------------------------------

local function current_file()
  local f = {}

  f.path = vim.fn.expand("%:p")
  f.name = vim.fn.fnamemodify(f.path, ":t")
  f.extension = vim.fn.fnamemodify(f.path, ":e")
  f.directory = vim.fn.fnamemodify(f.path, ":h")

  return f
end

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
  -- get's just the current split window
  local check = vim.api.nvim_win_get_width(0) < (trunc or -1)

  -- gets the whole nvim window
  if vim.api.nvim_get_option("laststatus") == 3 then check = vim.o.columns < (trunc or -1) end

  return check
end

--- truncate with an ellipsis or if surrounded by quotes, replace contents of quotes with ellipsis
--- @param str string
--- @param max_size integer
--- @return string
local function truncate_str(str, max_size)
  if not max_size or strwidth(str) < max_size then return str end
  local match, count = str:gsub("(['\"]).*%1", "%1" .. Icons.misc.ellipsis .. "%1")
  return count > 0 and match or str:sub(1, max_size - 1) .. Icons.misc.ellipsis
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
  if vim.g.started_by_firenvim then return exception_types.names.firenvim() end
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
  local status = vim.b[M.ctx.bufnr].gitsigns_status_dict or {}
  local is_valid = status and status.head ~= nil
  return is_valid and status or is_valid
end

-- ( GETTERS ) -----------------------------------------------------------------

local function get_diagnostics(seg_formatters_status)
  seg_formatters_status = seg_formatters_status or ""
  local function count(lvl) return #vim.diagnostic.get(M.ctx.bufnr, { severity = lvl }) end
  if vim.tbl_isempty(vim.lsp.get_clients({ bufnr = M.ctx.bufnr })) then return "" end

  local diags = {
    { num = count(vim.diagnostic.severity.ERROR), sign = Icons.lsp.error, hl = "StError" },
    { num = count(vim.diagnostic.severity.WARN), sign = Icons.lsp.warn, hl = "StWarn" },
    { num = count(vim.diagnostic.severity.INFO), sign = Icons.lsp.info, hl = "StInfo" },
    { num = count(vim.diagnostic.severity.HINT), sign = Icons.lsp.hint, hl = "StHint" },
  }

  local segments = ""
  for _, d in ipairs(diags) do
    if d.num > 0 then
      segments = fmt("%s%s", segments, seg(fmt("%s%s", d.num, d.sign), d.hl, { padding = { 1, 1 } }))
    end
  end

  return seg(segments .. "" .. seg_formatters_status, { margin = { 1, 1 } })
end

local function get_lsp_status(messages)
  --TODO: do some gsub replacements on the messages
  if string.match(messages, "loaded.") then
    return seg(string.gsub(messages, "loaded.", ""), "StModeInsert", { margin = { 1, 1 } })
  else
    return seg(messages, "StLspMessages", { margin = { 1, 1 } })
  end
  -- return seg(messages, "StBrightItalic", { margin = { 1, 1 } })
end

local function parse_filename(truncate_at)
  local function buf_expand(bufnr, mod) return expand("#" .. bufnr .. mod) end

  local modifier = ":t"
  local special_file_names = special_buffers()
  local special_buf = special_buffers()
  if special_buf then return "", "", special_buf end

  local fname = buf_expand(M.ctx.bufnr, modifier)

  local ok_devicons = pcall(require, "nvim-web-devicons")
  local icon, icon_hl = nil, nil
  if ok_devicons then
    icon, icon_hl = require("nvim-web-devicons").get_icon_color(fname)
  end

  local name = exception_types.names[M.ctx.filetype]
  if exception_types.filenames[current_file().name] ~= nil then
    name = exception_types.filenames[current_file().name]
  end
  local exception_icon = exception_types.filetypes[M.ctx.filetype] or ""
  if type(name) == "function" then return "", "", fmt("%s %s", exception_icon, name(fname, M.ctx.bufnr)) end

  if name then return "", "", name end

  if not fname or U.empty(fname) then return "", "", "No Name" end

  local path = (M.ctx.buftype == "" and not M.ctx.preview) and buf_expand(M.ctx.bufnr, ":~:.:h") or nil
  local is_root = path and #path == 1 -- "~" or "."
  -- local dir = path and not is_root and fn.pathshorten(fnamemodify(path, ":h")) .. "/" or ""
  local dir = path and not is_root and fn.pathshorten(fnamemodify(path, ":h")) .. "" or ""
  local parent = path and (is_root and path or fnamemodify(path, ":t")) or ""
  -- parent = parent ~= "" and parent .. "/" or ""
  parent = parent ~= "" and parent .. "" or ""

  return dir, parent, fname, icon, icon_hl
end

local function get_filename_parts(truncate_at)
  local directory_hl = "StDirectory"
  local parent_hl = "StParentDirectory"
  local filename_hl = "StFilename"

  -- if H.winhighlight_exists(M.ctx.winid, "Normal", "StatusLine") then
  --   directory_hl = H.adopt_winhighlight(M.ctx.winid, "StatusLine", "StCustomDirectory", "StTitle")
  --   parent_hl = H.adopt_winhighlight(M.ctx.winid, "StatusLine", "StCustomParentDir", "StTitle")
  --   filename_hl = H.adopt_winhighlight(M.ctx.winid, "StatusLine", "StCustomFilename", "StTitle")
  -- end

  local directory, parent, file, icon, icon_hl = parse_filename(truncate_at)

  return {
    file = { item = file, hl = filename_hl },
    dir = { item = directory, hl = directory_hl },
    parent = { item = parent, hl = parent_hl },
    icon = { item = icon, hl = icon_hl },
  }
end

-- ( SEGMENTS ) ----------------------------------------------------------------

local function seg_filename(truncate_at)
  local segments = get_filename_parts(truncate_at)

  local dir, parent, file, icon = segments.dir, segments.parent, segments.file, segments.icon

  local filename = file.item
  -- if icon.item ~= nil then filename = fmt(" %s %s", icon.item, file.item) end

  local file_hl = M.ctx.modified and "StModified" or file.hl

  -- usually our custom titles, like for megaterm, neo-tree, etc
  if dir.item == "" and parent.item == "" then
    return seg(
      fmt("%s%s%s", seg(dir.item, dir.hl), seg(parent.item, parent.hl), seg(filename, file_hl)),
      { margin = { 1, 1 } }
    )
  end

  -- if icon.item == nil or icon.item == "" then
  --   return seg(fmt("%s/%s/%s", seg(dir.item, dir.hl), seg(parent.item, parent.hl), seg(file.item, file_hl)), { margin = { 1, 1 } })
  -- end
  -- return seg(fmt("%s/%s/ %s %s", seg(dir.item, dir.hl), seg(parent.item, parent.hl), seg(icon.item, file_hl), seg(file.item, file_hl)), { margin = { 1, 1 } })

  if dir.item == "/" then
    return seg(fmt("/%s/%s", seg(parent.item, parent.hl), seg(filename, file_hl)), { margin = { 1, 1 } })
  end

  return seg(
    fmt("%s/%s/%s", seg(dir.item, dir.hl), seg(parent.item, parent.hl), seg(filename, file_hl)),
    { margin = { 1, 1 } }
  )
end

local function seg_buffer_count(truncate_at)
  local buffer_count = U.get_bufnrs()

  local msg = (is_truncated(truncate_at) or vim.g.started_by_firenvim) and ""
    or fmt("%s%s", Icons.misc.buffers, buffer_count)

  if buffer_count <= 1 then return "" end
  return seg(msg, "StBufferCount", { padding = { 0, 0 } })
end

local function seg_mode(truncate_at)
  -- Some useful glyphs:
  -- https://www.nerdfonts.com/cheat-sheet
  --           
  local mode_info = MODES[api.nvim_get_mode().mode]
  local mode = is_truncated(truncate_at) and mode_info.short or mode_info.long
  return seg(string.upper(mode), mode_info.hl, { padding = { 1, 1 } })
  -- return seg(string.upper(mode), mode_info.hl, { padding = { 1, 1 }, suffix = "░", suffix_hl = mode_info.separator_hl })
end

local function seg_lsp_clients(truncate_at)
  local bufnr = vim.api.nvim_get_current_buf()
  local clients = vim.lsp.get_clients({ bufnr = bufnr })

  if next(clients) == nil then return "" end

  local client_names = {}

  local function lsp_lookup(name)
    if U.tlen(clients) <= 2 then return name end
    local ls = vim.g.lsp_lookup[name]
    if ls == nil then ls = name end

    return ls
  end

  for _, client in pairs(clients) do
    table.insert(client_names, lsp_lookup(client.name))
  end

  local clients_str = U.strim(table.concat(client_names, "/"))
  if is_truncated(truncate_at) then
    return seg(#client_names, { prefix = fmt("%s ", Icons.lsp.clients), margin = { 0, 0 } })
  end
  return seg(clients_str, { prefix = fmt("%s ", Icons.lsp.clients), margin = { 0, 0 } })
end

local function seg_lsp_status(truncate_at)
  if is_truncated(truncate_at) then return "" end

  -- local enabled = not vim.g.disable_autoformat
  -- return get_diagnostics(seg(icons.kind.Null, "StModeInsert", enabled))

  -- -- Disable once we get fidget doing all the right things:
  local ok_messages, messages = pcall(vim.lsp.status)

  if ok_messages then
    if messages == "" and vim.g.lsp_progress_messages == "" then
      local enabled = not vim.g.disable_autoformat
      return get_diagnostics(seg(Icons.kind.Null, "StModeInsert", enabled, { margin = { 1, 0 } }))
    end
  end

  return get_lsp_status(vim.g.lsp_progress_messages)
end

-- file/selection info -------------------------------------

local function seg_selection_info()
  local sep_hl = "StLineSep"
  if not vim.fn.mode():find("[Vv]") then return "" end

  local wc = vim.fn.wordcount()
  local starts = vim.fn.line("v")
  local ends = vim.fn.line(".")
  local lines = starts <= ends and ends - starts + 1 or starts - ends + 1
  local words = wc.visual_words
  local chars = wc.visual_chars

  return seg(
    wrap(
      "VisualYank",
      table.concat({
        wrap("StModifiedIcon", "" .. " "),
        wrap("StLineNumber", tostring(chars) .. "ꮯ"),
        wrap(sep_hl, "/"),
        wrap("StLineTotal", tostring(words) .. "w"),
        wrap(sep_hl, ":"),
        wrap("StLineColumn", tostring(lines) .. "ꮮ"), -- alts: "%-3c" (for padding of 3)
      })
    ),
    { margin = { 1, 1 } }
  )
end

local function seg_lineinfo(truncate_at)
  local sep_hl = "StLineSep"

  -- Use virtual column number to allow update when paste last column
  if vim.fn.mode():find("[Vv]") then
    return seg_selection_info()
  else
    if is_truncated(truncate_at) then return "%l/%L:%v" end

    return seg(
      table.concat({
        wrap("StMetadataPrefix", Icons.misc.ln_sep .. " "),
        wrap("StLineNumber", "%l"),
        wrap(sep_hl, "/"),
        wrap("StLineTotal", "%L"),
        wrap(sep_hl, ":"),
        wrap("StLineColumn", "%-c"), -- alts: "%-3c" (for padding of 3)
      }),
      { margin = { 1, 1 } }
    )
  end
end

local function get_git_hunks()
  local status = vim.b[M.ctx.bufnr].gitsigns_status
  local head = vim.b[M.ctx.bufnr].gitsigns_head
  local status_dict = vim.b[M.ctx.bufnr].gitsigns_status_dict

  if status then
    if not U.falsy(status) then return head, status_dict, status end
    return head, {}, nil
  end

  if head then return head, {}, nil end

  return nil, {}, nil
end

local function seg_git_status(truncate_at)
  if is_abnormal_buffer() then return "" end

  local truncate_branch_at, truncate_symbol_at = unpack(truncate_at)
  local git_branch, git_status_dict, git_status = get_git_hunks()
  if U.falsy(git_branch) then return "" end

  local branch = is_truncated(truncate_branch_at) and truncate_str(git_branch or "", 14) or git_branch

  local added = string.format("+%s ", git_status_dict.added)
  local removed = string.format("-%s ", git_status_dict.removed)
  local changed = string.format("~%s ", git_status_dict.changed)

  return seg(
    table.concat({
      wrap("StGitBranch", branch),
      -- seg(git_status, "StBright", not U.falsy(git_status), { margin = { 1, 0 } }),
      seg(
        table.concat({
          wrap("StGitSignsAdd", added),
          wrap("StGitSignsDelete", removed),
          wrap("StGitSignsChange", changed),
        }),
        "Statusline",
        not U.falsy(git_status) and not is_truncated(truncate_branch_at),
        { margin = { 1, 0 } }
      ),
    }),
    { margin = { 1, 0 } }
  )
end

local function seg_megaterms()
  if Megaterm == nil then return "" end
  local megaterms = Megaterm.list()
  --        or icons.misc.terminal
  if #megaterms > 0 then return seg(fmt("%s %s", "", #megaterms)) end
  return ""
end

local function seg_rec_macro()
  local recording_register = vim.fn.reg_recording()
  local str = ""
  if recording_register ~= "" then str = " " .. recording_register end
  return seg(str, "StGitBranch", { margin = { 1, 1 }, padding = { 1, 0 } })
end

local function is_focused() return tonumber(vim.g.actual_curwin) == vim.api.nvim_get_current_win() end

-- ( STATUSLINE ) --------------------------------------------------------------

function mega.ui.statusline.render()
  local winnr = vim.g.statusline_winid or 0
  local bufnr = api.nvim_win_get_buf(winnr)
  local modified_icon = vim.g.started_by_firenvim and "?" or fmt("%s", Icons.misc.modified)

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

  -- vim.o.statusline = "%#Statusline# %2{mode()} | %F %m %r %= %{&spelllang} %y %8(%l,%c%) %8p%%"
  if not is_focused() then
    return "%#StatusLineInactive# %F %m %r %{&paste?'[paste] ':''} %= %{&spelllang}  %y %8(%l,%c%) %8p%%"
  end

  if is_plain() then
    local parts = {
      seg([[%<]]),
      seg_filename(),
      seg(modified_icon, "StModifiedIcon", M.ctx.modified, { margin = { 0, 1 } }),
      seg(Icons.misc.lock, "StModifiedIcon", M.ctx.readonly, { margin = { 0, 1 } }),
      "%=",
    }

    return table.concat(parts, "")
  end

  return table.concat({
    -- LEFT --------------------------------------------------------------------
    seg([[%<]]),
    -- seg_prefix(100),
    seg_mode(120),
    seg_buffer_count(100),
    seg_filename(120),
    seg(modified_icon, "StModifiedIcon", M.ctx.modified, { margin = { 0, 1 } }),
    seg(Icons.misc.lock, "StModifiedIcon", M.ctx.readonly, { margin = { 0, 1 } }),
    -- seg("%{&paste?'[paste] ':''}", "warningmsg", { margin = { 1, 1 } }),
    seg("Saving…", "StComment", vim.g.is_saving, { margin = { 0, 1 } }),
    -- seg_search_results(120),
    seg([[%=]]),
    -- CENTER ------------------------------------------------------------------
    seg_rec_macro(),
    seg_megaterms(),
    -- seg(get_substitution_status()),
    -- seg_hydra(120),
    seg([[%=]]),
    -- RIGHT -------------------------------------------------------------------
    seg("%*"),
    seg("%{&ff!='unix'?'['.&ff.'] ':''}", "warningmsg"),
    seg("%*"),
    seg("%{(&fenc!='utf-8'&&&fenc!='')?'['.&fenc.'] ':''}", "warningmsg"),
    seg("%*"),
    seg_lsp_clients(150),
    seg_lsp_status(100),
    seg_git_status({ 175, 80 }),
    -- seg(get_dap_status()),
    seg_lineinfo(75),
    -- seg_startuptime(),
    -- seg_suffix(100),
  })
end

vim.o.statusline = "%{%v:lua.mega.ui.statusline.render()%}"
