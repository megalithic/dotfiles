if not mega then return end

mega.ui.statusline = {}

-- @akinsho, @echasnovski, @lukas-reineke, @kristijanhusak, @mfussenegger

-- if not plugin_loaded("megaline") then
--   vim.o.statusline = "%#Statusline# %2{mode()} | %F %m %r %= %{&spelllang} %y %8(%l,%c%) %8p%%"
--
--   return
-- end

local M = {}

local fn = vim.fn
local api = vim.api
local expand = fn.expand
local strwidth = fn.strwidth
local fnamemodify = fn.fnamemodify
local fmt = string.format

local U = require("mega.utils")
local H = U.hl
local augroup = require("mega.autocmds").augroup
local icons = require("mega.settings").icons

vim.g.is_saving = false
local search_count_timer

augroup("megaline", {
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
  -- {
  --   event = { "LspProgress" },
  --   command = function() pcall(vim.cmd.redrawstatus) end,
  -- },
  {
    event = { "CursorMoved" },
    pattern = { "*" },
    command = function()
      -- TODO: wrap all of this in an xpcall to handle an error raised when searching, for example, for `dbg\(`
      if vim.o.hlsearch then
        local timer = vim.uv.new_timer()
        search_count_timer = timer
        timer:start(0, 200, function()
          vim.schedule(function()
            if timer == search_count_timer then
              pcall(vim.fn.searchcount, { recompute = 1, maxcount = 0, timeout = 100 })
              pcall(vim.cmd.redrawstatus)
            end
          end)
        end)
      end
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
    prefix_hl = "Statusline",
    padding = { 0, 0 },
    suffix = "",
    suffix_hl = "Statusline",
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

-- ( CONSTANTS ) ---------------------------------------------------------------

-- Custom `^V` and `^S` symbols to make this file appropriate for copy-paste
-- (otherwise those symbols are not displayed).
local CTRL_S = vim.keycode("<C-S>", true, true, true)
local CTRL_V = vim.keycode("<C-V>", true, true, true)
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
    terminal = fmt("%s ", icons.misc.terminal),
    quickfix = fmt("%s ", icons.misc.terminal),
  },
  filetypes = {
    alpha = "",
    org = "",
    orgagenda = "",
    dbui = "",
    tsplayground = "󰺔",
    fugitive = icons.vcs,
    fugitiveblame = icons.vcs,
    gitcommit = icons.vcs,
    NeogitCommitMessage = icons.vcs,
    Trouble = "",
    NeogitStatus = icons.git.symbol,
    vimwiki = "󰖬",
    help = icons.misc.help,
    undotree = fmt("%s", icons.misc.file_tree),
    NvimTree = fmt("%s", icons.misc.file_tree),
    dirbuf = "",
    oil = "",
    ["neo-tree"] = fmt("%s", icons.misc.file_tree),
    toggleterm = fmt("%s ", icons.misc.terminal),
    megaterm = fmt("%s ", icons.misc.terminal),
    terminal = fmt("%s ", icons.misc.terminal),
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
      return seg(fmt("Oil %s", vim.fn.expand("%:p")))
    end,
    toggleterm = function(_, buf)
      local shell = fnamemodify(vim.env.SHELL, ":t")
      return seg(fmt("Terminal(%s)[%s]", shell, api.nvim_buf_get_var(buf, "toggle_number")))
    end,
    megaterm = function(_, buf)
      local shell = fnamemodify(vim.env.SHELL, ":t")
      local mode = MODES[api.nvim_get_mode().mode]
      local mode_hl = mode.short == "T-I" and "StModeTermInsert" or "StModeTermNormal"
      return seg(fmt("megaterm#%d(%s)[%s]", api.nvim_buf_get_var(buf, "term_buf"), shell, api.nvim_buf_get_var(buf, "term_cmd") or buf), mode_hl)
    end,
    ["dap-repl"] = "Debugger REPL",
    kittybuf = "Kitty Scrollback Buffer",
    firenvim = function(fname, buf) return seg(fmt("%s firenvim (%s)", icons.misc.flames, M.ctx.filetype)) end,
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
  -- get's just the current split window
  local check = api.nvim_win_get_width(0) < (trunc or -1)

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
  local match, count = str:gsub("(['\"]).*%1", "%1" .. icons.misc.ellipsis .. "%1")
  return count > 0 and match or str:sub(1, max_size - 1) .. icons.misc.ellipsis
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

local function is_plain() return matches(M.ctx.filetype, plain_types.filetypes) or matches(M.ctx.buftype, plain_types.buftypes) or M.ctx.preview end

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
    { num = count(vim.diagnostic.severity.ERROR), sign = icons.lsp.error, hl = "StError" },
    { num = count(vim.diagnostic.severity.WARN), sign = icons.lsp.warn, hl = "StWarn" },
    { num = count(vim.diagnostic.severity.INFO), sign = icons.lsp.info, hl = "StInfo" },
    { num = count(vim.diagnostic.severity.HINT), sign = icons.lsp.hint, hl = "StHint" },
  }

  local segments = ""
  for _, d in ipairs(diags) do
    if d.num > 0 then segments = fmt("%s %s", segments, seg(fmt("%s%s", d.num, d.sign), d.hl)) end
  end

  return seg(segments .. " " .. seg_formatters_status, { margin = { 1, 1 } })
end

local function get_lsp_status(messages)
  --TODO: do some gsub replacements on the messages
  return seg(messages, { margin = { 1, 1 } })
end

local function get_dap_status()
  local ok, dap = pcall(require, "dap")
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
  -- if result == nil or vim.tbl_isempty(result) then return "" end
  -- return " " .. last_search:gsub("\\v", "") .. " " .. result.current .. "/" .. result.total .. ""

  if result.incomplete == 1 then -- timed out
    return fmt("%s %s ?/??", icons.misc.search, last_search)
  elseif result.incomplete == 2 then -- max count exceeded
    if result.total > result.maxcount and result.current > result.maxcount then
      return fmt("%s %s >%d/>%d", icons.misc.search, last_search, result.current, result.total)
    elseif result.total > result.maxcount then
      return fmt("%s %s %d/>%d (%s)", icons.misc.search, last_search, result.current, result.total)
    end
  end

  return fmt("%s %s %d/%d", icons.misc.search, last_search, result.current, result.total)
end

local function parse_filename(truncate_at)
  local function buf_expand(bufnr, mod) return expand("#" .. bufnr .. mod) end

  local modifier = ":t"
  local special_buf = special_buffers()
  if special_buf then return "", "", special_buf end

  local fname = buf_expand(M.ctx.bufnr, modifier)

  local name = exception_types.names[M.ctx.filetype]
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

  return dir, parent, fname
end

local function get_filename_parts(truncate_at)
  local directory_hl = "StDirectory"
  local parent_hl = "StParentDirectory"
  local filename_hl = "StFilename"

  if H.winhighlight_exists(M.ctx.winid, "Normal", "StatusLine") then
    directory_hl = H.adopt_winhighlight(M.ctx.winid, "StatusLine", "StCustomDirectory", "StTitle")
    parent_hl = H.adopt_winhighlight(M.ctx.winid, "StatusLine", "StCustomParentDir", "StTitle")
    filename_hl = H.adopt_winhighlight(M.ctx.winid, "StatusLine", "StCustomFilename", "StTitle")
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

  -- usually our custom titles, like for megaterm, neo-tree, etc
  if dir.item == "" and parent.item == "" then
    return seg(fmt("%s%s%s", seg(dir.item, dir.hl), seg(parent.item, parent.hl), seg(file.item, file_hl)), { margin = { 1, 1 } })
  end

  return seg(fmt("%s/%s/%s", seg(dir.item, dir.hl), seg(parent.item, parent.hl), seg(file.item, file_hl)), { margin = { 1, 1 } })
end

local function seg_prefix(truncate_at)
  local mode_info = MODES[api.nvim_get_mode().mode]
  local prefix = is_truncated(truncate_at) and "" or icons.misc.lblock
  return seg(prefix, mode_info.hl)
end

local function seg_suffix(truncate_at)
  local mode_info = MODES[api.nvim_get_mode().mode]
  local prefix = is_truncated(truncate_at) and "" or icons.misc.rblock
  return seg(prefix, mode_info.hl)
end

local function seg_mode(truncate_at)
  local mode_info = MODES[api.nvim_get_mode().mode]
  local mode = is_truncated(truncate_at) and mode_info.short or mode_info.long
  return seg(string.upper(mode), mode_info.hl, { padding = { 1, 1 } })
end

local function seg_lsp_status(truncate_at)
  if is_truncated(truncate_at) then return "" end

  -- local lsp_client_names = table.concat(
  --   vim.tbl_map(function(client) return client.name end, vim.tbl_values(vim.lsp.get_clients({ bufnr = M.ctx.bufnr }))),
  --   ", "
  -- )

  -- Enable once we get fidget doing all the right things:
  -- local enabled = not vim.g.disable_autoformat
  -- return get_diagnostics(seg(icons.lsp.kind.Null, "StModeInsert", enabled))

  -- Disable once we get fidget doing all the right things:
  -- local ok_messages, messages = pcall(vim.lsp.status)
  --
  -- if ok_messages then
  --   if messages == "" then
  --     local enabled = not vim.g.disable_autoformat
  --     return get_diagnostics(seg(icons.lsp.kind.Null, "StModeInsert", enabled))
  --     -- else
  --     --   messages = vim.iter(vim.split(messages, ", ")):last():gsub("%%", "%%%%")
  --     -- dd(lsp_client_names)
  --     --dd(messages)
  --   end
  -- end

  -- return get_lsp_status(messages)

  local enabled = not vim.g.disable_autoformat
  return get_diagnostics(seg(icons.kind.Null, "StModeInsert", enabled))
end

local function seg_lineinfo(truncate_at)
  local prefix = icons.misc.ln_sep or "L"
  local sep_hl = "StLineSep"

  -- Use virtual column number to allow update when paste last column
  if is_truncated(truncate_at) then return "%l/%L:%v" end

  return seg(
    table.concat({
      wrap("StMetadataPrefix", prefix .. " "),
      wrap("StLineNumber", "%l"),
      wrap(sep_hl, "/"),
      wrap("StLineTotal", "%L"),
      wrap(sep_hl, ":"),
      wrap("StLineColumn", "%-c"), -- alts: "%-3c" (for padding of 3)
    }),
    { margin = { 1, 1 } }
  )
end

local function seg_search_results(truncate_at)
  return seg(fmt("%s", get_search_results()), "StCount", not is_truncated(truncate_at) and vim.v.hlsearch > 0, { margin = { 1, 1 }, padding = { 1, 1 } })
end

local function seg_opened_terms(truncate_at)
  local function is_valid(buf_num)
    if not buf_num or buf_num < 1 then return false end
    local exists = vim.api.nvim_buf_is_valid(buf_num)
    return vim.bo[buf_num].buflisted and exists
  end

  ---@return number[]
  ---@diagnostic disable-next-line: return-type-mismatch
  local function get_valid_buffers() return vim.tbl_filter(is_valid, vim.api.nvim_list_bufs()) end
  local bufs = {}
  for i, buf_id in ipairs(get_valid_buffers()) do
    table.insert(bufs, vim.api.nvim_buf_get_name(buf_id))
  end
  -- P(get_valid_buffers())
  return seg(fmt(" %s ", unpack(bufs)), "StCount", not is_truncated(truncate_at))
end

local function seg_hydra(truncate_at)
  local ok_hydra, hydra = pcall(require, "hydra", { silent = true })

  if ok_hydra then
    return seg(
      fmt("%s", hydra.statusline.get_name()),
      hydra.statusline.get_color(),
      not is_truncated(truncate_at) and hydra.statusline.is_active(),
      { margin = { 1, 1 }, padding = { 1, 1 } }
    )
  else
    return ""
  end
end

local function seg_git_symbol(truncate_at)
  if is_abnormal_buffer() or not is_valid_git() then return "" end

  local symbol = is_truncated(truncate_at) and "" or icons.git.symbol
  return seg(symbol, "StGitSymbol")
end

local function seg_git_status(truncate_at)
  if is_abnormal_buffer() then return "" end

  local status = is_valid_git()
  if not status then return "" end

  local branch = is_truncated(truncate_at) and truncate_str(status.head or "", 14) or status.head
  return seg(branch, "StGitBranch", { margin = { 1, 1 }, prefix = seg_git_symbol(80), padding = { 1, 0 } })
end

local function seg_startuptime()
  local stats = require("lazy").stats()
  local ms = (math.floor(stats.startuptime * 100 + 0.5) / 100)
  return seg(ms, "StComment", { margin = { 1, 1 }, prefix = " ", suffix = "ms", padding = { 0, 0 } })
end

local function is_focused() return tonumber(vim.g.actual_curwin) == vim.api.nvim_get_current_win() end

-- ( STATUSLINE ) --------------------------------------------------------------

function mega.ui.statusline.render()
  local winnr = vim.g.statusline_winid or 0
  local bufnr = api.nvim_win_get_buf(winnr)
  local modified_icon = vim.g.started_by_firenvim and "?" or fmt("[%s]", icons.misc.modified)

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
      seg([[%<]]),
      seg_filename(),
      seg(modified_icon, "StModifiedIcon", M.ctx.modified, { margin = { 0, 1 } }), -- alts: "%m"
      seg(icons.misc.lock, "StModifiedIcon", M.ctx.readonly, { margin = { 0, 1 } }), -- alts: "%r"
      "%=",
    }

    return table.concat(parts, "")
  end

  return table.concat({
    seg([[%<]]),
    -- seg_prefix(100),
    seg_mode(120),
    seg_filename(120),
    seg(modified_icon, "StModifiedIcon", M.ctx.modified, { margin = { 0, 1 } }), -- alts: "%m"
    seg(icons.misc.lock, "StModifiedIcon", M.ctx.readonly, { margin = { 0, 1 } }), -- alts: "%r"
    -- seg("%{&paste?'[paste] ':''}", "warningmsg", { margin = { 1, 1 } }),
    seg("Saving…", "StComment", vim.g.is_saving, { margin = { 0, 1 } }),
    seg_search_results(120),
    -- seg_opened_terms(120),
    -- end left alignment
    seg([[%=]]),
    -- seg(get_substitution_status()),
    --
    seg_hydra(120),
    seg([[%=]]),
    -- begin right alignment
    seg("%*"),
    seg("%{&ff!='unix'?'['.&ff.'] ':''}", "warningmsg"),
    seg("%*"),
    seg("%{(&fenc!='utf-8'&&&fenc!='')?'['.&fenc.'] ':''}", "warningmsg"),
    seg("%*"),
    seg_lsp_status(100),
    seg_git_status(120),
    -- seg(get_dap_status()),
    seg_lineinfo(75),
    -- seg_startuptime(),
    -- seg_suffix(100),
  })
end

print(vim.o.statusline)
vim.o.statusline = "%{%v:lua.mega.ui.statusline.render()%}"
