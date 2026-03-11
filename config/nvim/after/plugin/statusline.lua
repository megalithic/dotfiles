if not Plugin_enabled() then
  vim.o.statusline = "%#Statusline# %2{mode()} | %F %m %r %= %{&spelllang} %y %8(%l,%c%) %8p%%"
  return
end

mega.ui.statusline = {}

-- HT: @akinsho, @echasnovski, @lukas-reineke, @kristijanhusak, @mfussenegger

local ctx -- Module-level context, set in render()

local fn = vim.fn
local api = vim.api
local expand = fn.expand
local strwidth = fn.strwidth
local fnamemodify = fn.fnamemodify
local fmt = string.format

local U = mega.u or {} -- Use the global utils with fallback

vim.g.is_saving = false
vim.g.lsp_progress_messages = ""

local redrawstatus = vim.schedule_wrap(function() vim.cmd.redrawstatus() end)

-- Diagnostics scope: "buffer_lsps" or "workspace_lsps"
local diagnostics_scope = "buffer_lsps"

-- Jujutsu (jj) cache - updated async on events, read during render
local jj_cache = { is_repo = false, change_id = nil, bookmarks = {}, conflict = false }

local function update_jj_cache()
  -- Check if in jj repo (cached, only runs on events not every render)
  jj_cache.is_repo = vim.fn.finddir(".jj", ".;") ~= ""
  if not jj_cache.is_repo then
    jj_cache.change_id = nil
    jj_cache.bookmarks = {}
    jj_cache.conflict = false
    return
  end

  vim.system(
    { "jj", "log", "-r", "@", "--no-graph", "-T", 'change_id.shortest(8) ++ "|" ++ bookmarks ++ "|" ++ conflict' },
    { text = true },
    function(result)
      if result.code ~= 0 then return end
      local output = vim.trim(result.stdout)
      local parts = vim.split(output, "|")
      if #parts >= 3 then
        jj_cache.change_id = parts[1] ~= "" and parts[1] or nil
        jj_cache.bookmarks = parts[2] ~= "" and vim.split(parts[2], " ") or {}
        jj_cache.conflict = parts[3] == "true"
      end
      vim.schedule(redrawstatus)
    end
  )
end

local clear_messages_timer
local clear_messages_on_end

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
    -- Redraw on mode change (for pi terminal exit hint)
    event = { "ModeChanged" },
    pattern = { "*:t", "t:*" },
    command = redrawstatus,
  },
  {
    event = { "LspProgress" },
    command = function(ctx)
      local client = vim.lsp.get_client_by_id(ctx.data.client_id)
      if not client then return end
      local clientName = client.name

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
        if clear_messages_on_end then clear_messages_on_end() end
      end

      clear_messages_on_end = function()
        clear_messages_timer = nil
        clear_messages_on_end = nil
        vim.g.lsp_progress_messages = ""
        pcall(vim.cmd.redrawstatus)
      end

      if progress.kind == "end" then
        vim.g.lsp_progress_messages = fmt("%s %s loaded.", mega.ui.icons.lsp.ok, clientName)

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

-- Jujutsu status updates (async)
Augroup("mega.ui.statusline.jj", {
  {
    event = { "VimEnter", "DirChanged" },
    command = update_jj_cache,
  },
  {
    event = { "BufWritePost", "FocusGained" },
    command = function()
      vim.defer_fn(update_jj_cache, 100) -- slight delay to let jj update
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

  opts = vim.tbl_extend("force", {
    margin = { 0, 0 },
    prefix = "",
    prefix_hl = hl,
    padding = { 0, 0 },
    suffix = "",
    suffix_hl = hl,
  }, opts or {})

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

-- ( CONSTANTS ) ---------------------------------------------------------------

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
    terminal = fmt("%s ", mega.ui.icons.misc.terminal),
    quickfix = fmt("%s ", mega.ui.icons.misc.terminal),
  },
  filenames = {
    __committia_diff__ = "git commit (diff)",
    __committia_status__ = "git commit (status)",
    COMMIT_EDITMSG = "git commit (message)",
  },
  filetypes = {
    alpha = "",
    org = "",
    orgagenda = "",
    dbui = "",
    tsplayground = "󰺔",
    fugitive = mega.ui.icons.git.symbol,
    fugitiveblame = mega.ui.icons.git.symbol,
    gitcommit = mega.ui.icons.git.symbol,
    NeogitCommitMessage = mega.ui.icons.git.symbol,
    Trouble = "",
    NeogitStatus = mega.ui.icons.git.symbol,
    vimwiki = "󰖬",
    help = mega.ui.icons.misc.help,
    undotree = fmt("%s", mega.ui.icons.misc.file_tree),
    NvimTree = fmt("%s", mega.ui.icons.misc.file_tree),
    dirbuf = "",
    oil = "",
    ["neo-tree"] = fmt("%s", mega.ui.icons.misc.file_tree),
    toggleterm = fmt("%s ", mega.ui.icons.misc.terminal),
    megaterm = fmt("%s ", mega.ui.icons.misc.terminal),
    terminal = fmt("%s ", mega.ui.icons.misc.terminal),
    calendar = "",
    minimap = "",
    octo = "",
    ["dap-repl"] = "",
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
    dirbuf = function(fname, buf) return seg(fmt("DirBuf %s", vim.fn.expand("%:p"))) end,
    oil = function(fname, buf) return seg(fmt("%s", vim.fn.expand("%:p"))) end,
    toggleterm = function(_, bufnr)
      local shell = fnamemodify(vim.env.SHELL, ":t")
      return seg(fmt("Terminal(%s)[%s]", shell, api.nvim_buf_get_var(bufnr, "toggle_number")))
    end,
    megaterm = function(_, bufnr)
      local shell = fnamemodify(vim.env.SHELL, ":t") or vim.o.shell
      local mode = MODES[api.nvim_get_mode().mode]
      local mode_hl = mode.short == "T-I" and "StModeTermInsert" or "StModeTermNormal"

      local ok, term_buf_var = pcall(vim.api.nvim_buf_get_var, bufnr, "term_buf")
      if ok and (vim.g.term_buf ~= nil or term_buf_var ~= nil) then
        local _, term_name = pcall(vim.api.nvim_buf_get_var, bufnr, "term_name")
        local _, term_cmd = pcall(vim.api.nvim_buf_get_var, bufnr, "term_cmd")
        return seg(string.format("%s(%s)[%s]", term_name or "megaterm", shell, term_cmd or bufnr), mode_hl)
      end

      return seg(string.format("megaterm#%d(%s)", bufnr, shell), mode_hl)
    end,
    ["dap-repl"] = "Debugger REPL",
    firenvim = function(fname, buf) return seg(fmt("%s firenvim (%s)", mega.ui.icons.misc.flames, ctx.filetype)) end,
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

local function is_truncated(trunc)
  local check = vim.api.nvim_win_get_width(0) < (trunc or -1)

  if vim.o.laststatus == 3 then check = vim.o.columns < (trunc or -1) end

  return check
end

local function truncate_str(str, max_size)
  if not max_size or strwidth(str) < max_size then return str end
  local match, count = str:gsub("(['\"]).*%1", "%1" .. mega.ui.icons.misc.ellipsis .. "%1")
  return count > 0 and match or str:sub(1, max_size - 1) .. mega.ui.icons.misc.ellipsis
end

local function matches(str, list)
  return #vim.tbl_filter(function(item) return item == str or string.match(str, item) end, list) > 0
end

local function special_buffers()
  local location_list = fn.getloclist(0, { filewinid = 0 })
  local is_loc_list = location_list.filewinid > 0
  local normal_term = ctx.buftype == "terminal" and ctx.filetype == ""

  if is_loc_list then return "Location List" end
  if vim.g.started_by_firenvim then return exception_types.names.firenvim() end
  if ctx.buftype == "quickfix" then return "Quickfix List" end
  if normal_term then return "Terminal(" .. fnamemodify(vim.env.SHELL, ":t") .. ")" end
  if ctx.preview then return "preview" end

  return nil
end

local function is_plain()
  return matches(ctx.filetype, plain_types.filetypes) or matches(ctx.buftype, plain_types.buftypes) or ctx.preview
end

local function is_abnormal_buffer() return vim.bo.buftype ~= "" end

local function is_valid_git()
  local status = vim.b[ctx.bufnr].gitsigns_status_dict or {}
  local is_valid = status and status.head ~= nil
  return is_valid and status or is_valid
end

-- ( GETTERS ) -----------------------------------------------------------------

-- Count diagnostics by context (buffer or workspace) and severity
-- When diagnostics_scope == "buffer_lsps", workspace counts only include LSPs attached to current buffer
local function count_diagnostics(ctx, severity)
  local bufnr = ctx == "buffer" and 0 or nil
  local namespaces = nil

  if ctx == "workspace" and diagnostics_scope == "buffer_lsps" then
    -- Only count from LSPs attached to current buffer
    -- Get client names for filtering
    local client_names = {}
    for _, client in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
      client_names[client.name] = true
    end

    -- Filter diagnostics by LSP client source
    local all_diags = vim.diagnostic.get(bufnr, { severity = severity })
    local filtered_count = 0
    for _, diag in ipairs(all_diags) do
      if diag.source and client_names[diag.source] then filtered_count = filtered_count + 1 end
    end
    return filtered_count
  else
    return #vim.diagnostic.get(bufnr, { severity = severity })
  end
end

-- Buffer/workspace diagnostics display (replaces old get_diagnostics)
-- Shows: " 2/15  3/8" (buffer_count/workspace_count)
local function seg_diagnostics()
  if vim.tbl_isempty(vim.lsp.get_clients({ bufnr = 0 })) then return "" end

  local severity = vim.diagnostic.severity
  local parts = {}

  local eb = count_diagnostics("buffer", severity.ERROR)
  local ew = count_diagnostics("workspace", severity.ERROR)
  local wb = count_diagnostics("buffer", severity.WARN)
  local ww = count_diagnostics("workspace", severity.WARN)

  if eb > 0 or ew > 0 then
    local buf_str = eb > 0 and tostring(eb) or "-"
    table.insert(parts, wrap("StError", mega.ui.icons.lsp.error .. " " .. buf_str .. "/" .. ew))
  end

  if wb > 0 or ww > 0 then
    local buf_str = wb > 0 and tostring(wb) or "-"
    table.insert(parts, wrap("StWarn", mega.ui.icons.lsp.warn .. " " .. buf_str .. "/" .. ww))
  end

  if #parts == 0 then
    return seg("󰓏", "StComment", { margin = { 1, 0 } }) -- all clear
  end

  return seg(table.concat(parts, " "), { margin = { 1, 0 } })
end

local function get_lsp_status(messages)
  if string.match(messages, "loaded.") then
    return seg(string.gsub(messages, "loaded.", ""), "StModeInsert", { margin = { 1, 1 } })
  else
    return seg(messages, "StLspMessages", { margin = { 1, 1 } })
  end
end

local function parse_filename(truncate_at)
  local function buf_expand(bufnr, mod) return expand("#" .. bufnr .. mod) end

  local modifier = ":t"
  local special_buf = special_buffers()
  if special_buf then return "", "", special_buf end

  local fname = buf_expand(ctx.bufnr, modifier)

  local ok_devicons = pcall(require, "nvim-web-devicons")
  local icon, icon_hl = nil, nil
  if ok_devicons then
    icon, icon_hl = require("nvim-web-devicons").get_icon_color(fname)
  end

  local name = exception_types.names[ctx.filetype]
  if exception_types.filenames[current_file().name] ~= nil then
    name = exception_types.filenames[current_file().name]
  end
  local exception_icon = exception_types.filetypes[ctx.filetype] or ""
  if type(name) == "function" then return "", "", fmt("%s %s", exception_icon, name(fname, ctx.bufnr)) end

  if name then return "", "", name end

  if not fname or U.empty(fname) then return "", "", "No Name" end

  local path = (ctx.buftype == "" and not ctx.preview) and buf_expand(ctx.bufnr, ":~:.:h") or nil
  local is_root = path and #path == 1
  local dir = path and not is_root and fn.pathshorten(fnamemodify(path, ":h")) .. "" or ""
  local parent = path and (is_root and path or fnamemodify(path, ":t")) or ""
  parent = parent ~= "" and parent .. "" or ""

  return dir, parent, fname, icon, icon_hl
end

local function get_filename_parts(truncate_at)
  local directory_hl = "StDirectory"
  local parent_hl = "StParentDirectory"
  local filename_hl = "StFilename"

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

  local file_hl = ctx.modified and "StModified" or file.hl

  if dir.item == "" and parent.item == "" then
    return seg(
      fmt("%s%s%s", seg(dir.item, dir.hl), seg(parent.item, parent.hl), seg(filename, file_hl)),
      { margin = { 1, 1 } }
    )
  end

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
    or fmt("%s%s", mega.ui.icons.misc.buffers, buffer_count)

  if buffer_count <= 1 then return "" end
  return seg(msg, "StBufferCount", { padding = { 0, 0 } })
end

local function seg_mode(truncate_at)
  local mode_info = MODES[api.nvim_get_mode().mode]
  local mode = is_truncated(truncate_at) and mode_info.short or mode_info.long
  return seg(string.upper(mode), mode_info.hl, { padding = { 1, 1 } })
end

-- LSP progress messages only (diagnostics now in seg_diagnostics)
local function seg_lsp_progress(truncate_at)
  if is_truncated(truncate_at) then return "" end

  local messages = vim.g.lsp_progress_messages or ""
  if messages == "" then return "" end

  return get_lsp_status(messages)
end

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
        wrap("StModifiedIcon", mega.ui.icons.misc.ln_sel .. " "),
        wrap("StLineNumber", tostring(chars) .. "ꮯ"),
        wrap(sep_hl, "/"),
        wrap("StLineTotal", tostring(words) .. "w"),
        wrap(sep_hl, ":"),
        wrap("StLineColumn", tostring(lines) .. "ꮮ"),
      })
    ),
    { margin = { 1, 1 } }
  )
end

local function seg_lineinfo(truncate_at)
  local sep_hl = "StLineSep"

  if vim.fn.mode():find("[Vv]") then
    return seg_selection_info()
  else
    if is_truncated(truncate_at) then return "%l/%L:%v" end

    return seg(
      table.concat({
        wrap("StMetadataPrefix", mega.ui.icons.misc.ln_sep .. " "),
        wrap("StLineNumber", "%l"),
        wrap(sep_hl, "/"),
        wrap("StLineTotal", "%L"),
        wrap(sep_hl, ":"),
        wrap("StLineColumn", "%-c"),
      }),
      { margin = { 1, 1 } }
    )
  end
end

local function get_git_hunks()
  local status = vim.b[ctx.bufnr].gitsigns_status
  local head = vim.b[ctx.bufnr].gitsigns_head
  local status_dict = vim.b[ctx.bufnr].gitsigns_status_dict

  if status then
    if not U.falsy(status) then return head, status_dict, status end
    return head, {}, nil
  end

  if head then return head, {}, nil end

  return nil, {}, nil
end

local function seg_git_status(truncate_at)
  if is_abnormal_buffer() then return "" end
  -- Skip git status if in a jj repo (jj handles VCS display)
  if jj_cache.is_repo then return "" end

  local truncate_branch_at, truncate_symbol_at = unpack(truncate_at)
  local git_branch, git_status_dict, git_status = get_git_hunks()
  if U.falsy(git_branch) then return "" end

  local branch = is_truncated(truncate_branch_at) and truncate_str(git_branch or "", 14) or git_branch

  local added = string.format("+%s ", git_status_dict.added or 0)
  local removed = string.format("-%s ", git_status_dict.removed or 0)
  local changed = string.format("~%s ", git_status_dict.changed or 0)

  return seg(
    table.concat({
      wrap("StGitBranch", branch),
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

local function seg_jj_status(truncate_at)
  if not jj_cache.change_id then return "" end

  local parts = {}

  -- Change ID (always show)
  table.insert(parts, wrap("StJjChangeId", jj_cache.change_id))

  -- Bookmark (if any, show first one, truncate if needed)
  if #jj_cache.bookmarks > 0 then
    local bm = jj_cache.bookmarks[1]
    if truncate_at and is_truncated(truncate_at) then bm = bm:sub(1, 10) end
    table.insert(parts, wrap("StJjBookmark", " " .. bm))
  end

  -- Conflict indicator
  if jj_cache.conflict then table.insert(parts, wrap("StJjConflict", " " .. mega.ui.icons.jj.conflict)) end

  return seg(
    table.concat({
      wrap("StJjIcon", mega.ui.icons.jj.symbol .. " "),
      table.concat(parts),
    }),
    { margin = { 1, 0 } }
  )
end

local function seg_megaterms()
  if mega.term == nil then return "" end
  local megaterms = mega.term.list()
  if #megaterms > 0 then
    local content = seg(fmt("%s %s", mega.ui.icons.misc.terminal, #megaterms))
    -- Make clickable to toggle terminal
    return "%@v:lua.mega.term.toggle@" .. content .. "%X"
  end
  return ""
end

local function seg_pi()
  if mega.p.pi == nil then return "" end

  local data = mega.p.pi.statusline_data()
  local icon = mega.ui.icons.pi.symbol

  -- Add panel indicator
  if mega.p.pi.is_panel_open and mega.p.pi.is_panel_open() then icon = icon .. "•" end

  if not data.connected then return seg(icon, "StComment", { margin = { 1, 0 } }) end

  local session = data.session or "pi"
  local ctx_str = data.context_count > 0 and fmt(" %d", data.context_count) or ""

  local content = seg(
    table.concat({
      wrap("StIdentifier", icon .. " "),
      wrap("StComment", session),
      wrap("StBufferCount", ctx_str),
    }),
    { margin = { 1, 0 } }
  )

  -- Make clickable to select session
  return "%@v:lua.mega.p.pi.select_session@" .. content .. "%X"
end

local function seg_rec_macro()
  local recording_register = vim.fn.reg_recording()
  local str = ""
  if recording_register ~= "" then str = " " .. recording_register end
  return seg(str, "StGitBranch", { margin = { 1, 1 }, padding = { 1, 0 } })
end

local function is_focused() return tonumber(vim.g.actual_curwin) == vim.api.nvim_get_current_win() end

-- ( STATUSLINE ) --------------------------------------------------------------

function mega.ui.statusline.render()
  local winnr = vim.g.statusline_winid or 0
  local bufnr = api.nvim_win_get_buf(winnr)
  local modified_icon = vim.g.started_by_firenvim and "?" or fmt("%s", mega.ui.icons.misc.modified)

  ctx = {
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

  if not is_focused() then
    return "%#StatusLineInactive# %F %m %r %{&paste?'[paste] ':''} %= %{&spelllang}  %y %8(%l,%c%) %8p%%"
  end

  -- Pi terminal gets a custom statusline
  if mega.p.pi and mega.p.pi.is_pi_terminal and mega.p.pi.is_pi_terminal(bufnr) then
    return mega.p.pi.render_term_statusline(bufnr)
  end

  if is_plain() then
    local parts = {
      seg([[%<]]),
      seg_filename(),
      seg(modified_icon, "StModifiedIcon", ctx.modified, { margin = { 0, 1 } }),
      seg(mega.ui.icons.misc.lock, "StModifiedIcon", ctx.readonly, { margin = { 0, 1 } }),
      "%=",
    }

    return table.concat(parts, "")
  end

  if vim.g.shade_context then
    local parts = {
      seg([[%<]]),
      seg(" 󰠮 notes "),
      seg_filename(),
      seg(modified_icon, "StModifiedIcon", ctx.modified, { margin = { 0, 1 } }),
      seg(mega.ui.icons.misc.lock, "StModifiedIcon", ctx.readonly, { margin = { 0, 1 } }),
      seg([[%=]]),
      seg_lineinfo(75),
    }

    return table.concat(parts, "")
  end

  return table.concat({
    seg([[%<]]),
    seg_mode(120),
    seg_buffer_count(100),
    seg_filename(120),
    seg(modified_icon, "StModifiedIcon", ctx.modified, { margin = { 0, 1 } }),
    seg(mega.ui.icons.misc.lock, "StModifiedIcon", ctx.readonly, { margin = { 0, 1 } }),
    seg("Saving…", "StComment", vim.g.is_saving, { margin = { 0, 1 } }),
    seg([[%=]]),
    seg_rec_macro(),
    seg_pi(),
    seg_megaterms(),
    seg([[%=]]),
    seg("%*"),
    seg("%{&ff!='unix'?'['.&ff.'] ':''}", "warningmsg"),
    seg("%*"),
    seg("%{(&fenc!='utf-8'&&&fenc!='')?'['.&fenc.'] ':''}", "warningmsg"),
    seg("%*"),
    seg_diagnostics(),
    seg_lsp_progress(100),
    seg_git_status({ 175, 80 }),
    seg_jj_status(120),
    seg_lineinfo(75),
  })
end

vim.o.statusline = "%{%v:lua.mega.ui.statusline.render()%}"

-- Toggle diagnostics scope: buffer_lsps (only attached LSPs) vs workspace_lsps (all)
vim.keymap.set("n", "<leader>td", function()
  diagnostics_scope = diagnostics_scope == "buffer_lsps" and "workspace_lsps" or "buffer_lsps"
  vim.cmd.redrawstatus()
  vim.notify("Diagnostics scope: " .. diagnostics_scope)
end, { desc = "Toggle diagnostics scope" })
